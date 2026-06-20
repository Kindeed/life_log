import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';

final class DeleteEvidenceEntry {
  final EvidenceRepositoryPort _repository;

  const DeleteEvidenceEntry(this._repository);

  Future<AppResult<void>> call(int id) async {
    try {
      await _repository.deleteEntry(id);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'evidence/delete-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
