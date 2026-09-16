import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/subscription/data/subscription_exchange_rate_service.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry_stats.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';

void main() {
  test('maps supported currency codes and formats original amounts', () {
    expect(subscriptionCurrencyFromCode('usd'), SubscriptionCurrency.usd);
    expect(subscriptionCurrencyFromCode('EUR'), SubscriptionCurrency.eur);
    expect(subscriptionCurrencyFromCode('unknown'), SubscriptionCurrency.cny);
    expect(formatSubscriptionAmount(12.5, SubscriptionCurrency.usd), '\$12.50');
  });

  test('converts statistics to CNY without changing original amount', () {
    final rates = SubscriptionExchangeRates(
      rateDate: DateTime(2026, 9, 16),
      fetchedAt: DateTime(2026, 9, 16, 9),
      cnyPerUnit: const {'CNY': 1.0, 'USD': 7.1},
    );
    final entry = SubscriptionEntry(
      id: 1,
      name: 'Cloud',
      price: 10,
      currency: SubscriptionCurrency.usd,
      cycle: SubscriptionBillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 9, 20),
    );

    expect(entry.price, 10);
    expect(entry.yearlyCostInCny(rates), 852);
    expect([entry].totalCostForMonthInCny(DateTime(2026, 9), rates), 71);
  });

  test('uses each subscription reminder window', () {
    final entries = [
      _entry(id: 1, paymentDate: DateTime(2026, 9, 3), reminderDays: 2),
      _entry(id: 2, paymentDate: DateTime(2026, 9, 3), reminderDays: 1),
      _entry(id: 3, paymentDate: DateTime(2026, 9, 2), reminderDays: 0),
    ];

    expect(
      entries.dueForReminderFrom(DateTime(2026, 9, 1)).map((entry) => entry.id),
      [1],
    );
    expect(
      [
        entries[2],
      ].dueForReminderFrom(DateTime(2026, 9, 2)).map((entry) => entry.id),
      [3],
    );
  });

  test(
    'caches same-day rates and uses stale cache when refresh fails',
    () async {
      final cache = _MemoryRateCache();
      final provider = _FakeRateProvider();
      final service = SubscriptionExchangeRateService(
        provider: provider,
        cache: cache,
      );

      final first = await service.load(DateTime(2026, 9, 16, 10));
      final second = await service.load(DateTime(2026, 9, 16, 18));

      expect(first.cnyPerUnit['USD'], 7.1);
      expect(second.fromCache, isFalse);
      expect(provider.calls, 1);

      provider.shouldFail = true;
      final stale = await service.load(DateTime(2026, 9, 17, 10));
      expect(stale.fromCache, isTrue);
      expect(stale.cnyPerUnit['USD'], 7.1);
      expect(stale.warning, contains('今日汇率暂未更新'));
    },
  );

  test('does not pretend unavailable rates are one-to-one', () async {
    final service = SubscriptionExchangeRateService(
      provider: _FakeRateProvider()..shouldFail = true,
      cache: _MemoryRateCache(),
    );

    final rates = await service.load(DateTime(2026, 9, 16));
    expect(rates.convertToCny(10, SubscriptionCurrency.usd), isNull);
    expect(rates.warning, contains('外币订阅暂不计入'));
  });
}

SubscriptionEntry _entry({
  required int id,
  required DateTime paymentDate,
  required int reminderDays,
}) {
  return SubscriptionEntry(
    id: id,
    name: 'Service $id',
    price: 10,
    cycle: SubscriptionBillingCycle.monthly,
    nextPaymentDate: paymentDate,
    reminderDays: reminderDays,
  );
}

final class _FakeRateProvider implements SubscriptionExchangeRateProvider {
  int calls = 0;
  bool shouldFail = false;

  @override
  Future<SubscriptionExchangeRates> load(DateTime now) async {
    calls++;
    if (shouldFail) throw StateError('offline');
    return SubscriptionExchangeRates(
      rateDate: DateTime(now.year, now.month, now.day),
      fetchedAt: now,
      cnyPerUnit: const {'CNY': 1.0, 'USD': 7.1},
    );
  }
}

final class _MemoryRateCache implements SubscriptionRateCache {
  Object? value;

  @override
  Object? read() => value;

  @override
  Future<void> write(Object value) async {
    this.value = value;
  }
}
