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

  StreamSubscription? _logSub;
  StreamSubscription? _subSub;
  StreamSubscription? _evidenceSub;
  StreamSubscription? _expenseRecordSub;
  Future<void>? _refreshInFlight;
  bool _refreshAgain = false;

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
      refreshStats();
    });

    // 监听订阅变化
    _subSub = SubscriptionRepository.to.watchSubscriptions().listen((_) {
      LogService.to.debug('Stats', 'Subscriptions Changed');
      refreshStats();
    });

    _evidenceSub = EvidenceRepository.to.watchEvidence().listen((_) {
      LogService.to.debug('Stats', 'Evidence Changed');
      refreshStats();
    });

    _expenseRecordSub = ExpenseRecordRepository.to.watchExpenseRecords().listen(
      (_) {
        LogService.to.debug('Stats', 'ExpenseRecords Changed');
        refreshStats();
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

  Future<void> refreshStats() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) {
      _refreshAgain = true;
      return activeRefresh;
    }

    _refreshInFlight = _runRefreshStats();
    return _refreshInFlight!;
  }

  Future<void> _runRefreshStats() async {
    try {
      do {
        _refreshAgain = false;
        final allLogs = await WorkLogRepository.to.getAllLogs();
        final allSubs = await SubscriptionRepository.to.getAllSubscriptions();
        final allEvidence = await EvidenceRepository.to.getAllEvidence();
        final allExpenseRecords = await ExpenseRecordRepository.to
            .getAllExpenseRecords();
        _calculateStats(allLogs, allSubs, allEvidence, allExpenseRecords);
      } while (_refreshAgain);
    } catch (e) {
      LogService.to.error('Stats', '刷新统计失败: $e');
    } finally {
      _refreshInFlight = null;
    }
  }

  String get selectedMonthLabel {
    final month = selectedMonth.value;
    return "${month.year}年${month.month}月";
  }

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

  void _calculateStats(
    List<WorkLog> logs,
    List<Subscription> subs,
    List<ExpenseEvidence> evidence,
    List<ExpenseRecord> expenseRecords,
  ) {
    final now = DateTime.now();
    lastUpdated.value =
        "${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    LogService.to.debug('Stats', 'Recalculated at ${lastUpdated.value}');

    final month = selectedMonth.value;
    final monthLogs = logs.inMonth(month).toList();

    // 1. 报销统计
    reimbursedAmount.value = monthLogs.totalReimbursedAmount;
    unreimbursedAmount.value = monthLogs.totalUnreimbursedAmount;
    final monthEvidence = evidence.inMonth(month).toList();
    evidenceReimbursedAmount.value = monthEvidence.totalReimbursedAmount;
    evidenceUnreimbursedAmount.value = monthEvidence.totalPendingAmount;

    // 2. 工时统计
    final monthStats = logs.getMonthStats(month);
    workHours.value = monthStats.workHours;
    workDays.value = monthStats.workDays;
    tripDays.value = monthStats.tripDays;
    restDays.value = monthStats.restDays;

    // 3. 订阅统计
    selectedMonthSubCost.value = subs.totalCostForMonth(month);
    selectedMonthExpenseRecordCost.value = expenseRecords
        .inMonth(month)
        .totalAmount;
    yearSubCost.value = subs.totalYearlyCost;
  }
}
