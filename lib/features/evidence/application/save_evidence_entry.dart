import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';

final class SaveEvidenceEntry {
  final EvidenceRepositoryPort _repository;

  const SaveEvidenceEntry(this._repository);

  Future<AppResult<void>> call(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  }) async {
    try {
      await _repository.saveEntry(
        entry,
        markDirty: markDirty,
        sourcePath: sourcePath,
        sourceExtension: sourceExtension,
      );
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'evidence/save-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
