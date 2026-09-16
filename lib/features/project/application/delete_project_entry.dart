import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';

final class DeleteProjectEntry {
  final ProjectRepositoryPort _repository;

  const DeleteProjectEntry(this._repository);

  Future<AppResult<void>> call(ProjectEntry entry) async {
    try {
      await _repository.deleteEntry(entry);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'project/delete-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
