import 'package:isar/isar.dart';

part 'work_log_model.g.dart';

@collection
class WorkLog {
  Id id = Isar.autoIncrement;

  // Sync fields
  int? remoteId;
  String? syncId;
  int remoteVersion = 0;
  DateTime? remoteUpdatedAt;
  DateTime? syncedAt;
  bool isDirty = false;
  DateTime? deletedAt;
  bool pendingDelete = false;

  late DateTime date; // 日期

  @enumerated
  late LogType type; // 类型：工作/休假/出差

  double? overtimeHours; // 加班时长

  String? location; // 出差地点 / 请假类型

  String? transport; // 交通工具

  double? expenses; // 垫付金额

  // --- 【新增】是否已报销 ---
  bool isReimbursed = false;

  String? note; // 备注
}

enum LogType {
  work, // 工作
  rest, // 休息
  leave, // 请假
  businessTrip, // 出差
}

extension WorkLogListDomainLogic on Iterable<WorkLog> {
  /// 计算总已报销金额
  double get totalReimbursedAmount {
    return where(
      (log) => log.expenses != null && log.expenses! > 0 && log.isReimbursed,
    ).fold(0.0, (sum, log) => sum + log.expenses!);
  }

  /// 计算总未报销金额
  double get totalUnreimbursedAmount {
    return where(
      (log) => log.expenses != null && log.expenses! > 0 && !log.isReimbursed,
    ).fold(0.0, (sum, log) => sum + log.expenses!);
  }

  /// 获取本月的日志
  Iterable<WorkLog> inMonth(DateTime monthYear) {
    return where(
      (log) =>
          log.date.year == monthYear.year && log.date.month == monthYear.month,
    );
  }

  /// 获取指定月份的统计数据
  WorkMonthStats getMonthStats(DateTime monthYear) {
    double hours = 0.0;
    int wDays = 0;
    int tDays = 0;
    int rDays = 0;

    final monthLogsByDate = <DateTime, List<WorkLog>>{};
    for (var log in inMonth(monthYear)) {
      final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
      if (monthLogsByDate[dateKey] == null) {
        monthLogsByDate[dateKey] = [];
      }
      monthLogsByDate[dateKey]!.add(log);
    }

    monthLogsByDate.forEach((date, dailyLogs) {
      bool hasWork = false;
      bool hasTrip = false;
      bool hasRestOrLeave = false;

      for (var log in dailyLogs) {
        if (log.type == LogType.work) {
          hasWork = true;
          if (log.overtimeHours != null) hours += log.overtimeHours!;
        } else if (log.type == LogType.businessTrip) {
          hasTrip = true;
        } else {
          hasRestOrLeave = true;
        }
      }

      if (hasWork) {
        wDays++;
      } else if (hasTrip) {
        tDays++;
      } else if (hasRestOrLeave) {
        rDays++;
      }
    });

    return WorkMonthStats(
      workHours: hours,
      workDays: wDays,
      tripDays: tDays,
      restDays: rDays,
    );
  }
}

class WorkMonthStats {
  final double workHours;
  final int workDays;
  final int tripDays;
  final int restDays;

  WorkMonthStats({
    required this.workHours,
    required this.workDays,
    required this.tripDays,
    required this.restDays,
  });
}
