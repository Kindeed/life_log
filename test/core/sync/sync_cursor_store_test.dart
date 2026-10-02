import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:life_log/core/sync/get_storage_sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_run_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory directory;
  late GetStorage storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sync_cursor_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (_) async => directory.path);
    storage = GetStorage(
      'cursor_${DateTime.now().microsecondsSinceEpoch}',
      directory.path,
    );
    await storage.initStorage;
  });

  tearDown(() async {
    await storage.erase();
    await storage.queue.add(() async {});
    // The locked GetStorage driver starts its backup write after the queued
    // flush completes. Keep the path-provider mock alive while it settles.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
  });

  test('persistent cursors are independent by owner and entity', () async {
    final ownerA = GetStorageSyncCursorStore(
      storage: storage,
      namespace: 'owner-a',
    );
    final ownerB = GetStorageSyncCursorStore(
      storage: storage,
      namespace: 'owner-b',
    );
    final at = DateTime.utc(2026, 10, 2);
    await ownerA.write('work_log', SyncCursor(updatedAt: at, rowId: '21'));
    await ownerA.write('project', SyncCursor(updatedAt: at, rowId: '34'));
    await ownerB.write('work_log', SyncCursor(updatedAt: at, rowId: '55'));

    final rebuiltA = GetStorageSyncCursorStore(
      storage: storage,
      namespace: 'owner-a',
    );
    expect((await rebuiltA.read('work_log'))!.rowId, '21');
    expect((await rebuiltA.read('work_log'))!.updatedAt, at);
    expect((await rebuiltA.read('project'))!.rowId, '34');
    expect((await ownerB.read('work_log'))!.rowId, '55');
    expect(await ownerB.read('project'), isNull);

    await rebuiltA.clear(['work_log', 'project']);
    expect(await ownerA.read('work_log'), isNull);
    expect(await ownerA.read('project'), isNull);
    expect((await ownerB.read('work_log'))!.rowId, '55');
  });

  test('a stale run cannot advance or read its captured cursor', () async {
    var current = true;
    final store = GetStorageSyncCursorStore(
      storage: storage,
      namespace: 'owner-a',
      context: SyncRunContext(
        ownerId: 'owner-a',
        sessionEpoch: 1,
        databaseGeneration: 0,
        runId: 1,
        isCurrent: () => current,
      ),
    );
    final at = DateTime.utc(2026, 10, 2);
    await store.write('work_log', SyncCursor(updatedAt: at, rowId: '21'));
    current = false;

    await expectLater(
      store.write('work_log', SyncCursor(updatedAt: at, rowId: '99')),
      throwsA(isA<SyncRunInvalidated>()),
    );
    await expectLater(
      store.read('work_log'),
      throwsA(isA<SyncRunInvalidated>()),
    );
    final nextRun = GetStorageSyncCursorStore(
      storage: storage,
      namespace: 'owner-a',
    );
    expect((await nextRun.read('work_log'))!.rowId, '21');
  });
}
