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

  Map<DateTime, List<WorkLogEntry>> groupedByLocalDate() {
    final result = <DateTime, List<WorkLogEntry>>{};
    for (final entry in this) {
      final key = dateOnlyLocal(entry.date);
      final normalized = entry.copyWith(date: key);
      result.putIfAbsent(key, () => <WorkLogEntry>[]).add(normalized);
    }
    for (final entries in result.values) {
      entries.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.id.compareTo(b.id);
      });
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

    for (final dayEntries in inMonth(monthYear).groupedByLocalDate().values) {
      var hasWork = false;
      var hasTrip = false;
      var hasRest = false;
      for (final entry in dayEntries) {
        switch (entry.type) {
          case WorkLogEntryType.work:
            hasWork = true;
            workHours += entry.overtimeHours ?? 0;
            break;
          case WorkLogEntryType.businessTrip:
            hasTrip = true;
            break;
          case WorkLogEntryType.leave:
          case WorkLogEntryType.rest:
            hasRest = true;
            break;
        }
      }
      if (hasWork) workDays++;
      if (hasTrip) tripDays++;
      if (hasRest) restDays++;
    }

    return WorkLogMonthSummary(
      workHours: workHours,
      workDays: workDays,
      tripDays: tripDays,
      restDays: restDays,
    );
  }
}
