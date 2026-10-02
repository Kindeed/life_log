import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:life_log/common/db/backup_service.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/db/database_restore_coordinator.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/get_storage_sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/features/statistics/presentation/statistics_controller.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../tool/isar_test_runtime.dart' show initializeTestIsar;

void main() {
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDirectory;
  late GetStorage storage;
  setUpAll(() async {
    await initializeTestIsar();
    storageDirectory = await Directory.systemTemp.createTemp('backup_cursors_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathChannel,
          (_) async => storageDirectory.path,
        );
    storage = GetStorage('GetStorage', storageDirectory.path);
    await storage.initStorage;
    await Supabase.initialize(
      url: 'https://restore-test.supabase.co',
      anonKey: 'test-key',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _EmptyAsyncStorage(),
      ),
      accessToken: () async => null,
      debug: false,
    );
  });
  tearDownAll(() async {
    await Supabase.instance.client.dispose();
    await storage.erase();
    await storage.queue.add<void>(() async {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    await storageDirectory.delete(recursive: true);
  });

  late Directory directory;
  late DbService db;
  late File backup;

  setUp(() async {
    await serviceLocator.reset();
    await storage.erase();
    directory = await Directory.systemTemp.createTemp('backup_public_test_');
    final opened = await IsarDatabase.open(
      schemas: DbService.schemas,
      directory: directory.path,
      name: 'backup_${DateTime.now().microsecondsSinceEpoch}',
      inspector: false,
    );
    db = await DbService().initWithDatabaseForTest(opened);
    serviceLocator.registerSingleton<DbService>(db);
    serviceLocator.registerSingleton<LogService>(LogService());
    await db.database.writeTxn(() async {
      await db.isar.workLogs.put(_workLog('backup record'));
    });
    backup = File('${directory.path}/exported.isar');
    await db.isar.copyToFile(backup.path);
    await db.database.writeTxn(() async {
      await db.isar.workLogs.put(_workLog('post-backup record'));
    });
  });

  tearDown(() async {
    if (db.isar.isOpen) await db.isar.close();
    if (serviceLocator.isRegistered<AuthService>()) {
      serviceLocator<AuthService>().dispose();
    }
    await serviceLocator.reset();
    await directory.delete(recursive: true);
  });

  test(
    'public backup restore keeps the injected database handle usable',
    () async {
      final holder = db.database;

      await BackupService.restoreFromBackup(backup);

      expect(identical(db.database, holder), isTrue);
      expect(
        (await holder.isar.workLogs.where().findAll()).single.note,
        'backup record',
      );
      await holder.writeTxn(() async {
        await holder.isar.workLogs.put(_workLog('after successful restore'));
      });
      expect(await holder.isar.workLogs.count(), 2);
    },
  );

  test(
    'statistics failure cannot roll back newly accepted restored edits',
    () async {
      serviceLocator.registerSingleton<StatisticsController>(
        _FailingStatistics(() async {
          await db.database.writeTxn(() async {
            await db.isar.workLogs.put(_workLog('new accepted edit'));
          });
          throw StateError('statistics unavailable');
        }),
      );

      await BackupService.restoreFromBackup(backup);

      final notes = (await db.isar.workLogs.where().findAll())
          .map((record) => record.note)
          .toSet();
      expect(notes, {'backup record', 'new accepted edit'});
      expect(LogService.to.latestError?.message, contains('恢复后刷新统计失败'));
    },
  );

  test('offline restore durably invalidates every account cursor', () async {
    const key = DatabaseRestoreCoordinator.restoreGenerationStorageKey;
    await storage.write(key, 7);
    await storage.write('sync_restored_generation_owner-a', 7);
    await storage.write('sync_restored_generation_owner-b', 7);
    final cursors = GetStorageSyncCursorStore(
      storage: storage,
      namespace: 'owner-a',
    );
    await cursors.write(
      'work_log',
      SyncCursor(updatedAt: DateTime.utc(2026, 10, 2), rowId: 'new-cloud-row'),
    );

    await BackupService.restoreFromBackup(backup);

    expect(storage.read<int>(key), 8);
    expect(
      await DatabaseRestoreCoordinator.readRestoreGeneration(
        directory.path,
        storedGeneration: 0,
      ),
      8,
    );
    for (final owner in ['owner-a', 'owner-b']) {
      expect(
        storage.read<int>('sync_restored_generation_$owner'),
        lessThan(storage.read<int>(key)!),
      );
    }
    expect(
      (await db.isar.workLogs.where().findAll()).single.note,
      'backup record',
    );
  });

  test(
    'connected restore clears current-owner cursors before writes resume',
    () async {
      final auth = AuthService(storage: storage);
      auth.currentUser.value = const User(
        id: 'owner-a',
        appMetadata: {},
        userMetadata: null,
        aud: 'authenticated',
        createdAt: '2026-10-01T00:00:00Z',
      );
      serviceLocator.registerSingleton<AuthService>(auth);
      final sync = SyncService();
      serviceLocator.registerSingleton<SyncService>(sync);
      final aCursors = GetStorageSyncCursorStore(
        storage: storage,
        namespace: 'owner-a',
      );
      final bCursors = GetStorageSyncCursorStore(
        storage: storage,
        namespace: 'owner-b',
      );
      final laterCursor = SyncCursor(
        updatedAt: DateTime.utc(2026, 10, 2),
        rowId: 'later-cloud-row',
      );
      await aCursors.write('work_log', laterCursor);
      await aCursors.write('project', laterCursor);
      await bCursors.write('work_log', laterCursor);
      const key = DatabaseRestoreCoordinator.restoreGenerationStorageKey;
      await storage.write(key, 7);
      await storage.write('sync_restored_generation_owner-a', 7);
      await storage.write('sync_restored_generation_owner-b', 7);
      final stale = sync.captureRunContext()!;

      await BackupService.restoreFromBackup(backup);

      expect(await aCursors.read('work_log'), isNull);
      expect(await aCursors.read('project'), isNull);
      expect(storage.read<int>('sync_restored_generation_owner-a'), isNull);
      expect(storage.read<int>(key), 8);
      expect(
        await DatabaseRestoreCoordinator.readRestoreGeneration(
          directory.path,
          storedGeneration: 0,
        ),
        8,
      );
      expect(storage.read<int>('sync_restored_generation_owner-b'), 7);
      expect(await bCursors.read('work_log'), isNotNull);
      expect(stale.isCurrent, isFalse);
      expect(sync.captureRunContext()?.isCurrent, isTrue);
    },
  );

  test(
    'marker failure aborts restore before replacing the current database',
    () async {
      final marker = File(
        '${directory.path}/${DatabaseRestoreCoordinator.restoreGenerationFileName}',
      );
      await marker.writeAsString('invalid-generation');
      await expectLater(
        BackupService.restoreFromBackup(backup),
        throwsA(isA<DatabaseRestoreFailure>()),
      );
      expect(await db.isar.workLogs.count(), 2);
      await db.database.writeTxn(() async {
        await db.isar.workLogs.put(_workLog('write after marker failure'));
      });
      expect(await db.isar.workLogs.count(), 3);
    },
  );

  test(
    'invalid candidate preserves current database and restore can retry',
    () async {
      final invalid = File('${directory.path}/invalid.isar');
      for (final bytes in [
        [0, 1, 2],
        List<int>.filled(16384, 0),
      ]) {
        await invalid.writeAsBytes(bytes);
        await expectLater(
          BackupService.restoreFromBackup(invalid),
          throwsA(isA<DatabaseRestoreFailure>()),
        );
        expect(await db.isar.workLogs.count(), 2);
      }

      expect(await db.isar.workLogs.count(), 2);
      await db.database.writeTxn(() async {
        await db.isar.workLogs.put(_workLog('write after rejected restore'));
      });
      expect(await db.isar.workLogs.count(), 3);
      await BackupService.restoreFromBackup(backup);
      expect(
        (await db.isar.workLogs.where().findAll()).single.note,
        'backup record',
      );
    },
  );
}

WorkLog _workLog(String note) => WorkLog()
  ..date = DateTime(2026, 10, 1)
  ..type = LogType.work
  ..overtimeHours = 0
  ..note = note;

final class _FailingStatistics extends StatisticsController {
  final Future<void> Function() callback;

  _FailingStatistics(this.callback);

  @override
  Future<void> refreshStats() => callback();
}

final class _EmptyAsyncStorage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
