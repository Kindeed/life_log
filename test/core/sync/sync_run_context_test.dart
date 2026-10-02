import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_engine.dart';
import 'package:life_log/core/sync/sync_queue.dart';
import 'package:life_log/core/sync/sync_run_context.dart';

void main() {
  for (final transition in [
    'account switch',
    'logout and login same owner',
    'database restore',
  ]) {
    test(
      '$transition discards an in-flight pull without cursor or merge',
      () async {
        var owner = 'owner-a';
        var epoch = 1;
        var generation = 0;
        final context = SyncRunContext(
          ownerId: 'owner-a',
          sessionEpoch: 1,
          databaseGeneration: 0,
          runId: 1,
          isCurrent: () => owner == 'owner-a' && epoch == 1 && generation == 0,
        );
        final adapter = _DeferredAdapter();
        final cursors = InMemorySyncCursorStore();
        final future = SyncEngine(
          adapters: [adapter],
          cursorStore: cursors,
          context: context,
        ).syncAll();
        await adapter.pullStarted.future;
        if (transition == 'account switch') owner = 'owner-b';
        if (transition == 'logout and login same owner') epoch = 3;
        if (transition == 'database restore') generation = 1;
        adapter.pull.complete([_remoteRow()]);
        final result = await future;
        expect(result.cancelled, isTrue);
        expect(adapter.merged, isEmpty);
        expect(adapter.pushCalls, 0);
        expect(cursors.peek('deferred'), isNull);
      },
    );
  }

  test(
    'stale push completion cannot record retry, conflict, success or purge',
    () async {
      var current = true;
      final adapter = _DeferredAdapter(
        pending: const ['item'],
        deferPush: true,
      );
      adapter.pull.complete([]);
      final queue = InMemorySyncQueue();
      final conflicts = InMemorySyncConflictStore();
      final future = SyncEngine(
        adapters: [adapter],
        cursorStore: InMemorySyncCursorStore(),
        queue: queue,
        conflictStore: conflicts,
        context: SyncRunContext(
          ownerId: 'owner-a',
          sessionEpoch: 1,
          databaseGeneration: 0,
          runId: 1,
          isCurrent: () => current,
        ),
      ).syncAll();
      await adapter.pushStarted.future;
      current = false;
      adapter.push.complete(
        PushResult(
          success: false,
          conflict: SyncConflictDraft(
            entityName: 'deferred',
            conflictType: SyncConflictType.updateConflict,
            message: 'conflict from former account',
          ),
        ),
      );
      expect((await future).cancelled, isTrue);
      expect(queue.peek('deferred', 'item'), isNull);
      expect(conflicts.conflicts, isEmpty);
      expect(adapter.purged, isEmpty);
    },
  );

  test(
    'foreign-owner remote row is rejected before merge and cursor',
    () async {
      final adapter = _DeferredAdapter();
      adapter.pull.complete([_remoteRow(owner: 'owner-b')]);
      final cursors = InMemorySyncCursorStore();
      await expectLater(
        SyncEngine(
          adapters: [adapter],
          cursorStore: cursors,
          context: SyncRunContext(
            ownerId: 'owner-a',
            sessionEpoch: 1,
            databaseGeneration: 0,
            runId: 1,
            isCurrent: () => true,
          ),
        ).syncAll(),
        throwsStateError,
      );
      expect(adapter.merged, isEmpty);
      expect(cursors.peek('deferred'), isNull);
    },
  );
}

Map<String, dynamic> _remoteRow({String owner = 'owner-a'}) => {
  'id': 7,
  'user_id': owner,
  'updated_at': '2026-10-01T00:00:00Z',
};

final class _DeferredAdapter implements SyncAdapter<String> {
  final pullStarted = Completer<void>();
  final pushStarted = Completer<void>();
  final pull = Completer<List<Map<String, dynamic>>>();
  final push = Completer<PushResult>();
  final merged = <Map<String, dynamic>>[];
  final purged = <String>[];
  final List<String> pending;
  final bool deferPush;
  int pushCalls = 0;

  _DeferredAdapter({this.pending = const [], this.deferPush = false});

  @override
  String get entityName => 'deferred';
  @override
  String get tableName => 'deferred_rows';
  @override
  String syncQueueKey(String entity) => entity;
  @override
  Future<List<String>> pendingLocalChanges() async => pending;
  @override
  Future<List<Map<String, dynamic>>> pullRemoteRows(SyncPullRequest request) {
    pullStarted.complete();
    return pull.future;
  }

  @override
  Future<void> mergeRemoteRow(Map<String, dynamic> row) async {
    merged.add(row);
  }

  @override
  Future<PushResult> pushLocalChange(String entity) {
    pushCalls++;
    pushStarted.complete();
    return deferPush
        ? push.future
        : Future.value(const PushResult(success: true));
  }

  @override
  Future<void> purgeLocalDeleted(String entity) async {
    purged.add(entity);
  }
}
