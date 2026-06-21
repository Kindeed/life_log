import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project SyncAdapter boundary', () {
    test('Project cloud sync is represented as a SyncAdapter', () {
      final adapterFile = File(
        'lib/features/project/sync/project_sync_adapter.dart',
      );
      final syncService = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(adapterFile.existsSync(), isTrue);

      final adapterSource = adapterFile.readAsStringSync();
      expect(adapterSource, contains('class ProjectSyncAdapter'));
      expect(adapterSource, contains('implements SyncAdapter<Project>'));
      expect(adapterSource, contains("String get entityName => 'project'"));
      expect(adapterSource, contains("String get tableName => 'projects'"));
      expect(adapterSource, contains('pendingLocalChanges()'));
      expect(adapterSource, contains('pullRemoteRows('));
      expect(adapterSource, contains('pushLocalChange('));
      expect(adapterSource, contains('mergeRemoteRow('));
      expect(adapterSource, contains('purgeLocalDeleted('));
      expect(adapterSource, contains("onConflict: 'user_id,sync_id'"));
      expect(adapterSource, contains('SyncConflictDraft'));

      expect(syncService, contains('ProjectSyncAdapter('));
      expect(syncService, contains('SyncEngine('));
      expect(
        syncService,
        isNot(contains('_dbService.syncRemoteProjectsToLocal')),
      );
      expect(syncService, isNot(contains('getPendingProjectsForSync()')));
    });
  });
}
