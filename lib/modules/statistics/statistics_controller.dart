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

class StatisticsController extends GetxController {
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
  final _allRefreshGate = _RefreshGate();
  final _workRefreshGate = _RefreshGate();
  final _subscriptionRefreshGate = _RefreshGate();
  final _evidenceRefreshGate = _RefreshGate();
  final _expenseRecordRefreshGate = _RefreshGate();

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
      _refreshWorkStats();
    });

    // 监听订阅变化
    _subSub = SubscriptionRepository.to.watchSubscriptions().listen((_) {
      LogService.to.debug('Stats', 'Subscriptions Changed');
      _refreshSubscriptionStats();
    });

    _evidenceSub = EvidenceRepository.to.watchEvidence().listen((_) {
      LogService.to.debug('Stats', 'Evidence Changed');
      _refreshEvidenceStats();
    });

    _expenseRecordSub = ExpenseRecordRepository.to.watchExpenseRecords().listen(
      (_) {
        LogService.to.debug('Stats', 'ExpenseRecords Changed');
        _refreshExpenseRecordStats();
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
    return _allRefreshGate.run(() async {
      try {
        final results = await Future.wait([
          WorkLogRepository.to.getAllLogs(),
          SubscriptionRepository.to.getAllSubscriptions(),
          EvidenceRepository.to.getAllEvidence(),
          ExpenseRecordRepository.to.getAllExpenseRecords(),
        ]);
        _logs = results[0] as List<WorkLog>;
        _subs = results[1] as List<Subscription>;
        _evidence = results[2] as List<ExpenseEvidence>;
        _expenseRecords = results[3] as List<ExpenseRecord>;
        _calculateAllStats();
      } catch (e) {
        LogService.to.error('Stats', '刷新统计失败: $e');
      }
    });
  }

  Future<void> _refreshWorkStats() async {
    return _workRefreshGate.run(() async {
      try {
        _logs = await WorkLogRepository.to.getAllLogs();
        _calculateWorkStats();
      } catch (e) {
        LogService.to.error('Stats', '刷新工时统计失败: $e');
      }
    });
  }

  Future<void> _refreshSubscriptionStats() async {
    return _subscriptionRefreshGate.run(() async {
      try {
        _subs = await SubscriptionRepository.to.getAllSubscriptions();
        _calculateSubscriptionStats();
      } catch (e) {
        LogService.to.error('Stats', '刷新订阅统计失败: $e');
      }
    });
  }

  Future<void> _refreshEvidenceStats() async {
    return _evidenceRefreshGate.run(() async {
      try {
        _evidence = await EvidenceRepository.to.getAllEvidence();
        _calculateEvidenceStats();
      } catch (e) {
        LogService.to.error('Stats', '刷新凭证统计失败: $e');
      }
    });
  }

  Future<void> _refreshExpenseRecordStats() async {
    return _expenseRecordRefreshGate.run(() async {
      try {
        _expenseRecords = await ExpenseRecordRepository.to
            .getAllExpenseRecords();
        _calculateExpenseRecordStats();
      } catch (e) {
        LogService.to.error('Stats', '刷新一次性消费统计失败: $e');
      }
    });
  }

  String get selectedMonthLabel {
    final month = selectedMonth.value;
    return "${month.year}年${month.month}月";
  }

  double get selectedMonthTotalCost =>
      selectedMonthSubCost.value + selectedMonthExpenseRecordCost.value;

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
    refreshStats();
  }

  void nextMonth() {
    final month = selectedMonth.value;
    selectedMonth.value = DateTime(month.year, month.month + 1);
    refreshStats();
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    selectedMonth.value = DateTime(now.year, now.month);
    refreshStats();
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
  }

  void _calculateExpenseRecordStats({bool updateTimestamp = true}) {
    if (updateTimestamp) _touchLastUpdated();
    selectedMonthExpenseRecordCost.value = _expenseRecords
        .inMonth(selectedMonth.value)
        .totalAmount;
  }

  List<DailyWorkStat> _buildDailyWorkStats(
    DateTime month,
    List<WorkLog> monthLogs,
  ) {
    final logsByDay = <int, List<WorkLog>>{};
    for (final log in monthLogs) {
      logsByDay.putIfAbsent(log.date.day, () => <WorkLog>[]).add(log);
    }

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(daysInMonth, (index) {
      final day = index + 1;
      final logs = logsByDay[day] ?? const <WorkLog>[];
      final overtimeHours = logs
          .where((log) => log.type == LogType.work)
          .fold(0.0, (sum, log) => sum + (log.overtimeHours ?? 0.0));

      DailyWorkKind kind = DailyWorkKind.empty;
      if (logs.any((log) => log.type == LogType.work)) {
        kind = DailyWorkKind.work;
      } else if (logs.any((log) => log.type == LogType.businessTrip)) {
        kind = DailyWorkKind.trip;
      } else if (logs.any(
        (log) => log.type == LogType.rest || log.type == LogType.leave,
      )) {
        kind = DailyWorkKind.restOrLeave;
      }

      return DailyWorkStat(
        date: DateTime(month.year, month.month, day),
        kind: kind,
        overtimeHours: overtimeHours,
      );
    });
  }
}

enum DailyWorkKind { empty, work, trip, restOrLeave }

class DailyWorkStat {
  final DateTime date;
  final DailyWorkKind kind;
  final double overtimeHours;

  const DailyWorkStat({
    required this.date,
    required this.kind,
    required this.overtimeHours,
  });
}

class ReimbursementStats {
  final double pending;
  final double reimbursed;

  const ReimbursementStats({required this.pending, required this.reimbursed});

  double get total => pending + reimbursed;
}

class _RefreshGate {
  Future<void>? _inFlight;
  bool _rerun = false;

  Future<void> run(Future<void> Function() operation) {
    final activeRefresh = _inFlight;
    if (activeRefresh != null) {
      _rerun = true;
      return activeRefresh;
    }

    _inFlight = _runLoop(operation);
    return _inFlight!;
  }

  Future<void> _runLoop(Future<void> Function() operation) async {
    try {
      do {
        _rerun = false;
        await operation();
      } while (_rerun);
    } finally {
      _inFlight = null;
    }
  }
}
