import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/statistics/presentation/statistics_controller.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

void main() {
  setUp(() async {
    await serviceLocator.reset();
    serviceLocator.registerSingleton<LogService>(LogService());
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  WorkLogEntry workLog(DateTime date) {
    return WorkLogEntry(
      id: date.day,
      date: date,
      type: WorkLogEntryType.work,
      overtimeHours: 1,
    );
  }

  SubscriptionEntry subscription(double price) {
    return SubscriptionEntry(
      id: 1,
      name: 'Service',
      price: price,
      cycle: SubscriptionBillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 5, 1),
    );
  }

  ExpenseRecordEntry expenseRecord(double amount) {
    return ExpenseRecordEntry(
      id: 1,
      expenseDate: DateTime(2026, 5, 2),
      amount: amount,
    );
  }

  EvidenceEntry evidenceEntry(String project, DateTime date, double amount) {
    return EvidenceEntry(
      id: date.day,
      projectName: project,
      evidenceDate: date,
      amount: amount,
    );
  }

  group('StatisticsController refresh', () {
    test('uses WorkLog feature domain boundary for work-log statistics', () {
      final source = File(
        'lib/features/statistics/presentation/statistics_controller.dart',
      ).readAsStringSync();

      expect(source, contains('WorkLogEntry'));
      expect(source, contains('WatchWorkLogEntries'));
      expect(source, contains('SubscriptionEntry'));
      expect(source, contains('WatchSubscriptionEntries'));
      expect(source, isNot(contains("work_log_model.dart")));
      expect(source, isNot(contains('WorkLogRepository.to')));
      expect(source, isNot(contains('List<WorkLog>')));
      expect(source, isNot(contains('LogType.')));
      expect(source, isNot(contains("subscription_model.dart")));
      expect(source, isNot(contains('SubscriptionRepository.to')));
      expect(source, isNot(contains('List<Subscription>')));
    });

    test('uses Evidence feature domain boundary for evidence statistics', () {
      final source = File(
        'lib/features/statistics/presentation/statistics_controller.dart',
      ).readAsStringSync();
      final binding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();

      expect(source, contains('EvidenceEntry'));
      expect(source, contains('WatchEvidenceEntries'));
      expect(source, isNot(contains("evidence_model.dart")));
      expect(source, isNot(contains('EvidenceRepository.to')));
      expect(source, isNot(contains('List<ExpenseEvidence>')));
      expect(appEntry, contains('configureEvidenceFeatureDependencies'));
      expect(binding, isNot(contains('configureEvidenceFeatureDependencies')));
    });

    test(
      'uses ExpenseRecord feature domain boundary for record statistics',
      () {
        final source = File(
          'lib/features/statistics/presentation/statistics_controller.dart',
        ).readAsStringSync();
        final binding = File(
          'lib/common/bindings/tabs_binding.dart',
        ).readAsStringSync();
        final appEntry = File(
          'lib/app/lifelog_mobile_entry.dart',
        ).readAsStringSync();

        expect(source, contains('ExpenseRecordEntry'));
        expect(source, contains('WatchExpenseRecordEntries'));
        expect(source, isNot(contains("expense_record_model.dart")));
        expect(source, isNot(contains('ExpenseRecordRepository.to')));
        expect(source, isNot(contains('List<ExpenseRecord>')));
        expect(appEntry, contains('configureExpenseFeatureDependencies'));
        expect(binding, isNot(contains('configureExpenseFeatureDependencies')));
      },
    );

    test('full refresh queries all sources and updates total cost', () async {
      var logQueries = 0;
      var subQueries = 0;
      var evidenceQueries = 0;
      var expenseQueries = 0;
      final controller = StatisticsController(
        getAllWorkLogEntries: () async {
          logQueries++;
          return [workLog(DateTime(2026, 5, 1))];
        },
        getAllSubscriptions: () async {
          subQueries++;
          return [subscription(10)];
        },
        getAllEvidence: () async {
          evidenceQueries++;
          return [evidenceEntry('Alpha', DateTime(2026, 5, 3), 5)];
        },
        getAllExpenseRecords: () async {
          expenseQueries++;
          return [expenseRecord(7)];
        },
      );
      controller.selectedMonth = DateTime(2026, 5);

      await controller.refreshStats();

      expect(logQueries, 1);
      expect(subQueries, 1);
      expect(evidenceQueries, 1);
      expect(expenseQueries, 1);
      expect(controller.selectedMonthTotalCost, 17);
    });

    test('full refresh keeps partial results when one source fails', () async {
      final controller = StatisticsController(
        getAllWorkLogEntries: () async => [workLog(DateTime(2026, 5, 1))],
        getAllSubscriptions: () async => throw StateError('subscriptions down'),
        getAllEvidence: () async => [
          evidenceEntry('Alpha', DateTime(2026, 5, 3), 5),
        ],
        getAllExpenseRecords: () async => [expenseRecord(7)],
      );
      controller.selectedMonth = DateTime(2026, 5);

      await controller.refreshStats();

      expect(controller.workDays, 1);
      expect(controller.evidenceUnreimbursedAmount, 5);
      expect(controller.selectedMonthExpenseRecordCost, 7);
      expect(controller.selectedMonthTotalCost, 7);
    });

    test('targeted refresh queries only changed sources', () async {
      var logQueries = 0;
      var subQueries = 0;
      var evidenceQueries = 0;
      var expenseQueries = 0;
      final controller = StatisticsController(
        getAllWorkLogEntries: () async {
          logQueries++;
          return [workLog(DateTime(2026, 5, 1))];
        },
        getAllSubscriptions: () async {
          subQueries++;
          return [subscription(12)];
        },
        getAllEvidence: () async {
          evidenceQueries++;
          return [evidenceEntry('Alpha', DateTime(2026, 5, 3), 5)];
        },
        getAllExpenseRecords: () async {
          expenseQueries++;
          return [expenseRecord(8)];
        },
      );
      controller.selectedMonth = DateTime(2026, 5);

      await controller.refreshChangedSourcesForTest({
        StatisticsRefreshSource.subscriptions,
        StatisticsRefreshSource.expenseRecords,
      });

      expect(logQueries, 0);
      expect(subQueries, 1);
      expect(evidenceQueries, 0);
      expect(expenseQueries, 1);
      expect(controller.selectedMonthTotalCost, 20);
    });

    test('shared gate reruns with merged pending sources', () async {
      var logQueries = 0;
      var evidenceQueries = 0;
      final logCompleter = Completer<List<WorkLogEntry>>();
      final evidenceCompleter = Completer<List<EvidenceEntry>>();
      final controller = StatisticsController(
        getAllWorkLogEntries: () {
          logQueries++;
          return logCompleter.future;
        },
        getAllSubscriptions: () async => const [],
        getAllEvidence: () {
          evidenceQueries++;
          return evidenceCompleter.future;
        },
        getAllExpenseRecords: () async => const [],
      );

      final first = controller.refreshChangedSourcesForTest({
        StatisticsRefreshSource.workLogs,
      });
      final second = controller.refreshChangedSourcesForTest({
        StatisticsRefreshSource.evidence,
      });

      logCompleter.complete([workLog(DateTime(2026, 5, 1))]);
      await Future<void>.delayed(Duration.zero);
      evidenceCompleter.complete([
        evidenceEntry('Alpha', DateTime(2026, 5, 3), 5),
      ]);
      await Future.wait([first, second]);

      expect(logQueries, 1);
      expect(evidenceQueries, 1);
    });

    test('shared gate bounds repeated reruns', () async {
      late final StatisticsController controller;
      var logQueries = 0;
      controller = StatisticsController(
        getAllWorkLogEntries: () async {
          logQueries++;
          if (logQueries < 20) {
            unawaited(
              controller.refreshChangedSourcesForTest({
                StatisticsRefreshSource.workLogs,
              }),
            );
          }
          return [workLog(DateTime(2026, 5, 1))];
        },
        getAllSubscriptions: () async => const [],
        getAllEvidence: () async => const [],
        getAllExpenseRecords: () async => const [],
      );

      await controller.refreshChangedSourcesForTest({
        StatisticsRefreshSource.workLogs,
      });

      expect(logQueries, 8);
    });
  });

  group('Evidence compatibility controller retirement', () {
    test(
      'production code no longer registers the compatibility controller',
      () {
        final binding = File(
          'lib/common/bindings/tabs_binding.dart',
        ).readAsStringSync();
        final backupService = File(
          'lib/common/db/backup_service.dart',
        ).readAsStringSync();

        expect(
          File(
            'lib/features/evidence/presentation/evidence_controller.dart',
          ).existsSync(),
          isFalse,
        );
        expect(
          File('lib/modules/evidence/evidence_controller.dart').existsSync(),
          isFalse,
        );
        expect(binding, isNot(contains('EvidenceController')));
        expect(backupService, isNot(contains('EvidenceController')));
      },
    );
  });
}
