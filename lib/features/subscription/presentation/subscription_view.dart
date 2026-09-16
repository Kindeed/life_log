import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_list_page.dart';
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
  final bool embedded;
  const SubscriptionView({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionCubit>(
      create: (_) => serviceLocator<SubscriptionCubit>()..start(),
      child: _SubscriptionContent(embedded: embedded),
    );
  }
}

class _SubscriptionContent extends StatelessWidget {
  final bool embedded;
  const _SubscriptionContent({required this.embedded});

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
          embedded: embedded,
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
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: ReorderableDelayedDragStartListener(
                          index: index,
                          child: _SubscriptionCard(
                            entry: entry,
                            semantic: semantic,
                            textSecondary: textSecondary,
                            exchangeRates: state.exchangeRates,
                            referenceDay: state.referenceDay,
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
                separatorBuilder: (_, _) => SizedBox(height: 8.h),
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
                        referenceDay: state.referenceDay,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: colors.onPrimaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.referenceDay.month} 月 · 本月预计',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(state.currentMonthCost),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Text('固定年支 ${formatMoney(state.yearlyCost)}'),
                    Text('${state.entries.length} 项订阅'),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (state.entries.any((e) => e.currency != SubscriptionCurrency.cny) ||
            state.exchangeRatesLoading ||
            state.exchangeRates.warning != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _ExchangeRateNotice(state: state),
          ),
        if (state.reminderEntries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(
                  Icons.notifications_none_rounded,
                  color: semantic.warning,
                ),
                title: Text(
                  '${state.reminderEntries.length} 项扣费提醒',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  for (final entry in state.reminderEntries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.name),
                      subtitle: Text(
                        '${entry.nextPaymentDate.month}月${entry.nextPaymentDate.day}日 · '
                        '${formatSubscriptionAmount(entry.price ?? 0, entry.currency)}',
                      ),
                      onTap: () =>
                          openSubscriptionEditorPage(context, entry: entry),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                '我的订阅',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PopupMenuButton<SubscriptionSortMode>(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 18, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      switch (state.sortMode) {
                        SubscriptionSortMode.manual => '手动',
                        SubscriptionSortMode.date => '日期',
                        SubscriptionSortMode.price => '金额',
                      },
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final filter in SubscriptionFilter.values)
              ChoiceChip(
                label: Text(switch (filter) {
                  SubscriptionFilter.all => '全部',
                  SubscriptionFilter.monthly => '每月',
                  SubscriptionFilter.yearly => '每年',
                  SubscriptionFilter.oneTime => '一次性',
                }),
                selected: state.filter == filter,
                showCheckmark: false,
                onSelected: (_) => cubit.setFilter(filter),
              ),
          ],
        ),
        if (state.filter == SubscriptionFilter.all &&
            state.sortMode == SubscriptionSortMode.manual)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '长按订阅可调整顺序',
              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
            ),
          ),
      ],
    );
  }
}

class _ExchangeRateNotice extends StatelessWidget {
  final SubscriptionState state;
  const _ExchangeRateNotice({required this.state});

  @override
  Widget build(BuildContext context) {
    final unsupported = state.currenciesWithoutRates
        .map((c) => c.code)
        .join('、');
    // Missing currencies remain explicit even when the rate provider also
    // reports a warning; totals must never appear complete in that case.
    final message = [
      if (unsupported.isNotEmpty) '缺少 $unsupported 汇率，合计未计入这些外币',
      if (state.exchangeRatesLoading)
        '正在更新汇率'
      else if (state.exchangeRates.warning != null)
        state.exchangeRates.warning!
      else
        '人民币估算 · ${state.exchangeRates.rateDate.month}月${state.exchangeRates.rateDate.day}日汇率',
    ].join(' · ');
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionEntry entry;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final SubscriptionExchangeRates exchangeRates;
  final DateTime referenceDay;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubscriptionCard({
    required this.entry,
    required this.semantic,
    required this.textSecondary,
    required this.exchangeRates,
    required this.referenceDay,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = dateOnlyLocal(
      entry.nextPaymentDate,
    ).difference(dateOnlyLocal(referenceDay)).inDays;
    final due = days < 0
        ? '已过期'
        : days == 0
        ? '今天扣费'
        : days == 1
        ? '明天扣费'
        : '${entry.nextPaymentDate.month}月${entry.nextPaymentDate.day}日扣费';
    final highlight = days >= 0 && days <= entry.reminderDays;
    final cycle = switch (entry.cycle) {
      SubscriptionBillingCycle.monthly => '每月',
      SubscriptionBillingCycle.yearly => '每年',
      SubscriptionBillingCycle.oneTime => '一次性',
      SubscriptionBillingCycle.custom => '自定义',
    };
    final amount = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatSubscriptionAmount(entry.price ?? 0, entry.currency),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          cycle,
          style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
        if (entry.currency != SubscriptionCurrency.cny)
          Text(
            _convertedAmount(),
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
      ],
    );
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Stack metadata and price for large text or narrow windows; never
          // shrink the user's requested font size to squeeze a currency value.
          final stacked =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(14) > 19;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      entry.name.trim().isEmpty
                          ? '?'
                          : entry.name.trim().characters.first,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          due,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: highlight ? semantic.warning : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!stacked) ...[
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * .38,
                      ),
                      child: amount,
                    ),
                  ],
                  PopupMenuButton<String>(
                    tooltip: '订阅操作',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) =>
                        value == 'edit' ? onTap() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑订阅')),
                      PopupMenuItem(value: 'delete', child: Text('删除订阅')),
                    ],
                  ),
                ],
              ),
              if (stacked) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: amount),
              ],
            ],
          );
        },
      ),
    );
  }

  String _convertedAmount() {
    final converted = exchangeRates.convertToCny(
      entry.price ?? 0,
      entry.currency,
    );
    return converted == null ? '人民币待换算' : '≈ ¥${converted.toStringAsFixed(2)}';
  }
}
