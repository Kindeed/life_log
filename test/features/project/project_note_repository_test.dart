import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/features/project/data/legacy_project_repository_adapter.dart';
import 'package:life_log/features/project/sync/project_sync_adapter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/project/data/project_note_dao.dart';
import 'package:life_log/features/project/data/project_note_model.dart';
import 'package:life_log/features/project/data/project_note_repository.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

import '../../../tool/isar_test_runtime.dart' show initializeTestIsar;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestIsar);
  late Directory directory;
  late IsarDatabase database;
  late ProjectNoteRepository repository;
  late String? owner;
  late Project project;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('lifelog_project_notes_');
    database = await IsarDatabase.open(
      schemas: DbService.schemas,
      directory: directory.path,
      name: 'notes_${DateTime.now().microsecondsSinceEpoch}',
      inspector: false,
    );
    owner = null;
    repository = ProjectNoteRepository(
      ProjectNoteDao(database: database, currentOwnerUserId: () => owner),
    );
    project = _project('设备项目', syncId: 'parent-sync-id');
    await database.writeTxn(() async {
      project.id = await database.isar.projects.put(project);
    });
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'persists a dated phase note and edits preserve creation time',
    () async {
      final saved = await repository.saveEntry(
        _entry(project, '  设备压力稳定，待客户确认  ', stage: '  调试  '),
      );
      expect(saved.id, greaterThan(0));
      expect(saved.content, '设备压力稳定，待客户确认');
      expect(saved.projectStageName, '调试');
      expect(saved.projectId, project.id);
      expect(saved.projectSyncId, project.syncId);
      expect(saved.date, DateTime(2026, 10, 11, 9, 30));

      final edited = await repository.saveEntry(
        _entry(
          project,
          '客户已确认，准备试产',
          id: saved.id,
          stage: '试产',
          createdAt: DateTime(2000),
        ),
      );
      expect(edited.createdAt, saved.createdAt);
      expect(edited.updatedAt.isBefore(saved.updatedAt), isFalse);
      expect(edited.content, '客户已确认，准备试产');
      expect((await repository.getEntries(_scope(project))).single, edited);
      await repository.deleteEntry(edited.id);
      expect(await repository.getEntries(_scope(project)), isEmpty);
    },
  );

  test(
    'sorts by event date then insertion time instead of edited time',
    () async {
      final newerEvent = await repository.saveEntry(
        _entry(project, '新事件', date: DateTime(2026, 10, 12)),
      );
      final olderEvent = await repository.saveEntry(
        _entry(project, '旧事件', date: DateTime(2026, 10, 1)),
      );
      await repository.saveEntry(
        _entry(project, '旧事件补充内容', id: olderEvent.id, date: olderEvent.date),
      );
      final entries = await repository.getEntries(_scope(project));
      expect(entries.map((entry) => entry.id), [newerEvent.id, olderEvent.id]);
    },
  );

  test('namesake projects never share or move notes', () async {
    final other = _project(project.name, syncId: 'different-parent');
    await database.writeTxn(() async {
      other.id = await database.isar.projects.put(other);
    });
    final saved = await repository.saveEntry(_entry(project, '设备一记录'));
    await repository.saveEntry(_entry(other, '设备二记录'));
    expect(
      (await repository.getEntries(
        _scope(project),
      )).map((entry) => entry.content),
      ['设备一记录'],
    );
    expect(
      (await repository.getEntries(
        _scope(other),
      )).map((entry) => entry.content),
      ['设备二记录'],
    );
    await expectLater(
      repository.saveEntry(_entry(other, '不能迁走', id: saved.id)),
      throwsStateError,
    );
    expect(
      await repository.getEntries(ProjectRecordScope(name: project.name)),
      isEmpty,
    );
    await expectLater(
      repository.saveEntry(
        ProjectNoteEntry(
          projectName: project.name,
          content: '只有名字不能创建关联',
          date: DateTime(2026, 10, 11),
          createdAt: DateTime(2026, 10, 11),
          updatedAt: DateTime(2026, 10, 11),
        ),
      ),
      throwsStateError,
    );
  });

  test('stale ids and mismatched parent identities are rejected', () async {
    await expectLater(
      repository.saveEntry(_entry(project, '记录', id: 100000)),
      throwsStateError,
    );
    final mismatched = _project(project.name, syncId: 'wrong-sync-id')
      ..id = project.id;
    await expectLater(
      repository.saveEntry(_entry(mismatched, '记录')),
      throwsStateError,
    );
    expect(await repository.getEntries(_scope(mismatched)), isEmpty);
    final absent = _project(project.name)..id = 999999;
    await expectLater(
      repository.saveEntry(_entry(absent, '记录')),
      throwsStateError,
    );
    await expectLater(
      repository.saveEntry(_entry(project, ' \n\t ')),
      throwsArgumentError,
    );
    expect(await database.isar.projectNotes.count(), 0);
  });

  test('project rename preserves membership and updates saved label', () async {
    final saved = await repository.saveEntry(_entry(project, '原记录'));
    final staleScope = _scope(project);
    await database.writeTxn(() async {
      project.name = '新项目名称';
      await database.isar.projects.put(project);
    });
    expect((await repository.getEntries(staleScope)).single.id, saved.id);
    final updated = await repository.saveEntry(
      _entry(project, '更新记录', id: saved.id),
    );
    expect(updated.projectName, '新项目名称');
  });

  test(
    'current owner sees own and unowned notes and cannot read or edit B',
    () async {
      owner = 'owner-a';
      final a = await repository.saveEntry(_entry(project, 'A记录'));
      owner = 'owner-b';
      final b = await repository.saveEntry(_entry(project, 'B记录'));
      owner = null;
      final local = await repository.saveEntry(_entry(project, '本地记录'));
      expect(
        (await repository.getEntries(_scope(project))).map((entry) => entry.id),
        [local.id],
      );
      owner = 'owner-a';
      expect(
        (await repository.getEntries(
          _scope(project),
        )).map((entry) => entry.id).toSet(),
        {a.id, local.id},
      );
      await expectLater(
        repository.saveEntry(_entry(project, '企图改B', id: b.id)),
        throwsStateError,
      );
      await expectLater(repository.deleteEntry(b.id), throwsStateError);
      expect((await database.isar.projectNotes.get(b.id))!.content, 'B记录');
    },
  );

  test(
    'a project owned by another account blocks all note operations',
    () async {
      owner = 'owner-a';
      await database.writeTxn(() async {
        project.ownerUserId = owner;
        await database.isar.projects.put(project);
      });
      final note = await repository.saveEntry(_entry(project, 'A私有记录'));
      owner = 'owner-b';
      expect(await repository.getEntries(_scope(project)), isEmpty);
      await expectLater(
        repository.saveEntry(_entry(project, '不能写')),
        throwsStateError,
      );
      await expectLater(repository.deleteEntry(note.id), throwsStateError);
      owner = null;
      expect(await repository.getEntries(_scope(project)), isEmpty);
    },
  );

  test(
    'owner switch while a write is queued rejects without persisting',
    () async {
      owner = 'owner-a';
      final queued = repository.saveEntry(_entry(project, '不能跨账号写入'));
      owner = 'owner-b';
      await expectLater(queued, throwsStateError);
      expect(await database.isar.projectNotes.count(), 0);
    },
  );

  test(
    'read results are rejected when the account changes during the query',
    () async {
      owner = 'owner-a';
      await repository.saveEntry(_entry(project, 'A私有记录'));
      final read = repository.getEntries(_scope(project));
      owner = 'owner-b';
      await expectLater(read, throwsStateError);
    },
  );

  test(
    'deleting a project removes its notes atomically and preserves namesakes',
    () async {
      final other = _project(project.name, syncId: 'other-id');
      await database.writeTxn(() async {
        other.id = await database.isar.projects.put(other);
      });
      final removed = await repository.saveEntry(_entry(project, '应删除'));
      final preserved = await repository.saveEntry(_entry(other, '应保留'));
      final db = await DbService().initWithDatabaseForTest(database);
      final watcher = database.isar.projectNotes.watchLazy().first;
      await db.deleteProjectCascade(
        projectId: project.id,
        projectName: project.name,
      );
      await watcher.timeout(const Duration(seconds: 3));
      expect(await database.isar.projectNotes.get(removed.id), isNull);
      expect(await database.isar.projectNotes.get(preserved.id), isNotNull);
      expect(
        (await database.isar.projects.get(project.id))!.deletedAt,
        isNotNull,
      );
      expect(await repository.getEntries(_scope(project)), isEmpty);
      expect(
        (await repository.getEntries(_scope(other))).single.id,
        preserved.id,
      );
    },
  );

  test(
    'cascade with a foreign-owner note refuses before altering any children',
    () async {
      final local = await repository.saveEntry(_entry(project, '未归属记录'));
      owner = 'owner-b';
      final foreign = await repository.saveEntry(_entry(project, 'B记录'));
      owner = null;
      final photo = PhotoItem()
        ..projectId = project.id
        ..projectName = project.name
        ..projectStageName = '调试'
        ..fileName = 'local.jpg'
        ..filePath = '/local-only/local.jpg'
        ..dateIndexed = DateTime(2026, 10, 10)
        ..createdAt = DateTime(2026, 10, 10);
      final trip = WorkLog()
        ..projectId = project.id
        ..projectName = project.name
        ..projectStageName = '调试'
        ..type = LogType.businessTrip
        ..date = DateTime(2026, 10, 10)
        ..overtimeHours = 0;
      await database.writeTxn(() async {
        photo.id = await database.isar.photoItems.put(photo);
        trip.id = await database.isar.workLogs.put(trip);
      });
      final db = await DbService().initWithDatabaseForTest(database);
      await expectLater(
        db.deleteProjectCascade(
          projectId: project.id,
          projectName: project.name,
        ),
        throwsStateError,
      );
      expect((await database.isar.projects.get(project.id))!.deletedAt, isNull);
      expect(
        (await database.isar.projectNotes.get(local.id))!.content,
        '未归属记录',
      );
      expect(
        (await database.isar.projectNotes.get(foreign.id))!.ownerUserId,
        'owner-b',
      );
      expect(
        (await database.isar.photoItems.get(photo.id))!.projectId,
        project.id,
      );
      expect(
        (await database.isar.workLogs.get(trip.id))!.projectId,
        project.id,
      );
    },
  );

  test(
    'unowned migration counts and claims local notes without cloud state',
    () async {
      final note = await repository.saveEntry(_entry(project, '本地未归属记录'));
      final db = await DbService().initWithDatabaseForTest(database);
      final before = await db.countUnownedRecords();
      expect(before.projectNotes, 1);
      expect(before.projects, 1);
      expect(before.totalCount, 2);
      await db.claimUnownedRecordsForOwnerForTest('claimed-owner');
      final claimed = (await database.isar.projectNotes.get(note.id))!;
      expect(claimed.ownerUserId, 'claimed-owner');
      expect((await db.countUnownedRecords()).projectNotes, 0);
      for (final cloudField in [
        'syncId',
        'remoteId',
        'isDirty',
        'pendingDelete',
        'deletedAt',
      ]) {
        expect(ProjectNoteSchema.properties.keys, isNot(contains(cloudField)));
      }
    },
  );

  test(
    'claiming local data keeps a parent shared when another account has notes',
    () async {
      final local = await repository.saveEntry(_entry(project, '等待A认领'));
      owner = 'owner-b';
      final b = await repository.saveEntry(_entry(project, 'B已归属记录'));
      final db = await DbService().initWithDatabaseForTest(database);
      await db.claimUnownedRecordsForOwnerForTest('owner-a');
      expect(
        (await database.isar.projects.get(project.id))!.ownerUserId,
        isNull,
      );
      expect(
        (await database.isar.projectNotes.get(local.id))!.ownerUserId,
        'owner-a',
      );
      expect(
        (await database.isar.projectNotes.get(b.id))!.ownerUserId,
        'owner-b',
      );
      owner = 'owner-a';
      expect(
        (await repository.getEntries(_scope(project))).single.id,
        local.id,
      );
      owner = 'owner-b';
      expect((await repository.getEntries(_scope(project))).single.id, b.id);
    },
  );

  test(
    'opening-context guards reject account and restore changes before commands',
    () async {
      var revision = 0;
      repository = ProjectNoteRepository(
        ProjectNoteDao(
          database: database,
          currentOwnerUserId: () => owner,
          contextToken: () => revision,
        ),
      );
      owner = 'owner-a';
      final opened = repository.captureContext();
      final saved = await repository.saveEntry(
        _entry(project, 'A已保存记录'),
        expectedContext: opened,
      );
      owner = 'owner-b';
      await expectLater(
        repository.saveEntry(_entry(project, 'A旧草稿'), expectedContext: opened),
        throwsStateError,
      );
      await expectLater(
        repository.deleteEntry(saved.id, expectedContext: opened),
        throwsStateError,
      );
      owner = 'owner-a';
      revision++;
      await expectLater(
        repository.saveEntry(
          _entry(project, 'A返回后旧草稿'),
          expectedContext: opened,
        ),
        throwsStateError,
      );
      await expectLater(
        repository.deleteEntry(saved.id, expectedContext: opened),
        throwsStateError,
      );
      expect(await database.isar.projectNotes.count(), 1);
    },
  );

  test(
    'saving or ensuring a shared project rejects an implicit foreign-note claim',
    () async {
      owner = 'owner-b';
      final b = await repository.saveEntry(_entry(project, 'B已归属记录'));
      final db = await _OwnerDb(
        () => 'owner-a',
      ).initWithDatabaseForTest(database);
      final proposed = DbService.snapshotProject(project)
        ..status = ProjectStatus.archived
        ..stageNames = ['新阶段'];
      await expectLater(db.addProject(proposed), throwsStateError);
      final saved = (await database.isar.projects.get(project.id))!;
      expect(saved.ownerUserId, isNull);
      expect(saved.status, ProjectStatus.active);
      expect(saved.stageNames, ['调试', '试产']);
      expect(
        (await database.isar.projectNotes.get(b.id))!.ownerUserId,
        'owner-b',
      );
      await database.writeTxn(() async {
        project.syncId = null;
        await database.isar.projects.put(project);
      });
      await expectLater(
        db.ensureProject(project.name, syncable: true),
        throwsStateError,
      );
      expect((await database.isar.projects.get(project.id))!.syncId, isNull);
      expect(
        (await database.isar.projects.get(project.id))!.ownerUserId,
        isNull,
      );
    },
  );

  test(
    'cloud deletion retains an editable local note parent and ignores replays and ACKs',
    () async {
      final db = await DbService().initWithDatabaseForTest(database);
      await database.writeTxn(() async {
        project
          ..remoteId = 55
          ..remoteVersion = 4
          ..isDirty = false;
        await database.isar.projects.put(project);
      });
      final note = await repository.saveEntry(_entry(project, '不能随云端删掉'));
      final stale = DbService.snapshotProject(project);
      final tombstone = <String, dynamic>{
        'id': 55,
        'sync_id': project.syncId,
        'name': project.name,
        'version': 5,
        'updated_at': '2026-10-11T12:00:00Z',
        'deleted_at': '2026-10-11T12:00:00Z',
      };
      await db.syncRemoteProjectToLocal(tombstone);
      var archived = (await db.getProject(project.id))!;
      expect(archived.isLocalArchive, isTrue);
      expect(archived.status, ProjectStatus.archived);
      expect(archived.deletedAt, isNull);
      expect(archived.pendingDelete, isFalse);
      expect(archived.isDirty, isFalse);
      expect(archived.remoteVersion, 5);
      expect(archived.toProjectEntry().isLocalArchive, isTrue);
      await database.writeTxn(() async {
        await database.isar.workLogs.put(
          WorkLog()
            ..date = DateTime(2026, 10, 11)
            ..type = LogType.businessTrip
            ..overtimeHours = 0
            ..projectName = archived.name
            ..projectId = archived.id
            ..projectSyncId = archived.syncId,
        );
      });
      expect(await db.getPendingProjectsForSync(), isEmpty);
      expect(await db.getAllProjectsForSync(), isEmpty);
      expect(
        (await repository.getEntries(_scope(archived))).single.id,
        note.id,
      );
      final edited = await repository.saveEntry(
        _entry(archived, '云端删除后仍可补充', id: note.id),
      );
      expect(edited.content, '云端删除后仍可补充');
      await db.syncRemoteProjectToLocal(tombstone);
      await db.syncRemoteProjectToLocal({
        ...tombstone,
        'name': '旧远端内容不能复活',
        'deleted_at': null,
        'version': 4,
      });
      final lateAck = DbService.snapshotProject(stale)..remoteVersion = 6;
      await db.updateProjectRemoteId(lateAck, sentSnapshot: stale);
      await db.purgeDeletedProject(project.id, sentSnapshot: stale);
      archived = (await db.getProject(project.id))!;
      expect(archived.isLocalArchive, isTrue);
      expect(archived.name, project.name);
      expect(archived.remoteVersion, 5);
      final localEdit = DbService.snapshotProject(archived)
        ..stageNames = ['本地后续阶段']
        ..status = ProjectStatus.active
        ..isDirty = true;
      await db.addProject(localEdit);
      final updated = (await db.getProject(project.id))!;
      expect(updated.status, ProjectStatus.archived);
      expect(updated.stageNames, ['本地后续阶段']);
      expect(updated.isDirty, isFalse);
      expect(await db.getPendingProjectsForSync(), isEmpty);
      await expectLater(
        db.ensureProject(project.name, syncable: true),
        throwsStateError,
      );
      expect(
        (await repository.getEntries(_scope(updated))).single.content,
        '云端删除后仍可补充',
      );
    },
  );

  test(
    'a delete acknowledgement keeps notes but a later explicit cascade deletes locally',
    () async {
      final db = await DbService().initWithDatabaseForTest(database);
      final note = await repository.saveEntry(_entry(project, 'ACK时保留记录'));
      final marked = (await db.markProjectDeleted(project.id))!;
      await db.purgeDeletedProject(
        project.id,
        sentSnapshot: DbService.snapshotProject(marked),
      );
      final retained = (await db.getProject(project.id))!;
      expect(retained.isLocalArchive, isTrue);
      expect(
        (await repository.getEntries(_scope(retained))).single.id,
        note.id,
      );
      final result = await db.deleteProjectCascade(
        projectId: project.id,
        projectName: project.name,
      );
      expect(result!.deletedProject, isNull);
      expect(await database.isar.projects.get(project.id), isNull);
      expect(await database.isar.projectNotes.get(note.id), isNull);
    },
  );

  test(
    'a stale project snapshot cannot make an HTTP request after local retention',
    () async {
      var requests = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final serverSubscription = server.listen((request) async {
        requests++;
        request.response.statusCode = 500;
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://${server.address.address}:${server.port}',
        'test-key',
      );
      final db = await _OwnerDb(
        () => 'owner-a',
      ).initWithDatabaseForTest(database);
      final ownerProject = DbService.snapshotProject(project)
        ..ownerUserId = 'owner-a';
      final stale = DbService.snapshotProject(ownerProject)..isDirty = true;
      await database.writeTxn(() async {
        ownerProject.isLocalArchive = true;
        await database.isar.projects.put(ownerProject);
      });
      final adapter = ProjectSyncAdapter(
        client: client,
        dbService: db,
        userId: 'owner-a',
      );
      try {
        await expectLater(adapter.pushLocalChange(stale), throwsStateError);
        expect(requests, 0);
      } finally {
        await client.dispose();
        await serverSubscription.cancel();
        await server.close(force: true);
      }
    },
  );

  test(
    'explicit unowned clear removes notes but preserves claimed notes',
    () async {
      final local = await repository.saveEntry(_entry(project, '未归属记录'));
      owner = 'claimed-owner';
      final claimed = await repository.saveEntry(_entry(project, '已归属记录'));
      final db = await DbService().initWithDatabaseForTest(database);
      final summary = await db.countUnownedRecords();
      expect(summary.projects, 0);
      expect(summary.projectNotes, 1);
      expect(summary.totalCount, 1);
      await db.deleteUnownedRecords();
      expect(await database.isar.projectNotes.get(local.id), isNull);
      expect(await database.isar.projectNotes.get(claimed.id), isNotNull);
      expect(await database.isar.projects.get(project.id), isNotNull);
      expect(
        (await repository.getEntries(_scope(project))).single.id,
        claimed.id,
      );
      expect((await db.countUnownedRecords()).totalCount, 0);
    },
  );
}

Project _project(String name, {String? syncId}) => Project()
  ..name = name
  ..syncId = syncId
  ..stageNames = ['调试', '试产']
  ..createdAt = DateTime(2026, 10, 1)
  ..updatedAt = DateTime(2026, 10, 1);

ProjectRecordScope _scope(Project project) => ProjectRecordScope(
  id: project.id,
  syncId: project.syncId,
  name: project.name,
);

ProjectNoteEntry _entry(
  Project project,
  String content, {
  int id = 0,
  String? stage,
  DateTime? date,
  DateTime? createdAt,
}) => ProjectNoteEntry(
  id: id,
  projectId: project.id,
  projectSyncId: project.syncId,
  projectName: project.name,
  projectStageName: stage,
  content: content,
  date: date ?? DateTime(2026, 10, 11, 9, 30),
  createdAt: createdAt ?? DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

final class _OwnerDb extends DbService {
  final String? Function() owner;

  _OwnerDb(this.owner);

  @override
  String? get currentOwnerUserId => owner();
}
