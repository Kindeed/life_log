import 'dart:async';
import 'package:get/get.dart';
import '../../common/services/log_service.dart';
import '../evidence/evidence_model.dart';
import '../evidence/evidence_repository.dart';
import '../expense/expense_record_model.dart';
import '../expense/expense_record_repository.dart';
import '../subscription/subscription_repository.dart';
import '../work_log/work_log_model.dart';
import '../work_log/work_log_repository.dart';
import '../subscription/subscription_model.dart';

enum StatisticsRefreshSource {
  workLogs,
  subscriptions,
  evidence,
  expenseRecords,
}

class StatisticsController extends GetxController {
  StatisticsController({
    Future<List<WorkLog>> Function()? getAllLogs,
    Future<List<Subscription>> Function()? getAllSubscriptions,
    Future<List<ExpenseEvidence>> Function()? getAllEvidence,
    Future<List<ExpenseRecord>> Function()? getAllExpenseRecords,
  }) : _getAllLogs = getAllLogs ?? (() => WorkLogRepository.to.getAllLogs()),
       _getAllSubscriptions =
           getAllSubscriptions ??
           (() => SubscriptionRepository.to.getAllSubscriptions()),
       _getAllEvidence =
           getAllEvidence ?? (() => EvidenceRepository.to.getAllEvidence()),
       _getAllExpenseRecords =
           getAllExpenseRecords ??
           (() => ExpenseRecordRepository.to.getAllExpenseRecords());

  // --- 1. 基础数据 ---
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  // --- 2. 工时/天数 (依然只看本月) ---
  final workHours = 0.0.obs;
  final workDays = 0.obs;
  final tripDays = 0.obs;
  final restDays = 0.obs;

  // --- 3. 财务统计 ---
  final selectedMonthSubCost = 0.0.obs;
  final selectedMonthExpenseRecordCost = 0.0.obs;
  final selectedMonthTotalCost = 0.0.obs;
  final yearSubCost = 0.0.obs;

  final reimbursedAmount = 0.0.obs;
  final unreimbursedAmount = 0.0.obs;
  final evidenceReimbursedAmount = 0.0.obs;
  final evidenceUnreimbursedAmount = 0.0.obs;
  final dailyWorkStats = <DailyWorkStat>[].obs;

  StreamSubscription? _logSub;
  StreamSubscription? _subSub;
  StreamSubscription? _evidenceSub;
  StreamSubscription? _expenseRecordSub;
  List<WorkLog> _logs = const [];
  List<Subscription> _subs = const [];
  List<ExpenseEvidence> _evidence = const [];
  List<ExpenseRecord> _expenseRecords = const [];
  final Future<List<WorkLog>> Function() _getAllLogs;
  final Future<List<Subscription>> Function() _getAllSubscriptions;
  final Future<List<ExpenseEvidence>> Function() _getAllEvidence;
  final Future<List<ExpenseRecord>> Function() _getAllExpenseRecords;
  final _refreshGate = _RefreshGate<StatisticsRefreshSource>();

  // --- 4. 调试/验证 ---
  final lastUpdated = "".obs;

  @override
  void onInit() {
    super.onInit();
    LogService.to.debug('Stats', 'Controller Init');
    refreshStats();

    // 监听工时变化
    _logSub = WorkLogRepository.to.watchLogs().listen((_) {
      LogService.to.debug('Stats', 'WorkLogs Changed');
      _refreshStatsFromWatch(
        StatisticsRefreshSource.workLogs,
        reason: 'work logs',
      );
    });

    // 监听订阅变化
    _subSub = SubscriptionRepository.to.watchSubscriptions().listen((_) {
      LogService.to.debug('Stats', 'Subscriptions Changed');
      _refreshStatsFromWatch(
        StatisticsRefreshSource.subscriptions,
        reason: 'subscriptions',
      );
    });

    _evidenceSub = EvidenceRepository.to.watchEvidence().listen((_) {
      LogService.to.debug('Stats', 'Evidence Changed');
      _refreshStatsFromWatch(
        StatisticsRefreshSource.evidence,
        reason: 'evidence',
      );
    });

    _expenseRecordSub = ExpenseRecordRepository.to.watchExpenseRecords().listen(
      (_) {
        LogService.to.debug('Stats', 'ExpenseRecords Changed');
        _refreshStatsFromWatch(
          StatisticsRefreshSource.expenseRecords,
          reason: 'expense records',
        );
      },
    );
  }

  @override
  void onClose() {
    LogService.to.debug('Stats', 'Controller Close');
    _logSub?.cancel();
    _subSub?.cancel();
    _evidenceSub?.cancel();
    _expenseRecordSub?.cancel();
    super.onClose();
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
          _logs = await _getAllLogs();
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
    } catch (e) {
      LogService.to.error('Stats', '刷新统计数据失败($source): $e');
      return false;
    }
  }

  String get selectedMonthLabel {
    final month = selectedMonth.value;
    return "${month.year}年${month.month}月";
  }

  ReimbursementStats get tripReimbursement => ReimbursementStats(
    pending: unreimbursedAmount.value,
    reimbursed: reimbursedAmount.value,
  );

  ReimbursementStats get evidenceReimbursement => ReimbursementStats(
    pending: evidenceUnreimbursedAmount.value,
    reimbursed: evidenceReimbursedAmount.value,
  );

  bool get isCurrentMonth {
    final now = DateTime.now();
    final month = selectedMonth.value;
    return month.year == now.year && month.month == now.month;
  }

  void previousMonth() {
    final month = selectedMonth.value;
    selectedMonth.value = DateTime(month.year, month.month - 1);
    _calculateAllStats();
  }

  void nextMonth() {
    final month = selectedMonth.value;
    selectedMonth.value = DateTime(month.year, month.month + 1);
    _calculateAllStats();
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    selectedMonth.value = DateTime(now.year, now.month);
    _calculateAllStats();
  }

  void _touchLastUpdated() {
    final now = DateTime.now();
    lastUpdated.value =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    LogService.to.debug('Stats', 'Recalculated at ${lastUpdated.value}');
  }

  void _calculateAllStats() {
    _touchLastUpdated();
    _calculateWorkStats(updateTimestamp: false);
    _calculateEvidenceStats(updateTimestamp: false);
    _calculateSubscriptionStats(updateTimestamp: false);
    _calculateExpenseRecordStats(updateTimestamp: false);
    _calculateSelectedMonthTotalCost();
  }

  void _calculateWorkStats({bool updateTimestamp = true}) {
    if (updateTimestamp) _touchLastUpdated();
    final month = selectedMonth.value;
    final monthLogs = _logs.inMonth(month).toList();

    reimbursedAmount.value = monthLogs.totalReimbursedAmount;
    unreimbursedAmount.value = monthLogs.totalUnreimbursedAmount;

    final monthStats = _logs.getMonthStats(month);
    workHours.value = monthStats.workHours;
    workDays.value = monthStats.workDays;
    tripDays.value = monthStats.tripDays;
    restDays.value = monthStats.restDays;
    dailyWorkStats.assignAll(_buildDailyWorkStats(month, monthLogs));
  }

  void _calculateEvidenceStats({bool updateTimestamp = true}) {
    if (updateTimestamp) _touchLastUpdated();
    final monthEvidence = _evidence.inMonth(selectedMonth.value).toList();
    evidenceReimbursedAmount.value = monthEvidence.totalReimbursedAmount;
    evidenceUnreimbursedAmount.value = monthEvidence.totalPendingAmount;
  }

  void _calculateSubscriptionStats({bool updateTimestamp = true}) {
    if (updateTimestamp) _touchLastUpdated();
    final month = selectedMonth.value;
    selectedMonthSubCost.value = _subs.totalCostForMonth(month);
    yearSubCost.value = _subs.totalYearlyCost;
    _calculateSelectedMonthTotalCost();
  }

  void _calculateExpenseRecordStats({bool updateTimestamp = true}) {
    if (updateTimestamp) _touchLastUpdated();
    selectedMonthExpenseRecordCost.value = _expenseRecords
        .inMonth(selectedMonth.value)
        .totalAmount;
    _calculateSelectedMonthTotalCost();
  }

  void _calculateSelectedMonthTotalCost() {
    selectedMonthTotalCost.value =
        selectedMonthSubCost.value + selectedMonthExpenseRecordCost.value;
  }

  List<DailyWorkStat> _buildDailyWorkStats(
    DateTime month,
    List<WorkLog> monthLogs,
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
        overtimeHours: log.type == LogType.work
            ? (log.overtimeHours ?? 0.0)
            : 0.0,
        hasWork: log.type == LogType.work,
        hasTrip: log.type == LogType.businessTrip,
        hasLeave: log.type == LogType.leave,
        hasRest: log.type == LogType.rest,
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
