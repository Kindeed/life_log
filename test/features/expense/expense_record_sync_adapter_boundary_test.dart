import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseRecord SyncAdapter boundary', () {
    test('ExpenseRecord cloud sync is represented as a SyncAdapter', () {
      final adapterFile = File(
        'lib/features/expense/sync/expense_record_sync_adapter.dart',
      );
      final syncService = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(adapterFile.existsSync(), isTrue);

      final adapterSource = adapterFile.readAsStringSync();
      expect(adapterSource, contains('class ExpenseRecordSyncAdapter'));
      expect(adapterSource, contains('implements SyncAdapter<ExpenseRecord>'));
      expect(
        adapterSource,
        contains("String get entityName => 'expense_record'"),
      );
      expect(
        adapterSource,
        contains("String get tableName => 'expense_records'"),
      );
      expect(adapterSource, contains('pendingLocalChanges()'));
      expect(adapterSource, contains('pullRemoteRows('));
      expect(adapterSource, contains('pushLocalChange('));
      expect(adapterSource, contains('mergeRemoteRow('));
      expect(adapterSource, contains('purgeLocalDeleted('));
      expect(adapterSource, contains("onConflict: 'user_id,sync_id'"));
      expect(adapterSource, contains('SyncConflictDraft'));

      expect(syncService, contains('ExpenseRecordSyncAdapter('));
      expect(syncService, contains('SyncEngine('));
      expect(
        syncService,
        isNot(contains('_dbService.syncRemoteExpenseRecordsToLocal')),
      );
      expect(syncService, isNot(contains('getPendingExpenseRecordsForSync()')));
    });
  });
}
