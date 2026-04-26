import 'dart:async';
import 'package:get/get.dart';
import '../../common/db/db_service.dart';
import '../../common/services/log_service.dart';
import '../work_log/work_log_model.dart';
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
  final yearSubCost = 0.0.obs;

  final reimbursedAmount = 0.0.obs;
  final unreimbursedAmount = 0.0.obs;

  StreamSubscription? _logSub;
  StreamSubscription? _subSub;

  // --- 4. 调试/验证 ---
  final lastUpdated = "".obs;

  @override
  void onInit() {
    super.onInit();
    LogService.to.debug('Stats', 'Controller Init');
    refreshStats();

    // 监听工时变化
    _logSub = DbService.to.watchWorkLogs().listen((_) {
      LogService.to.debug('Stats', 'WorkLogs Changed');
      refreshStats();
    });

    // 监听订阅变化
    _subSub = DbService.to.watchSubscriptions().listen((_) {
      LogService.to.debug('Stats', 'Subscriptions Changed');
      refreshStats();
    });
  }

  @override
  void onClose() {
    LogService.to.debug('Stats', 'Controller Close');
    _logSub?.cancel();
    _subSub?.cancel();
    super.onClose();
  }

  void refreshStats() async {
    final allLogs = await DbService.to.getAllLogs();
    final allSubs = await DbService.to.getAllSubscriptions();
    _calculateStats(allLogs, allSubs);
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

  void _calculateStats(List<WorkLog> logs, List<Subscription> subs) {
    final now = DateTime.now();
    lastUpdated.value =
        "${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    LogService.to.debug('Stats', 'Recalculated at ${lastUpdated.value}');

    final month = selectedMonth.value;
    final monthLogs = logs.inMonth(month).toList();

    // 1. 报销统计
    reimbursedAmount.value = monthLogs.totalReimbursedAmount;
    unreimbursedAmount.value = monthLogs.totalUnreimbursedAmount;

    // 2. 工时统计
    final monthStats = logs.getMonthStats(month);
    workHours.value = monthStats.workHours;
    workDays.value = monthStats.workDays;
    tripDays.value = monthStats.tripDays;
    restDays.value = monthStats.restDays;

    // 3. 订阅统计
    selectedMonthSubCost.value = subs.totalCostForMonth(month);
    yearSubCost.value = subs.totalYearlyCost;
  }
}
