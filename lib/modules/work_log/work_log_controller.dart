import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../common/db/db_service.dart';
import '../../common/services/event_bus.dart';
import 'work_log_model.dart';
import '../../common/services/log_service.dart';
// 记得引入 StatisticsController 以便联动刷新统计

class WorkLogController extends GetxController {
  static WorkLogController get to => Get.find();

  // --- 1. 日历状态 ---
  final focusedDay = DateTime.now().obs;
  final selectedDay = DateTime.now().obs;
  final calendarFormat = CalendarFormat.month.obs;

  // --- 2. 数据源 ---
  final logsMap = <DateTime, List<WorkLog>>{}.obs;
  final isLoading = true.obs;
  // 版本号：用于强制刷新日历（因为 logsMap.length 不变时 TableCalendar 不会重绘）
  final dataVersion = 0.obs;

  // 统计数据
  final monthStatsDays = 0.obs;
  final monthStatsHours = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    await loadData();
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
    isLoading.value = true;
    LogService.to.debug('WorkLog', '开始加载数据...');

    final allLogs = await DbService.to.getAllLogs();
    LogService.to.debug('WorkLog', '从数据库获取到 ${allLogs.length} 条记录');

    final newMap = <DateTime, List<WorkLog>>{};
    for (var log in allLogs) {
      final date = log.date;
      final key = DateTime(date.year, date.month, date.day);
      if (newMap[key] == null) newMap[key] = [];
      newMap[key]!.add(log);
    }

    logsMap.assignAll(newMap);
    dataVersion.value++; // 强制刷新日历
    LogService.to.info('WorkLog', '数据已更新，共 ${logsMap.length} 天有记录');
    _calculateMonthStats();

    isLoading.value = false;
    LogService.to.debug('WorkLog', '数据加载完成');
  }

  // 添加/修改日志
  Future<void> addLog(WorkLog log) async {
    await DbService.to.addLog(log);
    await loadData();
    LogService.to.info('WorkLog', '添加/修改日志: ${log.date}');
    EventBus.instance.fire(const WorkLogChangedEvent());
  }

  // 删除日志
  Future<void> deleteLog(int id) async {
    await DbService.to.deleteLog(id);
    await loadData();
    LogService.to.info('WorkLog', '删除日志 ID: $id');
    EventBus.instance.fire(const WorkLogChangedEvent());
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
