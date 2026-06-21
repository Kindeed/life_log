import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkLogDao boundary', () {
    test('DbService delegates WorkLog storage primitives to a feature DAO', () {
      final daoFile = File('lib/features/work_log/data/work_log_dao.dart');
      final dbService = File(
        'lib/common/db/db_service.dart',
      ).readAsStringSync();

      expect(daoFile.existsSync(), isTrue);

      final daoSource = daoFile.readAsStringSync();
      expect(daoSource, contains('class WorkLogDao'));
      expect(daoSource, contains('Future<WorkLog?> getById'));
      expect(daoSource, contains('Future<List<WorkLog>> getByMonth'));
      expect(
        daoSource,
        contains('Future<List<WorkLog>> getActiveByMonthForOwner'),
      );
      expect(
        daoSource,
        contains('Future<List<WorkLog>> getActiveSortedForOwner'),
      );
      expect(
        daoSource,
        contains('Future<List<WorkLog>> getActiveByDayForOwner'),
      );
      expect(daoSource, contains('Future<List<WorkLog>> getPendingForSync'));
      expect(
        daoSource,
        contains('Future<List<WorkLog>> getPendingForSyncForOwner'),
      );
      expect(daoSource, contains('Stream<void> watch'));
      expect(daoSource, contains('Future<void> delete'));

      expect(dbService, contains('late WorkLogDao _workLogDao'));
      expect(dbService, contains('_workLogDao = WorkLogDao(database)'));
      expect(dbService, contains('_workLogDao.getActiveByMonthForOwner('));
      expect(dbService, contains('_workLogDao.getActiveSortedForOwner('));
      expect(dbService, contains('_workLogDao.getActiveByDayForOwner('));
      expect(dbService, contains('_workLogDao.getPendingForSyncForOwner('));
      expect(dbService, contains('_workLogDao.watch()'));
      expect(dbService, contains('_workLogDao.delete('));
    });
  });
}
