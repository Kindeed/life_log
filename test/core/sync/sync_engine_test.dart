import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_engine.dart';

void main() {
  group('SyncEngine', () {
    test('pulls every adapter before pushing pending local changes', () async {
      final events = <String>[];
      final cursorStore = InMemorySyncCursorStore()
        ..seed(
          'work_log',
          SyncCursor(updatedAt: DateTime.utc(2026, 6, 20), rowId: '4'),
        );
      final work = _FakeAdapter(
        entityName: 'work_log',
        tableName: 'work_logs',
        events: events,
        remoteRows: [
          {'id': 5, 'updated_at': '2026-06-21T01:00:00.000Z'},
        ],
        pendingChanges: ['local-work'],
      );
      final subscription = _FakeAdapter(
        entityName: 'subscription',
        tableName: 'subscriptions',
        events: events,
        remoteRows: [
          {'id': 3, 'updated_at': '2026-06-21T02:00:00.000Z'},
        ],
        pendingChanges: ['local-sub'],
      );

      final summary = await SyncEngine(
        adapters: [work, subscription],
        cursorStore: cursorStore,
      ).syncAll();

      expect(events, [
        'pull:work_log',
        'merge:work_log:5',
        'pull:subscription',
        'merge:subscription:3',
        'pending:work_log',
        'push:work_log:local-work',
        'pending:subscription',
        'push:subscription:local-sub',
      ]);
      expect(work.pullRequests.single.cursor?.rowId, '4');
      expect(cursorStore.peek('work_log')?.rowId, '5');
      expect(cursorStore.peek('subscription')?.rowId, '3');
      expect(summary.success, isTrue);
      expect(summary.adapters['work_log']?.pulledRows, 1);
      expect(summary.adapters['subscription']?.pushedChanges, 1);
    });

    test('can purge local deleted entities after a successful push', () async {
      final events = <String>[];
      final adapter = _FakeAdapter(
        entityName: 'expense',
        tableName: 'expense_records',
        events: events,
        pendingChanges: ['deleted-expense'],
        pushResult: const PushResult(success: true, purgeLocalDeleted: true),
      );

      final summary = await SyncEngine(
        adapters: [adapter],
        cursorStore: InMemorySyncCursorStore(),
      ).syncAll(mode: SyncMode.fullRefresh);

      expect(adapter.pullRequests.single.cursor, isNull);
      expect(events, [
        'pull:expense',
        'pending:expense',
        'push:expense:deleted-expense',
        'purge:expense:deleted-expense',
      ]);
      expect(summary.adapters['expense']?.purgedLocalDeleted, 1);
    });

    test('records conflicts reported by adapters', () async {
      final conflictStore = InMemorySyncConflictStore();
      final adapter = _FakeAdapter(
        entityName: 'work_log',
        tableName: 'work_logs',
        events: <String>[],
        pendingChanges: ['local-work'],
        pushResult: PushResult(
          success: false,
          conflict: SyncConflictDraft(
            entityName: 'work_log',
            entitySyncId: 'sync-1',
            localId: '7',
            conflictType: SyncConflictType.updateConflict,
            message: 'Remote WorkLog update conflict',
          ),
        ),
      );

      final summary = await SyncEngine(
        adapters: [adapter],
        cursorStore: InMemorySyncCursorStore(),
        conflictStore: conflictStore,
      ).syncAll();

      expect(summary.success, isFalse);
      expect(summary.adapters['work_log']?.failedPushes, 1);
      expect(summary.adapters['work_log']?.conflicts, 1);
      expect(conflictStore.conflicts.single.entityName, 'work_log');
      expect(conflictStore.conflicts.single.entitySyncId, 'sync-1');
    });
  });
}

final class _FakeAdapter implements SyncAdapter<String> {
  @override
  final String entityName;

  @override
  final String tableName;

  final List<String> events;
  final List<Map<String, dynamic>> remoteRows;
  final List<String> pendingChanges;
  final PushResult pushResult;
  final pullRequests = <SyncPullRequest>[];

  _FakeAdapter({
    required this.entityName,
    required this.tableName,
    required this.events,
    this.remoteRows = const [],
    this.pendingChanges = const [],
    this.pushResult = const PushResult(success: true),
  });

  @override
  Future<void> mergeRemoteRow(Map<String, dynamic> row) async {
    events.add('merge:$entityName:${row['id']}');
  }

  @override
  Future<List<String>> pendingLocalChanges() async {
    events.add('pending:$entityName');
    return pendingChanges;
  }

  @override
  Future<void> purgeLocalDeleted(String entity) async {
    events.add('purge:$entityName:$entity');
  }

  @override
  Future<List<Map<String, dynamic>>> pullRemoteRows(
    SyncPullRequest request,
  ) async {
    events.add('pull:$entityName');
    pullRequests.add(request);
    return remoteRows;
  }

  @override
  Future<PushResult> pushLocalChange(String entity) async {
    events.add('push:$entityName:$entity');
    return pushResult;
  }
}
