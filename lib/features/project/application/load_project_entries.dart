import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';

final class LoadProjectEntries {
  final ProjectRepositoryPort _repository;

  const LoadProjectEntries(this._repository);

  Future<AppResult<List<ProjectEntry>>> call() async {
    try {
      return AppResult.success(await _repository.getAllEntries());
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'project/load-entries',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
