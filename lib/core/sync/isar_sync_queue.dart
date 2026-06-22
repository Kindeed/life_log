import 'package:isar/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/sync_queue.dart';
import 'package:life_log/core/sync/sync_queue_record.dart';

final class IsarSyncQueue implements SyncQueue {
  final IsarDatabase database;
  SyncClock clock;
  final Duration baseDelay;
  final Duration maxDelay;

  IsarSyncQueue(
    this.database, {
    this.clock = const SystemSyncClock(),
    this.baseDelay = const Duration(seconds: 30),
    this.maxDelay = const Duration(minutes: 30),
  });

  Future<SyncQueueRecord?> peek(String entityName, String entityKey) async {
    final candidates = await database.isar.syncQueueRecords
        .where()
        .anyId()
        .findAll();
    for (final record in candidates) {
      if (record.entityName == entityName && record.entityKey == entityKey) {
        return record;
      }
    }
    return null;
  }

  Future<List<SyncQueueRecord>> pendingEntries() async {
    final entries = await database.isar.syncQueueRecords
        .where()
        .anyId()
        .findAll();
    entries.sort((a, b) => a.nextAttemptAt.compareTo(b.nextAttemptAt));
    return entries;
  }

  Future<int> pendingCount() async {
    return database.isar.syncQueueRecords.count();
  }

  @override
  Future<bool> canAttempt(String entityName, String entityKey) async {
    final record = await peek(entityName, entityKey);
    if (record == null) return true;
    return !clock.now.isBefore(record.nextAttemptAt);
  }

  @override
  Future<void> recordFailure(
    String entityName,
    String entityKey, {
    Object? error,
  }) async {
    final previous = await peek(entityName, entityKey);
    final attemptCount = (previous?.attemptCount ?? 0) + 1;
    final now = clock.now;
    final record = previous ?? SyncQueueRecord()
      ..entityName = entityName
      ..entityKey = entityKey;
    record
      ..attemptCount = attemptCount
      ..lastAttemptAt = now
      ..nextAttemptAt = now.add(_delayForAttempt(attemptCount))
      ..lastError = error?.toString();

    await database.isar.writeTxn(() {
      return database.isar.syncQueueRecords.put(record);
    });
  }

  @override
  Future<void> recordSuccess(String entityName, String entityKey) async {
    final record = await peek(entityName, entityKey);
    if (record == null) return;
    await database.isar.writeTxn(() {
      return database.isar.syncQueueRecords.delete(record.id);
    });
  }

  Duration _delayForAttempt(int attemptCount) {
    final exponent = (attemptCount - 1).clamp(0, 20).toInt();
    final multiplier = 1 << exponent;
    final delay = baseDelay * multiplier;
    return delay > maxDelay ? maxDelay : delay;
  }
}
