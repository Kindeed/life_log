import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry_stats.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_month_snapshot.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class LoadWorkLogMonth {
  final WorkLogRepositoryPort _repository;

  const LoadWorkLogMonth(this._repository);

  Future<AppResult<WorkLogMonthSnapshot>> call(DateTime month) async {
    try {
      final localMonth = dateOnlyLocal(month);
      final entries = await _repository.getEntriesByMonth(localMonth);
      final entriesByDay = entries.groupedByLocalDate();

      final sortedDays = entriesByDay.keys.toList()..sort();
      final sortedEntriesByDay = <DateTime, List<WorkLogEntry>>{
        for (final day in sortedDays)
          day: List<WorkLogEntry>.unmodifiable(entriesByDay[day]!),
      };

      return AppResult.success(
        WorkLogMonthSnapshot(
          month: DateTime(localMonth.year, localMonth.month),
          entriesByDay: Map.unmodifiable(sortedEntriesByDay),
          summary: entries.getMonthSummary(localMonth),
        ),
      );
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'work-log/load-month',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
