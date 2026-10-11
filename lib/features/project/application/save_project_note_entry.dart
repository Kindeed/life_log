import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';

final class SaveProjectNoteEntry {
  final ProjectNoteRepositoryPort _repository;

  const SaveProjectNoteEntry(this._repository);

  Object? captureContext() => _repository.captureContext();

  Future<AppResult<ProjectNoteEntry>> call(
    ProjectNoteEntry entry, {
    Object? expectedContext,
  }) async {
    try {
      return AppResult.success(
        await _repository.saveEntry(entry, expectedContext: expectedContext),
      );
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'project/save-note',
          message: switch (error) {
            ArgumentError(:final message) => message.toString(),
            StateError(:final message) => message,
            _ => '保存项目记录失败，请重试',
          },
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
