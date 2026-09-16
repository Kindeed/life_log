enum SubscriptionCurrency { cny, usd, eur, jpy, hkd }

extension SubscriptionCurrencyInfo on SubscriptionCurrency {
  String get code => switch (this) {
    SubscriptionCurrency.cny => 'CNY',
    SubscriptionCurrency.usd => 'USD',
    SubscriptionCurrency.eur => 'EUR',
    SubscriptionCurrency.jpy => 'JPY',
    SubscriptionCurrency.hkd => 'HKD',
  };

  String get symbol => switch (this) {
    SubscriptionCurrency.cny => '¥',
    SubscriptionCurrency.usd => '\$',
    SubscriptionCurrency.eur => '€',
    SubscriptionCurrency.jpy => '¥',
    SubscriptionCurrency.hkd => 'HK\$',
  };

  String get label => switch (this) {
    SubscriptionCurrency.cny => '人民币',
    SubscriptionCurrency.usd => '美元',
    SubscriptionCurrency.eur => '欧元',
    SubscriptionCurrency.jpy => '日元',
    SubscriptionCurrency.hkd => '港币',
  };

  String get displayLabel => '$code · $label';
}

SubscriptionCurrency subscriptionCurrencyFromCode(Object? value) {
  final normalized = value?.toString().trim().toUpperCase();
  return SubscriptionCurrency.values.firstWhere(
    (currency) => currency.code == normalized,
    orElse: () => SubscriptionCurrency.cny,
  );
}

String formatSubscriptionAmount(double value, SubscriptionCurrency currency) {
  return '${currency.symbol}${value.toStringAsFixed(2)}';
}
