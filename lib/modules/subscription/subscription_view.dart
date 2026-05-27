import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_confirm_dialog.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_section_header.dart';
import 'subscription_controller.dart';
import 'subscription_model.dart';
import 'views/subscription_edit_view.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<SubscriptionController>();
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("财务")),
      body: SafeArea(
        child: Obx(() {
          final visibleSubs = logic.visibleSubs;
          if (visibleSubs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.subscriptions_outlined,
              title: "还没有固定支出",
              message: "使用右下角「添加支出」新增订阅、房租或月度开销。",
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ConstrainedPage(
                  child: _SubscriptionOverview(
                    logic: logic,
                    semantic: semantic,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
              if (logic.filter.value == SubscriptionFilter.all &&
                  logic.sortMode.value == SubscriptionSortMode.manual)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 88.h),
                  sliver: SliverReorderableList(
                    itemCount: visibleSubs.length,
                    onReorder: logic.reorderSub,
                    itemBuilder: (context, index) {
                      final sub = visibleSubs[index];
                      return ConstrainedPage(
                        key: ValueKey(sub.id),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: ReorderableDelayedDragStartListener(
                            index: index,
                            child: _SubscriptionCard(
                              sub: sub,
                              semantic: semantic,
                              textSecondary: textSecondary,
                              showDragHandle: true,
                              onTap: () => _showAddSheet(sub),
                              onDelete: () => _deleteSub(logic, sub),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 88.h),
                  sliver: SliverList.separated(
                    itemCount: visibleSubs.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final sub = visibleSubs[index];
                      return ConstrainedPage(
                        child: Dismissible(
                          key: ValueKey('sub-dismiss-${sub.id}'),
                          direction: DismissDirection.endToStart,
                          background: const SizedBox.shrink(),
                          secondaryBackground: _DeleteBackground(
                            color: theme.colorScheme.error,
                          ),
                          confirmDismiss: (_) => _deleteSub(logic, sub),
                          child: _SubscriptionCard(
                            sub: sub,
                            semantic: semantic,
                            textSecondary: textSecondary,
                            onTap: () => _showAddSheet(sub),
                            onDelete: () => _deleteSub(logic, sub),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text("添加支出"),
      ),
    );
  }

  void _showAddSheet([Subscription? sub]) {
    Get.to(() => SubscriptionEditView(sub: sub));
  }

  Future<bool> _deleteSub(
    SubscriptionController logic,
    Subscription sub,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      title: "删除支出",
      message: "确定删除「${sub.name}」吗？删除后无法恢复。",
      confirmLabel: "删除",
      destructive: true,
    );
    if (confirmed) {
      await logic.deleteSub(sub.id);
      return true;
    }
    return false;
  }
}

class _SubscriptionOverview extends StatelessWidget {
  final SubscriptionController logic;
  final AppSemanticColors semantic;
  final Color textSecondary;

  const _SubscriptionOverview({
    required this.logic,
    required this.semantic,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final warningActive = logic.dueSoonCount > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: "本月预计",
                  value: formatMoney(logic.currentMonthCost),
                  icon: Icons.calendar_month_rounded,
                  color: semantic.expense,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppMetricTile(
                  label: "固定年支",
                  value: formatMoney(logic.yearlyCost),
                  icon: Icons.account_balance_wallet_rounded,
                  color: semantic.stats,
                ),
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
                        ? "7 天内有 ${logic.dueSoonCount} 项即将扣费"
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
          const AppSectionHeader(title: "分类"),
          SizedBox(height: 8.h),
          AppFilterChipBar<SubscriptionFilter>(
            value: logic.filter.value,
            onChanged: logic.setFilter,
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
          SizedBox(height: 12.h),
          const AppSectionHeader(title: "排序"),
          SizedBox(height: 8.h),
          AppFilterChipBar<SubscriptionSortMode>(
            value: logic.sortMode.value,
            onChanged: logic.setSortMode,
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
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Subscription sub;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final bool showDragHandle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubscriptionCard({
    required this.sub,
    required this.semantic,
    required this.textSecondary,
    this.showDragHandle = false,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dueStatus = _dueStatus(sub.nextPaymentDate);
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
              sub.name.trim().isNotEmpty
                  ? sub.name.trim().substring(0, 1)
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
                  sub.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  "下次 ${_date(sub.nextPaymentDate)} · ${dueStatus.label}",
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
                AppPill(label: _cycleLabel(sub.cycle), color: semantic.expense),
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
                  formatMoney(sub.price ?? 0),
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

  String _cycleLabel(SubscriptionCycle cycle) {
    switch (cycle) {
      case SubscriptionCycle.monthly:
        return "每月";
      case SubscriptionCycle.yearly:
        return "每年";
      case SubscriptionCycle.oneTime:
        return "一次性";
    }
  }
}

class _DeleteBackground extends StatelessWidget {
  final Color color;

  const _DeleteBackground({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 22.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}

class _DueStatus {
  final String label;
  final bool shouldHighlight;

  const _DueStatus(this.label, this.shouldHighlight);
}
