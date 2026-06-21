import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('local data migration policy', () {
    test('login migration is explicit, backed up, and outside SyncService', () {
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final syncService = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();
      final migrationService = File(
        'lib/common/db/local_data_migration_service.dart',
      );
      final dbService = File(
        'lib/common/db/db_service.dart',
      ).readAsStringSync();

      expect(migrationService.existsSync(), isTrue);

      final migrationSource = migrationService.readAsStringSync();
      expect(migrationSource, contains('class LocalDataMigrationService'));
      expect(migrationSource, contains('loadSummary()'));
      expect(migrationSource, contains('migrateToCurrentAccountWithBackup()'));
      expect(migrationSource, contains('BackupService.exportBackup()'));
      expect(migrationSource, contains('claimUnownedRecordsForCurrentUser()'));
      expect(migrationSource, contains('deleteUnownedRecords()'));

      expect(dbService, contains('countUnownedRecords()'));
      expect(dbService, contains('deleteUnownedRecords()'));
      expect(appEntry, contains('LocalDataMigrationService'));
      expect(appEntry, contains('_installLocalDataMigrationPrompt'));
      expect(appEntry, contains('_LocalDataMigrationDecision.migrate'));
      expect(appEntry, contains('_LocalDataMigrationDecision.keepLocal'));
      expect(appEntry, contains('_LocalDataMigrationDecision.exportBackup'));
      expect(appEntry, contains('_LocalDataMigrationDecision.deleteLocal'));
      expect(appEntry, contains('migrateToCurrentAccountWithBackup()'));
      expect(appEntry, contains("reason: 'local-data-migration'"));
      expect(appEntry, contains('forceNew: true'));

      expect(
        syncService,
        isNot(contains('claimUnownedRecordsForCurrentUser()')),
      );
      expect(syncService, isNot(contains('LocalDataMigrationService')));
    });

    test('migration batches are persisted as local Isar records', () {
      final batchFile = File('lib/common/db/local_data_migration_batch.dart');
      final dbService = File(
        'lib/common/db/db_service.dart',
      ).readAsStringSync();
      final migrationSource = File(
        'lib/common/db/local_data_migration_service.dart',
      ).readAsStringSync();

      expect(batchFile.existsSync(), isTrue);

      final batchSource = batchFile.readAsStringSync();
      expect(batchSource, contains('@collection'));
      expect(batchSource, contains('class LocalDataMigrationBatch'));
      expect(batchSource, contains('fromOwner'));
      expect(batchSource, contains('toUserId'));
      expect(batchSource, contains('recordCount'));
      expect(batchSource, contains('startedAt'));
      expect(batchSource, contains('completedAt'));
      expect(batchSource, contains('status'));

      expect(dbService, contains('LocalDataMigrationBatchSchema'));
      expect(dbService, contains('startLocalDataMigrationBatch('));
      expect(dbService, contains('completeLocalDataMigrationBatch('));
      expect(dbService, contains('failLocalDataMigrationBatch('));
      expect(migrationSource, contains('startLocalDataMigrationBatch('));
      expect(migrationSource, contains('completeLocalDataMigrationBatch('));
      expect(migrationSource, contains('failLocalDataMigrationBatch('));
    });
  });
}
