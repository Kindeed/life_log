import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

final class DeleteSubscriptionEntry {
  final SubscriptionRepositoryPort _repository;

  const DeleteSubscriptionEntry(this._repository);

  Future<AppResult<void>> call(int id) async {
    try {
      await _repository.deleteEntry(id);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'subscription/delete-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
