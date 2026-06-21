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
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
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
        return AppListPage(
          title: "财务",
          isEmpty: visibleEntries.isEmpty,
          empty: const AppEmptyState(
            icon: Icons.subscriptions_outlined,
            title: "还没有固定支出",
            message: "使用右下角「添加支出」新增订阅、房租或月度开销。",
          ),
          overview: _SubscriptionOverview(
            state: state,
            cubit: context.read<SubscriptionCubit>(),
            semantic: semantic,
            textSecondary: textSecondary,
          ),
          sliverBuilder: (_) {
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
    final warningActive = state.dueSoonEntries.isNotEmpty;

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
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  warningActive
                      ? Icons.warning_amber_rounded
                      : Icons.event_available_rounded,
                  color: warningActive ? semantic.warning : semantic.success,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    warningActive
                        ? "7 天内有 ${state.dueSoonEntries.length} 项即将扣费"
                        : "7 天内暂无扣费提醒",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: warningActive ? semantic.warning : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          AppSection(
            title: "分类",
            child: AppFilterChipBar<SubscriptionFilter>(
              value: state.filter,
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
          SizedBox(height: 12.h),
          AppSection(
            title: "排序",
            child: AppFilterChipBar<SubscriptionSortMode>(
              value: state.sortMode,
              onChanged: cubit.setSortMode,
              items: const [
                AppFilterChipItem(
                  value: SubscriptionSortMode.manual,
                  label: "手动",
                  icon: Icons.drag_handle_rounded,
                ),
                AppFilterChipItem(
                  value: SubscriptionSortMode.date,
                  label: "日期",
                  icon: Icons.schedule_rounded,
                ),
                AppFilterChipItem(
                  value: SubscriptionSortMode.price,
                  label: "金额",
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionEntry entry;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final bool showDragHandle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubscriptionCard({
    required this.entry,
    required this.semantic,
    required this.textSecondary,
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
                AppPill(
                  label: _cycleLabel(entry.cycle),
                  color: semantic.expense,
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
                  formatMoney(entry.price ?? 0),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: "Roboto",
                  ),
                ),
              ),
              if (showDragHandle) ...[
                SizedBox(height: 6.h),
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
}

class _DueStatus {
  final String label;
  final bool shouldHighlight;

  const _DueStatus(this.label, this.shouldHighlight);
}
