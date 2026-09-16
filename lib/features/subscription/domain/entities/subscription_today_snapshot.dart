import 'package:equatable/equatable.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';

final class SubscriptionTodaySnapshot extends Equatable {
  final DateTime today;
  final List<SubscriptionEntry> dueSoonEntries;
  final double currentMonthCost;
  final double dueSoonCostCny;
  final SubscriptionExchangeRates exchangeRates;

  SubscriptionTodaySnapshot({
    required this.today,
    required this.dueSoonEntries,
    required this.currentMonthCost,
    this.dueSoonCostCny = 0,
    SubscriptionExchangeRates? exchangeRates,
  }) : exchangeRates =
           exchangeRates ?? SubscriptionExchangeRates.cnyOnly(today);

  static SubscriptionTodaySnapshot empty(DateTime today) {
    return SubscriptionTodaySnapshot(
      today: today,
      dueSoonEntries: const [],
      currentMonthCost: 0,
      dueSoonCostCny: 0,
      exchangeRates: SubscriptionExchangeRates.cnyOnly(today),
    );
  }

  @override
  List<Object?> get props => [
    today,
    dueSoonEntries,
    currentMonthCost,
    dueSoonCostCny,
    exchangeRates,
  ];
}
