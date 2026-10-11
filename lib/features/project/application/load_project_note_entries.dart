import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';

final class LoadProjectNoteEntries {
  final ProjectNoteRepositoryPort _repository;

  const LoadProjectNoteEntries(this._repository);

  Future<AppResult<List<ProjectNoteEntry>>> call(
    ProjectRecordScope scope,
  ) async {
    try {
      return AppResult.success(await _repository.getEntries(scope));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: error is ProjectNoteContextChanged
              ? 'project/notes-context-changed'
              : 'project/load-notes',
          message: error is ProjectNoteContextChanged
              ? error.message
              : '读取项目记录失败，请重试',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
