import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_month_snapshot.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_today_snapshot.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class LoadWorkLogToday {
  final WorkLogRepositoryPort _repository;

  const LoadWorkLogToday(this._repository);

  Future<AppResult<WorkLogTodaySnapshot>> call(DateTime today) async {
    try {
      final localToday = dateOnlyLocal(today);
      final entries = await _repository.getAllEntries();
      final latestByDay = _latestEntriesByDay(entries);
      final recentStart = localToday.subtract(const Duration(days: 6));
      final recentEntries =
          latestByDay.entries
              .where((entry) {
                final day = entry.key;
                return !day.isBefore(recentStart) && !day.isAfter(localToday);
              })
              .map((entry) => entry.value)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      return AppResult.success(
        WorkLogTodaySnapshot(
          today: localToday,
          todayEntry: latestByDay[localToday],
          recentEntries: List.unmodifiable(recentEntries),
          currentMonthSummary: _calculateCurrentMonthSummary(
            latestByDay,
            localToday,
          ),
        ),
      );
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'work-log/load-today',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Map<DateTime, WorkLogEntry> _latestEntriesByDay(List<WorkLogEntry> entries) {
    final latestByDay = <DateTime, WorkLogEntry>{};

    for (final entry in entries) {
      final day = dateOnlyLocal(entry.date);
      final normalized = entry.copyWith(date: day);
      final existing = latestByDay[day];
      if (existing == null || normalized.isNewerThan(existing)) {
        latestByDay[day] = normalized;
      }
    }

    return latestByDay;
  }

  WorkLogMonthSummary _calculateCurrentMonthSummary(
    Map<DateTime, WorkLogEntry> latestByDay,
    DateTime today,
  ) {
    var workHours = 0.0;
    var workDays = 0;
    var tripDays = 0;
    var restDays = 0;

    for (final entry in latestByDay.values) {
      if (entry.date.year != today.year || entry.date.month != today.month) {
        continue;
      }

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
