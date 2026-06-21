import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

final class ReorderSubscriptionEntries {
  final SubscriptionRepositoryPort _repository;

  const ReorderSubscriptionEntries(this._repository);

  Future<AppResult<void>> call(
    List<SubscriptionEntry> entries, {
    required int oldIndex,
    required int newIndex,
  }) async {
    try {
      if (oldIndex < 0 || oldIndex >= entries.length) {
        return const AppResult.success(null);
      }

      var targetIndex = newIndex.clamp(0, entries.length);
      if (oldIndex < targetIndex) {
        targetIndex -= 1;
      }

      final reorderedEntries = List<SubscriptionEntry>.of(entries);
      final entry = reorderedEntries.removeAt(oldIndex);
      reorderedEntries.insert(targetIndex, entry);

      await _repository.reorderEntries(reorderedEntries);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'subscription/reorder-entries',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
