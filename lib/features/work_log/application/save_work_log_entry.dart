import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class SaveWorkLogEntry {
  final WorkLogRepositoryPort _repository;

  const SaveWorkLogEntry(this._repository);

  Future<AppResult<void>> call(
    WorkLogEntry entry, {
    required bool markDirty,
  }) async {
    try {
      await _repository.saveEntry(entry, markDirty: markDirty);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'work-log/save-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
