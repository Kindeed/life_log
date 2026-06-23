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
      expect(adapterSource, contains("'linked_project_name'"));
      expect(adapterSource, contains("'project_sync_id'"));

      expect(syncService, contains('WorkLogSyncAdapter('));
      expect(syncService, contains('SyncEngine('));
      expect(syncService, contains('_syncWorkLogsWithEngine('));
      expect(syncService, isNot(contains('_dbService.syncRemoteLogsToLocal')));
      expect(syncService, isNot(contains('getPendingLogsForSync()')));
    });

    test('WorkLog project link sync does not reuse trip location field', () {
      final adapterSource = File(
        'lib/features/work_log/sync/work_log_sync_adapter.dart',
      ).readAsStringSync();
      final dbService = File(
        'lib/common/db/db_service.dart',
      ).readAsStringSync();
      final migrations = Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.sql'))
          .map((file) => file.readAsStringSync())
          .join('\n');

      expect(
        adapterSource,
        contains("'project_name': entity.type == LogType.businessTrip"),
      );
      expect(
        adapterSource,
        contains("'linked_project_name': entity.projectName"),
      );
      expect(dbService, contains("data['linked_project_name']"));
      expect(dbService, contains("data['project_sync_id']"));
      expect(migrations, contains('linked_project_name'));
      expect(migrations, contains('idx_work_logs_user_project_sync_id'));
    });
  });
}
