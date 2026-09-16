import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry_stats.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_today_snapshot.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

final class LoadSubscriptionToday {
  final SubscriptionRepositoryPort _repository;
  final Future<SubscriptionExchangeRates> Function(DateTime)? _loadRates;

  const LoadSubscriptionToday(
    this._repository, {
    Future<SubscriptionExchangeRates> Function(DateTime)? loadRates,
  }) : _loadRates = loadRates;

  Future<AppResult<SubscriptionTodaySnapshot>> call(DateTime today) async {
    try {
      final localToday = dateOnlyLocal(today);
      final entries = await _repository.getAllEntries();
      final needsRates = entries.any(
        (entry) =>
            entry.currency != SubscriptionCurrency.cny &&
            (entry.price ?? 0) > 0,
      );
      final loadRates = _loadRates;
      final rates = loadRates != null && needsRates
          ? await loadRates(localToday)
          : SubscriptionExchangeRates.cnyOnly(localToday);
      final dueSoonEntries = entries.dueForReminderFrom(localToday);
      final dueSoonCostCny = dueSoonEntries.fold<double>(
        0,
        (sum, entry) =>
            sum + (rates.convertToCny(entry.price ?? 0, entry.currency) ?? 0),
      );

      return AppResult.success(
        SubscriptionTodaySnapshot(
          today: localToday,
          dueSoonEntries: List.unmodifiable(dueSoonEntries),
          dueSoonCostCny: dueSoonCostCny,
          exchangeRates: rates,
          currentMonthCost: entries.totalCostForMonthInCny(
            DateTime(localToday.year, localToday.month),
            rates,
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
