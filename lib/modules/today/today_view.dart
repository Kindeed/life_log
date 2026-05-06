import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_action_sheet.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/views/evidence_editor_sheet.dart';
import 'package:life_log/modules/expense/expense_record_controller.dart';
import 'package:life_log/modules/expense/views/expense_record_edit_view.dart';
import 'package:life_log/modules/subscription/subscription_controller.dart';
import 'package:life_log/modules/subscription/views/subscription_edit_view.dart';
import 'package:life_log/modules/tabs/tabs_controller.dart';
import 'package:life_log/modules/work_log/views/log_edit_view.dart';
import 'package:life_log/modules/work_log/work_log_controller.dart';
import 'package:life_log/modules/work_log/work_log_model.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final workLog = Get.find<WorkLogController>();
    final subscriptions = Get.find<SubscriptionController>();
    final evidence = Get.find<EvidenceController>();
    final expenses = Get.find<ExpenseRecordController>();
    final statsColor = Theme.of(context).semanticColors.stats;
    final semantic = Theme.of(context).semanticColors;
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(title: const Text('今天')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              workLog.loadData(),
              subscriptions.loadData(),
              evidence.loadEvidence(),
              expenses.loadRecords(),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ConstrainedPage(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateHeader(now: now, textSecondary: textSecondary),
                        SizedBox(height: 16.h),
                        Obx(() {
                          final todayLogs = workLog.getEventsForDay(today);
                          return _TodayLogCard(
                            logs: todayLogs,
                            onTap: () => Get.to(
                              () => LogEditView(
                                selectedDate: today,
                                existingLog: todayLogs.isEmpty
                                    ? null
                                    : todayLogs.first,
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: 12.h),
                        Obx(
                          () => _DueSoonCard(
                            subs: subscriptions.dueSoonSubs,
                            textSecondary: textSecondary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Obx(() {
                          final expenseTotal =
                              subscriptions.currentMonthCost +
                              expenses.totalForMonth(
                                DateTime(now.year, now.month),
                              );
                          return Row(
                            children: [
                              Expanded(
                                child: AppMetricTile(
                                  label: '本月工时',
                                  value: workLog.monthStatsHours.value
                                      .toStringAsFixed(1),
                                  icon: Icons.timelapse_rounded,
                                  color: semantic.work,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: AppMetricTile(
                                  label: '本月支出',
                                  value: formatMoney(expenseTotal),
                                  icon: Icons.payments_rounded,
                                  color: semantic.expense,
                                ),
                              ),
                            ],
                          );
                        }),
                        SizedBox(height: 10.h),
                        Obx(
                          () => AppMetricTile(
                            label: '凭证待报销',
                            value: formatMoney(evidence.totalPendingAmount),
                            icon: Icons.pending_actions_rounded,
                            color: statsColor,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _QuickActions(today: today),
                        SizedBox(height: 18.h),
                        Text(
                          '最近记录',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 10.h),
                        Obx(() => _RecentLogs(workLog: workLog, today: today)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime now;
  final Color textSecondary;

  const _DateHeader({required this.now, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('M月d日 EEEE').format(now),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4.h),
        Text('生活记录从今天开始', style: TextStyle(color: textSecondary)),
      ],
    );
  }
}

class _TodayLogCard extends StatelessWidget {
  final List<WorkLog> logs;
  final VoidCallback onTap;

  const _TodayLogCard({required this.logs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final primary = logs.isEmpty ? null : logs.first;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(
            Icons.today_rounded,
            color: Theme.of(context).semanticColors.work,
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今天的工作日志',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  primary == null ? '记录今天' : _logSummary(primary),
                  style: TextStyle(color: textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  String _logSummary(WorkLog log) {
    final type = switch (log.type) {
      LogType.work => '工作',
      LogType.rest => '休息',
      LogType.leave => '请假',
      LogType.businessTrip => '出差',
    };
    final extra = log.type == LogType.work
        ? ' · 加班 ${(log.overtimeHours ?? 0).toStringAsFixed(1)}h'
        : log.location?.trim().isNotEmpty == true
        ? ' · ${log.location}'
        : '';
    return '$type$extra';
  }
}

class _DueSoonCard extends StatelessWidget {
  final List subs;
  final Color textSecondary;

  const _DueSoonCard({required this.subs, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Theme.of(context).semanticColors.expense,
              ),
              SizedBox(width: 8.w),
              Text(
                '即将扣款',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => TabsController.to.changePage(2),
                child: const Text('查看全部'),
              ),
            ],
          ),
          if (subs.isEmpty)
            Text('7 天内没有订阅扣款', style: TextStyle(color: textSecondary))
          else
            for (final sub in subs.take(3))
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Row(
                  children: [
                    Expanded(child: Text(sub.name)),
                    Text(
                      '${sub.nextPaymentDate.month}/${sub.nextPaymentDate.day}  ${formatMoney(sub.price ?? 0)}',
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final DateTime today;

  const _QuickActions({required this.today});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(14.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          _action('工时', Icons.work_history_rounded, () {
            Get.to(() => LogEditView(selectedDate: today));
          }),
          _action('支出', Icons.payments_rounded, () {
            AppActionSheet.show(
              title: '添加支出',
              actions: [
                AppActionSheetItem(
                  icon: Icons.subscriptions_rounded,
                  title: '订阅/固定支出',
                  onTap: () => Get.to(() => const SubscriptionEditView()),
                ),
                AppActionSheetItem(
                  icon: Icons.receipt_rounded,
                  title: '一次性消费',
                  onTap: () =>
                      Get.to(() => ExpenseRecordEditView(initialDate: today)),
                ),
              ],
            );
          }),
          _action('凭证', Icons.attach_file_rounded, () {
            showEvidenceEditorSheet();
          }),
          _action('项目', Icons.folder_special_rounded, () {
            TabsController.to.changePage(3);
          }),
        ],
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) {
    return Builder(
      builder: (context) {
        final color = Theme.of(context).colorScheme.primary;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AppPill(
            icon: icon,
            label: label,
            color: color,
            selected: true,
          ),
        );
      },
    );
  }
}

class _RecentLogs extends StatelessWidget {
  final WorkLogController workLog;
  final DateTime today;

  const _RecentLogs({required this.workLog, required this.today});

  @override
  Widget build(BuildContext context) {
    final rows = <WorkLog>[];
    for (var i = 0; i < 7; i++) {
      rows.addAll(workLog.getEventsForDay(today.subtract(Duration(days: i))));
    }
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history_rounded,
        title: '最近没有记录',
        message: '使用上方快捷入口开始记录。',
      );
    }
    rows.sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: rows.take(7).map((log) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: AppCard(
            onTap: () => Get.to(
              () => LogEditView(selectedDate: log.date, existingLog: log),
            ),
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${log.date.month}/${log.date.day} · ${log.type.name}',
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
