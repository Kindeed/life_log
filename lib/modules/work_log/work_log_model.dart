import 'package:isar/isar.dart';

import '../../common/utils/date_utils.dart';

part 'work_log_model.g.dart';

@collection
class WorkLog {
  Id id = Isar.autoIncrement;

  // Sync fields
  String? ownerUserId;
  int? remoteId;
  String? syncId;
  int remoteVersion = 0;
  DateTime? remoteUpdatedAt;
  DateTime? syncedAt;
  bool isDirty = false;
  @Index()
  DateTime? deletedAt;
  bool pendingDelete = false;

  DateTime? createdAt;
  DateTime? updatedAt;

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
  Map<DateTime, WorkLog> latestByLocalDate() {
    final result = <DateTime, WorkLog>{};
    for (final log in this) {
      final key = dateOnlyLocal(log.date);
      final existing = result[key];
      if (existing == null || _isNewerWorkLog(log, existing)) {
        result[key] = log;
      }
    }
    return result;
  }

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
    final localMonth = dateOnlyLocal(monthYear);
    return where(
      (log) =>
          dateOnlyLocal(log.date).year == localMonth.year &&
          dateOnlyLocal(log.date).month == localMonth.month,
    );
  }

  /// 获取指定月份的统计数据
  WorkMonthStats getMonthStats(DateTime monthYear) {
    double hours = 0.0;
    int wDays = 0;
    int tDays = 0;
    int rDays = 0;

    for (final log in inMonth(monthYear).latestByLocalDate().values) {
      switch (log.type) {
        case LogType.work:
          wDays++;
          hours += log.overtimeHours ?? 0.0;
          break;
        case LogType.businessTrip:
          tDays++;
          break;
        case LogType.leave:
        case LogType.rest:
          rDays++;
          break;
      }
    }

    return WorkMonthStats(
      workHours: hours,
      workDays: wDays,
      tripDays: tDays,
      restDays: rDays,
    );
  }
}

bool _isNewerWorkLog(WorkLog next, WorkLog current) {
  final nextTime = next.updatedAt ?? next.createdAt ?? next.date;
  final currentTime = current.updatedAt ?? current.createdAt ?? current.date;
  final timeCompare = nextTime.compareTo(currentTime);
  if (timeCompare != 0) return timeCompare > 0;
  return next.id > current.id;
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

extension WorkLogBusinessChanges on WorkLog {
  bool hasBusinessChangesComparedTo(WorkLog other) {
    return date != other.date ||
        type != other.type ||
        overtimeHours != other.overtimeHours ||
        location != other.location ||
        transport != other.transport ||
        expenses != other.expenses ||
        isReimbursed != other.isReimbursed ||
        note != other.note;
  }
}
