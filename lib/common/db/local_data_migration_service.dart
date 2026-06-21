import 'package:life_log/common/db/backup_service.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/db/local_data_migration_summary.dart';

class LocalDataMigrationService {
  final DbService dbService;

  const LocalDataMigrationService(this.dbService);

  Future<LocalDataMigrationSummary> loadSummary() {
    return dbService.countUnownedRecords();
  }

  Future<void> migrateToCurrentAccountWithBackup() async {
    final summary = await loadSummary();
    if (!summary.hasData) return;

    final currentUserId = dbService.currentOwnerUserId;
    if (currentUserId == null) return;

    final batchId = await dbService.startLocalDataMigrationBatch(
      toUserId: currentUserId,
      recordCount: summary.totalCount,
    );
    try {
      await BackupService.exportBackup();
      await dbService.claimUnownedRecordsForCurrentUser();
      await dbService.completeLocalDataMigrationBatch(batchId);
    } catch (_) {
      await dbService.failLocalDataMigrationBatch(batchId);
      rethrow;
    }
  }

  Future<void> exportBackup() {
    return BackupService.exportBackup();
  }

  Future<void> deleteUnownedRecords() {
    return dbService.deleteUnownedRecords();
  }
}
