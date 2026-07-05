import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry_stats.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_today_snapshot.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class LoadWorkLogToday {
  final WorkLogRepositoryPort _repository;

  const LoadWorkLogToday(this._repository);

  Future<AppResult<WorkLogTodaySnapshot>> call(DateTime today) async {
    try {
      final localToday = dateOnlyLocal(today);
      final entries = await _repository.getAllEntries();
      final normalizedEntries = entries
          .map((entry) => entry.copyWith(date: dateOnlyLocal(entry.date)))
          .toList(growable: false);
      final latestByDay = normalizedEntries.latestByLocalDate();
      final recentStart = localToday.subtract(const Duration(days: 6));
      final recentEntries = normalizedEntries.where((entry) {
        final day = dateOnlyLocal(entry.date);
        return !day.isBefore(recentStart) && !day.isAfter(localToday);
      }).toList()..sort(_compareRecentEntries);

      return AppResult.success(
        WorkLogTodaySnapshot(
          today: localToday,
          todayEntry: latestByDay[localToday],
          recentEntries: List.unmodifiable(recentEntries),
          currentMonthSummary: normalizedEntries.getMonthSummary(localToday),
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

  int _compareRecentEntries(WorkLogEntry a, WorkLogEntry b) {
    final dateCompare = b.date.compareTo(a.date);
    if (dateCompare != 0) return dateCompare;
    if (a.isNewerThan(b)) return -1;
    if (b.isNewerThan(a)) return 1;
    return b.id.compareTo(a.id);
  }
}
