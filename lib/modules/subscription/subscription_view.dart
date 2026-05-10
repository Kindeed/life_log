import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/layout/constrained_page.dart';
import '../../common/utils/formatters.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_action_sheet.dart';
import '../../common/widgets/app_confirm_dialog.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_filter_chip_bar.dart';
import '../../common/widgets/app_floating_action_pill.dart';
import '../../common/widgets/app_metric_tile.dart';
import '../../common/widgets/app_pill.dart';
import '../../common/widgets/app_section_header.dart';
import '../expense/expense_record_controller.dart';
import '../expense/expense_record_model.dart';
import '../expense/views/expense_record_edit_view.dart';
import 'subscription_controller.dart';
import 'subscription_model.dart';
import 'views/subscription_edit_view.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<SubscriptionController>();
    final expenseLogic = Get.find<ExpenseRecordController>();
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("财务")),
      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            logic.onScroll(notification);
            return true;
          },
          child: Obx(() {
            final subsCount = logic.subs.length;
            final recordCount = expenseLogic.records.length;
            final section = logic.section.value;
            if (subsCount == 0 && recordCount == 0) {
              return AppEmptyState(
                icon: Icons.subscriptions_outlined,
                title: "还没有支出记录",
                message: "添加固定支出或项目支出后，会在这里看到财务概览。",
                actionLabel: "添加支出",
                onAction: () => _showAddActions(),
              );
            }

            final visibleSubs = section == FinanceSection.fixed
                ? logic.visibleSubs
                : const <Subscription>[];
            final visibleRecords = section == FinanceSection.records
                ? _sortedExpenseRecords(expenseLogic.records)
                : const <ExpenseRecord>[];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ConstrainedPage(
                    child: _SubscriptionOverview(
                      logic: logic,
                      expenseLogic: expenseLogic,
                      semantic: semantic,
                      textSecondary: textSecondary,
                      section: section,
                      onSectionChanged: logic.setSection,
                    ),
                  ),
                ),
                if (section == FinanceSection.records)
                  if (visibleRecords.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          "还没有项目支出",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 88.h),
                      sliver: SliverList.separated(
                        itemCount: visibleRecords.length,
                        separatorBuilder: (_, _) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final record = visibleRecords[index];
                          return ConstrainedPage(
                            child: _ExpenseRecordCard(
                              record: record,
                              semantic: semantic,
                              textSecondary: textSecondary,
                              onTap: () => Get.to(
                                () => ExpenseRecordEditView(record: record),
                              ),
                              onDelete: () =>
                                  _deleteExpenseRecord(expenseLogic, record),
                            ),
                          );
                        },
                      ),
                    )
                else if (visibleSubs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        "当前分类暂无记录",
                        style: TextStyle(color: textSecondary, fontSize: 14.sp),
                      ),
                    ),
                  )
                else if (_canReorder(logic))
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(
        () => AppFloatingActionPill(
          label: "添加支出",
          icon: Icons.add_rounded,
          color: semantic.expense,
          visible: logic.isFabVisible.value,
          onPressed: () => _showAddActions(),
        ),
      ),
    );
  }

  List<ExpenseRecord> _sortedExpenseRecords(List<ExpenseRecord> records) {
    return records.toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  bool _canReorder(SubscriptionController logic) {
    return logic.filter.value == SubscriptionFilter.all &&
        logic.sortMode.value == SubscriptionSortMode.manual;
  }

  void _showAddSheet([Subscription? sub]) {
    Get.to(() => SubscriptionEditView(sub: sub));
  }

  void _showAddActions() {
    AppActionSheet.show(
      title: '添加支出',
      actions: [
        AppActionSheetItem(
          icon: Icons.subscriptions_rounded,
          title: '订阅/固定支出',
          onTap: () => _showAddSheet(),
        ),
        AppActionSheetItem(
          icon: Icons.receipt_rounded,
          title: '一次性消费',
          onTap: () => Get.to(() => const ExpenseRecordEditView()),
        ),
      ],
    );
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

  Future<void> _deleteExpenseRecord(
    ExpenseRecordController logic,
    ExpenseRecord record,
  ) async {
    final title = record.merchant?.trim().isNotEmpty == true
        ? record.merchant!.trim()
        : record.category.label;
    final confirmed = await AppConfirmDialog.show(
      title: "删除项目支出",
      message: "确定删除「$title」这条支出吗？删除后无法恢复。",
      confirmLabel: "删除",
      destructive: true,
    );
    if (confirmed) {
      await logic.deleteRecord(record.id);
    }
  }
}

class _SubscriptionOverview extends StatelessWidget {
  final SubscriptionController logic;
  final ExpenseRecordController expenseLogic;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final FinanceSection section;
  final ValueChanged<FinanceSection> onSectionChanged;

  const _SubscriptionOverview({
    required this.logic,
    required this.expenseLogic,
    required this.semantic,
    required this.textSecondary,
    required this.section,
    required this.onSectionChanged,
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
                  value: formatMoney(
                    logic.currentMonthCost +
                        expenseLogic.totalForMonth(
                          DateTime(DateTime.now().year, DateTime.now().month),
                        ),
                  ),
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
          const AppSectionHeader(title: "类型"),
          SizedBox(height: 8.h),
          AppFilterChipBar<FinanceSection>(
            value: section,
            onChanged: onSectionChanged,
            items: const [
              AppFilterChipItem(
                value: FinanceSection.fixed,
                label: "固定支出",
                icon: Icons.subscriptions_rounded,
              ),
              AppFilterChipItem(
                value: FinanceSection.records,
                label: "项目支出",
                icon: Icons.receipt_rounded,
              ),
            ],
          ),
          if (section == FinanceSection.fixed) ...[
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
          ],
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.drag_indicator_rounded,
                      color: textSecondary,
                      size: 18.sp,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _date(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  _DueStatus _dueStatus(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
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

class _ExpenseRecordCard extends StatelessWidget {
  final ExpenseRecord record;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _ExpenseRecordCard({
    required this.record,
    required this.semantic,
    required this.textSecondary,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = record.merchant?.trim().isNotEmpty == true
        ? record.merchant!.trim()
        : record.category.label;
    final project = record.projectName?.trim();

    return Dismissible(
      key: ValueKey('expense-record-${record.id}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: _DeleteBackground(color: semantic.warning),
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: semantic.expense.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.receipt_rounded,
                color: semantic.expense,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    '${formatDateYmd(record.expenseDate)} · ${record.category.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp, color: textSecondary),
                  ),
                  if (project != null && project.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    AppPill(
                      icon: Icons.folder_special_rounded,
                      label: project,
                      color: semantic.project,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              formatMoney(record.amount),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                fontFamily: "Roboto",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueStatus {
  final String label;
  final bool shouldHighlight;

  const _DueStatus(this.label, this.shouldHighlight);
}
