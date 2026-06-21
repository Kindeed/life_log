import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DAO owner/deleted filter policy', () {
    test('feature DAOs expose owner-aware active query helpers', () {
      final daoFiles = {
        'workLog': File('lib/features/work_log/data/work_log_dao.dart'),
        'subscription': File(
          'lib/features/subscription/data/subscription_dao.dart',
        ),
        'project': File('lib/features/project/data/project_dao.dart'),
        'expense': File('lib/features/expense/data/expense_record_dao.dart'),
        'evidence': File('lib/features/evidence/data/evidence_dao.dart'),
      };

      for (final entry in daoFiles.entries) {
        final source = entry.value.readAsStringSync();
        expect(
          source,
          contains('getActiveSortedForOwner'),
          reason: '${entry.key} DAO should filter owner/deleted in Isar.',
        );
        expect(
          source,
          contains('getPendingForSyncForOwner'),
          reason: '${entry.key} DAO should filter owner/dirty in Isar.',
        );
        expect(source, contains('ownerMatches(ownerUserId)'));
        expect(source, contains('deletedAtIsNull()'));
        expect(source, contains('isDirtyEqualTo(true)'));
        expect(source, contains('pendingDeleteEqualTo(true)'));
      }

      final workLogSource = daoFiles['workLog']!.readAsStringSync();
      expect(workLogSource, contains('getActiveByMonthForOwner'));
      expect(workLogSource, contains('getActiveByDayForOwner'));
    });

    test('DbService list reads delegate owner/deleted filtering to DAOs', () {
      final source = File('lib/common/db/db_service.dart').readAsStringSync();

      expect(
        source,
        contains('getActiveByMonthForOwner(month, currentOwnerUserId)'),
      );
      expect(source, contains('getActiveSortedForOwner(currentOwnerUserId)'));
      expect(
        source,
        contains('getActiveByDayForOwner(date, currentOwnerUserId)'),
      );
      expect(source, contains('getPendingForSyncForOwner(currentOwnerUserId)'));
      expect(
        source,
        isNot(contains('final logs = await _workLogDao.getAllSorted();')),
      );
      expect(
        source,
        isNot(contains('final subs = await _subscriptionDao.getAllSorted();')),
      );
      expect(
        source,
        isNot(contains('final logs = await _workLogDao.getPendingForSync();')),
      );
    });
  });
}
