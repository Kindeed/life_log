import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/isar_sync_conflict_store.dart';
import 'package:life_log/core/sync/isar_sync_queue.dart';
import 'package:life_log/features/sync_center/domain/sync_center_repository_port.dart';
import 'package:life_log/features/sync_center/domain/sync_center_snapshot.dart';

final class IsarSyncCenterRepository implements SyncCenterRepositoryPort {
  final IsarSyncQueue queue;
  final IsarSyncConflictStore conflictStore;

  IsarSyncCenterRepository(IsarDatabase database)
    : queue = IsarSyncQueue(database),
      conflictStore = IsarSyncConflictStore(database);

  @override
  Future<SyncCenterSnapshot> loadSnapshot() async {
    final queueRecords = await queue.pendingEntries();
    final conflictRecords = await conflictStore.unresolvedConflicts();
    return SyncCenterSnapshot(
      pendingQueueEntries: queueRecords
          .map(
            (record) => SyncQueueEntry(
              entityName: record.entityName,
              entityKey: record.entityKey,
              attemptCount: record.attemptCount,
              nextAttemptAt: record.nextAttemptAt,
              lastAttemptAt: record.lastAttemptAt,
              lastError: record.lastError,
            ),
          )
          .toList(growable: false),
      unresolvedConflicts: conflictRecords
          .map(
            (record) => SyncConflictEntry(
              id: record.id,
              entityName: record.entityName,
              entitySyncId: record.entitySyncId,
              conflictType: record.conflictType,
              message: record.message,
              detectedAt: record.detectedAt,
              localVersion: record.localVersion,
              remoteVersion: record.remoteVersion,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> resolveConflict(int id, {required String resolution}) {
    return conflictStore.resolve(id, resolution: resolution);
  }
}
