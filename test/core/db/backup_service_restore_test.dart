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
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/project/data/project_note_dao.dart';
import 'package:life_log/features/project/data/project_note_model.dart';
import 'package:life_log/features/project/data/project_note_repository.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../tool/isar_test_runtime.dart' show initializeTestIsar;
import '../../support/test_get_storage.dart';
import '../../fixtures/project_before_local_notes/project_model.dart'
    as old
    show Project, ProjectSchema;

void main() {
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDirectory;
  late GetStorage storage;
  late TestGetStorage storageFixture;
  setUpAll(() async {
    await initializeTestIsar();
    storageDirectory = await Directory.systemTemp.createTemp('backup_cursors_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathChannel,
          (_) async => storageDirectory.path,
        );
    storageFixture = await TestGetStorage.open('GetStorage', storageDirectory);
    storage = storageFixture.storage;
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
    await storageFixture.close();
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
    'local project notes survive export and restore with the same DAO handle',
    () async {
      final project = Project()
        ..name = '设备调试'
        ..createdAt = DateTime(2026, 10, 1)
        ..updatedAt = DateTime(2026, 10, 1);
      await db.database.writeTxn(() async {
        project.id = await db.isar.projects.put(project);
      });
      final repository = ProjectNoteRepository(
        ProjectNoteDao(
          database: db.database,
          currentOwnerUserId: () => db.currentOwnerUserId,
        ),
      );
      final note = await repository.saveEntry(
        ProjectNoteEntry(
          projectId: project.id,
          projectName: project.name,
          projectStageName: '试产',
          content: '备份中的设备状态和生产安排',
          date: DateTime(2026, 10, 10, 8, 30),
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 10),
        ),
      );
      final notesBackup = File('${directory.path}/project-notes.isar');
      await db.isar.copyToFile(notesBackup.path);
      await repository.deleteEntry(note.id);
      final scope = ProjectRecordScope(name: project.name, id: project.id);
      expect(await repository.getEntries(scope), isEmpty);

      final restored = repository.watchEntries().first;
      await BackupService.restoreFromBackup(notesBackup);
      await restored.timeout(const Duration(seconds: 3));
      final entries = await repository.getEntries(scope);
      expect(entries.single, note);
      final change = repository.watchEntries().first;
      await repository.deleteEntry(note.id);
      await change.timeout(const Duration(seconds: 3));
      expect(await repository.getEntries(scope), isEmpty);
    },
  );

  test(
    'backup notes remain isolated by their original local account after restore',
    () async {
      final project = Project()
        ..name = '共享本地项目'
        ..createdAt = DateTime(2026, 10, 1)
        ..updatedAt = DateTime(2026, 10, 1);
      await db.database.writeTxn(() async {
        project.id = await db.isar.projects.put(project);
      });
      String? owner;
      final repository = ProjectNoteRepository(
        ProjectNoteDao(database: db.database, currentOwnerUserId: () => owner),
      );
      ProjectNoteEntry draft(String content) => ProjectNoteEntry(
        projectId: project.id,
        projectName: project.name,
        content: content,
        date: DateTime(2026, 10, 11),
        createdAt: DateTime(2026, 10, 11),
        updatedAt: DateTime(2026, 10, 11),
      );
      owner = 'owner-a';
      final a = await repository.saveEntry(draft('A的本地记录'));
      owner = 'owner-b';
      final b = await repository.saveEntry(draft('B的本地记录'));
      owner = null;
      final local = await repository.saveEntry(draft('未归属本地记录'));
      final notesBackup = File('${directory.path}/account-notes.isar');
      await db.isar.copyToFile(notesBackup.path);
      await repository.deleteEntry(local.id);
      await BackupService.restoreFromBackup(notesBackup);
      final scope = ProjectRecordScope(name: project.name, id: project.id);
      owner = 'owner-a';
      expect(
        (await repository.getEntries(scope)).map((entry) => entry.id).toSet(),
        {a.id, local.id},
      );
      await expectLater(repository.deleteEntry(b.id), throwsStateError);
      owner = 'owner-b';
      expect(
        (await repository.getEntries(scope)).map((entry) => entry.id).toSet(),
        {b.id, local.id},
      );
      owner = null;
      expect((await repository.getEntries(scope)).single.id, local.id);
    },
  );

  test(
    'local archive flags survive backup and restored ids reject an older draft context',
    () async {
      final project = Project()
        ..name = '云删后本地保留'
        ..syncId = 'cloud-deleted-parent'
        ..remoteId = 64
        ..remoteVersion = 4
        ..createdAt = DateTime(2026, 10, 1)
        ..updatedAt = DateTime(2026, 10, 1);
      await db.database.writeTxn(() async {
        project.id = await db.isar.projects.put(project);
      });
      final repository = ProjectNoteRepository(
        ProjectNoteDao(
          database: db.database,
          currentOwnerUserId: () => db.currentOwnerUserId,
          contextToken: () => db.databaseGeneration,
        ),
      );
      final note = await repository.saveEntry(
        ProjectNoteEntry(
          projectId: project.id,
          projectSyncId: project.syncId,
          projectName: project.name,
          content: '保持本地设备记录',
          date: DateTime(2026, 10, 11),
          createdAt: DateTime(2026, 10, 11),
          updatedAt: DateTime(2026, 10, 11),
        ),
      );
      await db.syncRemoteProjectToLocal({
        'id': 64,
        'sync_id': project.syncId,
        'version': 5,
        'deleted_at': '2026-10-11T12:00:00Z',
        'updated_at': '2026-10-11T12:00:00Z',
      });
      final archiveBackup = File('${directory.path}/local-archive.isar');
      await db.isar.copyToFile(archiveBackup.path);
      final olderContext = repository.captureContext();
      await BackupService.restoreFromBackup(archiveBackup);
      final restoredProject = (await db.getProject(project.id))!;
      expect(restoredProject.isLocalArchive, isTrue);
      expect(restoredProject.status, ProjectStatus.archived);
      expect(await db.getAllProjectsForSync(), isEmpty);
      expect(await db.getPendingProjectsForSync(), isEmpty);
      final scope = ProjectRecordScope(
        name: project.name,
        id: project.id,
        syncId: project.syncId,
      );
      expect((await repository.getEntries(scope)).single, note);
      await expectLater(
        repository.saveEntry(note, expectedContext: olderContext),
        throwsStateError,
      );
      await expectLater(
        repository.deleteEntry(note.id, expectedContext: olderContext),
        throwsStateError,
      );
      expect((await repository.getEntries(scope)).single, note);
      await repository.saveEntry(
        note,
        expectedContext: repository.captureContext(),
      );
    },
  );

  test(
    'a pre-notes backup migrates without removing projects or work logs',
    () async {
      final olderName = 'pre_notes_${DateTime.now().microsecondsSinceEpoch}';
      final older = await IsarDatabase.open(
        schemas: DbService.schemas
            .where((schema) => schema.name != ProjectNoteSchema.name)
            .map(
              (schema) => schema.name == 'Project' ? old.ProjectSchema : schema,
            )
            .toList(),
        directory: directory.path,
        name: olderName,
        inspector: false,
      );
      final oldBackup = File('${directory.path}/pre-notes-export.isar');
      try {
        await older.writeTxn(() async {
          await older.isar.workLogs.put(_workLog('旧版备份工时'));
          final project = old.Project()
            ..name = '旧版项目'
            ..syncId = 'old-parent-identity'
            ..remoteId = 88
            ..remoteVersion = 9
            ..stageNames = ['生产', '验收']
            ..createdAt = DateTime(2026, 10, 1)
            ..updatedAt = DateTime(2026, 10, 1);
          project.id = await older.isar.collection<old.Project>().put(project);
          await older.isar.photoItems.put(
            PhotoItem()
              ..projectId = project.id
              ..projectName = project.name
              ..projectStageName = '生产'
              ..description = '升级前设备状态'
              ..fileName = 'local.jpg'
              ..filePath = '/local-only/local.jpg'
              ..dateIndexed = DateTime(2026, 10, 1)
              ..createdAt = DateTime(2026, 10, 1),
          );
          await older.isar.workLogs.put(
            _workLog('旧版项目出差')
              ..type = LogType.businessTrip
              ..projectId = project.id
              ..projectSyncId = project.syncId
              ..projectName = project.name
              ..projectStageName = '验收',
          );
          await older.isar.expenseRecords.put(
            ExpenseRecord()
              ..projectId = project.id
              ..projectSyncId = project.syncId
              ..projectName = project.name
              ..projectStageName = '验收'
              ..expenseDate = DateTime(2026, 10, 1)
              ..amount = 1234.56
              ..currency = 'USD'
              ..note = '旧版原币金额',
          );
        });
        await older.isar.copyToFile(oldBackup.path);
      } finally {
        await older.close();
      }
      await BackupService.restoreFromBackup(oldBackup);
      expect(
        (await db.isar.workLogs.where().findAll()).map((log) => log.note),
        containsAll(['旧版备份工时', '旧版项目出差']),
      );
      final project = (await db.isar.projects.where().findAll()).single;
      expect(project.name, '旧版项目');
      expect(project.stageNames, ['生产', '验收']);
      expect(project.isLocalArchive, isFalse);
      expect(project.syncId, 'old-parent-identity');
      expect(project.remoteId, 88);
      expect(project.remoteVersion, 9);
      final photo = (await db.isar.photoItems.where().findAll()).single;
      expect(photo.projectId, project.id);
      expect(photo.description, '升级前设备状态');
      expect(photo.filePath, '/local-only/local.jpg');
      final trip = (await db.isar.workLogs.where().findAll()).singleWhere(
        (log) => log.type == LogType.businessTrip,
      );
      expect(trip.projectId, project.id);
      expect(trip.projectSyncId, project.syncId);
      expect(trip.projectStageName, '验收');
      final amount = (await db.isar.expenseRecords.where().findAll()).single;
      expect(amount.amount, 1234.56);
      expect(amount.currency, 'USD');
      expect(amount.projectId, project.id);
      expect(amount.projectSyncId, project.syncId);
      expect(await db.isar.projectNotes.count(), 0);
    },
  );

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
