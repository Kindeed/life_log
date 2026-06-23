import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class LoadProjectWorkLogTrips {
  final WorkLogRepositoryPort _repository;

  const LoadProjectWorkLogTrips(this._repository);

  Future<AppResult<List<WorkLogEntry>>> call(String projectName) async {
    try {
      final normalizedProjectName = projectName.trim();
      if (normalizedProjectName.isEmpty) {
        return const AppResult.success(<WorkLogEntry>[]);
      }
      final entries = await _repository.getAllEntries();
      final trips =
          entries
              .where(
                (entry) =>
                    entry.type == WorkLogEntryType.businessTrip &&
                    entry.projectName?.trim() == normalizedProjectName,
              )
              .toList()
            ..sort((a, b) {
              final dateCompare = dateOnlyLocal(
                b.date,
              ).compareTo(dateOnlyLocal(a.date));
              if (dateCompare != 0) return dateCompare;
              return b.id.compareTo(a.id);
            });
      return AppResult.success(List<WorkLogEntry>.unmodifiable(trips));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'work-log/load-project-trips',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
