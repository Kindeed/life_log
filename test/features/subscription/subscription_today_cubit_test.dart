import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/subscription/application/load_subscription_today.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/presentation/subscription_today_cubit.dart';

void main() {
  group('LoadSubscriptionToday', () {
    test(
      'builds due-soon entries and current-month cost from domain entries',
      () async {
        final repository = _FakeSubscriptionRepository([
          _entry(
            id: 1,
            name: 'Cloud',
            price: 10,
            nextPaymentDate: DateTime(2026, 5, 9),
          ),
          _entry(
            id: 2,
            name: 'Annual',
            price: 120,
            cycle: SubscriptionBillingCycle.yearly,
            nextPaymentDate: DateTime(2026, 5, 10),
          ),
          _entry(
            id: 3,
            name: 'Later',
            price: 8,
            nextPaymentDate: DateTime(2026, 5, 20),
          ),
        ]);

        final result = await LoadSubscriptionToday(
          repository,
        ).call(DateTime(2026, 5, 9, 13));

        final snapshot = result.valueOrNull!;
        expect(result.isSuccess, isTrue);
        expect(snapshot.today, DateTime(2026, 5, 9));
        expect(snapshot.dueSoonEntries.map((entry) => entry.name), [
          'Cloud',
          'Annual',
        ]);
        expect(snapshot.currentMonthCost, 138);
      },
    );

    test('returns failure when the repository throws', () async {
      final result = await LoadSubscriptionToday(
        _FakeSubscriptionRepository.throws(StateError('subscription down')),
      ).call(DateTime(2026, 5, 9));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'subscription/load-today');
      expect(result.failureOrNull?.message, contains('subscription down'));
    });
  });

  group('SubscriptionTodayCubit', () {
    test('loads today snapshot and reloads when entries change', () async {
      final repository = _WatchableSubscriptionRepository([
        _entry(id: 1, name: 'Before', nextPaymentDate: DateTime(2026, 5, 9)),
      ]);
      addTearDown(repository.dispose);
      final cubit = SubscriptionTodayCubit(
        loadToday: LoadSubscriptionToday(repository),
        watchEntries: WatchSubscriptionEntries(repository),
        todayProvider: () => DateTime(2026, 5, 9, 18),
      );
      addTearDown(cubit.close);

      cubit.start();
      await _settleCubitAsyncWork();

      expect(repository.getAllEntriesCallCount, 1);
      expect(cubit.state.status, SubscriptionTodayStatus.ready);
      expect(cubit.state.snapshot.dueSoonEntries.single.name, 'Before');

      repository.replaceEntries([
        _entry(id: 2, name: 'After', nextPaymentDate: DateTime(2026, 5, 10)),
      ]);
      repository.emitChange();
      await _settleCubitAsyncWork();

      expect(repository.getAllEntriesCallCount, 2);
      expect(cubit.state.snapshot.dueSoonEntries.single.name, 'After');
    });
  });

  group('TodayView architecture guard', () {
    test('reads subscription dashboard state from the feature Cubit', () {
      final source = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();
      final di = File(
        'lib/features/subscription/subscription_feature_di.dart',
      ).readAsStringSync();

      expect(source, contains('SubscriptionTodayCubit'));
      expect(source, contains('BlocBuilder<'));
      expect(source, isNot(contains('SubscriptionController')));
      expect(source, isNot(contains('subscription_controller.dart')));
      expect(source, isNot(contains('subscriptions.loadData')));
      expect(source, isNot(contains('subscriptions.currentMonthCost')));
      expect(source, isNot(contains('subscriptions.dueSoonSubs')));
      expect(di, contains('registerLazySingleton<LoadSubscriptionToday>'));
      expect(di, contains('registerFactory<SubscriptionTodayCubit>'));
    });
  });
}

SubscriptionEntry _entry({
  required int id,
  required String name,
  double? price = 10,
  SubscriptionBillingCycle cycle = SubscriptionBillingCycle.monthly,
  required DateTime nextPaymentDate,
}) {
  return SubscriptionEntry(
    id: id,
    name: name,
    price: price,
    cycle: cycle,
    nextPaymentDate: nextPaymentDate,
  );
}

final class _FakeSubscriptionRepository implements SubscriptionRepositoryPort {
  final List<SubscriptionEntry> entries;
  final Object? error;

  _FakeSubscriptionRepository(this.entries) : error = null;

  _FakeSubscriptionRepository.throws(this.error) : entries = const [];

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async {
    final activeError = error;
    if (activeError != null) throw activeError;
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
  Stream<void> watchEntries() => const Stream.empty();
}

final class _WatchableSubscriptionRepository
    implements SubscriptionRepositoryPort {
  final StreamController<void> _changes = StreamController<void>.broadcast();
  List<SubscriptionEntry> _entries;
  int getAllEntriesCallCount = 0;

  _WatchableSubscriptionRepository(this._entries);

  void replaceEntries(List<SubscriptionEntry> entries) {
    _entries = entries;
  }

  void emitChange() {
    _changes.add(null);
  }

  Future<void> dispose() {
    return _changes.close();
  }

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async {
    getAllEntriesCallCount += 1;
    return _entries;
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
  Stream<void> watchEntries() => _changes.stream;
}

Future<void> _settleCubitAsyncWork() async {
  await pumpEventQueue();
  await pumpEventQueue();
}
