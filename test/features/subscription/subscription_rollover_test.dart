import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/subscription/data/legacy_subscription_repository_adapter.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry_stats.dart';

void main() {
  group('recurring subscriptions after an old payment date', () {
    test('monthly billing continues in the following month', () {
      final entry = _entry(nextPaymentDate: DateTime(2026, 9, 10));

      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)),
        DateTime(2026, 10, 10),
      );
      expect(entry.costForMonth(DateTime(2026, 10)), 15);
      expect(entry.nextPaymentDate, DateTime(2026, 9, 10));
    });

    test('the payment day remains due for the whole local day', () {
      final entry = _entry(nextPaymentDate: DateTime(2026, 9, 10, 23));

      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 10, 23, 59)),
        DateTime(2026, 10, 10),
      );
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 11)),
        DateTime(2026, 11, 10),
      );
    });

    test('monthly billing skips multiple stale months and years', () {
      final entry = _entry(nextPaymentDate: DateTime(2024, 11, 10));

      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2027, 1, 1)),
        DateTime(2027, 1, 10),
      );
      expect(entry.costForMonth(DateTime(2027, 1)), 15);
    });

    test('an explicitly scheduled future payment is preserved', () {
      final entry = _entry(
        anchorDate: DateTime(2026, 9, 10),
        nextPaymentDate: DateTime(2026, 12, 23),
      );

      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)),
        DateTime(2026, 12, 23),
      );
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 12, 24)),
        DateTime(2027, 1, 10),
      );
    });

    test('a future start prevents premature billing from an old date', () {
      final entry = _entry(
        anchorDate: DateTime(2026, 12, 10),
        nextPaymentDate: DateTime(2026, 9, 10),
      );

      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)),
        DateTime(2026, 12, 10),
      );
      expect(entry.costForMonth(DateTime(2026, 10)), 0);
      expect([entry].dueSoonFrom(DateTime(2026, 10, 1)), isEmpty);
    });

    test('a monthly charge moved earlier does not recur in the same month', () {
      final legacy = _legacy(
        anchorDate: DateTime(2026, 9, 10),
        nextPaymentDate: DateTime(2026, 10, 1),
      );
      final entry = legacy.toSubscriptionEntry();
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 2)),
        DateTime(2026, 11, 10),
      );
      expect(
        legacy.nextOccurrenceAfter(DateTime(2026, 10, 2)),
        DateTime(2026, 11, 10),
      );
      expect([entry].dueForReminderFrom(DateTime(2026, 10, 9)), isEmpty);
      expect(entry.costForMonth(DateTime(2026, 10)), 15);
    });

    test('a yearly charge moved earlier does not recur in the same year', () {
      final legacy = _legacy(
        cycle: SubscriptionCycle.yearly,
        anchorDate: DateTime(2025, 10, 10),
        nextPaymentDate: DateTime(2026, 10, 1),
      );
      final entry = legacy.toSubscriptionEntry();
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 2)),
        DateTime(2027, 10, 10),
      );
      expect(
        legacy.nextOccurrenceAfter(DateTime(2026, 10, 2)),
        DateTime(2027, 10, 10),
      );
      expect([entry].dueForReminderFrom(DateTime(2026, 10, 9)), isEmpty);
      expect(entry.costForMonth(DateTime(2026, 10)), 15);
    });

    test(
      'a yearly payment moved to another month is charged once that year',
      () {
        final legacy = _legacy(
          cycle: SubscriptionCycle.yearly,
          anchorDate: DateTime(2025, 10, 10),
          nextPaymentDate: DateTime(2026, 9, 1),
        );
        final entry = legacy.toSubscriptionEntry();
        expect(entry.costForMonth(DateTime(2026, 9)), 15);
        expect(entry.costForMonth(DateTime(2026, 10)), 0);
        expect(legacy.costForMonth(DateTime(2026, 9)), 15);
        expect(legacy.costForMonth(DateTime(2026, 10)), 0);
        expect(
          entry.nextBillingDateOnOrAfter(DateTime(2026, 9, 2)),
          DateTime(2027, 10, 10),
        );
        expect(entry.costForMonth(DateTime(2027, 10)), 15);
      },
    );

    test('the 31st clamps in February and returns to the 31st in March', () {
      final entry = _entry(
        anchorDate: DateTime(2026, 1, 31),
        nextPaymentDate: DateTime(2026, 2, 28),
      );

      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 2, 1)),
        DateTime(2026, 2, 28),
      );
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 3, 1)),
        DateTime(2026, 3, 31),
      );
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 4, 1)),
        DateTime(2026, 4, 30),
      );
      expect(entry.anchorDate, DateTime(2026, 1, 31));
      expect(entry.nextPaymentDate, DateTime(2026, 2, 28));
    });

    test('yearly billing crosses years without manual advancement', () {
      final entry = _entry(
        cycle: SubscriptionBillingCycle.yearly,
        nextPaymentDate: DateTime(2024, 9, 10),
      );

      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 9, 1)),
        DateTime(2026, 9, 10),
      );
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 9, 11)),
        DateTime(2027, 9, 10),
      );
      expect(entry.costForMonth(DateTime(2026, 9)), 15);
      expect(entry.costForMonth(DateTime(2026, 10)), 0);
    });

    test('a leap-day yearly anchor returns to February 29 in leap years', () {
      final entry = _entry(
        cycle: SubscriptionBillingCycle.yearly,
        anchorDate: DateTime(2024, 2, 29),
        nextPaymentDate: DateTime(2025, 2, 28),
      );

      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 2, 1)),
        DateTime(2026, 2, 28),
      );
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2028, 2, 1)),
        DateTime(2028, 2, 29),
      );
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2028, 3, 1)),
        DateTime(2029, 2, 28),
      );
    });

    test('inactive subscriptions never produce upcoming payments', () {
      for (final status in [
        SubscriptionStatus.paused,
        SubscriptionStatus.canceled,
        SubscriptionStatus.archived,
      ]) {
        final entry = _entry(
          status: status,
          nextPaymentDate: DateTime(2026, 9, 10),
        );

        expect(
          entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)),
          isNull,
          reason: status.name,
        );
        expect([entry].dueSoonFrom(DateTime(2026, 10, 10)), isEmpty);
        expect([entry].dueForReminderFrom(DateTime(2026, 10, 10)), isEmpty);
      }
    });

    test('a payment on the end date is included but a later one is not', () {
      final included = _entry(
        nextPaymentDate: DateTime(2026, 9, 10),
        endDate: DateTime(2026, 10, 10),
      );
      final excluded = _entry(
        nextPaymentDate: DateTime(2026, 9, 10),
        endDate: DateTime(2026, 10, 9),
      );

      expect(
        included.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)),
        DateTime(2026, 10, 10),
      );
      expect(included.costForMonth(DateTime(2026, 10)), 15);
      expect(included.nextBillingDateOnOrAfter(DateTime(2026, 10, 11)), isNull);
      expect(excluded.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)), isNull);
      expect(excluded.costForMonth(DateTime(2026, 10)), 0);
    });

    test('one-time and custom payments do not gain recurring dates', () {
      for (final cycle in [
        SubscriptionBillingCycle.oneTime,
        SubscriptionBillingCycle.custom,
      ]) {
        final entry = _entry(
          cycle: cycle,
          nextPaymentDate: DateTime(2026, 9, 10),
        );

        expect(
          entry.nextBillingDateOnOrAfter(DateTime(2026, 9, 10, 23)),
          DateTime(2026, 9, 10),
        );
        expect(entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)), isNull);
        expect(entry.costForMonth(DateTime(2026, 9)), 15);
        expect(entry.costForMonth(DateTime(2026, 10)), 0);
      }
    });
  });

  group('upcoming payment selection', () {
    test('the seven-day window includes both local-day boundaries', () {
      final onStart = _entry(id: 1, nextPaymentDate: DateTime(2026, 9, 10, 23));
      final onEnd = _entry(id: 2, nextPaymentDate: DateTime(2026, 9, 17, 23));
      final afterEnd = _entry(id: 3, nextPaymentDate: DateTime(2026, 9, 18));

      final due = [
        afterEnd,
        onEnd,
        onStart,
      ].dueSoonFrom(DateTime(2026, 10, 10, 22));

      expect(due.map((entry) => entry.id), [1, 2]);
      expect(due[0], same(onStart));
      expect(due[1], same(onEnd));
    });

    test(
      'sorting uses the projected dates and keeps the original entities',
      () {
        final later = _entry(id: 1, nextPaymentDate: DateTime(2024, 1, 20));
        final sooner = _entry(id: 2, nextPaymentDate: DateTime(2026, 9, 12));

        final due = [
          later,
          sooner,
        ].dueSoonFrom(DateTime(2026, 10, 10), daysAhead: 15);

        expect(due.map((entry) => entry.id), [2, 1]);
        expect(due[0], same(sooner));
        expect(due[1], same(later));
        expect(later.nextPaymentDate, DateTime(2024, 1, 20));
        expect(sooner.nextPaymentDate, DateTime(2026, 9, 12));
      },
    );

    test('each recurring reminder uses its own inclusive window', () {
      final today = _entry(
        id: 1,
        nextPaymentDate: DateTime(2026, 9, 10),
        reminderDays: 0,
      );
      final boundary = _entry(
        id: 2,
        nextPaymentDate: DateTime(2026, 9, 12),
        reminderDays: 2,
      );
      final beyondBoundary = _entry(
        id: 3,
        nextPaymentDate: DateTime(2026, 9, 13),
        reminderDays: 2,
      );
      final tomorrowWithNoAdvanceNotice = _entry(
        id: 4,
        nextPaymentDate: DateTime(2026, 9, 11),
        reminderDays: 0,
      );

      final due = [
        beyondBoundary,
        boundary,
        tomorrowWithNoAdvanceNotice,
        today,
      ].dueForReminderFrom(DateTime(2026, 10, 10));

      expect(due.map((entry) => entry.id), [1, 2]);
      expect(due[0], same(today));
      expect(due[1], same(boundary));
    });

    test('future-looking windows exclude canceled and ended contracts', () {
      final canceled = _entry(
        nextPaymentDate: DateTime(2026, 10, 12),
        status: SubscriptionStatus.canceled,
        reminderDays: 7,
      );
      final ended = _entry(
        nextPaymentDate: DateTime(2026, 9, 12),
        endDate: DateTime(2026, 10, 11),
        reminderDays: 7,
      );
      final entries = [canceled, ended];

      expect(entries.dueSoonFrom(DateTime(2026, 10, 10)), isEmpty);
      expect(entries.dueForReminderFrom(DateTime(2026, 10, 10)), isEmpty);
    });
  });

  group('domain and legacy monthly cost boundaries', () {
    test('a manually postponed monthly payment cannot exceed the end date', () {
      final legacy = _legacy(
        nextPaymentDate: DateTime(2026, 10, 20),
        anchorDate: DateTime(2026, 9, 10),
        endDate: DateTime(2026, 10, 15),
      );
      final entry = legacy.toSubscriptionEntry();

      expect(legacy.costForMonth(DateTime(2026, 10)), 0);
      expect(entry.costForMonth(DateTime(2026, 10)), 0);
      expect(entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)), isNull);
      expect([entry].dueForReminderFrom(DateTime(2026, 10, 20)), isEmpty);
      expect(legacy.nextPaymentDate, DateTime(2026, 10, 20));
      expect(legacy.anchorDate, DateTime(2026, 9, 10));
    });

    test('a manually postponed payment on the end date is still charged', () {
      final legacy = _legacy(
        nextPaymentDate: DateTime(2026, 10, 20),
        anchorDate: DateTime(2026, 9, 10),
        endDate: DateTime(2026, 10, 20),
      );
      final entry = legacy.toSubscriptionEntry();

      expect(legacy.costForMonth(DateTime(2026, 10)), 15);
      expect(entry.costForMonth(DateTime(2026, 10)), 15);
      expect(
        entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 20, 23)),
        DateTime(2026, 10, 20),
      );
      expect([entry].dueForReminderFrom(DateTime(2026, 10, 20)), [entry]);
      expect([entry].dueSoonFrom(DateTime(2026, 10, 20)), [entry]);
      expect(entry.nextBillingDateOnOrAfter(DateTime(2026, 10, 21)), isNull);
      expect(legacy.costForMonth(DateTime(2026, 11)), 0);
    });

    test(
      'a manually changed yearly day shares the exact end-date boundary',
      () {
        for (final endDay in [15, 20]) {
          final legacy = _legacy(
            cycle: SubscriptionCycle.yearly,
            nextPaymentDate: DateTime(2026, 9, 20),
            anchorDate: DateTime(2025, 9, 10),
            endDate: DateTime(2026, 9, endDay),
          );
          final entry = legacy.toSubscriptionEntry();
          final expectedCost = endDay == 20 ? 15 : 0;

          expect(legacy.costForMonth(DateTime(2026, 9)), expectedCost);
          expect(entry.costForMonth(DateTime(2026, 9)), expectedCost);
          expect(
            entry.nextBillingDateOnOrAfter(DateTime(2026, 9, 20)),
            endDay == 20 ? DateTime(2026, 9, 20) : null,
          );
          expect(
            [entry].dueForReminderFrom(DateTime(2026, 9, 20)),
            endDay == 20 ? [entry] : isEmpty,
          );
          expect(legacy.costForMonth(DateTime(2026, 8)), 0);
          expect(legacy.costForMonth(DateTime(2026, 10)), 0);
          expect(legacy.nextPaymentDate, DateTime(2026, 9, 20));
          expect(legacy.anchorDate, DateTime(2025, 9, 10));
        }
      },
    );

    test('monthly billing does not charge after the exact end date', () {
      final legacy = _legacy(
        nextPaymentDate: DateTime(2026, 1, 31),
        endDate: DateTime(2026, 2, 27),
      );

      expect(legacy.costForMonth(DateTime(2026, 1)), 15);
      expect(legacy.costForMonth(DateTime(2026, 2)), 0);
      expect(legacy.toSubscriptionEntry().costForMonth(DateTime(2026, 2)), 0);
    });

    test(
      'clamped month-end billing includes an end date on the payment day',
      () {
        final legacy = _legacy(
          nextPaymentDate: DateTime(2026, 1, 31),
          endDate: DateTime(2026, 2, 28),
        );

        expect(legacy.costForMonth(DateTime(2026, 2)), 15);
        expect(
          legacy.toSubscriptionEntry().costForMonth(DateTime(2026, 2)),
          15,
        );
        expect(legacy.costForMonth(DateTime(2026, 3)), 0);
      },
    );

    test('yearly leap-day cost honors the actual leap-year payment day', () {
      final legacy = _legacy(
        cycle: SubscriptionCycle.yearly,
        nextPaymentDate: DateTime(2024, 2, 29),
        endDate: DateTime(2028, 2, 28),
      );

      expect(legacy.costForMonth(DateTime(2027, 2)), 15);
      expect(legacy.costForMonth(DateTime(2028, 2)), 0);
      expect(legacy.toSubscriptionEntry().costForMonth(DateTime(2028, 2)), 0);
    });

    test('one-time and custom costs obey their payment and end dates', () {
      for (final cycle in [
        SubscriptionCycle.oneTime,
        SubscriptionCycle.custom,
      ]) {
        final legacy = _legacy(
          cycle: cycle,
          nextPaymentDate: DateTime(2026, 10, 20),
          anchorDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 10, 19),
        );

        expect(legacy.costForMonth(DateTime(2026, 10)), 0);
        expect(
          legacy.toSubscriptionEntry().costForMonth(DateTime(2026, 10)),
          0,
        );
        expect(legacy.costForMonth(DateTime(2026, 11)), 0);
      }
    });

    test('cost and display projection never change stored sync metadata', () {
      final legacy =
          _legacy(
              nextPaymentDate: DateTime(2026, 9, 10),
              anchorDate: DateTime(2026, 1, 10),
            )
            ..ownerUserId = 'owner'
            ..remoteId = 99
            ..syncId = 'stable-sync-id'
            ..remoteVersion = 7
            ..remoteUpdatedAt = DateTime(2026, 9, 1)
            ..syncedAt = DateTime(2026, 9, 2)
            ..isDirty = false
            ..pendingDelete = false;
      final original = legacy.toSubscriptionEntry();

      expect(legacy.costForMonth(DateTime(2026, 10)), 15);
      expect(
        original.nextBillingDateOnOrAfter(DateTime(2026, 10, 1)),
        DateTime(2026, 10, 10),
      );
      expect(legacy.toSubscriptionEntry(), original);
      expect(legacy.nextPaymentDate, DateTime(2026, 9, 10));
      expect(legacy.anchorDate, DateTime(2026, 1, 10));
      expect(legacy.ownerUserId, 'owner');
      expect(legacy.remoteId, 99);
      expect(legacy.syncId, 'stable-sync-id');
      expect(legacy.remoteVersion, 7);
      expect(legacy.remoteUpdatedAt, DateTime(2026, 9, 1));
      expect(legacy.syncedAt, DateTime(2026, 9, 2));
      expect(legacy.isDirty, isFalse);
      expect(legacy.pendingDelete, isFalse);
      expect(legacy.deletedAt, isNull);
    });
  });
}

SubscriptionEntry _entry({
  int id = 1,
  SubscriptionBillingCycle cycle = SubscriptionBillingCycle.monthly,
  required DateTime nextPaymentDate,
  DateTime? anchorDate,
  DateTime? endDate,
  SubscriptionStatus status = SubscriptionStatus.active,
  int reminderDays = 1,
}) {
  return SubscriptionEntry(
    id: id,
    name: 'Service $id',
    price: 15,
    cycle: cycle,
    nextPaymentDate: nextPaymentDate,
    anchorDate: anchorDate,
    endDate: endDate,
    status: status,
    reminderDays: reminderDays,
  );
}

Subscription _legacy({
  SubscriptionCycle cycle = SubscriptionCycle.monthly,
  required DateTime nextPaymentDate,
  DateTime? anchorDate,
  DateTime? endDate,
}) {
  return Subscription()
    ..id = 7
    ..name = 'Service'
    ..price = 15
    ..cycle = cycle
    ..nextPaymentDate = nextPaymentDate
    ..anchorDate = anchorDate
    ..endDate = endDate;
}
