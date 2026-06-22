import 'package:isar/isar.dart';
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

  Future<List<SyncConflictRecord>> unresolvedConflicts() async {
    final records = await database.isar.syncConflictRecords
        .where()
        .anyId()
        .findAll();
    final unresolved = records
        .where((record) => record.resolvedAt == null)
        .toList();
    unresolved.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return unresolved;
  }

  Future<int> unresolvedCount() async {
    return (await unresolvedConflicts()).length;
  }

  Future<void> resolve(int id, {required String resolution}) async {
    final isar = database.isar;
    await isar.writeTxn(() async {
      final record = await isar.syncConflictRecords.get(id);
      if (record == null) return;
      record
        ..resolvedAt = DateTime.now().toUtc()
        ..resolution = resolution;
      await isar.syncConflictRecords.put(record);
    });
  }
}
