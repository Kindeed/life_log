import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';

final class LoadEvidenceEntries {
  final EvidenceRepositoryPort _repository;

  const LoadEvidenceEntries(this._repository);

  Future<AppResult<List<EvidenceEntry>>> call() async {
    try {
      final entries = await _repository.getAllEntries();
      return AppResult.success(List.unmodifiable(entries));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'evidence/load-entries',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
