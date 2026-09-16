import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_list_page.dart';
import 'package:life_log/common/widgets/app_metric_grid.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_section.dart';
import 'package:life_log/common/widgets/app_swipe_action.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/application/delete_subscription_entry.dart';
import 'package:life_log/features/subscription/application/reorder_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';

import 'subscription_cubit.dart';
import 'subscription_dialogs.dart';
import 'subscription_editor_launcher.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionCubit>(
      create: (_) => serviceLocator<SubscriptionCubit>()..start(),
      child: const _SubscriptionContent(),
    );
  }
}

class _SubscriptionContent extends StatelessWidget {
  const _SubscriptionContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, state) {
        final visibleEntries = state.visibleEntries;
        final cubit = context.read<SubscriptionCubit>();
        final isLoading =
            state.status == SubscriptionReadStatus.initial ||
            state.status == SubscriptionReadStatus.loading;
        final isFailure = state.status == SubscriptionReadStatus.failure;
        final showPageState = isFailure || state.entries.isEmpty;
        return AppListPage(
          title: "订阅",
          isLoading: isLoading,
          loading: const AppLoading(label: '正在加载订阅'),
          isEmpty: !isLoading && showPageState,
          empty: isFailure
              ? _SubscriptionLoadFailure(onRetry: cubit.loadEntries)
              : const AppEmptyState(
                  icon: Icons.subscriptions_outlined,
                  title: "还没有固定支出",
                  message: "使用右下角「添加支出」新增订阅、房租或月度开销。",
                ),
          overview: showPageState
              ? null
              : _SubscriptionOverview(
                  state: state,
                  cubit: cubit,
                  semantic: semantic,
                  textSecondary: textSecondary,
                ),
          onRefresh: cubit.loadEntries,
          sliverBuilder: (_) {
            if (visibleEntries.isEmpty) {
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 88.h),
                sliver: const SliverToBoxAdapter(
                  child: ConstrainedPage(
                    child: AppEmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: "该分类暂无支出",
                      message: "切换分类或添加一笔对应类型的支出。",
                    ),
                  ),
                ),
              );
            }

            if (state.filter == SubscriptionFilter.all &&
                state.sortMode == SubscriptionSortMode.manual) {
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 88.h),
                sliver: SliverReorderableList(
                  itemCount: visibleEntries.length,
                  onReorder: (oldIndex, newIndex) {
                    unawaited(
                      _reorderEntries(
                        context,
                        visibleEntries,
                        oldIndex,
                        newIndex,
                      ),
                    );
                  },
                  itemBuilder: (context, index) {
                    final entry = visibleEntries[index];
                    return ConstrainedPage(
                      key: ValueKey(entry.id),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: ReorderableDelayedDragStartListener(
                          index: index,
                          child: _SubscriptionCard(
                            entry: entry,
                            semantic: semantic,
                            textSecondary: textSecondary,
                            exchangeRates: state.exchangeRates,
                            showDragHandle: true,
                            onTap: () => openSubscriptionEditorPage(
                              context,
                              entry: entry,
                            ),
                            onDelete: () => _deleteEntry(context, entry),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 88.h),
              sliver: SliverList.separated(
                itemCount: visibleEntries.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final entry = visibleEntries[index];
                  return ConstrainedPage(
                    child: Dismissible(
                      key: ValueKey('sub-dismiss-${entry.id}'),
                      direction: DismissDirection.endToStart,
                      background: const SizedBox.shrink(),
                      secondaryBackground: AppSwipeAction.delete(
                        color: theme.colorScheme.error,
                      ),
                      confirmDismiss: (_) => _deleteEntry(context, entry),
                      child: _SubscriptionCard(
                        entry: entry,
                        semantic: semantic,
                        textSecondary: textSecondary,
                        exchangeRates: state.exchangeRates,
                        onTap: () =>
                            openSubscriptionEditorPage(context, entry: entry),
                        onDelete: () => _deleteEntry(context, entry),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'subscription_add_fab',
            onPressed: () => openSubscriptionEditorPage(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text("添加支出"),
          ),
        );
      },
    );
  }

  Future<void> _reorderEntries(
    BuildContext context,
    List<SubscriptionEntry> entries,
    int oldIndex,
    int newIndex,
  ) async {
    final result = await serviceLocator<ReorderSubscriptionEntries>().call(
      entries,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );

    if (!context.mounted) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      _showSubscriptionMessage(
        context,
        "排序失败：${_errorText(failure.message)}",
        isError: true,
      );
      return;
    }

    await context.read<SubscriptionCubit>().loadEntries();
  }

  Future<bool> _deleteEntry(
    BuildContext context,
    SubscriptionEntry entry,
  ) async {
    final confirmed = await confirmSubscriptionDelete(
      context,
      name: entry.name,
    );
    if (confirmed) {
      final result = await serviceLocator<DeleteSubscriptionEntry>().call(
        entry.id,
      );
      if (!context.mounted) return result.isSuccess;

      final failure = result.failureOrNull;
      if (failure != null) {
        // A repository error may be reported after a local tombstone was
        // committed. Reload so a stale in-memory snapshot cannot restore it.
        await context.read<SubscriptionCubit>().loadEntries();
        if (!context.mounted) return false;
        _showSubscriptionMessage(
          context,
          "删除失败：${_errorText(failure.message)}",
          isError: true,
        );
        return false;
      }

      await context.read<SubscriptionCubit>().loadEntries();
      return true;
    }
    return false;
  }

  void _showSubscriptionMessage(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? theme.colorScheme.error : semantic.success,
        ),
      );
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _SubscriptionLoadFailure extends StatelessWidget {
  final VoidCallback onRetry;

  const _SubscriptionLoadFailure({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42.sp,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 12.h),
            Text(
              '订阅加载失败',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              '本地记录暂时无法读取，请重试。',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 16.h),
            AppButton.secondary(
              label: '重试',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionOverview extends StatelessWidget {
  final SubscriptionState state;
  final SubscriptionCubit cubit;
  final AppSemanticColors semantic;
  final Color textSecondary;

  const _SubscriptionOverview({
    required this.state,
    required this.cubit,
    required this.semantic,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMetricGrid(
            children: [
              AppMetricTile(
                label: "本月预计",
                value: formatMoney(state.currentMonthCost),
                icon: Icons.calendar_month_rounded,
                color: semantic.expense,
              ),
              AppMetricTile(
                label: "固定年支",
                value: formatMoney(state.yearlyCost),
                icon: Icons.account_balance_wallet_rounded,
                color: semantic.stats,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          AppCard(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
            child: _ReminderPanel(
              entries: state.reminderEntries,
              referenceDay: state.referenceDay,
              semantic: semantic,
              rates: state.exchangeRates,
            ),
          ),
          if (state.entries.any(
                (entry) => entry.currency != SubscriptionCurrency.cny,
              ) ||
              state.exchangeRatesLoading ||
              state.exchangeRates.warning != null ||
              state.currenciesWithoutRates.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _ExchangeRateNotice(state: state, semantic: semantic),
          ],
          SizedBox(height: 14.h),
          AppSection(
            title: '筛选与排序',
            trailing: PopupMenuButton<SubscriptionSortMode>(
              initialValue: state.sortMode,
              onSelected: cubit.setSortMode,
              tooltip: '选择排序',
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: SubscriptionSortMode.manual,
                  child: Text('手动排序'),
                ),
                PopupMenuItem(
                  value: SubscriptionSortMode.date,
                  child: Text('按扣费日期'),
                ),
                PopupMenuItem(
                  value: SubscriptionSortMode.price,
                  child: Text('按金额'),
                ),
              ],
              child: AppPill(
                label: _sortLabel(state.sortMode),
                icon: Icons.swap_vert_rounded,
                color: semantic.stats,
              ),
            ),
            child: AppCard(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
              child: AppFilterChipBar<SubscriptionFilter>(
                value: state.filter,
                columns: 4,
                onChanged: cubit.setFilter,
                items: const [
                  AppFilterChipItem(value: SubscriptionFilter.all, label: "全部"),
                  AppFilterChipItem(
                    value: SubscriptionFilter.monthly,
                    label: "每月",
                    icon: Icons.repeat_rounded,
                  ),
                  AppFilterChipItem(
                    value: SubscriptionFilter.yearly,
                    label: "每年",
                    icon: Icons.event_repeat_rounded,
                  ),
                  AppFilterChipItem(
                    value: SubscriptionFilter.oneTime,
                    label: "一次性",
                    icon: Icons.looks_one_rounded,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  String _sortLabel(SubscriptionSortMode mode) {
    return switch (mode) {
      SubscriptionSortMode.manual => '手动',
      SubscriptionSortMode.date => '日期',
      SubscriptionSortMode.price => '金额',
    };
  }
}

class _ReminderPanel extends StatelessWidget {
  final List<SubscriptionEntry> entries;
  final DateTime referenceDay;
  final AppSemanticColors semantic;
  final SubscriptionExchangeRates rates;

  const _ReminderPanel({
    required this.entries,
    required this.referenceDay,
    required this.semantic,
    required this.rates,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasReminders = entries.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasReminders
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: hasReminders ? semantic.warning : semantic.success,
              size: 21.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '扣费提醒',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              hasReminders ? '按单项设置' : '暂无提醒',
              style: TextStyle(fontSize: 11.sp, color: textSecondary),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (!hasReminders)
          Text(
            '近期没有需要提醒的扣费。可在编辑订阅中设置当天或提前 1、3、7、14 天提醒。',
            style: TextStyle(fontSize: 12.sp, color: textSecondary),
          )
        else
          for (final entry in entries.take(3))
            _ReminderRow(
              entry: entry,
              referenceDay: referenceDay,
              rates: rates,
              semantic: semantic,
            ),
        if (entries.length > 3) ...[
          SizedBox(height: 4.h),
          Text(
            '还有 ${entries.length - 3} 项提醒，请在列表中查看',
            style: TextStyle(fontSize: 11.sp, color: textSecondary),
          ),
        ],
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final SubscriptionEntry entry;
  final DateTime referenceDay;
  final SubscriptionExchangeRates rates;
  final AppSemanticColors semantic;

  const _ReminderRow({
    required this.entry,
    required this.referenceDay,
    required this.rates,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final localDate = dateOnlyLocal(entry.nextPaymentDate);
    final days = localDate.difference(dateOnlyLocal(referenceDay)).inDays;
    final dueLabel = days == 0
        ? '今天'
        : days == 1
        ? '明天'
        : '$days 天后';
    final converted = rates.convertToCny(entry.price ?? 0, entry.currency);
    final amount = formatSubscriptionAmount(entry.price ?? 0, entry.currency);
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        children: [
          Container(
            width: 7.w,
            height: 7.w,
            decoration: BoxDecoration(
              color: semantic.warning,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${entry.name} · $dueLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (entry.currency != SubscriptionCurrency.cny)
                Text(
                  converted == null
                      ? '人民币待换算'
                      : '≈ ¥${converted.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 10.sp, color: textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExchangeRateNotice extends StatelessWidget {
  final SubscriptionState state;
  final AppSemanticColors semantic;

  const _ExchangeRateNotice({required this.state, required this.semantic});

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final unsupported = state.currenciesWithoutRates
        .map((currency) => currency.code)
        .join('、');
    final message = state.exchangeRatesLoading
        ? '正在获取今日汇率，人民币统计会自动更新'
        : state.exchangeRates.warning ??
              (unsupported.isNotEmpty
                  ? '暂缺少 $unsupported 汇率，人民币统计未计入这些外币'
                  : '人民币估算使用 ${_rateDate(state.exchangeRates.rateDate)} 汇率');
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(Icons.sync_alt_rounded, size: 18.sp, color: semantic.stats),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11.sp, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _rateDate(DateTime date) {
    final local = dateOnlyLocal(date);
    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionEntry entry;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final SubscriptionExchangeRates exchangeRates;
  final bool showDragHandle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubscriptionCard({
    required this.entry,
    required this.semantic,
    required this.textSecondary,
    required this.exchangeRates,
    this.showDragHandle = false,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dueStatus = _dueStatus(entry.nextPaymentDate);
    final accent = dueStatus.shouldHighlight
        ? semantic.warning
        : semantic.expense;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.w),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              entry.name.trim().isNotEmpty
                  ? entry.name.trim().substring(0, 1)
                  : "?",
              style: TextStyle(
                color: accent,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  "下次 ${_date(entry.nextPaymentDate)} · ${dueStatus.label}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: dueStatus.shouldHighlight
                        ? semantic.warning
                        : textSecondary,
                    fontWeight: dueStatus.shouldHighlight
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    AppPill(
                      label: _cycleLabel(entry.cycle),
                      color: semantic.expense,
                    ),
                    AppPill(
                      label: _reminderLabel(entry.reminderDays),
                      icon: Icons.notifications_none_rounded,
                      color: semantic.stats,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatSubscriptionAmount(entry.price ?? 0, entry.currency),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: "Roboto",
                  ),
                ),
              ),
              if (entry.currency != SubscriptionCurrency.cny) ...[
                SizedBox(height: 3.h),
                Text(
                  _convertedAmount(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: Theme.of(context).colorScheme.error,
                tooltip: '删除订阅',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
              if (showDragHandle) ...[
                SizedBox(height: 2.h),
                Icon(
                  Icons.drag_indicator_rounded,
                  color: textSecondary,
                  size: 18.sp,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _date(DateTime date) {
    final local = dateOnlyLocal(date);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  _DueStatus _dueStatus(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = dateOnlyLocal(date);
    final target = DateTime(local.year, local.month, local.day);
    final days = target.difference(today).inDays;
    if (days < 0) return const _DueStatus("已过期", true);
    if (days == 0) return const _DueStatus("今天扣费", true);
    if (days <= 7) return _DueStatus("$days 天后", true);
    return _DueStatus("$days 天后", false);
  }

  String _cycleLabel(SubscriptionBillingCycle cycle) {
    switch (cycle) {
      case SubscriptionBillingCycle.monthly:
        return "每月";
      case SubscriptionBillingCycle.yearly:
        return "每年";
      case SubscriptionBillingCycle.oneTime:
        return "一次性";
      case SubscriptionBillingCycle.custom:
        return "自定义";
    }
  }

  String _reminderLabel(int days) {
    return days == 0 ? '当天提醒' : '提前$days天';
  }

  String _convertedAmount() {
    final converted = exchangeRates.convertToCny(
      entry.price ?? 0,
      entry.currency,
    );
    return converted == null
        ? '人民币汇率暂不可用'
        : '≈ ¥${converted.toStringAsFixed(2)}';
  }
}

class _DueStatus {
  final String label;
  final bool shouldHighlight;

  const _DueStatus(this.label, this.shouldHighlight);
}
