import 'package:isar_community/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_conflict_model.dart';
import 'package:life_log/core/sync/sync_run_context.dart';

final class IsarSyncConflictStore implements SyncConflictStore {
  final IsarDatabase database;
  final SyncRunContext? context;

  const IsarSyncConflictStore(this.database, {this.context});

  @override
  Future<void> record(SyncConflictDraft conflict) async {
    context?.checkCurrent();
    if (context != null && conflict.ownerUserId != context!.ownerId) {
      throw StateError('Conflict belongs to a different owner');
    }
    final record = SyncConflictRecord()
      ..ownerUserId = conflict.ownerUserId
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
    await database.writeTxn(() {
      context?.checkCurrent();
      return database.isar.syncConflictRecords.put(record);
    });
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
    await database.writeTxn(() async {
      context?.checkCurrent();
      final isar = database.isar;
      final record = await isar.syncConflictRecords.get(id);
      context?.checkCurrent();
      if (record == null) return;
      if (context != null && record.ownerUserId != context!.ownerId) {
        throw StateError('Conflict belongs to a different owner');
      }
      record
        ..resolvedAt = DateTime.now().toUtc()
        ..resolution = resolution;
      await isar.syncConflictRecords.put(record);
    });
  }
}
