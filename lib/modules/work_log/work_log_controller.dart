import 'dart:async';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../common/utils/date_utils.dart';
import 'work_log_model.dart';
import '../../common/services/log_service.dart';
import 'work_log_repository.dart';

class WorkLogController extends GetxController {
  static WorkLogController get to => Get.find();

  // --- 1. 日历状态 ---
  final focusedDay = dateOnlyLocal(DateTime.now()).obs;
  final selectedDay = dateOnlyLocal(DateTime.now()).obs;
  final calendarFormat = CalendarFormat.week.obs;

  // --- 2. 数据源 ---
  final logsMap = <DateTime, List<WorkLog>>{}.obs;
  final isLoading = true.obs;
  // 版本号：用于强制刷新日历
  final dataVersion = 0.obs;

  // 统计数据
  final monthStatsDays = 0.obs;
  final monthStatsHours = 0.0.obs;

  StreamSubscription? _dbSub;

  @override
  void onInit() {
    super.onInit();
    _loadDataSafely('startup');
    _dbSub = WorkLogRepository.to.watchLogs().listen((_) {
      _loadDataSafely('watch');
    });
  }

  @override
  void onClose() {
    _dbSub?.cancel();
    super.onClose();
  }

  // --- 核心操作 ---

  void onDaySelected(DateTime selected, DateTime focused) {
    final safeSelected = dateOnlyLocal(selected);
    if (!isSameDay(selectedDay.value, safeSelected)) {
      selectedDay.value = safeSelected;
    }
    focusedDay.value = dateOnlyLocal(focused);
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = dateOnlyLocal(focused);
  }

  void onFormatChanged(CalendarFormat format) {
    calendarFormat.value = format;
  }

  List<WorkLog> getEventsForDay(DateTime day) {
    final key = dateOnlyLocal(day);
    return logsMap[key] ?? [];
  }

  WorkLog? getLogForDay(DateTime day) {
    final logs = getEventsForDay(day);
    return logs.isEmpty ? null : logs.first;
  }

  // 加载数据
  Future<void> loadData() async {
    isLoading.value = true;
    try {
      LogService.to.debug('WorkLog', '开始加载数据...');

      await WorkLogRepository.to.normalizeDuplicateDays();
      final allLogs = await WorkLogRepository.to.getAllLogs();
      LogService.to.debug('WorkLog', '从数据库获取到 ${allLogs.length} 条记录');

      final newMap = <DateTime, List<WorkLog>>{};
      for (final entry in allLogs.latestByLocalDate().entries) {
        newMap[entry.key] = [entry.value];
      }

      logsMap.assignAll(newMap);
      dataVersion.value++; // 强制刷新日历
      LogService.to.info('WorkLog', '数据已更新，共 ${logsMap.length} 天有记录');
      _calculateMonthStats();

      LogService.to.debug('WorkLog', '数据加载完成');
    } catch (e, stackTrace) {
      LogService.to.error('WorkLog', '加载数据失败: $e', stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  void _loadDataSafely(String reason) {
    unawaited(loadData());
    LogService.to.debug('WorkLog', '触发数据加载: $reason');
  }

  // 添加/修改日志
  Future<void> addLog(WorkLog log) async {
    try {
      await WorkLogRepository.to.saveLog(log);
      LogService.to.info('WorkLog', '添加/修改日志: ${log.date}');
    } catch (e, stackTrace) {
      LogService.to.error('WorkLog', '保存日志失败: $e', stackTrace);
      Get.snackbar('保存失败', e.toString());
      rethrow;
    }
  }

  // 删除日志
  Future<void> deleteLog(int id) async {
    try {
      await WorkLogRepository.to.deleteLog(id);
      LogService.to.info('WorkLog', '删除日志 ID: $id');
    } catch (e, stackTrace) {
      LogService.to.error('WorkLog', '删除日志失败: $e', stackTrace);
      Get.snackbar('删除失败', e.toString());
      rethrow;
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
