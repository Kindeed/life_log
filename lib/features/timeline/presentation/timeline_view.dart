import 'dart:async';

import 'package:flutter/material.dart';
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_load_failure.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_add_action_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_detail_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_legacy_view_adapter.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/presentation/expense_record_editor_launcher.dart';
import 'package:life_log/features/more/presentation/quick_action_contract.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/presentation/subscription_editor_launcher.dart';
import 'package:life_log/features/timeline/application/timeline_query.dart';
import 'package:life_log/features/timeline/domain/timeline_record.dart';
import 'package:life_log/features/timeline/presentation/timeline_cubit.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_launcher.dart';

export 'package:life_log/features/timeline/domain/timeline_record.dart';

class TimelineView extends StatefulWidget {
  static const title = '全部记录';

  final TimelineCubit? cubit;
  final Future<void> Function(BuildContext, TimelineRecord)? openRecord;
  final Future<void> Function(BuildContext, TimelineFilter)? createRecord;

  const TimelineView({
    super.key,
    this.cubit,
    this.openRecord,
    this.createRecord,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late final TimelineCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? _createCubit();
    _cubit.start();
  }

  TimelineCubit _createCubit() {
    final account = serviceLocator.isRegistered<ProfileAccountRepositoryPort>()
        ? serviceLocator<ProfileAccountRepositoryPort>()
        : null;
    final initialAccount = account?.loadAccount();
    var firstAccountSnapshot = true;
    return TimelineCubit(
      query: TimelineQuery(
        workLogs: serviceLocator<WorkLogRepositoryPort>(),
        expenses: serviceLocator<ExpenseRecordRepositoryPort>(),
        evidence: serviceLocator<EvidenceRepositoryPort>(),
        subscriptions: serviceLocator<SubscriptionRepositoryPort>(),
        watchScope: account == null
            ? null
            : () => account
                  .watchAccount()
                  .where((snapshot) {
                    if (firstAccountSnapshot) {
                      firstAccountSnapshot = false;
                      return snapshot != initialAccount;
                    }
                    // Account snapshots do not expose a durable owner id. Treat
                    // every subsequent auth notification as a cache boundary.
                    return true;
                  })
                  .map((_) {}),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.cubit == null) unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimelineCubit, TimelineState>(
      bloc: _cubit,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(TimelineView.title),
            actions: [
              IconButton(
                tooltip: '刷新记录',
                onPressed: state.isLoading ? null : () => _cubit.refresh(),
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: '新增记录',
                onPressed: () => _addRecord(state.filter),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ConstrainedPage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: AppFilterChipBar<TimelineFilter>(
                      value: state.filter,
                      onChanged: _cubit.selectFilter,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _selectDates(state),
                          icon: const Icon(Icons.date_range_outlined, size: 18),
                          label: Text(
                            state.range == null
                                ? '全部日期'
                                : '${formatDateYmd(state.range!.start)} 至 ${formatDateYmd(state.range!.end)}',
                          ),
                        ),
                        if (state.range != null)
                          TextButton(
                            onPressed: () => _cubit.selectRange(null),
                            child: const Text('清除日期筛选'),
                          ),
                        Text(
                          '${state.totalCount} 条',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (state.isLoading && state.visibleCount > 0)
                    const LinearProgressIndicator(minHeight: 2),
                  if (state.visibleCount > 0 &&
                      state.visibleFailures.isNotEmpty)
                    AppLoadFailure(
                      compact: true,
                      message: '${_failedLabels(state)}未能更新，当前显示已读取的记录。',
                      onRetry: () => _cubit.retry(),
                    ),
                  Expanded(
                    key: const ValueKey('timeline-list-region'),
                    child: _content(state),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(TimelineState state) {
    final failures = state.visibleFailures;
    if (state.visibleCount == 0) {
      if (state.isLoading) return const AppLoading(label: '正在加载记录');
      if (failures.isNotEmpty) {
        return AppLoadFailure(
          message: '${_failedLabels(state)}读取失败，请重试。',
          onRetry: () => _cubit.retry(),
        );
      }
      return AppEmptyState(
        icon: Icons.view_agenda_outlined,
        title: state.range == null
            ? '暂无${state.filter == TimelineFilter.all ? '' : state.filter.label}记录'
            : '这段时间没有记录',
        message: state.range == null
            ? '添加记录后，会按日期显示在这里。'
            : '可更改日期范围，或清除筛选查看全部历史。',
      );
    }
    return ListView.builder(
      key: PageStorageKey('timeline:${state.selectionKey}'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: state.rows.length + 1,
      findChildIndexCallback: (key) {
        if (key is! ValueKey<String>) return null;
        if (key.value == 'timeline-footer') {
          return state.rows.length;
        }
        return state.rowIndexes[key.value];
      },
      itemBuilder: (context, index) {
        if (index == state.rows.length) {
          return Padding(
            key: const ValueKey('timeline-footer'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: state.hasMore
                ? OutlinedButton.icon(
                    onPressed: _cubit.loadMore,
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(
                      '加载更多（已显示 ${state.visibleCount} / ${state.totalCount} 条）',
                    ),
                  )
                : Text(
                    '已显示 ${state.visibleCount} 条',
                    textAlign: TextAlign.center,
                  ),
          );
        }
        final row = state.rows[index];
        return switch (row) {
          TimelineDateRow(:final date) => Padding(
            key: ValueKey(row.key),
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              formatDateYmd(date),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TimelineRecordRow(:final record) => Padding(
            key: ValueKey(row.key),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _TimelineRecordTile(
              record: record,
              onTap: () => _openRecord(record),
            ),
          ),
        };
      },
    );
  }

  String _failedLabels(TimelineState state) =>
      state.visibleFailures.keys.map((source) => source.label).join('、');

  Future<void> _selectDates(TimelineState state) async {
    final now = DateTime.now();
    var first = DateTime(now.year - 20);
    var last = DateTime(now.year + 20, 12, 31);
    final range = state.range;
    if (range != null) {
      if (range.start.isBefore(first)) first = range.start;
      if (range.end.isAfter(last)) last = range.end;
    }
    for (final record in state.allRecords) {
      final date = record.date;
      if (date.isBefore(first)) {
        first = DateTime(date.year, date.month, date.day);
      }
      if (date.isAfter(last)) last = DateTime(date.year, date.month, date.day);
    }
    final result = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: state.range == null
          ? null
          : DateTimeRange(start: state.range!.start, end: state.range!.end),
      helpText: '选择记录日期范围',
      saveText: '确定',
    );
    if (!mounted || result == null) return;
    _cubit.selectRange(TimelineDateRange(result.start, result.end));
  }

  Future<void> _openRecord(TimelineRecord record) async {
    final open = widget.openRecord;
    if (open != null) {
      await open(context, record);
    } else {
      switch (record) {
        case TimelineWorkRecord(:final entry):
          await openWorkLogEditorPage(
            context,
            selectedDate: entry.date,
            existingEntry: entry,
          );
        case TimelineExpenseRecord(:final entry):
          await openExpenseRecordEditorPage(context, entry: entry);
        case TimelineEvidenceRecord(:final entry):
          await showEvidenceDetailSheet(
            context,
            legacyEvidenceFromEntry(entry),
          );
        case TimelineSubscriptionRecord(:final entry):
          await openSubscriptionEditorPage(context, entry: entry);
      }
    }
    if (mounted) await _cubit.refresh(sources: {record.type});
  }

  Future<void> _addRecord(TimelineFilter filter) async {
    var type = filter;
    if (type == TimelineFilter.all) {
      type =
          await showAppBottomSheet<TimelineFilter>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final source in TimelineQuery.sources)
                    ListTile(
                      leading: Icon(_typeIcon(source)),
                      title: Text(_createLabel(source)),
                      onTap: () => Navigator.of(sheetContext).pop(source),
                    ),
                ],
              ),
            ),
          ) ??
          TimelineFilter.all;
    }
    if (!mounted || type == TimelineFilter.all) return;
    final create = widget.createRecord;
    if (create != null) {
      await create(context, type);
    } else {
      switch (type) {
        case TimelineFilter.work:
          await openWorkLogEditorPage(context, selectedDate: DateTime.now());
        case TimelineFilter.expense:
          await openExpenseRecordEditorPage(
            context,
            initialDate: DateTime.now(),
          );
        case TimelineFilter.evidence:
          showEvidenceAddActions(context);
          return;
        case TimelineFilter.subscription:
          await openSubscriptionEditorPage(context);
        case TimelineFilter.all:
          return;
      }
    }
    if (mounted) await _cubit.refresh(sources: {type});
  }
}

class _TimelineRecordTile extends StatelessWidget {
  final TimelineRecord record;
  final VoidCallback onTap;
  const _TimelineRecordTile({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, subtitle) = _recordText(record);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(_typeIcon(record.type), color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    record.type.label,
                    subtitle,
                  ].where((text) => text.isNotEmpty).join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

(String, String) _recordText(TimelineRecord record) => switch (record) {
  TimelineWorkRecord(:final entry) => (
    switch (entry.type) {
      WorkLogEntryType.work => '工作',
      WorkLogEntryType.rest => '休息',
      WorkLogEntryType.leave => '请假',
      WorkLogEntryType.businessTrip => '出差',
    },
    [
      if (entry.overtimeHours != null)
        '加班 ${entry.overtimeHours!.toStringAsFixed(1)} 小时',
      if (entry.location?.trim().isNotEmpty == true) entry.location!.trim(),
      if (entry.note?.trim().isNotEmpty == true) entry.note!.trim(),
    ].join(' · '),
  ),
  TimelineExpenseRecord(:final entry) => (
    entry.merchant?.trim().isNotEmpty == true
        ? entry.merchant!.trim()
        : entry.category.label,
    [
      formatMoney(entry.amount, currency: entry.currency),
      if (entry.projectName?.trim().isNotEmpty == true)
        entry.projectName!.trim(),
    ].join(' · '),
  ),
  TimelineEvidenceRecord(:final entry) => (
    entry.merchant?.trim().isNotEmpty == true
        ? entry.merchant!.trim()
        : entry.category.label,
    [
      entry.status.label,
      if (entry.amount != null)
        formatMoney(entry.amount!, currency: entry.currency),
      if (entry.projectName.trim().isNotEmpty) entry.projectName,
    ].join(' · '),
  ),
  TimelineSubscriptionRecord(:final entry) => (
    entry.name,
    [
      if (entry.price != null)
        formatMoney(entry.price!, currency: entry.currency.code),
      '下次扣费 ${formatDateYmd(entry.nextPaymentDate)}',
      switch (entry.cycle) {
        SubscriptionBillingCycle.monthly => '每月',
        SubscriptionBillingCycle.yearly => '每年',
        SubscriptionBillingCycle.oneTime => '一次性',
        SubscriptionBillingCycle.custom => '自定义',
      },
    ].join(' · '),
  ),
};

IconData _typeIcon(TimelineFilter type) => switch (type) {
  TimelineFilter.all => Icons.view_agenda_outlined,
  TimelineFilter.work => Icons.work_history_outlined,
  TimelineFilter.expense => Icons.payments_outlined,
  TimelineFilter.evidence => Icons.receipt_long_outlined,
  TimelineFilter.subscription => Icons.subscriptions_outlined,
};

String _createLabel(TimelineFilter type) => switch (type) {
  TimelineFilter.work => QuickActionLabels.recordWorkLog,
  TimelineFilter.expense => QuickActionLabels.recordExpense,
  TimelineFilter.evidence => QuickActionLabels.addEvidence,
  TimelineFilter.subscription => '添加订阅',
  TimelineFilter.all => '新增记录',
};
