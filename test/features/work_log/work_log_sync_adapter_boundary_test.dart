import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkLog SyncAdapter boundary', () {
    test('WorkLog cloud sync is represented as a SyncAdapter', () {
      final adapterFile = File(
        'lib/features/work_log/sync/work_log_sync_adapter.dart',
      );
      final syncService = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(adapterFile.existsSync(), isTrue);

      final adapterSource = adapterFile.readAsStringSync();
      expect(adapterSource, contains('class WorkLogSyncAdapter'));
      expect(adapterSource, contains('implements SyncAdapter<WorkLog>'));
      expect(adapterSource, contains("String get entityName => 'work_log'"));
      expect(adapterSource, contains("String get tableName => 'work_logs'"));
      expect(adapterSource, contains('pendingLocalChanges()'));
      expect(adapterSource, contains('pullRemoteRows('));
      expect(adapterSource, contains('pushLocalChange('));
      expect(adapterSource, contains('mergeRemoteRow('));
      expect(adapterSource, contains('purgeLocalDeleted('));
      expect(adapterSource, contains("onConflict: 'user_id,sync_id'"));

      expect(syncService, contains('WorkLogSyncAdapter('));
      expect(syncService, contains('SyncEngine('));
      expect(syncService, contains('_syncWorkLogsWithEngine('));
      expect(syncService, isNot(contains('_dbService.syncRemoteLogsToLocal')));
      expect(syncService, isNot(contains('getPendingLogsForSync()')));
    });
  });
}
