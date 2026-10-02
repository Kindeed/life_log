import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_queue.dart';
import 'package:life_log/core/sync/sync_run_context.dart';

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

  bool get success => failedPushes == 0 && skippedByBackoff == 0;
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
  final SyncRunContext? context;

  SyncEngine({
    required this.adapters,
    required this.cursorStore,
    this.conflictStore = const NoopSyncConflictStore(),
    this.queue = const NoopSyncQueue(),
    SyncRunControl? runControl,
    this.context,
  }) : runControl = runControl ?? SyncRunControl();

  Future<SyncSummary> syncAll({SyncMode mode = SyncMode.incremental}) async {
    final builders = <String, _AdapterSummaryBuilder>{};

    try {
      for (final adapter in adapters) {
        _checkCurrent();
        final cursor = mode == SyncMode.fullRefresh
            ? null
            : await cursorStore.read(adapter.entityName);
        _checkCurrent();
        final request = SyncPullRequest(mode: mode, cursor: cursor);
        final rows = await adapter.pullRemoteRows(request);
        _checkCurrent();
        SyncCursor? nextCursor;

        for (final row in rows) {
          _checkCurrent();
          context?.checkRemoteRow(row);
          await adapter.mergeRemoteRow(row);
          _checkCurrent();
          nextCursor = _cursorFromRow(row) ?? nextCursor;
        }

        if (nextCursor != null) {
          _checkCurrent();
          await cursorStore.write(adapter.entityName, nextCursor);
          _checkCurrent();
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
        _checkCurrent();

        for (final entity in pending) {
          if (runControl.isCancelled) {
            cancelled = true;
            break;
          }
          await runControl.waitIfPaused();
          _checkCurrent();

          final entityKey = _syncQueueKey(adapter, entity);
          final canAttempt = await queue.canAttempt(
            adapter.entityName,
            entityKey,
          );
          _checkCurrent();
          if (!canAttempt) {
            builder.skippedByBackoff++;
            continue;
          }

          final PushResult result;
          try {
            result = await adapter.pushLocalChange(entity);
          } on SyncRunInvalidated {
            rethrow;
          } catch (error) {
            _checkCurrent();
            await queue.recordFailure(
              adapter.entityName,
              entityKey,
              error: error,
            );
            _checkCurrent();
            // Keep the existing service error handling (including expired auth),
            // while persisting backoff for actual transport failures as well.
            rethrow;
          }
          _checkCurrent();
          if (result.success) {
            await queue.recordSuccess(adapter.entityName, entityKey);
            _checkCurrent();
            builder.pushedChanges++;
            if (result.purgeLocalDeleted) {
              await adapter.purgeLocalDeleted(entity);
              _checkCurrent();
              builder.purgedLocalDeleted++;
            }
          } else {
            await queue.recordFailure(
              adapter.entityName,
              entityKey,
              error: result.conflict?.message,
            );
            _checkCurrent();
            builder.failedPushes++;
            final conflict = result.conflict;
            if (conflict != null) {
              await conflictStore.record(conflict);
              _checkCurrent();
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
    } on SyncRunInvalidated {
      return SyncSummary(
        adapters: {
          for (final entry in builders.entries) entry.key: entry.value.build(),
        },
        cancelled: true,
      );
    }
  }

  void _checkCurrent() {
    context?.checkCurrent();
    if (runControl.isCancelled) throw const SyncRunInvalidated();
  }

  String _syncQueueKey(SyncAdapter<dynamic> adapter, dynamic entity) {
    return adapter.syncQueueKey(entity);
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
