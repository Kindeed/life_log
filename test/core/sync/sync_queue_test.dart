import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_engine.dart';
import 'package:life_log/core/sync/sync_queue.dart';

void main() {
  group('SyncQueue backoff', () {
    test('failed pushes are delayed until their retry time', () async {
      final events = <String>[];
      final queue = InMemorySyncQueue(
        clock: _MutableClock(DateTime.utc(2026, 6, 21)),
        baseDelay: const Duration(minutes: 1),
      );
      final adapter = _QueueAdapter(events);

      var summary = await SyncEngine(
        adapters: [adapter],
        cursorStore: InMemorySyncCursorStore(),
        queue: queue,
      ).syncAll();

      expect(summary.adapters['queue_entity']?.failedPushes, 1);
      expect(queue.peek('queue_entity', 'entity-1')?.attemptCount, 1);

      summary = await SyncEngine(
        adapters: [adapter],
        cursorStore: InMemorySyncCursorStore(),
        queue: queue,
      ).syncAll();

      expect(summary.adapters['queue_entity']?.skippedByBackoff, 1);
      expect(events.where((event) => event == 'push').length, 1);

      queue.clock = _MutableClock(DateTime.utc(2026, 6, 21, 0, 1, 1));
      adapter.pushResult = const PushResult(success: true);
      summary = await SyncEngine(
        adapters: [adapter],
        cursorStore: InMemorySyncCursorStore(),
        queue: queue,
      ).syncAll();

      expect(summary.adapters['queue_entity']?.pushedChanges, 1);
      expect(queue.peek('queue_entity', 'entity-1'), isNull);
    });

    test('cancelled runs stop before pushing pending changes', () async {
      final events = <String>[];
      final adapter = _QueueAdapter(events);

      final summary = await SyncEngine(
        adapters: [adapter],
        cursorStore: InMemorySyncCursorStore(),
        runControl: SyncRunControl.cancelled(),
      ).syncAll();

      expect(summary.cancelled, isTrue);
      expect(events, ['pull']);
    });
  });
}

final class _MutableClock implements SyncClock {
  @override
  DateTime now;

  _MutableClock(this.now);
}

final class _QueueAdapter
    implements SyncAdapter<String>, SyncEntityKeyResolver<String> {
  final List<String> events;
  PushResult pushResult = const PushResult(success: false);

  _QueueAdapter(this.events);

  @override
  String get entityName => 'queue_entity';

  @override
  String get tableName => 'queue_entities';

  @override
  Future<void> mergeRemoteRow(Map<String, dynamic> row) async {}

  @override
  Future<List<String>> pendingLocalChanges() async => ['entity'];

  @override
  Future<void> purgeLocalDeleted(String entity) async {}

  @override
  Future<List<Map<String, dynamic>>> pullRemoteRows(
    SyncPullRequest request,
  ) async {
    events.add('pull');
    return const [];
  }

  @override
  Future<PushResult> pushLocalChange(String entity) async {
    events.add('push');
    return pushResult;
  }

  @override
  String syncQueueKey(String entity) => 'entity-1';
}
