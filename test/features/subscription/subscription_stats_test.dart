import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry_stats.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/subscription_feature_di.dart';
import 'package:life_log/features/subscription/data/legacy_subscription_repository_adapter.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';

void main() {
  SubscriptionEntry entry({
    int id = 1,
    String name = 'Service',
    double? price = 10,
    SubscriptionBillingCycle cycle = SubscriptionBillingCycle.monthly,
    DateTime? nextPaymentDate,
    DateTime? anchorDate,
    DateTime? endDate,
    SubscriptionStatus status = SubscriptionStatus.active,
    int? sortIndex,
  }) {
    return SubscriptionEntry(
      id: id,
      name: name,
      price: price,
      cycle: cycle,
      nextPaymentDate: nextPaymentDate ?? DateTime(2026, 5, 10),
      anchorDate: anchorDate,
      endDate: endDate,
      status: status,
      sortIndex: sortIndex,
    );
  }

  group('SubscriptionEntryStats', () {
    test(
      'calculates month and yearly cost without depending on Isar model',
      () {
        final entries = [
          entry(price: 10),
          entry(
            price: 120,
            cycle: SubscriptionBillingCycle.yearly,
            nextPaymentDate: DateTime(2026, 5, 20),
          ),
          entry(
            price: 8,
            cycle: SubscriptionBillingCycle.oneTime,
            nextPaymentDate: DateTime(2026, 6, 1),
          ),
          entry(price: null),
        ];

        expect(entries.totalCostForMonth(DateTime(2026, 5)), 130);
        expect(entries.totalCostForMonth(DateTime(2026, 6)), 18);
        expect(entries.totalYearlyCost, 248);
      },
    );

    test('respects anchor date, end date, and inactive statuses', () {
      final startsInJune = entry(
        price: 10,
        anchorDate: DateTime(2026, 6, 10),
        nextPaymentDate: DateTime(2026, 6, 10),
      );
      final endsInMay = entry(
        price: 10,
        anchorDate: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 5, 31),
      );
      final paused = entry(price: 10, status: SubscriptionStatus.paused);
      final canceled = entry(price: 10, status: SubscriptionStatus.canceled);

      expect(startsInJune.costForMonth(DateTime(2026, 5)), 0);
      expect(startsInJune.costForMonth(DateTime(2026, 6)), 10);
      expect(endsInMay.costForMonth(DateTime(2026, 5)), 10);
      expect(endsInMay.costForMonth(DateTime(2026, 6)), 0);
      expect(paused.costForMonth(DateTime(2026, 5)), 0);
      expect(canceled.yearlyCost, 0);
    });

    test('advances monthly anchors safely across short months', () {
      final monthly31 = entry(
        cycle: SubscriptionBillingCycle.monthly,
        anchorDate: DateTime(2026, 1, 31),
        nextPaymentDate: DateTime(2026, 1, 31),
      );

      expect(
        monthly31.nextOccurrenceAfter(DateTime(2026, 2, 1)),
        DateTime(2026, 2, 28),
      );
    });

    test('finds subscriptions due soon using local-day bounds', () {
      final entries = [
        entry(id: 1, nextPaymentDate: DateTime(2026, 5, 1, 23)),
        entry(id: 2, nextPaymentDate: DateTime(2026, 5, 8)),
        entry(id: 3, nextPaymentDate: DateTime(2026, 5, 9)),
        entry(id: 4, nextPaymentDate: DateTime(2026, 4, 30, 23)),
      ];

      final dueSoon = entries.dueSoonFrom(DateTime(2026, 5, 1, 9));

      expect(dueSoon.map((item) => item.id), [1, 2]);
    });
  });

  group('legacy subscription adapter', () {
    test('maps only business fields into the feature domain entity', () {
      final legacy = Subscription()
        ..id = 7
        ..name = 'Cloud'
        ..price = 15
        ..cycle = SubscriptionCycle.yearly
        ..nextPaymentDate = DateTime(2026, 5, 12)
        ..reminderDays = 3
        ..note = 'renew'
        ..sortIndex = 2
        ..syncId = 'remote-sync'
        ..remoteId = 99
        ..isDirty = true;

      final entry = legacy.toSubscriptionEntry();

      expect(entry.id, 7);
      expect(entry.name, 'Cloud');
      expect(entry.price, 15);
      expect(entry.cycle, SubscriptionBillingCycle.yearly);
      expect(entry.nextPaymentDate, DateTime(2026, 5, 12));
      expect(entry.reminderDays, 3);
      expect(entry.note, 'renew');
      expect(entry.sortIndex, 2);

      final domainSource = File(
        'lib/features/subscription/domain/entities/subscription_entry.dart',
      ).readAsStringSync();
      expect(domainSource, isNot(contains('syncId')));
      expect(domainSource, isNot(contains('remoteId')));
      expect(domainSource, isNot(contains('isDirty')));
      expect(domainSource, isNot(contains('pendingDelete')));
      expect(domainSource, isNot(contains('deletedAt')));
    });
  });

  group('configureSubscriptionFeatureDependencies', () {
    test('registers repository port and watcher without GetX callers', () {
      final locator = GetIt.asNewInstance();
      final repository = _FakeSubscriptionRepository();

      configureSubscriptionFeatureDependencies(
        locator: locator,
        repository: repository,
      );

      expect(locator.isRegistered<SubscriptionRepositoryPort>(), isTrue);
      expect(locator.isRegistered<WatchSubscriptionEntries>(), isTrue);

      final watcher = locator<WatchSubscriptionEntries>();
      expect(watcher(), isA<Stream<void>>());
    });
  });
}

final class _FakeSubscriptionRepository implements SubscriptionRepositoryPort {
  final _controller = StreamController<void>.broadcast();

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async {
    return const [];
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
  Stream<void> watchEntries() {
    return _controller.stream;
  }
}
