import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

final class LoadSubscriptionEditDraft {
  final SubscriptionRepositoryPort _repository;

  const LoadSubscriptionEditDraft(this._repository);

  Future<AppResult<SubscriptionEditDraft?>> call(int id) async {
    try {
      return AppResult.success(await _repository.getEditDraft(id));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'subscription/load-edit-draft',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
