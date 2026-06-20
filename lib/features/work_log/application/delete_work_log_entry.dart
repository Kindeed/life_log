import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class DeleteWorkLogEntry {
  final WorkLogRepositoryPort _repository;

  const DeleteWorkLogEntry(this._repository);

  Future<AppResult<void>> call(int id) async {
    try {
      await _repository.deleteEntry(id);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'work-log/delete-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
