import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/application/watch_evidence_entries.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry_stats.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/expense/application/watch_expense_record_entries.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry_stats.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry_stats.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry_stats.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/common/services/log_service.dart';

enum StatisticsRefreshSource {
  workLogs,
  subscriptions,
  evidence,
  expenseRecords,
}

class StatisticsController extends ChangeNotifier {
  StatisticsController({
    Future<List<WorkLogEntry>> Function()? getAllWorkLogEntries,
    Stream<void> Function()? watchWorkLogEntries,
    Future<List<SubscriptionEntry>> Function()? getAllSubscriptions,
    Stream<void> Function()? watchSubscriptionEntries,
    Future<List<EvidenceEntry>> Function()? getAllEvidence,
    Stream<void> Function()? watchEvidenceEntries,
    Future<List<ExpenseRecordEntry>> Function()? getAllExpenseRecords,
    Stream<void> Function()? watchExpenseRecordEntries,
  }) : _getAllWorkLogEntries =
           getAllWorkLogEntries ??
           (() => serviceLocator<WorkLogRepositoryPort>().getAllEntries()),
       _watchWorkLogEntries =
           watchWorkLogEntries ??
           (() => serviceLocator<WatchWorkLogEntries>()()),
       _getAllSubscriptions =
           getAllSubscriptions ??
           (() => serviceLocator<SubscriptionRepositoryPort>().getAllEntries()),
       _watchSubscriptionEntries =
           watchSubscriptionEntries ??
           (() => serviceLocator<WatchSubscriptionEntries>()()),
       _getAllEvidence =
           getAllEvidence ??
           (() => serviceLocator<EvidenceRepositoryPort>().getAllEntries()),
       _watchEvidenceEntries =
           watchEvidenceEntries ??
           (() => serviceLocator<WatchEvidenceEntries>()()),
       _getAllExpenseRecords =
           getAllExpenseRecords ??
           (() =>
               serviceLocator<ExpenseRecordRepositoryPort>().getAllEntries()),
       _watchExpenseRecordEntries =
           watchExpenseRecordEntries ??
           (() => serviceLocator<WatchExpenseRecordEntries>()());

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  double workHours = 0;
  int workDays = 0;
  int tripDays = 0;
  int restDays = 0;

  double selectedMonthSubCost = 0;
  double selectedMonthExpenseRecordCost = 0;
  double selectedMonthTotalCost = 0;
  double yearSubCost = 0;

  double reimbursedAmount = 0;
  double unreimbursedAmount = 0;
  double evidenceReimbursedAmount = 0;
  double evidenceUnreimbursedAmount = 0;
  List<DailyWorkStat> dailyWorkStats = const [];

  StreamSubscription? _logSub;
  StreamSubscription? _subSub;
  StreamSubscription? _evidenceSub;
  StreamSubscription? _expenseRecordSub;
  List<WorkLogEntry> _workLogEntries = const [];
  List<SubscriptionEntry> _subs = const [];
  List<EvidenceEntry> _evidence = const [];
  List<ExpenseRecordEntry> _expenseRecords = const [];
  final Future<List<WorkLogEntry>> Function() _getAllWorkLogEntries;
  final Stream<void> Function() _watchWorkLogEntries;
  final Future<List<SubscriptionEntry>> Function() _getAllSubscriptions;
  final Stream<void> Function() _watchSubscriptionEntries;
  final Future<List<EvidenceEntry>> Function() _getAllEvidence;
  final Stream<void> Function() _watchEvidenceEntries;
  final Future<List<ExpenseRecordEntry>> Function() _getAllExpenseRecords;
  final Stream<void> Function() _watchExpenseRecordEntries;
  final _refreshGate = _RefreshGate<StatisticsRefreshSource>();
  bool _started = false;

  String lastUpdated = '';

  void start() {
    if (_started) return;
    _started = true;
    LogService.to.debug('Stats', 'Controller Init');
    refreshStats();

    _logSub = _watchWorkLogEntries().listen((_) {
      LogService.to.debug('Stats', 'WorkLogs Changed');
      _refreshStatsFromWatch(
        StatisticsRefreshSource.workLogs,
        reason: 'work logs',
      );
    });

    _subSub = _watchSubscriptionEntries().listen((_) {
      LogService.to.debug('Stats', 'Subscriptions Changed');
      _refreshStatsFromWatch(
        StatisticsRefreshSource.subscriptions,
        reason: 'subscriptions',
      );
    });

    _evidenceSub = _watchEvidenceEntries().listen((_) {
      LogService.to.debug('Stats', 'Evidence Changed');
      _refreshStatsFromWatch(
        StatisticsRefreshSource.evidence,
        reason: 'evidence',
      );
    });

    _expenseRecordSub = _watchExpenseRecordEntries().listen((_) {
      LogService.to.debug('Stats', 'ExpenseRecords Changed');
      _refreshStatsFromWatch(
        StatisticsRefreshSource.expenseRecords,
        reason: 'expense records',
      );
    });
  }

  @override
  void dispose() {
    LogService.to.debug('Stats', 'Controller Close');
    _logSub?.cancel();
    _subSub?.cancel();
    _evidenceSub?.cancel();
    _expenseRecordSub?.cancel();
    super.dispose();
  }

  Future<void> refreshStats() async {
    return _refreshGate.run(
      StatisticsRefreshSource.values.toSet(),
      _refreshChangedSources,
    );
  }

  Future<void> refreshChangedSourcesForTest(
    Set<StatisticsRefreshSource> sources,
  ) {
    return _refreshGate.run(sources, _refreshChangedSources);
  }

  void _refreshStatsFromWatch(
    StatisticsRefreshSource source, {
    required String reason,
  }) {
    unawaited(_refreshGate.run({source}, _refreshChangedSources));
    LogService.to.debug('Stats', 'Queued stats refresh from $reason');
  }

  Future<void> _refreshChangedSources(
    Set<StatisticsRefreshSource> sources,
  ) async {
    final allSources = StatisticsRefreshSource.values.toSet();
    final loaded = <StatisticsRefreshSource>{};

    for (final source in StatisticsRefreshSource.values) {
      if (!sources.contains(source)) continue;
      if (await _loadStatsSource(source)) {
        loaded.add(source);
      }
    }

    if (loaded.isEmpty) return;

    if (sources.containsAll(allSources)) {
      _calculateAllStats();
      return;
    }

    if (loaded.contains(StatisticsRefreshSource.workLogs)) {
      _calculateWorkStats();
    }
    if (loaded.contains(StatisticsRefreshSource.subscriptions)) {
      _calculateSubscriptionStats();
    }
    if (loaded.contains(StatisticsRefreshSource.evidence)) {
      _calculateEvidenceStats();
    }
    if (loaded.contains(StatisticsRefreshSource.expenseRecords)) {
      _calculateExpenseRecordStats();
    }
  }

  Future<bool> _loadStatsSource(StatisticsRefreshSource source) async {
    try {
      switch (source) {
        case StatisticsRefreshSource.workLogs:
          _workLogEntries = await _getAllWorkLogEntries();
          return true;
        case StatisticsRefreshSource.subscriptions:
          _subs = await _getAllSubscriptions();
          return true;
        case StatisticsRefreshSource.evidence:
          _evidence = await _getAllEvidence();
          return true;
        case StatisticsRefreshSource.expenseRecords:
          _expenseRecords = await _getAllExpenseRecords();
          return true;
      }
    } catch (e, stackTrace) {
      LogService.to.error('Stats', '刷新统计数据失败($source): $e', stackTrace);
      return false;
    }
  }

  String get selectedMonthLabel {
    final month = selectedMonth;
    return "${month.year}年${month.month}月";
  }

  ReimbursementStats get tripReimbursement => ReimbursementStats(
    pending: unreimbursedAmount,
    reimbursed: reimbursedAmount,
  );

  ReimbursementStats get evidenceReimbursement => ReimbursementStats(
    pending: evidenceUnreimbursedAmount,
    reimbursed: evidenceReimbursedAmount,
  );

  bool get isCurrentMonth {
    final now = DateTime.now();
    final month = selectedMonth;
    return month.year == now.year && month.month == now.month;
  }

  void previousMonth() {
    final month = selectedMonth;
    selectedMonth = DateTime(month.year, month.month - 1);
    _calculateAllStats();
  }

  void nextMonth() {
    final month = selectedMonth;
    selectedMonth = DateTime(month.year, month.month + 1);
    _calculateAllStats();
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    _calculateAllStats();
  }

  void _touchLastUpdated() {
    final now = DateTime.now();
    lastUpdated =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    LogService.to.debug('Stats', 'Recalculated at $lastUpdated');
  }

  void _calculateAllStats() {
    _touchLastUpdated();
    _calculateWorkStats(updateTimestamp: false, notify: false);
    _calculateEvidenceStats(updateTimestamp: false, notify: false);
    _calculateSubscriptionStats(updateTimestamp: false, notify: false);
    _calculateExpenseRecordStats(updateTimestamp: false, notify: false);
    _calculateSelectedMonthTotalCost();
    notifyListeners();
  }

  void _calculateWorkStats({bool updateTimestamp = true, bool notify = true}) {
    if (updateTimestamp) _touchLastUpdated();
    final month = selectedMonth;
    final monthLogs = _workLogEntries.inMonth(month).toList();

    reimbursedAmount = monthLogs.totalReimbursedAmount;
    unreimbursedAmount = monthLogs.totalUnreimbursedAmount;

    final monthStats = _workLogEntries.getMonthSummary(month);
    workHours = monthStats.workHours;
    workDays = monthStats.workDays;
    tripDays = monthStats.tripDays;
    restDays = monthStats.restDays;
    dailyWorkStats = _buildDailyWorkStats(month, monthLogs);
    if (notify) notifyListeners();
  }

  void _calculateEvidenceStats({
    bool updateTimestamp = true,
    bool notify = true,
  }) {
    if (updateTimestamp) _touchLastUpdated();
    final monthEvidence = _evidence.inMonth(selectedMonth).toList();
    evidenceReimbursedAmount = monthEvidence.totalReimbursedAmount;
    evidenceUnreimbursedAmount = monthEvidence.totalPendingAmount;
    if (notify) notifyListeners();
  }

  void _calculateSubscriptionStats({
    bool updateTimestamp = true,
    bool notify = true,
  }) {
    if (updateTimestamp) _touchLastUpdated();
    final month = selectedMonth;
    selectedMonthSubCost = _subs.totalCostForMonth(month);
    yearSubCost = _subs.totalYearlyCost;
    _calculateSelectedMonthTotalCost();
    if (notify) notifyListeners();
  }

  void _calculateExpenseRecordStats({
    bool updateTimestamp = true,
    bool notify = true,
  }) {
    if (updateTimestamp) _touchLastUpdated();
    selectedMonthExpenseRecordCost = _expenseRecords
        .inMonth(selectedMonth)
        .totalAmount;
    _calculateSelectedMonthTotalCost();
    if (notify) notifyListeners();
  }

  void _calculateSelectedMonthTotalCost() {
    selectedMonthTotalCost =
        selectedMonthSubCost + selectedMonthExpenseRecordCost;
  }

  List<DailyWorkStat> _buildDailyWorkStats(
    DateTime month,
    List<WorkLogEntry> monthLogs,
  ) {
    final latestLogsByDay = monthLogs.latestByLocalDate();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return List.generate(daysInMonth, (index) {
      final day = index + 1;
      final log = latestLogsByDay[DateTime(month.year, month.month, day)];
      if (log == null) {
        return DailyWorkStat(
          date: DateTime(month.year, month.month, day),
          overtimeHours: 0.0,
          hasWork: false,
          hasTrip: false,
          hasLeave: false,
          hasRest: false,
        );
      }

      return DailyWorkStat(
        date: DateTime(month.year, month.month, day),
        overtimeHours: log.type == WorkLogEntryType.work
            ? (log.overtimeHours ?? 0.0)
            : 0.0,
        hasWork: log.type == WorkLogEntryType.work,
        hasTrip: log.type == WorkLogEntryType.businessTrip,
        hasLeave: log.type == WorkLogEntryType.leave,
        hasRest: log.type == WorkLogEntryType.rest,
      );
    });
  }
}

class DailyWorkStat {
  final DateTime date;
  final double overtimeHours;
  final bool hasWork;
  final bool hasTrip;
  final bool hasLeave;
  final bool hasRest;

  const DailyWorkStat({
    required this.date,
    required this.overtimeHours,
    required this.hasWork,
    required this.hasTrip,
    required this.hasLeave,
    required this.hasRest,
  });

  bool get hasAnyStatus => hasWork || hasTrip || hasLeave || hasRest;

  int get statusCount =>
      [hasWork, hasTrip, hasLeave, hasRest].where((value) => value).length;
}

class ReimbursementStats {
  final double pending;
  final double reimbursed;

  const ReimbursementStats({required this.pending, required this.reimbursed});

  double get total => pending + reimbursed;
}

class _RefreshGate<T> {
  static const _maxRunsPerDrain = 8;

  Future<void>? _inFlight;
  final Set<T> _pending = {};

  Future<void> run(Set<T> requested, Future<void> Function(Set<T>) operation) {
    _pending.addAll(requested);
    final activeRefresh = _inFlight;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final completer = Completer<void>();
    _inFlight = completer.future;
    unawaited(
      _runLoop(operation).then(completer.complete).catchError((error, stack) {
        completer.completeError(error, stack);
      }),
    );
    return completer.future;
  }

  Future<void> _runLoop(Future<void> Function(Set<T>) operation) async {
    try {
      var runs = 0;
      while (_pending.isNotEmpty && runs < _maxRunsPerDrain) {
        runs++;
        final current = Set<T>.of(_pending);
        _pending.clear();
        await operation(current);
      }
      if (_pending.isNotEmpty) {
        _pending.clear();
        LogService.to.error(
          'Stats',
          '统计刷新循环超过 $_maxRunsPerDrain 次，已丢弃本轮剩余刷新请求',
        );
      }
    } finally {
      _inFlight = null;
    }
  }
}
