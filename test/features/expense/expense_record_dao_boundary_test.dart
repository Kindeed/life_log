import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseRecordDao boundary', () {
    test(
      'DbService uses feature DAO reads and owner-fenced ExpenseRecord mutations',
      () {
        final daoFile = File(
          'lib/features/expense/data/expense_record_dao.dart',
        );
        final dbService = File(
          'lib/common/db/db_service.dart',
        ).readAsStringSync();

        expect(daoFile.existsSync(), isTrue);

        final daoSource = daoFile.readAsStringSync();
        expect(daoSource, contains('class ExpenseRecordDao'));
        expect(daoSource, contains('Future<ExpenseRecord?> getById'));
        expect(daoSource, contains('Future<List<ExpenseRecord>> getAllSorted'));
        expect(
          daoSource,
          contains('Future<List<ExpenseRecord>> getActiveSortedForOwner'),
        );
        expect(
          daoSource,
          contains('Future<List<ExpenseRecord>> getPendingForSync'),
        );
        expect(
          daoSource,
          contains('Future<List<ExpenseRecord>> getPendingForSyncForOwner'),
        );
        expect(daoSource, contains('Stream<void> watch'));
        expect(daoSource, contains('Future<void> delete'));

        expect(dbService, contains('late ExpenseRecordDao _expenseRecordDao'));
        expect(
          dbService,
          contains('_expenseRecordDao = ExpenseRecordDao(database)'),
        );
        expect(
          dbService,
          contains('_expenseRecordDao.getActiveSortedForOwner('),
        );
        expect(
          dbService,
          contains('_expenseRecordDao.getPendingForSyncForOwner(owner)'),
        );
        expect(dbService, contains('_preparePendingSyncRows('));
        expect(dbService, contains('_expenseRecordDao.getById('));
        expect(dbService, contains('_expenseRecordDao.watch()'));
        expect(dbService, contains('Future<void> purgeDeletedExpenseRecord('));
        expect(dbService, contains('_syncWrite(context, (owner) async'));
        expect(dbService, contains('live.ownerUserId != owner'));
        expect(dbService, contains('await isar.expenseRecords.delete(id)'));
      },
    );
  });
}
