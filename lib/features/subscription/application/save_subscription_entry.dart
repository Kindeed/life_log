import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

final class SaveSubscriptionEntry {
  final SubscriptionRepositoryPort _repository;

  const SaveSubscriptionEntry(this._repository);

  Future<AppResult<void>> call(
    SubscriptionEntry entry, {
    required bool markDirty,
  }) async {
    try {
      await _repository.saveEntry(entry, markDirty: markDirty);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'subscription/save-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
