import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/isar_sync_queue.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_engine.dart';
import 'package:life_log/core/sync/sync_queue.dart';

void main() {
  final isarLibraryPath = _isarLibraryPath();
  final isarSkip = isarLibraryPath != null
      ? false
      : 'isar.dll is not available in this test environment. '
            'Set ISAR_DLL_PATH or place it at D:\\Tool\\Isar\\isar.dll.';

  setUpAll(() async {
    if (isarLibraryPath == null) return;
    await Isar.initializeIsarCore(libraries: {Abi.current(): isarLibraryPath});
  });

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

    test('IsarSyncQueue keeps retry backoff after queue rebuild', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'life_log_sync_queue_test_',
      );
      final database = await IsarDatabase.open(
        schemas: DbService.schemas,
        directory: tempDir.path,
        name: 'sync_queue_${DateTime.now().microsecondsSinceEpoch}',
      );
      final clock = _MutableClock(DateTime.utc(2026, 6, 21));

      try {
        final queue = IsarSyncQueue(
          database,
          clock: clock,
          baseDelay: const Duration(minutes: 1),
        );
        await queue.recordFailure('work_log', 'sync-1', error: 'offline');

        final rebuilt = IsarSyncQueue(
          database,
          clock: clock,
          baseDelay: const Duration(minutes: 1),
        );

        expect(await rebuilt.canAttempt('work_log', 'sync-1'), isFalse);
        expect((await rebuilt.peek('work_log', 'sync-1'))?.attemptCount, 1);

        clock.now = DateTime.utc(2026, 6, 21, 0, 1, 1);
        expect(await rebuilt.canAttempt('work_log', 'sync-1'), isTrue);

        await rebuilt.recordSuccess('work_log', 'sync-1');
        expect(await rebuilt.peek('work_log', 'sync-1'), isNull);
      } finally {
        await database.isar.close(deleteFromDisk: true);
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    }, skip: isarSkip);
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

String? _isarLibraryPath() {
  final envPath = Platform.environment['ISAR_DLL_PATH'];
  if (envPath != null && File(envPath).existsSync()) return envPath;
  const fallback = 'D:\\Tool\\Isar\\isar.dll';
  if (File(fallback).existsSync()) return fallback;
  return null;
}
