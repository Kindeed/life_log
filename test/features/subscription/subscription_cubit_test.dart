import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/presentation/subscription_cubit.dart';

void main() {
  group('SubscriptionCubit', () {
    test(
      'loads entries and derives visible list, totals, and due-soon state',
      () async {
        final repository = _SubscriptionCubitRepository(
          entries: [
            _entry(
              id: 1,
              name: 'Cloud',
              price: 10,
              cycle: SubscriptionBillingCycle.monthly,
              nextPaymentDate: DateTime(2026, 5, 3),
              sortIndex: 2,
            ),
            _entry(
              id: 2,
              name: 'Rent',
              price: 120,
              cycle: SubscriptionBillingCycle.yearly,
              nextPaymentDate: DateTime(2026, 5, 8),
              sortIndex: 1,
            ),
            _entry(
              id: 3,
              name: 'One Shot',
              price: 5,
              cycle: SubscriptionBillingCycle.oneTime,
              nextPaymentDate: DateTime(2026, 6, 1),
              sortIndex: 3,
            ),
          ],
        );
        final cubit = _cubit(repository);
        addTearDown(cubit.close);

        await cubit.loadEntries();

        expect(cubit.state.status, SubscriptionReadStatus.ready);
        expect(cubit.state.visibleEntries.map((entry) => entry.name), [
          'Rent',
          'Cloud',
          'One Shot',
        ]);
        expect(cubit.state.currentMonthCost, 130);
        expect(cubit.state.yearlyCost, 245);
        expect(cubit.state.dueSoonEntries.map((entry) => entry.id), [1, 2]);
      },
    );

    test('filters and sorts from cached domain entries', () async {
      final repository = _SubscriptionCubitRepository(
        entries: [
          _entry(id: 1, name: 'Low', price: 3, sortIndex: 2),
          _entry(
            id: 2,
            name: 'Annual',
            price: 20,
            cycle: SubscriptionBillingCycle.yearly,
            sortIndex: 1,
          ),
          _entry(id: 3, name: 'High', price: 30, sortIndex: 3),
        ],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      await cubit.loadEntries();

      cubit.setFilter(SubscriptionFilter.monthly);
      expect(cubit.state.visibleEntries.map((entry) => entry.name), [
        'Low',
        'High',
      ]);

      cubit.setSortMode(SubscriptionSortMode.price);
      expect(cubit.state.visibleEntries.map((entry) => entry.name), [
        'High',
        'Low',
      ]);
    });

    test('reloads entries when repository emits changes', () async {
      final repository = _SubscriptionCubitRepository(
        entries: [_entry(id: 1, name: 'Before')],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      cubit.start();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.visibleEntries.single.name, 'Before');

      repository.entries = [_entry(id: 2, name: 'After')];
      repository.emitChange();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.visibleEntries.single.name, 'After');
    });

    test('emits failure state when loading entries fails', () async {
      final repository = _SubscriptionCubitRepository(
        entries: const [],
        loadError: StateError('subscriptions down'),
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.loadEntries();

      expect(cubit.state.status, SubscriptionReadStatus.failure);
      expect(cubit.state.failure?.code, 'subscription/load-entries');
      expect(cubit.state.failure?.message, contains('subscriptions down'));
    });

    test(
      'ignores a stale load completion after a newer delete refresh',
      () async {
        final staleLoad = Completer<List<SubscriptionEntry>>();
        final repository = _SubscriptionCubitRepository(
          entries: [_entry(id: 1, name: 'Deleted')],
          queuedLoads: [staleLoad.future, Future.value(const [])],
        );
        final cubit = _cubit(repository);
        addTearDown(cubit.close);

        final firstLoad = cubit.loadEntries();
        final secondLoad = cubit.loadEntries();
        await secondLoad;

        staleLoad.complete([_entry(id: 1, name: 'Deleted')]);
        await firstLoad;

        expect(cubit.state.entries, isEmpty);
        expect(cubit.state.visibleEntries, isEmpty);
      },
    );

    test('rolls cached totals and reminders into the new month', () async {
      var now = DateTime(2026, 5, 31, 23, 59);
      final monthly = _entry(
        id: 1,
        currency: SubscriptionCurrency.usd,
        nextPaymentDate: DateTime(2026, 5, 1),
      );
      final repository = _SubscriptionCubitRepository(
        entries: [
          monthly,
          _entry(
            id: 2,
            price: 120,
            cycle: SubscriptionBillingCycle.yearly,
            nextPaymentDate: DateTime(2026, 5, 20),
          ),
        ],
      );
      final rates = SubscriptionExchangeRates(
        rateDate: DateTime(2026, 5, 31),
        fetchedAt: now,
        cnyPerUnit: const {'CNY': 1, 'USD': 7},
        fromCache: true,
      );
      final cubit = SubscriptionCubit(
        loadEntries: LoadSubscriptionEntries(repository),
        watchEntries: WatchSubscriptionEntries(repository),
        initialNow: () => now,
        loadExchangeRates: (_) async => rates,
      );
      addTearDown(cubit.close);
      await cubit.loadEntries();
      await pumpEventQueue();
      expect(cubit.state.currentMonthCost, 190);
      cubit.setFilter(SubscriptionFilter.monthly);
      cubit.setSortMode(SubscriptionSortMode.date);

      now = DateTime(2026, 6, 1);
      cubit.refreshReferenceDay();

      expect(cubit.state.referenceDay, DateTime(2026, 6, 1));
      expect(cubit.state.currentMonthCost, 70);
      expect(cubit.state.reminderEntries, [monthly]);
      expect(cubit.state.filter, SubscriptionFilter.monthly);
      expect(cubit.state.sortMode, SubscriptionSortMode.date);
      expect(cubit.state.exchangeRates, same(rates));
      expect(cubit.state.status, SubscriptionReadStatus.ready);
      expect(monthly.nextPaymentDate, DateTime(2026, 5, 1));
      expect(repository.loadCount, 1);
      expect(repository.saveCount, 0);

      final unchanged = cubit.state;
      now = DateTime(2026, 6, 1, 12);
      cubit.refreshReferenceDay();
      expect(cubit.state, same(unchanged));
    });

    test('keeps failure and cached data when the local day changes', () async {
      var now = DateTime(2026, 5, 31);
      final repository = _SubscriptionCubitRepository(
        entries: [_entry(id: 1, nextPaymentDate: DateTime(2026, 5, 1))],
      );
      final cubit = SubscriptionCubit(
        loadEntries: LoadSubscriptionEntries(repository),
        watchEntries: WatchSubscriptionEntries(repository),
        initialNow: () => now,
      );
      addTearDown(cubit.close);
      await cubit.loadEntries();
      repository.loadError = StateError('offline read failed');
      await cubit.loadEntries();
      final previous = cubit.state;

      now = DateTime(2026, 6, 1);
      cubit.refreshReferenceDay();

      expect(cubit.state.referenceDay, DateTime(2026, 6, 1));
      expect(cubit.state.status, SubscriptionReadStatus.failure);
      expect(cubit.state.failure, same(previous.failure));
      expect(cubit.state.entries, previous.entries);
      expect(cubit.state.exchangeRates, same(previous.exchangeRates));
      expect(repository.loadCount, 2);
      expect(repository.saveCount, 0);
    });

    test('keeps a pending rate request while refreshing the date', () async {
      var now = DateTime(2026, 5, 31);
      final rates = Completer<SubscriptionExchangeRates>();
      final repository = _SubscriptionCubitRepository(
        entries: [_entry(id: 1, currency: SubscriptionCurrency.usd)],
      );
      final cubit = SubscriptionCubit(
        loadEntries: LoadSubscriptionEntries(repository),
        watchEntries: WatchSubscriptionEntries(repository),
        initialNow: () => now,
        loadExchangeRates: (_) => rates.future,
      );
      addTearDown(cubit.close);
      await cubit.loadEntries();
      expect(cubit.state.exchangeRatesLoading, isTrue);

      now = DateTime(2026, 6, 1);
      cubit.refreshReferenceDay();
      expect(cubit.state.exchangeRatesLoading, isTrue);
      expect(cubit.state.status, SubscriptionReadStatus.ready);
      rates.complete(
        SubscriptionExchangeRates(
          rateDate: now,
          fetchedAt: now,
          cnyPerUnit: const {'CNY': 1, 'USD': 7},
        ),
      );
      await pumpEventQueue();
      expect(cubit.state.referenceDay, DateTime(2026, 6, 1));
      expect(cubit.state.currentMonthCost, 70);
      expect(cubit.state.exchangeRatesLoading, isFalse);
    });

    test('date sorting follows the next recurring charge', () async {
      final repository = _SubscriptionCubitRepository(
        entries: [
          _entry(id: 1, nextPaymentDate: DateTime(2026, 1, 1)),
          _entry(id: 2, nextPaymentDate: DateTime(2026, 6, 30)),
          _entry(
            id: 3,
            cycle: SubscriptionBillingCycle.oneTime,
            nextPaymentDate: DateTime(2026, 1, 15),
          ),
          _entry(
            id: 4,
            cycle: SubscriptionBillingCycle.yearly,
            nextPaymentDate: DateTime(2026, 5, 10),
          ),
        ],
      );
      final cubit = SubscriptionCubit(
        loadEntries: LoadSubscriptionEntries(repository),
        watchEntries: WatchSubscriptionEntries(repository),
        initialNow: () => DateTime(2026, 6, 29),
      );
      addTearDown(cubit.close);
      await cubit.loadEntries();
      cubit.setSortMode(SubscriptionSortMode.date);

      expect(cubit.state.visibleEntries.map((entry) => entry.id), [2, 1, 4, 3]);
      expect(repository.saveCount, 0);
    });
  });
}

SubscriptionCubit _cubit(_SubscriptionCubitRepository repository) {
  return SubscriptionCubit(
    loadEntries: LoadSubscriptionEntries(repository),
    watchEntries: WatchSubscriptionEntries(repository),
    initialNow: () => DateTime(2026, 5, 1, 9),
  );
}

SubscriptionEntry _entry({
  required int id,
  String name = 'Service',
  double? price = 10,
  SubscriptionCurrency currency = SubscriptionCurrency.cny,
  SubscriptionBillingCycle cycle = SubscriptionBillingCycle.monthly,
  DateTime? nextPaymentDate,
  int? sortIndex,
}) {
  return SubscriptionEntry(
    id: id,
    name: name,
    price: price,
    currency: currency,
    cycle: cycle,
    nextPaymentDate: nextPaymentDate ?? DateTime(2026, 5, 10),
    sortIndex: sortIndex,
  );
}

final class _SubscriptionCubitRepository implements SubscriptionRepositoryPort {
  final _controller = StreamController<void>.broadcast();
  Object? loadError;
  List<SubscriptionEntry> entries;
  final List<Future<List<SubscriptionEntry>>> queuedLoads;
  int loadCount = 0;
  int saveCount = 0;

  _SubscriptionCubitRepository({
    required this.entries,
    this.loadError,
    this.queuedLoads = const [],
  });

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async {
    loadCount++;
    if (queuedLoads.isNotEmpty) {
      return queuedLoads.removeAt(0);
    }
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return entries;
  }

  @override
  Future<SubscriptionEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Future<void> reorderEntries(List<SubscriptionEntry> entries) async {}

  @override
  Future<void> saveEntry(
    SubscriptionEntry entry, {
    required bool markDirty,
  }) async {
    saveCount++;
  }

  @override
  Stream<void> watchEntries() => _controller.stream;

  void emitChange() {
    _controller.add(null);
  }
}
