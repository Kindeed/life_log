import 'package:get/get.dart';
import '../../common/db/db_service.dart';
import '../work_log/log_model.dart';
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

  @override
  void onInit() {
    super.onInit();
    _updateMonthLabels();
    refreshStats();
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
    _updateMonthLabels();

    double hours = 0.0;
    int wDays = 0;
    int tDays = 0;
    int rDays = 0;
    
    double reimbursed = 0.0;
    double unreimbursed = 0.0;

    for (var log in logs) {
      // --- 【修改点 1】报销统计移到最外层 (不分月份，统计所有) ---
      if (log.expenses != null && log.expenses! > 0) {
        if (log.isReimbursed) {
          reimbursed += log.expenses!; 
        } else {
          unreimbursed += log.expenses!; 
        }
      }
      // ----------------------------------------------------

      // --- 【修改点 2】工时统计依然限制在“本月” ---
      if (log.date.year == now.year && log.date.month == now.month) {
        if (log.type == LogType.work) {
          wDays++;
          if (log.overtimeHours != null) hours += log.overtimeHours!;
        } else if (log.type == LogType.businessTrip) {
          tDays++;
        } else {
          rDays++;
        }
      }
    }

    workHours.value = hours;
    workDays.value = wDays;
    tripDays.value = tDays;
    restDays.value = rDays;
    reimbursedAmount.value = reimbursed;
    unreimbursedAmount.value = unreimbursed;

    // --- 订阅逻辑不变 ---
    double nextMonthCost = 0.0;
    double yearTotal = 0.0;
    
    for (var sub in subs) {
      double price = sub.price ?? 0.0; 
      double yearlyPrice = price;
      
      if (sub.cycle == SubscriptionCycle.monthly) {
        yearlyPrice = price * 12;
        nextMonthCost += price; 
      } else {
        if (sub.nextPaymentDate.month == nextMonth.value) {
          nextMonthCost += price;
        }
      }
      yearTotal += yearlyPrice;
    }
    nextMonthSubCost.value = nextMonthCost;
    yearSubCost.value = yearTotal;
  }
}