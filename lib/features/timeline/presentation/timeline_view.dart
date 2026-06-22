import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/evidence/presentation/evidence_list_view.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';
import 'package:life_log/features/shell/presentation/profile_action_button.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/presentation/subscription_cubit.dart';
import 'package:life_log/features/subscription/presentation/subscription_view.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/work_log_cubit.dart';
import 'package:life_log/features/work_log/presentation/work_log_view.dart';

enum TimelineFilter { all, work, expense, evidence, subscription }

class TimelineView extends StatefulWidget {
  static const title = '记录';

  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  TimelineFilter _filter = TimelineFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(TimelineView.title),
        actions: const [ProfileActionButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: AppFilterChipBar<TimelineFilter>(
              value: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
              items: const [
                AppFilterChipItem(
                  value: TimelineFilter.all,
                  label: '全部',
                  icon: Icons.view_agenda_outlined,
                ),
                AppFilterChipItem(
                  value: TimelineFilter.work,
                  label: '工时',
                  icon: Icons.work_history_outlined,
                ),
                AppFilterChipItem(
                  value: TimelineFilter.expense,
                  label: '支出',
                  icon: Icons.payments_outlined,
                ),
                AppFilterChipItem(
                  value: TimelineFilter.evidence,
                  label: '凭证',
                  icon: Icons.receipt_long_outlined,
                ),
                AppFilterChipItem(
                  value: TimelineFilter.subscription,
                  label: '订阅',
                  icon: Icons.subscriptions_outlined,
                ),
              ],
            ),
          ),
          Expanded(child: _contentFor(_filter)),
        ],
      ),
    );
  }

  Widget _contentFor(TimelineFilter filter) {
    return switch (filter) {
      TimelineFilter.all => const _UnifiedTimeline(),
      TimelineFilter.work => const WorkLogView(),
      TimelineFilter.expense => const _ExpenseRecordTimeline(),
      TimelineFilter.evidence => const EvidenceListView(),
      TimelineFilter.subscription => const SubscriptionView(),
    };
  }
}

class TimelineItem {
  final DateTime date;
  final String typeLabel;
  final String title;
  final String subtitle;
  final IconData icon;

  const TimelineItem({
    required this.date,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _UnifiedTimeline extends StatelessWidget {
  const _UnifiedTimeline();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WorkLogCubit>(
          create: (_) => serviceLocator<WorkLogCubit>()..start(),
        ),
        BlocProvider<ExpenseRecordCubit>(
          create: (_) => serviceLocator<ExpenseRecordCubit>()..start(),
        ),
        BlocProvider<EvidenceCubit>(
          create: (_) => serviceLocator<EvidenceCubit>()..start(),
        ),
        BlocProvider<SubscriptionCubit>(
          create: (_) => serviceLocator<SubscriptionCubit>()..start(),
        ),
      ],
      child: BlocBuilder<WorkLogCubit, WorkLogState>(
        builder: (context, workState) {
          return BlocBuilder<ExpenseRecordCubit, ExpenseRecordState>(
            builder: (context, expenseState) {
              return BlocBuilder<EvidenceCubit, EvidenceState>(
                builder: (context, evidenceState) {
                  return BlocBuilder<SubscriptionCubit, SubscriptionState>(
                    builder: (context, subscriptionState) {
                      final items = [
                        ..._workItems(workState),
                        ..._expenseItems(expenseState),
                        ..._evidenceItems(evidenceState),
                        ..._subscriptionItems(subscriptionState),
                      ]..sort((a, b) => b.date.compareTo(a.date));

                      final isLoading =
                          workState.status == WorkLogStatus.loading ||
                          expenseState.status == ExpenseRecordStatus.loading ||
                          evidenceState.status == EvidenceStatus.loading ||
                          subscriptionState.status ==
                              SubscriptionReadStatus.loading;
                      if (items.isEmpty && isLoading) {
                        return const AppLoading(label: '正在加载记录');
                      }
                      if (items.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.view_agenda_outlined,
                          title: '暂无记录',
                          message: '工时、支出、凭证和订阅会在这里按时间显示。',
                        );
                      }

                      final groups = _groupItemsByDay(items);
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        children: [
                          for (final group in groups.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                                bottom: AppSpacing.xs,
                              ),
                              child: Text(
                                formatDateYmd(group.key),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            for (final item in group.value)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _TimelineItemRow(item: item),
                              ),
                          ],
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<TimelineItem> _workItems(WorkLogState state) {
    return state.entriesByDay.values
        .expand((entries) => entries)
        .map(
          (entry) => TimelineItem(
            date: entry.date,
            typeLabel: '工时',
            title: _workLogTitle(entry),
            subtitle: [
              if (entry.overtimeHours != null)
                '加班 ${entry.overtimeHours!.toStringAsFixed(1)}h',
              if (entry.location?.trim().isNotEmpty == true)
                entry.location!.trim(),
              if (entry.note?.trim().isNotEmpty == true) entry.note!.trim(),
            ].join(' · '),
            icon: Icons.work_history_rounded,
          ),
        )
        .toList();
  }

  List<TimelineItem> _expenseItems(ExpenseRecordState state) {
    return state.entries
        .map(
          (entry) => TimelineItem(
            date: entry.expenseDate,
            typeLabel: '支出',
            title: entry.merchant?.trim().isNotEmpty == true
                ? entry.merchant!.trim()
                : entry.category.label,
            subtitle: [
              formatMoney(entry.amount),
              if (entry.projectName?.trim().isNotEmpty == true)
                entry.projectName!.trim(),
            ].join(' · '),
            icon: Icons.payments_rounded,
          ),
        )
        .toList();
  }

  List<TimelineItem> _evidenceItems(EvidenceState state) {
    return state.entries
        .map(
          (entry) => TimelineItem(
            date: entry.evidenceDate,
            typeLabel: '凭证',
            title: entry.merchant?.trim().isNotEmpty == true
                ? entry.merchant!.trim()
                : entry.category.label,
            subtitle: [
              entry.status.label,
              if ((entry.amount ?? 0) > 0) formatMoney(entry.amount ?? 0),
              entry.projectName,
            ].join(' · '),
            icon: Icons.receipt_long_rounded,
          ),
        )
        .toList();
  }

  List<TimelineItem> _subscriptionItems(SubscriptionState state) {
    return state.entries
        .map(
          (entry) => TimelineItem(
            date: entry.nextPaymentDate,
            typeLabel: '订阅',
            title: entry.name,
            subtitle: [
              if ((entry.price ?? 0) > 0) formatMoney(entry.price ?? 0),
              _subscriptionCycleLabel(entry.cycle),
            ].join(' · '),
            icon: Icons.subscriptions_rounded,
          ),
        )
        .toList();
  }
}

class _TimelineItemRow extends StatelessWidget {
  final TimelineItem item;

  const _TimelineItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(item.icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    item.typeLabel,
                    item.subtitle,
                  ].where((part) => part.trim().isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Map<DateTime, List<TimelineItem>> _groupItemsByDay(List<TimelineItem> items) {
  final groups = <DateTime, List<TimelineItem>>{};
  for (final item in items) {
    groups.putIfAbsent(dateOnlyLocal(item.date), () => []).add(item);
  }
  return groups;
}

String _workLogTitle(WorkLogEntry entry) {
  return switch (entry.type) {
    WorkLogEntryType.work => '工作',
    WorkLogEntryType.rest => '休息',
    WorkLogEntryType.leave => '请假',
    WorkLogEntryType.businessTrip => '出差',
  };
}

String _subscriptionCycleLabel(SubscriptionBillingCycle cycle) {
  return switch (cycle) {
    SubscriptionBillingCycle.monthly => '每月',
    SubscriptionBillingCycle.yearly => '每年',
    SubscriptionBillingCycle.oneTime => '一次性',
    SubscriptionBillingCycle.custom => '自定义',
  };
}

class _ExpenseRecordTimeline extends StatelessWidget {
  const _ExpenseRecordTimeline();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExpenseRecordCubit>(
      create: (_) => serviceLocator<ExpenseRecordCubit>()..start(),
      child: BlocBuilder<ExpenseRecordCubit, ExpenseRecordState>(
        builder: (context, state) {
          if (state.status == ExpenseRecordStatus.loading &&
              state.entries.isEmpty) {
            return const AppLoading(label: '正在加载支出');
          }

          if (state.entries.isEmpty) {
            return const AppEmptyState(
              icon: Icons.payments_outlined,
              title: '暂无支出记录',
              message: '一次性消费和项目垫付会在这里按时间显示。',
            );
          }

          final entries = [...state.entries]
            ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _ExpenseRecordRow(entry: entries[index]);
            },
          );
        },
      ),
    );
  }
}

class _ExpenseRecordRow extends StatelessWidget {
  final ExpenseRecordEntry entry;

  const _ExpenseRecordRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    final merchant = entry.merchant?.trim();
    final project = entry.projectName?.trim();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant == null || merchant.isEmpty
                      ? entry.category.label
                      : merchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    formatDateYmd(entry.expenseDate),
                    if (project != null && project.isNotEmpty) project,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            formatMoney(entry.amount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
