import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';

final class CreateProjectEntry {
  final ProjectRepositoryPort _repository;

  const CreateProjectEntry(this._repository);

  Future<AppResult<ProjectEntry>> call(String name) async {
    try {
      return AppResult.success(await _repository.ensureEntry(name));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'project/create-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
