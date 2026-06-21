import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry_stats.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_today_snapshot.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

final class LoadSubscriptionToday {
  final SubscriptionRepositoryPort _repository;

  const LoadSubscriptionToday(this._repository);

  Future<AppResult<SubscriptionTodaySnapshot>> call(DateTime today) async {
    try {
      final localToday = dateOnlyLocal(today);
      final entries = await _repository.getAllEntries();

      return AppResult.success(
        SubscriptionTodaySnapshot(
          today: localToday,
          dueSoonEntries: List.unmodifiable(entries.dueSoonFrom(localToday)),
          currentMonthCost: entries.totalCostForMonth(
            DateTime(localToday.year, localToday.month),
          ),
        ),
      );
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'subscription/load-today',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
