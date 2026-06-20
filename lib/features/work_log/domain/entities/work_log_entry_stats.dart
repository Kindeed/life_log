import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_month_snapshot.dart';

extension WorkLogEntryStats on Iterable<WorkLogEntry> {
  Map<DateTime, WorkLogEntry> latestByLocalDate() {
    final result = <DateTime, WorkLogEntry>{};
    for (final entry in this) {
      final key = dateOnlyLocal(entry.date);
      final normalized = entry.copyWith(date: key);
      final existing = result[key];
      if (existing == null || normalized.isNewerThan(existing)) {
        result[key] = normalized;
      }
    }
    return result;
  }

  Iterable<WorkLogEntry> inMonth(DateTime monthYear) {
    final localMonth = dateOnlyLocal(monthYear);
    return where((entry) {
      final day = dateOnlyLocal(entry.date);
      return day.year == localMonth.year && day.month == localMonth.month;
    });
  }

  double get totalReimbursedAmount {
    return where(
      (entry) =>
          entry.expenses != null && entry.expenses! > 0 && entry.isReimbursed,
    ).fold(0.0, (sum, entry) => sum + entry.expenses!);
  }

  double get totalUnreimbursedAmount {
    return where(
      (entry) =>
          entry.expenses != null && entry.expenses! > 0 && !entry.isReimbursed,
    ).fold(0.0, (sum, entry) => sum + entry.expenses!);
  }

  WorkLogMonthSummary getMonthSummary(DateTime monthYear) {
    var workHours = 0.0;
    var workDays = 0;
    var tripDays = 0;
    var restDays = 0;

    for (final entry in inMonth(monthYear).latestByLocalDate().values) {
      switch (entry.type) {
        case WorkLogEntryType.work:
          workDays++;
          workHours += entry.overtimeHours ?? 0;
          break;
        case WorkLogEntryType.businessTrip:
          tripDays++;
          break;
        case WorkLogEntryType.leave:
        case WorkLogEntryType.rest:
          restDays++;
          break;
      }
    }

    return WorkLogMonthSummary(
      workHours: workHours,
      workDays: workDays,
      tripDays: tripDays,
      restDays: restDays,
    );
  }
}
