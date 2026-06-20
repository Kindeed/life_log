import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

final class LoadSubscriptionEntries {
  final SubscriptionRepositoryPort _repository;

  const LoadSubscriptionEntries(this._repository);

  Future<AppResult<List<SubscriptionEntry>>> call() async {
    try {
      final entries = await _repository.getAllEntries();
      return AppResult.success(List.unmodifiable(entries));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'subscription/load-entries',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
