import 'dart:async';
import 'package:get/get.dart';
import '../../common/db/db_service.dart';
import '../../common/services/log_service.dart';
import '../work_log/work_log_model.dart';
import '../subscription/subscription_model.dart';

class StatisticsController extends GetxController {
  // --- 1. 基础数据 ---
  final currentMonth = DateTime.now().month.obs;
  final nextMonth = 0.obs;

  // --- 2. 工时/天数 (依然只看本月) ---
  final workHours = 0.0.obs;
  final workDays = 0.obs;
  final tripDays = 0.obs;
  final restDays = 0.obs;

  // --- 3. 财务统计 ---
  final nextMonthSubCost = 0.0.obs;
  final yearSubCost = 0.0.obs;

  // 【修改】这两个变量现在代表“全部历史累计”
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
    _updateMonthLabels();
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

  void _updateMonthLabels() {
    final now = DateTime.now();
    currentMonth.value = now.month;
    int next = now.month + 1;
    if (next > 12) next = 1;
    nextMonth.value = next;
  }

  void _calculateStats(List<WorkLog> logs, List<Subscription> subs) {
    final now = DateTime.now();
    lastUpdated.value =
        "${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    LogService.to.debug('Stats', 'Recalculated at ${lastUpdated.value}');
    _updateMonthLabels();

    // 1. 报销统计
    reimbursedAmount.value = logs.totalReimbursedAmount;
    unreimbursedAmount.value = logs.totalUnreimbursedAmount;

    // 2. 工时统计
    final monthStats = logs.getMonthStats(now);
    workHours.value = monthStats.workHours;
    workDays.value = monthStats.workDays;
    tripDays.value = monthStats.tripDays;
    restDays.value = monthStats.restDays;

    // 3. 订阅统计
    nextMonthSubCost.value = subs.totalCostForMonth(nextMonth.value);
    yearSubCost.value = subs.totalYearlyCost;
  }
}
