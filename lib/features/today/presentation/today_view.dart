import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/presentation/evidence_add_action_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';
import 'package:life_log/features/expense/presentation/expense_record_editor_launcher.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/presentation/subscription_editor_launcher.dart';
import 'package:life_log/features/subscription/presentation/subscription_today_cubit.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_launcher.dart';
import 'package:life_log/features/work_log/presentation/work_log_today_cubit.dart';
import 'package:life_log/features/shell/presentation/tabs_controller.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WorkLogTodayCubit>(
          create: (_) => serviceLocator<WorkLogTodayCubit>()..start(),
        ),
        BlocProvider<SubscriptionTodayCubit>(
          create: (_) => serviceLocator<SubscriptionTodayCubit>()..start(),
        ),
        BlocProvider<ExpenseRecordCubit>(
          create: (_) => serviceLocator<ExpenseRecordCubit>()..start(),
        ),
        BlocProvider<EvidenceCubit>(
          create: (_) => serviceLocator<EvidenceCubit>()..start(),
        ),
      ],
      child: const _TodayContent(),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent();

  @override
  Widget build(BuildContext context) {
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
              context.read<WorkLogTodayCubit>().loadToday(),
              context.read<SubscriptionTodayCubit>().loadToday(),
              context.read<ExpenseRecordCubit>().loadEntries(),
              context.read<EvidenceCubit>().loadEntries(),
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
                        BlocBuilder<WorkLogTodayCubit, WorkLogTodayState>(
                          builder: (context, workLogState) {
                            final todayEntry = workLogState.snapshot.todayEntry;
                            return _TodayLogCard(
                              entry: todayEntry,
                              onTap: () => openWorkLogEditorPage(
                                context,
                                selectedDate: today,
                                existingEntry: todayEntry,
                                onSavedOrDeleted: () => context
                                    .read<WorkLogTodayCubit>()
                                    .loadToday(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                        BlocBuilder<
                          SubscriptionTodayCubit,
                          SubscriptionTodayState
                        >(
                          buildWhen: (previous, current) =>
                              previous.snapshot.dueSoonEntries !=
                              current.snapshot.dueSoonEntries,
                          builder: (context, subscriptionState) {
                            return _DueSoonCard(
                              subs: subscriptionState.snapshot.dueSoonEntries,
                              textSecondary: textSecondary,
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                        BlocBuilder<WorkLogTodayCubit, WorkLogTodayState>(
                          buildWhen: (previous, current) =>
                              previous.snapshot.currentMonthSummary.workHours !=
                              current.snapshot.currentMonthSummary.workHours,
                          builder: (context, workLogState) {
                            return BlocBuilder<
                              SubscriptionTodayCubit,
                              SubscriptionTodayState
                            >(
                              buildWhen: (previous, current) =>
                                  previous.snapshot.currentMonthCost !=
                                  current.snapshot.currentMonthCost,
                              builder: (context, subscriptionState) {
                                return BlocBuilder<
                                  ExpenseRecordCubit,
                                  ExpenseRecordState
                                >(
                                  buildWhen: (previous, current) =>
                                      previous.currentMonthTotal !=
                                      current.currentMonthTotal,
                                  builder: (context, expenseState) {
                                    final expenseTotal =
                                        subscriptionState
                                            .snapshot
                                            .currentMonthCost +
                                        expenseState.currentMonthTotal;
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: AppMetricTile(
                                            label: '本月工时',
                                            value: workLogState
                                                .snapshot
                                                .currentMonthSummary
                                                .workHours
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
                                  },
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: 10.h),
                        BlocBuilder<EvidenceCubit, EvidenceState>(
                          buildWhen: (previous, current) =>
                              previous.totalPendingAmount !=
                              current.totalPendingAmount,
                          builder: (context, state) => AppMetricTile(
                            label: '凭证待报销',
                            value: formatMoney(state.totalPendingAmount),
                            icon: Icons.pending_actions_rounded,
                            color: statsColor,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        BlocBuilder<WorkLogTodayCubit, WorkLogTodayState>(
                          buildWhen: (previous, current) =>
                              previous.snapshot.todayEntry !=
                              current.snapshot.todayEntry,
                          builder: (context, workLogState) {
                            return _QuickActions(
                              today: today,
                              existingTodayEntry:
                                  workLogState.snapshot.todayEntry,
                              onWorkLogChanged: () =>
                                  context.read<WorkLogTodayCubit>().loadToday(),
                              onExpenseChanged: () => context
                                  .read<ExpenseRecordCubit>()
                                  .loadEntries(),
                            );
                          },
                        ),
                        SizedBox(height: 18.h),
                        Text(
                          '最近记录',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 10.h),
                        BlocBuilder<WorkLogTodayCubit, WorkLogTodayState>(
                          buildWhen: (previous, current) =>
                              previous.snapshot.recentEntries !=
                              current.snapshot.recentEntries,
                          builder: (context, workLogState) {
                            return _RecentLogs(
                              entries: workLogState.snapshot.recentEntries,
                              onWorkLogChanged: () =>
                                  context.read<WorkLogTodayCubit>().loadToday(),
                            );
                          },
                        ),
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
  final WorkLogEntry? entry;
  final VoidCallback onTap;

  const _TodayLogCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
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
                  entry == null ? '记录今天' : _logSummary(entry!),
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

  String _logSummary(WorkLogEntry log) {
    final type = switch (log.type) {
      WorkLogEntryType.work => '工作',
      WorkLogEntryType.rest => '休息',
      WorkLogEntryType.leave => '请假',
      WorkLogEntryType.businessTrip => '出差',
    };
    final location = log.location?.trim();
    final extra = log.type == WorkLogEntryType.work
        ? ' · 加班 ${(log.overtimeHours ?? 0).toStringAsFixed(1)}h'
        : location != null && location.isNotEmpty
        ? ' · $location'
        : '';
    return '$type$extra';
  }
}

class _DueSoonCard extends StatelessWidget {
  final List<SubscriptionEntry> subs;
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
                onPressed: () =>
                    TabsScope.of(context).goTo(TabsDestination.finance),
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
  final WorkLogEntry? existingTodayEntry;
  final Future<void> Function() onWorkLogChanged;
  final Future<void> Function() onExpenseChanged;

  const _QuickActions({
    required this.today,
    required this.existingTodayEntry,
    required this.onWorkLogChanged,
    required this.onExpenseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(14.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          _action('工时', Icons.work_history_rounded, () {
            openWorkLogEditorPage(
              context,
              selectedDate: today,
              existingEntry: existingTodayEntry,
              onSavedOrDeleted: onWorkLogChanged,
            );
          }),
          _action(
            '支出',
            Icons.payments_rounded,
            () => _showExpenseActions(context),
          ),
          _action('凭证', Icons.attach_file_rounded, () {
            showEvidenceAddActions(
              context,
              galleryTitle: '导入截图',
              fileSubtitle: '发票 PDF 或图片文件',
              manualSubtitle: null,
            );
          }),
          _action('项目', Icons.folder_special_rounded, () {
            TabsScope.of(context).goTo(TabsDestination.project);
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

  void _showExpenseActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24.r,
                    offset: Offset(0, 12.h),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                      child: Text(
                        '添加支出',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.subscriptions_rounded,
                        color: colorScheme.primary,
                      ),
                      title: const Text('订阅/固定支出'),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        openSubscriptionEditorPage(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.receipt_rounded,
                        color: colorScheme.primary,
                      ),
                      title: const Text('一次性消费'),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        openExpenseRecordEditorPage(
                          context,
                          initialDate: today,
                          onSavedOrDeleted: onExpenseChanged,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentLogs extends StatelessWidget {
  final List<WorkLogEntry> entries;
  final Future<void> Function() onWorkLogChanged;

  const _RecentLogs({required this.entries, required this.onWorkLogChanged});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history_rounded,
        title: '最近没有记录',
        message: '使用上方快捷入口开始记录。',
      );
    }
    return Column(
      children: entries.take(7).map((log) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: AppCard(
            onTap: () => openWorkLogEditorPage(
              context,
              selectedDate: log.date,
              existingEntry: log,
              onSavedOrDeleted: onWorkLogChanged,
            ),
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatDateYmd(log.date)} · ${_workLogTypeLabel(log.type)}',
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

String _workLogTypeLabel(WorkLogEntryType type) {
  return switch (type) {
    WorkLogEntryType.work => '工作',
    WorkLogEntryType.rest => '休息',
    WorkLogEntryType.leave => '请假',
    WorkLogEntryType.businessTrip => '出差',
  };
}
