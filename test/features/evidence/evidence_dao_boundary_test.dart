import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EvidenceDao boundary', () {
    test(
      'DbService uses feature DAO reads and owner-fenced Evidence mutations',
      () {
        final daoFile = File('lib/features/evidence/data/evidence_dao.dart');
        final dbService = File(
          'lib/common/db/db_service.dart',
        ).readAsStringSync();

        expect(daoFile.existsSync(), isTrue);

        final daoSource = daoFile.readAsStringSync();
        expect(daoSource, contains('class EvidenceDao'));
        expect(daoSource, contains('Future<ExpenseEvidence?> getById'));
        expect(daoSource, contains('Future<ExpenseEvidence?> getBySyncId'));
        expect(
          daoSource,
          contains('Future<List<ExpenseEvidence>> getAllSorted'),
        );
        expect(
          daoSource,
          contains('Future<List<ExpenseEvidence>> getActiveSortedForOwner'),
        );
        expect(
          daoSource,
          contains('Future<List<ExpenseEvidence>> getPendingForSync'),
        );
        expect(
          daoSource,
          contains('Future<List<ExpenseEvidence>> getPendingForSyncForOwner'),
        );
        expect(daoSource, contains('Stream<void> watch'));
        expect(daoSource, contains('Future<void> delete'));

        expect(dbService, contains('late EvidenceDao _evidenceDao'));
        expect(dbService, contains('_evidenceDao = EvidenceDao(database)'));
        expect(dbService, contains('_evidenceDao.getActiveSortedForOwner('));
        expect(
          dbService,
          contains('_evidenceDao.getPendingForSyncForOwner(owner)'),
        );
        expect(dbService, contains('_preparePendingSyncRows('));
        expect(dbService, contains('_evidenceDao.getById('));
        expect(dbService, contains('syncIdEqualTo(syncId)'));
        expect(dbService, contains('_firstForCurrentOwner'));
        expect(dbService, contains('_evidenceDao.watch()'));
        expect(dbService, contains('Future<void> purgeDeletedEvidence('));
        expect(dbService, contains('_syncWrite(context, (owner) async'));
        expect(dbService, contains('live.ownerUserId != owner'));
        expect(dbService, contains('await isar.expenseEvidences.delete(id)'));
      },
    );
  });
}
