import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final isarLibraryPath = _isarLibraryPath();
  final isarSkip = isarLibraryPath != null
      ? false
      : 'isar.dll is not available in this test environment. '
            'Set ISAR_DLL_PATH or place it at D:\\Tool\\Isar\\isar.dll.';
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://life-log-test.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryGotrueAsyncStorage(),
      ),
      accessToken: () async => null,
      debug: false,
    );
    if (isarLibraryPath == null) return;
    await Isar.initializeIsarCore(libraries: {Abi.current(): isarLibraryPath});
  });

  Future<({DbService db, Directory tempDir})> openDb() async {
    final tempDir = await Directory.systemTemp.createTemp('life_log_db_test_');
    final service = DbService();
    final database = await IsarDatabase.open(
      schemas: DbService.schemas,
      directory: tempDir.path,
      name: 'life_log_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    return (
      db: await service.initWithDatabaseForTest(database),
      tempDir: tempDir,
    );
  }

  group('real Isar database behavior', () {
    late Directory tempDir;
    late DbService db;

    setUp(() async {
      final opened = await openDb();
      db = opened.db;
      tempDir = opened.tempDir;
    });

    tearDown(() async {
      await db.isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      if (serviceLocator.isRegistered<AuthService>()) {
        final auth = serviceLocator<AuthService>();
        await serviceLocator.unregister<AuthService>();
        auth.dispose();
      }
    });

    test(
      'claiming local records assigns PhotoItem owner without sync fields',
      () async {
        final createdAt = DateTime(2026, 5, 1);
        await db.isar.writeTxn(() async {
          await db.isar.photoItems.put(
            PhotoItem()
              ..createdAt = createdAt
              ..dateIndexed = createdAt
              ..fileName = 'local.jpg'
              ..filePath = '/tmp/local.jpg',
          );
          await db.isar.expenseEvidences.put(
            ExpenseEvidence()
              ..projectName = 'Build'
              ..evidenceDate = createdAt,
          );
          await db.isar.projects.put(
            Project()
              ..name = 'Build'
              ..createdAt = createdAt
              ..updatedAt = createdAt,
          );
        });

        await db.claimUnownedRecordsForOwnerForTest('user-1');

        final photo = await db.isar.photoItems.where().findFirst();
        final project = await db.isar.projects.where().findFirst();

        expect(photo!.ownerUserId, 'user-1');
        expect(project!.ownerUserId, 'user-1');
        expect(project.syncId, isNotNull);
        expect(project.isDirty, isTrue);
      },
      skip: isarSkip,
    );

    test('remote expense pull auto-creates syncable dirty project', () async {
      await db.syncRemoteExpenseRecordToLocal({
        'id': 11,
        'sync_id': 'expense-11',
        'version': 1,
        'updated_at': '2026-05-01T00:00:00Z',
        'expense_date': '2026-05-01',
        'project_name': 'Remote Build',
        'amount': 12.5,
        'currency': 'CNY',
      });

      final project = await db.isar.projects.where().findFirst();
      final record = await db.isar.expenseRecords.where().findFirst();

      expect(project!.name, 'Remote Build');
      expect(project.syncId, isNotNull);
      expect(project.isDirty, isTrue);
      expect(record!.projectId, project.id);
    }, skip: isarSkip);

    test('new local evidence can be deleted from visible records', () async {
      final id = await db.addEvidence(
        ExpenseEvidence()
          ..projectName = 'Build'
          ..evidenceDate = DateTime(2026, 6, 15)
          ..amount = 42,
      );

      expect(await db.getAllEvidence(), hasLength(1));

      final deleted = await db.markEvidenceDeleted(id);
      await db.purgeDeletedEvidence(id);

      expect(deleted, isNotNull);
      expect(await db.getAllEvidence(), isEmpty);
      expect(await db.isar.expenseEvidences.get(id), isNull);
    }, skip: isarSkip);

    test('work log edit preserves existing sync identity', () async {
      final remoteUpdatedAt = DateTime.utc(2026, 6, 23, 9);
      final syncedAt = DateTime.utc(2026, 6, 23, 10);
      late final int id;
      await db.isar.writeTxn(() async {
        id = await db.isar.workLogs.put(
          WorkLog()
            ..ownerUserId = 'user-1'
            ..remoteId = 41
            ..syncId = 'sync-work-log-1'
            ..remoteVersion = 7
            ..remoteUpdatedAt = remoteUpdatedAt
            ..syncedAt = syncedAt
            ..date = DateTime(2026, 6, 23)
            ..type = LogType.work
            ..overtimeHours = 1,
        );
      });

      await db.addLog(
        WorkLog()
          ..id = id
          ..syncId = 'sync-work-log-1'
          ..date = DateTime(2026, 6, 23)
          ..type = LogType.work
          ..overtimeHours = 2,
      );

      final saved = await db.isar.workLogs.get(id);
      expect(saved!.ownerUserId, 'user-1');
      expect(saved.remoteId, 41);
      expect(saved.syncId, 'sync-work-log-1');
      expect(saved.remoteVersion, 7);
      expect(saved.remoteUpdatedAt?.toUtc(), remoteUpdatedAt);
      expect(saved.syncedAt?.toUtc(), syncedAt);
      expect(saved.isDirty, isTrue);
      expect(saved.overtimeHours, 2);
    }, skip: isarSkip);

    test(
      'logged-in work-log sequence keeps unowned local entries visible',
      () async {
        await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 6, 23)
            ..type = LogType.work
            ..overtimeHours = 1
            ..note = 'yesterday-local',
        );
        _registerTestAuthUser('user-1');
        await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 6, 24)
            ..type = LogType.work
            ..overtimeHours = 2
            ..note = 'today-owned',
        );
        await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 6, 23)
            ..type = LogType.work
            ..overtimeHours = 3
            ..note = 'yesterday-owned',
        );

        final logs = await db.getLogsByMonth(DateTime(2026, 6));

        expect(logs.map((log) => log.note), [
          'yesterday-local',
          'yesterday-owned',
          'today-owned',
        ]);
        expect(logs.map((log) => log.ownerUserId), [null, 'user-1', 'user-1']);
      },
      skip: isarSkip,
    );

    test(
      'logged-in month read keeps yesterday today and future across repeated saves',
      () async {
        _registerTestAuthUser('user-1');

        await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 7, 6)
            ..type = LogType.work
            ..overtimeHours = 1
            ..note = 'yesterday-first',
        );
        await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 7, 8)
            ..type = LogType.work
            ..overtimeHours = 4
            ..note = 'future-owned',
        );
        await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 7, 7)
            ..type = LogType.work
            ..overtimeHours = 2
            ..note = 'today-owned',
        );

        var logs = await db.getLogsByMonth(DateTime(2026, 7));

        expect(logs.map((log) => log.note), [
          'yesterday-first',
          'today-owned',
          'future-owned',
        ]);
        expect(logs.map((log) => log.ownerUserId), [
          'user-1',
          'user-1',
          'user-1',
        ]);

        await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 7, 6)
            ..type = LogType.work
            ..overtimeHours = 3
            ..note = 'yesterday-second',
        );

        logs = await db.getLogsByMonth(DateTime(2026, 7));

        expect(logs.map((log) => log.note), [
          'yesterday-first',
          'yesterday-second',
          'today-owned',
          'future-owned',
        ]);
        expect(logs.map((log) => log.ownerUserId), [
          'user-1',
          'user-1',
          'user-1',
          'user-1',
        ]);
      },
      skip: isarSkip,
    );

    test(
      'id zero add methods allocate new Isar ids instead of overwriting',
      () async {
        final firstLogId = await db.addLog(
          WorkLog()
            ..id = 0
            ..date = DateTime(2026, 7, 1)
            ..type = LogType.work
            ..note = 'work-first',
        );
        final secondLogId = await db.addLog(
          WorkLog()
            ..id = 0
            ..date = DateTime(2026, 7, 2)
            ..type = LogType.work
            ..note = 'work-second',
        );

        final firstSubscriptionId = await db.addSubscription(
          Subscription()
            ..id = 0
            ..name = 'Music'
            ..cycle = SubscriptionCycle.monthly
            ..nextPaymentDate = DateTime(2026, 7, 1),
        );
        final secondSubscriptionId = await db.addSubscription(
          Subscription()
            ..id = 0
            ..name = 'Storage'
            ..cycle = SubscriptionCycle.monthly
            ..nextPaymentDate = DateTime(2026, 7, 2),
        );

        final firstEvidenceId = await db.addEvidence(
          ExpenseEvidence()
            ..id = 0
            ..projectName = 'Alpha'
            ..evidenceDate = DateTime(2026, 7, 1),
        );
        final secondEvidenceId = await db.addEvidence(
          ExpenseEvidence()
            ..id = 0
            ..projectName = 'Beta'
            ..evidenceDate = DateTime(2026, 7, 2),
        );

        final firstExpenseId = await db.addExpenseRecord(
          ExpenseRecord()
            ..id = 0
            ..expenseDate = DateTime(2026, 7, 1)
            ..amount = 10,
        );
        final secondExpenseId = await db.addExpenseRecord(
          ExpenseRecord()
            ..id = 0
            ..expenseDate = DateTime(2026, 7, 2)
            ..amount = 20,
        );

        final firstProjectId = await db.addProject(
          Project()
            ..id = 0
            ..name = 'Alpha'
            ..createdAt = DateTime(2026, 7, 1)
            ..updatedAt = DateTime(2026, 7, 1),
        );
        final secondProjectId = await db.addProject(
          Project()
            ..id = 0
            ..name = 'Beta'
            ..createdAt = DateTime(2026, 7, 2)
            ..updatedAt = DateTime(2026, 7, 2),
        );

        await db.addPhoto(
          PhotoItem()
            ..id = 0
            ..createdAt = DateTime(2026, 7, 1)
            ..dateIndexed = DateTime(2026, 7, 1)
            ..fileName = 'first.jpg'
            ..filePath = '/tmp/first.jpg',
        );
        await db.addPhoto(
          PhotoItem()
            ..id = 0
            ..createdAt = DateTime(2026, 7, 2)
            ..dateIndexed = DateTime(2026, 7, 2)
            ..fileName = 'second.jpg'
            ..filePath = '/tmp/second.jpg',
        );

        expect([
          firstLogId,
          secondLogId,
          firstSubscriptionId,
          secondSubscriptionId,
          firstEvidenceId,
          secondEvidenceId,
          firstExpenseId,
          secondExpenseId,
          firstProjectId,
          secondProjectId,
        ], everyElement(isNot(0)));
        expect(firstLogId, isNot(secondLogId));
        expect(firstSubscriptionId, isNot(secondSubscriptionId));
        expect(firstEvidenceId, isNot(secondEvidenceId));
        expect(firstExpenseId, isNot(secondExpenseId));
        expect(firstProjectId, isNot(secondProjectId));

        final logs = await db.isar.workLogs.where().findAll();
        final subscriptions = await db.isar.subscriptions.where().findAll();
        final evidence = await db.isar.expenseEvidences.where().findAll();
        final expenses = await db.isar.expenseRecords.where().findAll();
        final projects = await db.isar.projects.where().findAll();
        final photos = await db.isar.photoItems.where().findAll();

        expect(logs.map((log) => log.note), ['work-first', 'work-second']);
        expect(subscriptions.map((sub) => sub.name), ['Music', 'Storage']);
        expect(evidence.map((item) => item.projectName), ['Alpha', 'Beta']);
        expect(expenses.map((record) => record.amount), [10, 20]);
        expect(projects.map((project) => project.name), ['Alpha', 'Beta']);
        expect(photos.map((photo) => photo.fileName), [
          'first.jpg',
          'second.jpg',
        ]);
      },
      skip: isarSkip,
    );

    test(
      'remote pulls do not mutate rows owned by another local user',
      () async {
        final existingAt = DateTime.utc(2026, 7, 1);
        await db.isar.writeTxn(() async {
          await db.isar.workLogs.put(
            WorkLog()
              ..ownerUserId = 'user-1'
              ..remoteId = 101
              ..syncId = 'shared-work'
              ..remoteVersion = 1
              ..date = DateTime(2026, 7, 1)
              ..type = LogType.work
              ..note = 'user-1 work',
          );
          await db.isar.subscriptions.put(
            Subscription()
              ..ownerUserId = 'user-1'
              ..remoteId = 102
              ..syncId = 'shared-subscription'
              ..remoteVersion = 1
              ..name = 'user-1 subscription'
              ..cycle = SubscriptionCycle.monthly
              ..nextPaymentDate = existingAt,
          );
          await db.isar.expenseEvidences.put(
            ExpenseEvidence()
              ..ownerUserId = 'user-1'
              ..remoteId = 103
              ..syncId = 'shared-evidence'
              ..remoteVersion = 1
              ..projectName = 'user-1 evidence'
              ..evidenceDate = existingAt,
          );
          await db.isar.expenseRecords.put(
            ExpenseRecord()
              ..ownerUserId = 'user-1'
              ..remoteId = 104
              ..syncId = 'shared-expense'
              ..remoteVersion = 1
              ..expenseDate = existingAt
              ..amount = 10,
          );
          await db.isar.projects.put(
            Project()
              ..ownerUserId = 'user-1'
              ..remoteId = 105
              ..syncId = 'shared-project'
              ..remoteVersion = 1
              ..name = 'user-1 project'
              ..createdAt = existingAt
              ..updatedAt = existingAt,
          );
          await db.isar.evidenceAttachments.put(
            EvidenceAttachment()
              ..ownerUserId = 'user-1'
              ..syncId = 'shared-attachment'
              ..evidenceSyncId = 'user-1-evidence-parent'
              ..remoteStoragePath = 'user-1/attachment.pdf'
              ..originalFileName = 'user-1.pdf'
              ..uploadState = EvidenceAttachmentUploadState.uploaded
              ..createdAt = existingAt
              ..updatedAt = existingAt,
          );
        });

        _registerTestAuthUser('user-2');

        await db.syncRemoteLogToLocal({
          'id': 101,
          'sync_id': 'shared-work',
          'version': 2,
          'updated_at': '2026-07-02T00:00:00Z',
          'date': '2026-07-02',
          'type': 'work',
          'notes': 'user-2 work',
        });
        await db.syncRemoteSubscriptionToLocal({
          'id': 102,
          'sync_id': 'shared-subscription',
          'version': 2,
          'updated_at': '2026-07-02T00:00:00Z',
          'name': 'user-2 subscription',
          'cycle': 'monthly',
          'next_due_date': '2026-07-02',
        });
        await db.syncRemoteEvidenceToLocal({
          'id': 103,
          'sync_id': 'shared-evidence',
          'version': 2,
          'updated_at': '2026-07-02T00:00:00Z',
          'project_name': 'user-2 evidence',
          'evidence_date': '2026-07-02',
        });
        await db.syncRemoteExpenseRecordToLocal({
          'id': 104,
          'sync_id': 'shared-expense',
          'version': 2,
          'updated_at': '2026-07-02T00:00:00Z',
          'expense_date': '2026-07-02',
          'amount': 20,
        });
        await db.syncRemoteProjectToLocal({
          'id': 105,
          'sync_id': 'shared-project',
          'version': 2,
          'updated_at': '2026-07-02T00:00:00Z',
          'name': 'user-2 project',
        });
        await db.syncRemoteEvidenceAttachmentToLocal({
          'sync_id': 'shared-attachment',
          'evidence_sync_id': 'user-2-evidence-parent',
          'remote_storage_path': 'user-2/attachment.pdf',
          'original_file_name': 'user-2.pdf',
          'upload_state': 'uploaded',
          'updated_at': '2026-07-02T00:00:00Z',
        });

        final logs = await db.isar.workLogs.where().findAll();
        final subscriptions = await db.isar.subscriptions.where().findAll();
        final evidence = await db.isar.expenseEvidences.where().findAll();
        final expenses = await db.isar.expenseRecords.where().findAll();
        final projects = await db.isar.projects.where().findAll();
        final attachments = await db.isar.evidenceAttachments.where().findAll();

        expect(logs.map((log) => log.ownerUserId), ['user-1', 'user-2']);
        expect(logs.map((log) => log.note), ['user-1 work', 'user-2 work']);
        expect(subscriptions.map((sub) => sub.ownerUserId), [
          'user-1',
          'user-2',
        ]);
        expect(subscriptions.map((sub) => sub.name), [
          'user-1 subscription',
          'user-2 subscription',
        ]);
        expect(evidence.map((item) => item.ownerUserId), ['user-1', 'user-2']);
        expect(evidence.map((item) => item.projectName), [
          'user-1 evidence',
          'user-2 evidence',
        ]);
        expect(expenses.map((record) => record.ownerUserId), [
          'user-1',
          'user-2',
        ]);
        expect(expenses.map((record) => record.amount), [10, 20]);
        expect(
          projects
              .where((project) => project.name == 'user-1 project')
              .single
              .ownerUserId,
          'user-1',
        );
        expect(
          projects
              .where((project) => project.name == 'user-2 project')
              .single
              .ownerUserId,
          'user-2',
        );
        expect(attachments.map((attachment) => attachment.ownerUserId), [
          'user-1',
          'user-2',
        ]);
        expect(attachments.map((attachment) => attachment.remoteStoragePath), [
          'user-1/attachment.pdf',
          'user-2/attachment.pdf',
        ]);
      },
      skip: isarSkip,
    );

    test('remote relationship lookup uses the current owner', () async {
      final existingAt = DateTime.utc(2026, 7, 1);
      late int user2ProjectId;
      late int user2TripWorkLogId;
      await db.isar.writeTxn(() async {
        await db.isar.projects.put(
          Project()
            ..ownerUserId = 'user-1'
            ..syncId = 'shared-link-project'
            ..name = 'user-1 link project'
            ..createdAt = existingAt
            ..updatedAt = existingAt,
        );
        user2ProjectId = await db.isar.projects.put(
          Project()
            ..ownerUserId = 'user-2'
            ..syncId = 'shared-link-project'
            ..name = 'user-2 link project'
            ..createdAt = existingAt
            ..updatedAt = existingAt,
        );
        await db.isar.workLogs.put(
          WorkLog()
            ..ownerUserId = 'user-1'
            ..syncId = 'shared-trip'
            ..date = DateTime(2026, 7, 1)
            ..type = LogType.businessTrip
            ..note = 'user-1 trip',
        );
        user2TripWorkLogId = await db.isar.workLogs.put(
          WorkLog()
            ..ownerUserId = 'user-2'
            ..syncId = 'shared-trip'
            ..date = DateTime(2026, 7, 1)
            ..type = LogType.businessTrip
            ..note = 'user-2 trip',
        );
      });

      _registerTestAuthUser('user-2');

      await db.syncRemoteExpenseRecordToLocal({
        'id': 301,
        'sync_id': 'expense-with-links',
        'version': 1,
        'updated_at': '2026-07-02T00:00:00Z',
        'expense_date': '2026-07-02',
        'amount': 30,
        'project_name': 'ignored when sync id matches',
        'project_sync_id': 'shared-link-project',
        'trip_work_log_sync_id': 'shared-trip',
      });

      final record = await db.isar.expenseRecords.where().findFirst();

      expect(record!.ownerUserId, 'user-2');
      expect(record.projectId, user2ProjectId);
      expect(record.projectName, 'user-2 link project');
      expect(record.tripWorkLogId, user2TripWorkLogId);
      expect(await db.isar.projects.where().count(), 2);
      expect(await db.isar.workLogs.where().count(), 2);
    }, skip: isarSkip);

    test(
      'ensuring evidence attachments only supersedes current owner attachments',
      () async {
        final existingAt = DateTime.utc(2026, 7, 1);
        await db.isar.writeTxn(() async {
          await db.isar.evidenceAttachments.put(
            EvidenceAttachment()
              ..ownerUserId = 'user-1'
              ..syncId = 'user-1-attachment'
              ..evidenceSyncId = 'shared-evidence-sync'
              ..localPath = '/tmp/user-1.pdf'
              ..remoteStoragePath = 'user-1/attachment.pdf'
              ..originalFileName = 'user-1.pdf'
              ..uploadState = EvidenceAttachmentUploadState.uploaded
              ..createdAt = existingAt
              ..updatedAt = existingAt,
          );
        });

        _registerTestAuthUser('user-2');
        final user2File = File(
          '${tempDir.path}${Platform.pathSeparator}u2.txt',
        );
        await user2File.writeAsString('user-2 attachment');

        await db.addEvidence(
          ExpenseEvidence()
            ..syncId = 'shared-evidence-sync'
            ..projectName = 'Attachment'
            ..evidenceDate = existingAt
            ..localFilePath = user2File.path
            ..fileName = 'u2.txt',
        );

        final attachments = await db.isar.evidenceAttachments.where().findAll();
        final user1Attachment = attachments
            .where((attachment) => attachment.ownerUserId == 'user-1')
            .single;
        final user2Attachment = attachments
            .where((attachment) => attachment.ownerUserId == 'user-2')
            .single;

        expect(
          user1Attachment.uploadState,
          EvidenceAttachmentUploadState.uploaded,
        );
        expect(user1Attachment.deletedAt, isNull);
        expect(user2Attachment.evidenceSyncId, 'shared-evidence-sync');
        expect(
          user2Attachment.uploadState,
          EvidenceAttachmentUploadState.pending,
        );
        expect(user2Attachment.deletedAt, isNull);
      },
      skip: isarSkip,
    );

    test(
      'remote tombstones do not delete rows owned by another local user',
      () async {
        final existingAt = DateTime.utc(2026, 7, 1);
        await db.isar.writeTxn(() async {
          await db.isar.workLogs.put(
            WorkLog()
              ..ownerUserId = 'user-1'
              ..remoteId = 201
              ..syncId = 'delete-work'
              ..date = DateTime(2026, 7, 1)
              ..type = LogType.work
              ..note = 'keep work',
          );
          await db.isar.subscriptions.put(
            Subscription()
              ..ownerUserId = 'user-1'
              ..remoteId = 202
              ..syncId = 'delete-subscription'
              ..name = 'keep subscription'
              ..cycle = SubscriptionCycle.monthly
              ..nextPaymentDate = existingAt,
          );
          await db.isar.expenseEvidences.put(
            ExpenseEvidence()
              ..ownerUserId = 'user-1'
              ..remoteId = 203
              ..syncId = 'delete-evidence'
              ..projectName = 'keep evidence'
              ..evidenceDate = existingAt,
          );
          await db.isar.expenseRecords.put(
            ExpenseRecord()
              ..ownerUserId = 'user-1'
              ..remoteId = 204
              ..syncId = 'delete-expense'
              ..expenseDate = existingAt
              ..amount = 10,
          );
          await db.isar.projects.put(
            Project()
              ..ownerUserId = 'user-1'
              ..remoteId = 205
              ..syncId = 'delete-project'
              ..name = 'keep project'
              ..createdAt = existingAt
              ..updatedAt = existingAt,
          );
          await db.isar.evidenceAttachments.put(
            EvidenceAttachment()
              ..ownerUserId = 'user-1'
              ..syncId = 'delete-attachment'
              ..evidenceSyncId = 'delete-evidence-parent'
              ..remoteStoragePath = 'user-1/delete.pdf'
              ..originalFileName = 'delete.pdf'
              ..uploadState = EvidenceAttachmentUploadState.uploaded
              ..createdAt = existingAt
              ..updatedAt = existingAt,
          );
        });

        _registerTestAuthUser('user-2');
        const deletedAt = '2026-07-02T00:00:00Z';

        await db.syncRemoteLogToLocal({
          'id': 201,
          'sync_id': 'delete-work',
          'version': 2,
          'updated_at': deletedAt,
          'deleted_at': deletedAt,
        });
        await db.syncRemoteSubscriptionToLocal({
          'id': 202,
          'sync_id': 'delete-subscription',
          'version': 2,
          'updated_at': deletedAt,
          'deleted_at': deletedAt,
        });
        await db.syncRemoteEvidenceToLocal({
          'id': 203,
          'sync_id': 'delete-evidence',
          'version': 2,
          'updated_at': deletedAt,
          'deleted_at': deletedAt,
        });
        await db.syncRemoteExpenseRecordToLocal({
          'id': 204,
          'sync_id': 'delete-expense',
          'version': 2,
          'updated_at': deletedAt,
          'deleted_at': deletedAt,
        });
        await db.syncRemoteProjectToLocal({
          'id': 205,
          'sync_id': 'delete-project',
          'version': 2,
          'updated_at': deletedAt,
          'deleted_at': deletedAt,
        });
        await db.syncRemoteEvidenceAttachmentToLocal({
          'sync_id': 'delete-attachment',
          'evidence_sync_id': 'delete-evidence-parent',
          'updated_at': deletedAt,
          'deleted_at': deletedAt,
        });

        expect(await db.isar.workLogs.where().count(), 1);
        expect(await db.isar.subscriptions.where().count(), 1);
        expect(await db.isar.expenseEvidences.where().count(), 1);
        expect(await db.isar.expenseRecords.where().count(), 1);
        expect(await db.isar.projects.where().count(), 1);
        expect(await db.isar.evidenceAttachments.where().count(), 1);
        expect(
          (await db.isar.workLogs.where().findFirst())!.ownerUserId,
          'user-1',
        );
        expect(
          (await db.isar.subscriptions.where().findFirst())!.ownerUserId,
          'user-1',
        );
        expect(
          (await db.isar.expenseEvidences.where().findFirst())!.ownerUserId,
          'user-1',
        );
        expect(
          (await db.isar.expenseRecords.where().findFirst())!.ownerUserId,
          'user-1',
        );
        expect(
          (await db.isar.projects.where().findFirst())!.ownerUserId,
          'user-1',
        );
        expect(
          (await db.isar.evidenceAttachments.where().findFirst())!.ownerUserId,
          'user-1',
        );
      },
      skip: isarSkip,
    );
  });

  test('database startup maintenance is explicit instead of init-blocking', () {
    final source = File('lib/common/db/db_service.dart').readAsStringSync();

    expect(source, contains('Future<DbService> init({'));
    expect(source, contains('bool runStartupMaintenance = false'));
    expect(source, contains('Future<void> runStartupMaintenance'));
    expect(
      source,
      isNot(
        contains(
          'Future<DbService> init() async {\n'
          '    // 获取手机里专门存文档的路径',
        ),
      ),
    );
  });
}

void _registerTestAuthUser(String userId) {
  final auth = AuthService();
  auth.currentUser.value = User(
    id: userId,
    appMetadata: const {},
    userMetadata: null,
    aud: 'authenticated',
    createdAt: '2026-06-23T00:00:00Z',
  );
  serviceLocator.registerSingleton<AuthService>(auth);
}

final class _MemoryGotrueAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }
}

String? _isarLibraryPath() {
  final explicitPath = Platform.environment['ISAR_DLL_PATH'];
  if (explicitPath != null && explicitPath.trim().isNotEmpty) {
    final file = File(explicitPath.trim());
    if (file.existsSync()) return file.path;
  }

  final defaultDDrivePath = File(r'D:\Tool\Isar\isar.dll');
  if (defaultDDrivePath.existsSync()) {
    return defaultDDrivePath.path;
  }

  return null;
}
