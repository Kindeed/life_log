import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Evidence SyncAdapter boundary', () {
    test('Evidence cloud sync is represented as a SyncAdapter', () {
      final adapterFile = File(
        'lib/features/evidence/sync/evidence_sync_adapter.dart',
      );
      final syncService = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(adapterFile.existsSync(), isTrue);

      final adapterSource = adapterFile.readAsStringSync();
      expect(adapterSource, contains('class EvidenceSyncAdapter'));
      expect(
        adapterSource,
        contains('implements SyncAdapter<ExpenseEvidence>'),
      );
      expect(adapterSource, contains("String get entityName => 'evidence'"));
      expect(
        adapterSource,
        contains("String get tableName => 'expense_evidence'"),
      );
      expect(adapterSource, contains('pendingLocalChanges()'));
      expect(adapterSource, contains('pullRemoteRows('));
      expect(adapterSource, contains('pushLocalChange('));
      expect(adapterSource, contains('mergeRemoteRow('));
      expect(adapterSource, contains('purgeLocalDeleted('));
      expect(adapterSource, contains("onConflict: 'user_id,sync_id'"));
      expect(adapterSource, contains('SyncConflictDraft'));
      expect(adapterSource, contains('syncAttachmentsForEvidence'));
      expect(adapterSource, contains('downloadEvidenceFile'));

      expect(syncService, contains('EvidenceSyncAdapter('));
      expect(syncService, contains('SyncEngine('));
      expect(
        syncService,
        isNot(contains('_dbService.syncRemoteEvidenceRowsToLocal')),
      );
      expect(syncService, isNot(contains('getPendingEvidenceForSync()')));
    });
  });
}
