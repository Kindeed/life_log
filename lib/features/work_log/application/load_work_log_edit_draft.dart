import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class LoadWorkLogEditDraft {
  final WorkLogRepositoryPort _repository;

  const LoadWorkLogEditDraft(this._repository);

  Future<AppResult<WorkLogEditDraft?>> call(int id) async {
    try {
      return AppResult.success(await _repository.getEditDraft(id));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'work-log/load-edit-draft',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
