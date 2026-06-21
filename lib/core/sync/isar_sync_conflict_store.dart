import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_conflict_model.dart';

final class IsarSyncConflictStore implements SyncConflictStore {
  final IsarDatabase database;

  const IsarSyncConflictStore(this.database);

  @override
  Future<void> record(SyncConflictDraft conflict) async {
    final isar = database.isar;
    final record = SyncConflictRecord()
      ..entityName = conflict.entityName
      ..entitySyncId = conflict.entitySyncId
      ..localId = conflict.localId
      ..remoteId = conflict.remoteId
      ..conflictType = conflict.conflictType.name
      ..localVersion = conflict.localVersion
      ..remoteVersion = conflict.remoteVersion
      ..localUpdatedAt = conflict.localUpdatedAt
      ..remoteUpdatedAt = conflict.remoteUpdatedAt
      ..message = conflict.message
      ..detectedAt = conflict.detectedAt;
    await isar.writeTxn(() => isar.syncConflictRecords.put(record));
  }
}
