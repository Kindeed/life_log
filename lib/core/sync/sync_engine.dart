import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_queue.dart';

class AdapterSyncSummary {
  final int pulledRows;
  final int pushedChanges;
  final int failedPushes;
  final int purgedLocalDeleted;
  final int conflicts;
  final int skippedByBackoff;

  const AdapterSyncSummary({
    required this.pulledRows,
    required this.pushedChanges,
    required this.failedPushes,
    required this.purgedLocalDeleted,
    required this.conflicts,
    required this.skippedByBackoff,
  });

  bool get success => failedPushes == 0;
}

class SyncSummary {
  final Map<String, AdapterSyncSummary> adapters;
  final bool cancelled;

  const SyncSummary({required this.adapters, this.cancelled = false});

  bool get success =>
      !cancelled && adapters.values.every((summary) => summary.success);
}

class SyncEngine {
  final List<SyncAdapter<dynamic>> adapters;
  final SyncCursorStore cursorStore;
  final SyncConflictStore conflictStore;
  final SyncQueue queue;
  final SyncRunControl runControl;

  SyncEngine({
    required this.adapters,
    required this.cursorStore,
    this.conflictStore = const NoopSyncConflictStore(),
    this.queue = const NoopSyncQueue(),
    SyncRunControl? runControl,
  }) : runControl = runControl ?? SyncRunControl();

  Future<SyncSummary> syncAll({SyncMode mode = SyncMode.incremental}) async {
    final builders = <String, _AdapterSummaryBuilder>{};

    for (final adapter in adapters) {
      final cursor = mode == SyncMode.fullRefresh
          ? null
          : await cursorStore.read(adapter.entityName);
      final request = SyncPullRequest(mode: mode, cursor: cursor);
      final rows = await adapter.pullRemoteRows(request);
      SyncCursor? nextCursor;

      for (final row in rows) {
        await adapter.mergeRemoteRow(row);
        nextCursor = _cursorFromRow(row) ?? nextCursor;
      }

      if (nextCursor != null) {
        await cursorStore.write(adapter.entityName, nextCursor);
      }

      builders[adapter.entityName] = _AdapterSummaryBuilder()
        ..pulledRows = rows.length;
    }

    var cancelled = false;

    for (final adapter in adapters) {
      final builder = builders.putIfAbsent(
        adapter.entityName,
        _AdapterSummaryBuilder.new,
      );
      if (runControl.isCancelled) {
        cancelled = true;
        break;
      }
      final pending = await adapter.pendingLocalChanges();

      for (final entity in pending) {
        if (runControl.isCancelled) {
          cancelled = true;
          break;
        }
        await runControl.waitIfPaused();

        final entityKey = _syncQueueKey(adapter, entity);
        if (!await queue.canAttempt(adapter.entityName, entityKey)) {
          builder.skippedByBackoff++;
          continue;
        }

        final result = await adapter.pushLocalChange(entity);
        if (result.success) {
          await queue.recordSuccess(adapter.entityName, entityKey);
          builder.pushedChanges++;
          if (result.purgeLocalDeleted) {
            await adapter.purgeLocalDeleted(entity);
            builder.purgedLocalDeleted++;
          }
        } else {
          await queue.recordFailure(
            adapter.entityName,
            entityKey,
            error: result.conflict?.message,
          );
          builder.failedPushes++;
          final conflict = result.conflict;
          if (conflict != null) {
            await conflictStore.record(conflict);
            builder.conflicts++;
          }
        }
      }
    }

    return SyncSummary(
      adapters: {
        for (final entry in builders.entries) entry.key: entry.value.build(),
      },
      cancelled: cancelled,
    );
  }

  String _syncQueueKey(SyncAdapter<dynamic> adapter, dynamic entity) {
    final maybeResolver = adapter as dynamic;
    if (maybeResolver is SyncEntityKeyResolver<dynamic>) {
      return maybeResolver.syncQueueKey(entity);
    }
    return entity.hashCode.toString();
  }

  SyncCursor? _cursorFromRow(Map<String, dynamic> row) {
    final rawUpdatedAt = row['updated_at'];
    final rawId = row['id'];
    if (rawUpdatedAt == null || rawId == null) return null;

    final updatedAt = rawUpdatedAt is DateTime
        ? rawUpdatedAt.toUtc()
        : DateTime.tryParse(rawUpdatedAt.toString())?.toUtc();
    if (updatedAt == null) return null;

    return SyncCursor(updatedAt: updatedAt, rowId: rawId.toString());
  }
}

final class _AdapterSummaryBuilder {
  int pulledRows = 0;
  int pushedChanges = 0;
  int failedPushes = 0;
  int purgedLocalDeleted = 0;
  int conflicts = 0;
  int skippedByBackoff = 0;

  AdapterSyncSummary build() {
    return AdapterSyncSummary(
      pulledRows: pulledRows,
      pushedChanges: pushedChanges,
      failedPushes: failedPushes,
      purgedLocalDeleted: purgedLocalDeleted,
      conflicts: conflicts,
      skippedByBackoff: skippedByBackoff,
    );
  }
}
