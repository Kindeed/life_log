import 'package:equatable/equatable.dart';
import 'package:life_log/common/utils/date_utils.dart';

import 'subscription_currency.dart';

/// Rates are expressed as CNY for one unit of the source currency.
final class SubscriptionExchangeRates extends Equatable {
  final DateTime rateDate;
  final DateTime fetchedAt;
  final Map<String, double> cnyPerUnit;
  final bool fromCache;
  final String? warning;

  const SubscriptionExchangeRates({
    required this.rateDate,
    required this.fetchedAt,
    required this.cnyPerUnit,
    this.fromCache = false,
    this.warning,
  });

  factory SubscriptionExchangeRates.cnyOnly(DateTime now, {String? warning}) {
    final localNow = dateOnlyLocal(now);
    return SubscriptionExchangeRates(
      rateDate: localNow,
      fetchedAt: now,
      cnyPerUnit: const {'CNY': 1.0},
      warning: warning,
    );
  }

  double? convertToCny(double amount, SubscriptionCurrency currency) {
    final rate = cnyPerUnit[currency.code];
    return rate == null ? null : amount * rate;
  }

  bool hasRateFor(SubscriptionCurrency currency) {
    return cnyPerUnit[currency.code] != null;
  }

  SubscriptionExchangeRates copyWith({
    bool? fromCache,
    String? warning,
    bool clearWarning = false,
  }) {
    return SubscriptionExchangeRates(
      rateDate: rateDate,
      fetchedAt: fetchedAt,
      cnyPerUnit: cnyPerUnit,
      fromCache: fromCache ?? this.fromCache,
      warning: clearWarning ? null : warning ?? this.warning,
    );
  }

  @override
  List<Object?> get props => [
    rateDate,
    fetchedAt,
    cnyPerUnit,
    fromCache,
    warning,
  ];
}
