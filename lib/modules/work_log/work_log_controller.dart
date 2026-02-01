import 'package:get/get.dart';
import 'package:life_log/modules/statistics/statistics_controller.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../common/db/db_service.dart';
import 'log_model.dart';
// 记得引入 StatisticsController 以便联动刷新统计

class WorkLogController extends GetxController {
  static WorkLogController get to => Get.find();

  // --- 1. 日历状态 ---
  final focusedDay = DateTime.now().obs;
  final selectedDay = DateTime.now().obs;
  final calendarFormat = CalendarFormat.month.obs; 

  // --- 2. 数据源 ---
  final logsMap = <DateTime, List<WorkLog>>{}.obs;
  
  // 统计数据
  final monthStatsDays = 0.obs;
  final monthStatsHours = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // --- 核心操作 ---

  void onDaySelected(DateTime selected, DateTime focused) {
    final safeSelected = DateTime(selected.year, selected.month, selected.day);
    if (!isSameDay(selectedDay.value, safeSelected)) {
      selectedDay.value = safeSelected;
      focusedDay.value = focused;
      update();
    }
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
  }

  void onFormatChanged(CalendarFormat format) {
    calendarFormat.value = format;
  }

  List<WorkLog> getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return logsMap[key] ?? [];
  }

  // 加载数据
  Future<void> loadData() async {
    final allLogs = await DbService.to.getAllLogs();
    
    final newMap = <DateTime, List<WorkLog>>{};
    for (var log in allLogs) {
      final date = log.date;
      final key = DateTime(date.year, date.month, date.day);
      if (newMap[key] == null) newMap[key] = [];
      newMap[key]!.add(log);
    }
    
    logsMap.value = newMap;
    _calculateMonthStats();
  }

  // 添加/修改日志
  Future<void> addLog(WorkLog log) async {
    await DbService.to.addLog(log);
    await loadData(); // 刷新日历
    // 尝试刷新统计页面的数据 (如果有的话)
    if (Get.isRegistered<StatisticsController>()) {
      Get.find<StatisticsController>().refreshStats();
    }
  }

  // --- 【新增】删除日志 ---
  Future<void> deleteLog(int id) async {
    await DbService.to.deleteLog(id);
    await loadData(); // 刷新日历
    // 联动刷新统计
    if (Get.isRegistered<StatisticsController>()) {
      Get.find<StatisticsController>().refreshStats();
    }
  }

  void _calculateMonthStats() {
    final currentMonth = focusedDay.value;
    int days = 0;
    double hours = 0.0;

    logsMap.forEach((date, logs) {
      if (date.year == currentMonth.year && date.month == currentMonth.month) {
        final hasWork = logs.any((l) => l.type == LogType.work);
        if (hasWork) days++;

        for (var log in logs) {
          if (log.type == LogType.work && log.overtimeHours != null) {
            hours += log.overtimeHours!;
          }
        }
      }
    });

    monthStatsDays.value = days;
    monthStatsHours.value = hours;
  }
}