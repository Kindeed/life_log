import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';
import 'package:life_log/modules/expense/expense_record_model.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:life_log/modules/statistics/statistics_controller.dart';
import 'package:life_log/modules/subscription/subscription_model.dart';
import 'package:life_log/modules/work_log/work_log_model.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(LogService());
  });

  tearDown(Get.reset);

  WorkLog workLog(DateTime date) {
    return WorkLog()
      ..date = date
      ..type = LogType.work
      ..overtimeHours = 1;
  }

  Subscription subscription(double price) {
    return Subscription()
      ..name = 'Service'
      ..price = price
      ..cycle = SubscriptionCycle.monthly
      ..nextPaymentDate = DateTime(2026, 5, 1);
  }

  ExpenseRecord expenseRecord(double amount) {
    return ExpenseRecord()
      ..expenseDate = DateTime(2026, 5, 2)
      ..amount = amount;
  }

  ExpenseEvidence evidenceItem(String project, DateTime date, double amount) {
    return ExpenseEvidence()
      ..projectName = project
      ..evidenceDate = date
      ..amount = amount;
  }

  PhotoItem photoItem(String project, DateTime createdAt) {
    return PhotoItem()
      ..projectName = project
      ..createdAt = createdAt
      ..fileName = '$project.jpg'
      ..filePath = '/tmp/$project.jpg'
      ..dateIndexed = DateTime(createdAt.year, createdAt.month, createdAt.day);
  }

  group('StatisticsController refresh', () {
    test('full refresh queries all sources and updates total cost', () async {
      var logQueries = 0;
      var subQueries = 0;
      var evidenceQueries = 0;
      var expenseQueries = 0;
      final controller = StatisticsController(
        getAllLogs: () async {
          logQueries++;
          return [workLog(DateTime(2026, 5, 1))];
        },
        getAllSubscriptions: () async {
          subQueries++;
          return [subscription(10)];
        },
        getAllEvidence: () async {
          evidenceQueries++;
          return [evidenceItem('Alpha', DateTime(2026, 5, 3), 5)];
        },
        getAllExpenseRecords: () async {
          expenseQueries++;
          return [expenseRecord(7)];
        },
      );
      controller.selectedMonth.value = DateTime(2026, 5);

      await controller.refreshStats();

      expect(logQueries, 1);
      expect(subQueries, 1);
      expect(evidenceQueries, 1);
      expect(expenseQueries, 1);
      expect(controller.selectedMonthTotalCost.value, 17);
    });

    test('full refresh keeps partial results when one source fails', () async {
      final controller = StatisticsController(
        getAllLogs: () async => [workLog(DateTime(2026, 5, 1))],
        getAllSubscriptions: () async => throw StateError('subscriptions down'),
        getAllEvidence: () async => [
          evidenceItem('Alpha', DateTime(2026, 5, 3), 5),
        ],
        getAllExpenseRecords: () async => [expenseRecord(7)],
      );
      controller.selectedMonth.value = DateTime(2026, 5);

      await controller.refreshStats();

      expect(controller.workDays.value, 1);
      expect(controller.evidenceUnreimbursedAmount.value, 5);
      expect(controller.selectedMonthExpenseRecordCost.value, 7);
      expect(controller.selectedMonthTotalCost.value, 7);
    });

    test('targeted refresh queries only changed sources', () async {
      var logQueries = 0;
      var subQueries = 0;
      var evidenceQueries = 0;
      var expenseQueries = 0;
      final controller = StatisticsController(
        getAllLogs: () async {
          logQueries++;
          return [workLog(DateTime(2026, 5, 1))];
        },
        getAllSubscriptions: () async {
          subQueries++;
          return [subscription(12)];
        },
        getAllEvidence: () async {
          evidenceQueries++;
          return [evidenceItem('Alpha', DateTime(2026, 5, 3), 5)];
        },
        getAllExpenseRecords: () async {
          expenseQueries++;
          return [expenseRecord(8)];
        },
      );
      controller.selectedMonth.value = DateTime(2026, 5);

      await controller.refreshChangedSourcesForTest({
        StatisticsRefreshSource.subscriptions,
        StatisticsRefreshSource.expenseRecords,
      });

      expect(logQueries, 0);
      expect(subQueries, 1);
      expect(evidenceQueries, 0);
      expect(expenseQueries, 1);
      expect(controller.selectedMonthTotalCost.value, 20);
    });

    test('shared gate reruns with merged pending sources', () async {
      var logQueries = 0;
      var evidenceQueries = 0;
      final logCompleter = Completer<List<WorkLog>>();
      final evidenceCompleter = Completer<List<ExpenseEvidence>>();
      final controller = StatisticsController(
        getAllLogs: () {
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
        evidenceItem('Alpha', DateTime(2026, 5, 3), 5),
      ]);
      await Future.wait([first, second]);

      expect(logQueries, 1);
      expect(evidenceQueries, 1);
    });

    test('shared gate bounds repeated reruns', () async {
      late final StatisticsController controller;
      var logQueries = 0;
      controller = StatisticsController(
        getAllLogs: () async {
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

  group('EvidenceController cache', () {
    test('search and sort reuse grouped cache and preserve group order', () {
      final controller = EvidenceController();
      controller.evidence.assignAll([
        evidenceItem('Alpha', DateTime(2026, 5, 3), 3),
        evidenceItem('Beta', DateTime(2026, 5, 2), 7),
        evidenceItem('Alpha', DateTime(2026, 5, 1), 1),
      ]);
      controller.rebuildSummaryCachesForTest();

      final grouped = controller.groupedEvidence;
      final alphaItems = grouped['Alpha']!;
      expect(alphaItems.map((item) => item.evidenceDate.day), [3, 1]);

      controller.updateSearch('alp');
      expect(identical(grouped, controller.groupedEvidence), isTrue);
      expect(controller.filteredProjectSummaries.single.projectName, 'Alpha');

      controller.setSortMode(EvidenceSortMode.amount);
      expect(identical(grouped, controller.groupedEvidence), isTrue);
      expect(controller.projectSummaries.first.projectName, 'Beta');
    });
  });

  group('PhotoController cache', () {
    test('search and sort reuse grouped cache and preserve group order', () {
      final controller = PhotoController();
      controller.photos.assignAll([
        photoItem('Alpha', DateTime(2026, 5, 3)),
        photoItem('Beta', DateTime(2026, 5, 2)),
        photoItem('Alpha', DateTime(2026, 5, 1)),
      ]);
      controller.rebuildProjectCachesForTest();

      final grouped = controller.groupedPhotos;
      final alphaPhotos = grouped['Alpha']!;
      expect(alphaPhotos.map((item) => item.createdAt.day), [3, 1]);

      controller.updateProjectSearch('alp');
      expect(identical(grouped, controller.groupedPhotos), isTrue);
      expect(controller.filteredProjectSummaries.single.name, 'Alpha');

      controller.setProjectSortMode(ProjectSortMode.count);
      expect(identical(grouped, controller.groupedPhotos), isTrue);
      expect(controller.projectSummaries.first.name, 'Alpha');
    });
  });
}
