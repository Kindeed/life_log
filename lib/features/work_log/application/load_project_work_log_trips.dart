import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class LoadProjectWorkLogTrips {
  final WorkLogRepositoryPort _repository;

  const LoadProjectWorkLogTrips(this._repository);

  Future<AppResult<List<WorkLogEntry>>> call(
    String projectName, {
    bool includeUnlinked = false,
    int? projectId,
    String? projectSyncId,
  }) async {
    try {
      final normalizedProjectName = projectName.trim();
      if (normalizedProjectName.isEmpty) {
        return const AppResult.success(<WorkLogEntry>[]);
      }
      final entries = await _repository.getAllEntries();
      final scope = ProjectRecordScope(
        name: normalizedProjectName,
        id: projectId,
        syncId: projectSyncId,
      );
      final trips =
          entries.where((entry) {
            if (entry.type != WorkLogEntryType.businessTrip) {
              return false;
            }
            final linkedName = entry.projectName?.trim();
            // Existing name-only callers retain their legacy selection.
            final matches = projectId == null && projectSyncId == null
                ? linkedName == normalizedProjectName
                : scope.contains(
                    name: entry.projectName,
                    id: entry.projectId,
                    syncId: entry.projectSyncId,
                  );
            return matches ||
                (includeUnlinked &&
                    entry.projectId == null &&
                    entry.projectSyncId?.trim().isNotEmpty != true &&
                    (linkedName == null || linkedName.isEmpty));
          }).toList()..sort((a, b) {
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
