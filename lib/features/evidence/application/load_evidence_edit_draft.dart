import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';

final class LoadEvidenceEditDraft {
  final EvidenceRepositoryPort _repository;

  const LoadEvidenceEditDraft(this._repository);

  Future<AppResult<EvidenceEditDraft?>> call(int id) async {
    try {
      return AppResult.success(await _repository.getEditDraft(id));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'evidence/load-edit-draft',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
