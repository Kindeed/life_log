import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';

final class DeleteProjectNoteEntry {
  final ProjectNoteRepositoryPort _repository;

  const DeleteProjectNoteEntry(this._repository);

  Object? captureContext() => _repository.captureContext();

  Future<AppResult<void>> call(int id, {Object? expectedContext}) async {
    try {
      await _repository.deleteEntry(id, expectedContext: expectedContext);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'project/delete-note',
          message: error is StateError
              ? error.message.toString()
              : '删除项目记录失败，请重试',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
