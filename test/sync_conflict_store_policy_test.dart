import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sync conflict local store policy', () {
    test('local Isar conflict record captures unresolved sync conflicts', () {
      final file = File('lib/core/sync/sync_conflict_model.dart');

      expect(file.existsSync(), isTrue);

      final source = file.readAsStringSync();
      expect(source, contains('@collection'));
      expect(source, contains('class SyncConflictRecord'));
      expect(source, contains('entityName'));
      expect(source, contains('entitySyncId'));
      expect(source, contains('localId'));
      expect(source, contains('remoteId'));
      expect(source, contains('conflictType'));
      expect(source, contains('localVersion'));
      expect(source, contains('remoteVersion'));
      expect(source, contains('localUpdatedAt'));
      expect(source, contains('remoteUpdatedAt'));
      expect(source, contains('message'));
      expect(source, contains('detectedAt'));
      expect(source, contains('resolvedAt'));
      expect(source, contains('resolution'));
    });

    test('DbService registers sync conflict schema', () {
      final source = File('lib/common/db/db_service.dart').readAsStringSync();

      expect(source, contains('SyncConflictRecordSchema'));
    });

    test('SyncService passes an Isar conflict store to SyncEngine', () {
      final source = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(source, contains('IsarSyncConflictStore'));
      expect(source, contains('conflictStore:'));
    });

    test('WorkLog adapter reports update and delete conflicts', () {
      final source = File(
        'lib/features/work_log/sync/work_log_sync_adapter.dart',
      ).readAsStringSync();

      expect(source, contains('SyncConflictDraft'));
      expect(source, contains('SyncConflictType.updateConflict'));
      expect(source, contains('SyncConflictType.deleteConflict'));
    });
  });
}
