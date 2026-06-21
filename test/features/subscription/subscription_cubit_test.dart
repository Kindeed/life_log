import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
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
  SubscriptionBillingCycle cycle = SubscriptionBillingCycle.monthly,
  DateTime? nextPaymentDate,
  int? sortIndex,
}) {
  return SubscriptionEntry(
    id: id,
    name: name,
    price: price,
    cycle: cycle,
    nextPaymentDate: nextPaymentDate ?? DateTime(2026, 5, 10),
    sortIndex: sortIndex,
  );
}

final class _SubscriptionCubitRepository implements SubscriptionRepositoryPort {
  final _controller = StreamController<void>.broadcast();
  Object? loadError;
  List<SubscriptionEntry> entries;

  _SubscriptionCubitRepository({required this.entries, this.loadError});

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async {
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
  }) async {}

  @override
  Stream<void> watchEntries() => _controller.stream;

  void emitChange() {
    _controller.add(null);
  }
}
