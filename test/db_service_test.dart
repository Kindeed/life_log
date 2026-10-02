import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:life_log/core/sync/isar_sync_queue.dart';
import 'package:life_log/core/sync/sync_queue_record.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:life_log/features/work_log/sync/work_log_sync_adapter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tool/isar_test_runtime.dart' show initializeTestIsar;

late GetStorage _testAuthStorage;

void main() {
  late Directory authStorageDirectory;
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    authStorageDirectory = await Directory.systemTemp.createTemp(
      'life_log_auth_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathChannel,
          (_) async => authStorageDirectory.path,
        );
    _testAuthStorage = GetStorage('auth', authStorageDirectory.path);
    await _testAuthStorage.initStorage;
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
    await initializeTestIsar();
  });

  tearDownAll(() async {
    await _testAuthStorage.erase();
    await authStorageDirectory.delete(recursive: true);
    await Supabase.instance.client.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
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

    test('a delayed work ACK preserves a newer edit and dirty state', () async {
      final id = await db.addLog(
        WorkLog()
          ..date = DateTime(2026, 10, 1)
          ..type = LogType.work
          ..remoteId = 11
          ..syncId = 'ack-work'
          ..remoteVersion = 1
          ..note = 'sent',
      );
      final sent = DbService.snapshotWorkLog((await db.getWorkLog(id))!);
      final ack = DbService.snapshotWorkLog(sent)
        ..remoteVersion = 2
        ..isDirty = false
        ..syncedAt = DateTime.utc(2026, 10, 1);
      final networkResponse = Completer<void>();
      final delayedAck = networkResponse.future.then(
        (_) => db.updateWorkLogRemoteId(ack, sentSnapshot: sent),
      );

      final edited = (await db.getWorkLog(id))!..note = 'new local edit';
      await db.addLog(edited);
      networkResponse.complete();
      await delayedAck;

      final live = (await db.getWorkLog(id))!;
      expect(live.note, 'new local edit');
      expect(live.isDirty, isTrue);
      expect(live.remoteVersion, 2);
      expect(live.syncedAt?.toUtc(), ack.syncedAt?.toUtc());
    });

    test('delayed ACK preserves a newer local tombstone', () async {
      final id = await db.addLog(
        WorkLog()
          ..date = DateTime(2026, 10, 1)
          ..type = LogType.work
          ..remoteId = 12
          ..remoteVersion = 1
          ..syncId = 'ack-delete',
      );
      final sent = DbService.snapshotWorkLog((await db.getWorkLog(id))!);
      final ack = DbService.snapshotWorkLog(sent)..remoteVersion = 2;
      final deleted = (await db.markLogDeleted(id))!;

      await db.updateWorkLogRemoteId(ack, sentSnapshot: sent);

      final live = (await db.isar.workLogs.get(id))!;
      expect(live.pendingDelete, isTrue);
      expect(live.deletedAt?.toUtc(), deleted.deletedAt?.toUtc());
      expect(live.isDirty, isTrue);
      expect(live.remoteVersion, 2);
    });

    test(
      'unchanged snapshot ACK clears dirty without replacing local fields',
      () async {
        final id = await db.addProject(
          Project()
            ..name = 'Project'
            ..createdAt = DateTime.utc(2026, 10, 1)
            ..updatedAt = DateTime.utc(2026, 10, 1)
            ..syncId = 'project-ack'
            ..isDirty = true,
        );
        final sent = DbService.snapshotProject((await db.getProject(id))!);
        final ack = DbService.snapshotProject(sent)
          ..remoteId = 40
          ..remoteVersion = 1
          ..syncedAt = DateTime.utc(2026, 10, 2);
        await db.updateProjectCover(
          DbService.snapshotProject(sent)
            ..localCoverPath = '/local/new-cover.jpg',
        );

        await db.updateProjectRemoteId(ack, sentSnapshot: sent);

        final live = (await db.getProject(id))!;
        expect(live.localCoverPath, '/local/new-cover.jpg');
        expect(live.isDirty, isFalse);
        expect(live.remoteVersion, 1);
      },
    );

    test(
      'subscription edit and same-value revert stays pending after old ACK',
      () async {
        final id = await db.addSubscription(
          Subscription()
            ..name = 'A'
            ..nextPaymentDate = DateTime(2026, 10, 1)
            ..remoteId = 50
            ..remoteVersion = 1
            ..syncId = 'revert-subscription'
            ..isDirty = true,
        );
        final sent = DbService.snapshotSubscription(
          (await db.getSubscription(id))!,
        );
        await db.addSubscription((await db.getSubscription(id))!..name = 'B');
        await db.addSubscription((await db.getSubscription(id))!..name = 'A');
        final ack = DbService.snapshotSubscription(sent)..remoteVersion = 2;

        await db.updateSubscriptionRemoteId(ack, sentSnapshot: sent);

        final live = (await db.getSubscription(id))!;
        expect(live.name, 'A');
        expect(live.isDirty, isTrue);
        expect(live.remoteVersion, 2);
      },
    );

    test(
      'an editor opened before ACK retains the latest remote base on save',
      () async {
        final id = await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 10, 1)
            ..type = LogType.work
            ..remoteId = 51
            ..remoteVersion = 1
            ..syncId = 'stale-editor',
        );
        final staleEditor = (await db.getWorkLog(id))!;
        final sent = DbService.snapshotWorkLog(staleEditor);
        await db.updateWorkLogRemoteId(
          DbService.snapshotWorkLog(sent)..remoteVersion = 2,
          sentSnapshot: sent,
        );
        staleEditor.note = 'saved after response';
        await db.addLog(staleEditor);
        final live = (await db.getWorkLog(id))!;
        expect(live.remoteVersion, 2);
        expect(live.note, 'saved after response');
        expect(live.isDirty, isTrue);
      },
    );

    test(
      'old delete ACK cannot purge a record edited after its tombstone snapshot',
      () async {
        final id = await db.addLog(
          WorkLog()
            ..date = DateTime(2026, 10, 1)
            ..type = LogType.work
            ..remoteId = 52
            ..syncId = 'delete-purge',
        );
        final sent = DbService.snapshotWorkLog((await db.markLogDeleted(id))!);
        final edited = DbService.snapshotWorkLog(sent)
          ..note = 'new tombstone note';
        await db.addLog(edited);

        await db.purgeDeletedLog(id, sentSnapshot: sent);

        expect((await db.isar.workLogs.get(id))!.note, 'new tombstone note');
      },
    );

    test(
      'dirty pulls retain each entity base version and pending tombstone',
      () async {
        final at = DateTime.utc(2026, 10, 1);
        await db.isar.writeTxn(() async {
          await db.isar.workLogs.put(
            WorkLog()
              ..syncId = 'dirty-work'
              ..remoteId = 61
              ..remoteVersion = 1
              ..isDirty = true
              ..pendingDelete = true
              ..deletedAt = at
              ..date = at
              ..type = LogType.work
              ..note = 'local work',
          );
          await db.isar.subscriptions.put(
            Subscription()
              ..syncId = 'dirty-sub'
              ..remoteId = 62
              ..remoteVersion = 1
              ..isDirty = true
              ..pendingDelete = true
              ..deletedAt = at
              ..name = 'local sub'
              ..nextPaymentDate = at,
          );
          await db.isar.expenseEvidences.put(
            ExpenseEvidence()
              ..syncId = 'dirty-evidence'
              ..remoteId = 63
              ..remoteVersion = 1
              ..isDirty = true
              ..pendingDelete = true
              ..deletedAt = at
              ..projectName = 'local evidence'
              ..evidenceDate = at,
          );
          await db.isar.expenseRecords.put(
            ExpenseRecord()
              ..syncId = 'dirty-expense'
              ..remoteId = 64
              ..remoteVersion = 1
              ..isDirty = true
              ..pendingDelete = true
              ..deletedAt = at
              ..expenseDate = at
              ..amount = 9,
          );
          await db.isar.projects.put(
            Project()
              ..syncId = 'dirty-project'
              ..remoteId = 65
              ..remoteVersion = 1
              ..isDirty = true
              ..pendingDelete = true
              ..deletedAt = at
              ..name = 'local project'
              ..createdAt = at
              ..updatedAt = at,
          );
        });
        Map<String, dynamic> row(int id, String syncId) => {
          'id': id,
          'sync_id': syncId,
          'version': 2,
          'updated_at': '2026-10-02T00:00:00Z',
          'deleted_at': '2026-10-02T00:00:00Z',
        };
        await db.syncRemoteLogToLocal(row(61, 'dirty-work'));
        await db.syncRemoteSubscriptionToLocal(row(62, 'dirty-sub'));
        await db.syncRemoteEvidenceToLocal(row(63, 'dirty-evidence'));
        await db.syncRemoteExpenseRecordToLocal(row(64, 'dirty-expense'));
        await db.syncRemoteProjectToLocal(row(65, 'dirty-project'));
        final rows = <dynamic>[
          (await db.isar.workLogs.where().findFirst())!,
          (await db.isar.subscriptions.where().findFirst())!,
          (await db.isar.expenseEvidences.where().findFirst())!,
          (await db.isar.expenseRecords.where().findFirst())!,
          (await db.isar.projects.where().findFirst())!,
        ];
        for (final dynamic live in rows) {
          expect(live.remoteVersion, 1);
          expect(live.pendingDelete, isTrue);
          expect(live.deletedAt?.toUtc(), at);
          expect(live.isDirty, isTrue);
        }
      },
    );

    test('delayed pull from A cannot enter B or unowned records', () async {
      _registerTestAuthUser('user-a');
      var current = true;
      final context = SyncRunContext(
        ownerId: 'user-a',
        sessionEpoch: 1,
        databaseGeneration: db.databaseGeneration,
        runId: 1,
        isCurrent: () => current,
      );
      final networkResponse = Completer<Map<String, dynamic>>();
      final pull = networkResponse.future.then(
        (row) => db.syncRemoteLogToLocal(row, context: context),
      );
      final failure = expectLater(pull, throwsA(isA<SyncRunInvalidated>()));
      serviceLocator<AuthService>().currentUser.value = const User(
        id: 'user-b',
        appMetadata: {},
        userMetadata: null,
        aud: 'authenticated',
        createdAt: '2026-10-01T00:00:00Z',
      );
      current = false;
      networkResponse.complete({
        'user_id': 'user-a',
        'id': 70,
        'sync_id': 'delayed-a',
        'version': 1,
        'date': '2026-10-01',
        'type': 'work',
      });
      await failure;
      expect(await db.isar.workLogs.count(), 0);
    });

    test('invalidated same-owner session rejects a late ACK', () async {
      _registerTestAuthUser('user-a');
      final id = await db.addLog(
        WorkLog()
          ..date = DateTime(2026, 10, 1)
          ..type = LogType.work
          ..syncId = 'same-owner-session',
      );
      final sent = DbService.snapshotWorkLog((await db.getWorkLog(id))!);
      final context = SyncRunContext(
        ownerId: 'user-a',
        sessionEpoch: 1,
        databaseGeneration: db.databaseGeneration,
        runId: 1,
        isCurrent: () => false,
      );
      await expectLater(
        db.updateWorkLogRemoteId(
          DbService.snapshotWorkLog(sent)
            ..remoteId = 80
            ..remoteVersion = 1,
          context: context,
          sentSnapshot: sent,
        ),
        throwsA(isA<SyncRunInvalidated>()),
      );
      final live = (await db.getWorkLog(id))!;
      expect(live.remoteId, isNull);
      expect(live.isDirty, isTrue);
    });

    test(
      'a late attachment upload cannot revive delete or newer local bytes',
      () async {
        final at = DateTime.utc(2026, 10, 1);
        final attachment = EvidenceAttachment()
          ..syncId = 'attachment-late'
          ..evidenceSyncId = 'evidence-late'
          ..originalFileName = 'old.pdf'
          ..localPath = '/local/old.pdf'
          ..contentHash = 'old-hash'
          ..createdAt = at
          ..updatedAt = at;
        await db.isar.writeTxn(
          () => db.isar.evidenceAttachments.put(attachment),
        );
        final sent = (await db.isar.evidenceAttachments.get(attachment.id))!;
        await db.isar.writeTxn(() async {
          final live = (await db.isar.evidenceAttachments.get(sent.id))!;
          live.contentHash = 'new-hash';
          await db.isar.evidenceAttachments.put(live);
        });
        await db.markEvidenceAttachmentUploaded(
          sent,
          remoteStoragePath: 'old-object',
        );
        var live = (await db.isar.evidenceAttachments.get(sent.id))!;
        expect(live.uploadState, EvidenceAttachmentUploadState.pending);
        expect(live.remoteStoragePath, isNull);
        await db.isar.writeTxn(() async {
          live
            ..uploadState = EvidenceAttachmentUploadState.deleted
            ..deletedAt = at;
          await db.isar.evidenceAttachments.put(live);
        });
        await db.markEvidenceAttachmentUploaded(
          sent,
          remoteStoragePath: 'old-object',
        );
        live = (await db.isar.evidenceAttachments.get(sent.id))!;
        expect(live.uploadState, EvidenceAttachmentUploadState.deleted);
        expect(live.deletedAt?.toUtc(), at);
      },
    );

    test(
      'legacy sync identities persist once without changing business state',
      () async {
        _registerTestAuthUser('owner-a');
        final at = DateTime.utc(2026, 10, 2);
        final nextAttempt = DateTime.utc(2030, 1, 1);
        await db.isar.writeTxn(() async {
          await db.isar.workLogs.put(
            WorkLog()
              ..ownerUserId = 'owner-a'
              ..date = at
              ..type = LogType.work
              ..note = 'legacy work'
              ..isDirty = true
              ..updatedAt = at,
          );
          await db.isar.subscriptions.put(
            Subscription()
              ..ownerUserId = 'owner-a'
              ..name = 'legacy subscription'
              ..syncId = '  '
              ..nextPaymentDate = at
              ..isDirty = true,
          );
          await db.isar.expenseEvidences.put(
            ExpenseEvidence()
              ..ownerUserId = 'owner-a'
              ..projectName = 'legacy project'
              ..evidenceDate = at
              ..isDirty = true
              ..updatedAt = at,
          );
          await db.isar.expenseRecords.put(
            ExpenseRecord()
              ..ownerUserId = 'owner-a'
              ..expenseDate = at
              ..amount = 8
              ..isDirty = true
              ..updatedAt = at,
          );
          await db.isar.projects.put(
            Project()
              ..ownerUserId = 'owner-a'
              ..name = 'legacy project'
              ..createdAt = at
              ..updatedAt = at
              ..isDirty = true,
          );
          for (final owner in ['owner-b', null]) {
            await db.isar.workLogs.put(
              WorkLog()
                ..ownerUserId = owner
                ..date = at
                ..type = LogType.work
                ..isDirty = true,
            );
          }
          await db.isar.projects.put(
            Project()
              ..ownerUserId = 'owner-a'
              ..name = 'photo only'
              ..createdAt = at
              ..updatedAt = at,
          );
          for (final entity in [
            'work_log',
            'subscription',
            'evidence',
            'expense_record',
            'project',
          ]) {
            await db.isar.syncQueueRecords.put(
              SyncQueueRecord()
                ..entityName = entity
                ..entityKey = 'owner-a:local:1'
                ..attemptCount = 4
                ..nextAttemptAt = nextAttempt
                ..lastAttemptAt = at
                ..lastError = 'lost response',
            );
          }
          await db.isar.syncQueueRecords.put(
            SyncQueueRecord()
              ..entityName = 'work_log'
              ..entityKey = 'owner-b:local:1'
              ..attemptCount = 2
              ..nextAttemptAt = nextAttempt,
          );
        });
        final context = SyncRunContext(
          ownerId: 'owner-a',
          sessionEpoch: 1,
          databaseGeneration: db.databaseGeneration,
          runId: 1,
          isCurrent: () => true,
        );
        Future<Map<String, dynamic>> readPending() async => {
          'work_log': (await db.getPendingLogsForSync(context: context)).single,
          'subscription': (await db.getPendingSubscriptionsForSync(
            context: context,
          )).single,
          'evidence': (await db.getPendingEvidenceForSync(
            context: context,
          )).single,
          'expense_record': (await db.getPendingExpenseRecordsForSync(
            context: context,
          )).single,
          'project': (await db.getPendingProjectsForSync(
            context: context,
          )).single,
        };
        final first = await readPending();
        final second = await readPending();
        final queue = IsarSyncQueue(db.database);
        for (final entry in first.entries) {
          final dynamic row = entry.value;
          final dynamic reread = second[entry.key];
          expect(row.syncId, isNotEmpty);
          expect(reread.syncId, row.syncId);
          expect(row.isDirty, isTrue);
          if (entry.key != 'subscription') {
            expect(row.updatedAt?.toUtc(), at);
          }
          final key = 'owner-a:sync:${row.syncId}';
          final retry = (await queue.peek(entry.key, key))!;
          expect(retry.attemptCount, 4);
          expect(retry.nextAttemptAt.toUtc(), nextAttempt);
          expect(retry.lastAttemptAt?.toUtc(), at);
          expect(retry.lastError, 'lost response');
          expect(await queue.peek(entry.key, 'owner-a:local:1'), isNull);
          expect(await queue.canAttempt(entry.key, key), isFalse);
          await queue.recordSuccess(entry.key, key);
          expect(await queue.peek(entry.key, key), isNull);
        }
        expect((await db.isar.workLogs.get(1))!.note, 'legacy work');
        expect((await db.isar.workLogs.get(2))!.syncId, isNull);
        expect((await db.isar.workLogs.get(3))!.syncId, isNull);
        expect((await db.isar.projects.get(2))!.syncId, isNull);
        expect(
          (await queue.peek('work_log', 'owner-b:local:1'))!.attemptCount,
          2,
        );
      },
    );

    test('retry-key migration keeps the strongest existing backoff', () async {
      _registerTestAuthUser('owner-a');
      final at = DateTime.utc(2026, 10, 2);
      await db.isar.writeTxn(() async {
        await db.isar.workLogs.put(
          WorkLog()
            ..ownerUserId = 'owner-a'
            ..syncId = 'existing-identity'
            ..date = at
            ..type = LogType.work
            ..isDirty = true,
        );
        await db.isar.syncQueueRecords.put(
          SyncQueueRecord()
            ..entityName = 'work_log'
            ..entityKey = 'owner-a:local:1'
            ..attemptCount = 5
            ..lastAttemptAt = at.add(const Duration(minutes: 1))
            ..nextAttemptAt = DateTime.utc(2030, 1, 1)
            ..lastError = 'newer failure',
        );
        await db.isar.syncQueueRecords.put(
          SyncQueueRecord()
            ..entityName = 'work_log'
            ..entityKey = 'owner-a:sync:existing-identity'
            ..attemptCount = 2
            ..lastAttemptAt = at
            ..nextAttemptAt = DateTime.utc(2029, 1, 1)
            ..lastError = 'older failure',
        );
      });

      await db.getPendingLogsForSync();

      final entries = await IsarSyncQueue(db.database).pendingEntries();
      expect(entries, hasLength(1));
      expect(entries.single.entityKey, 'owner-a:sync:existing-identity');
      expect(entries.single.attemptCount, 5);
      expect(entries.single.nextAttemptAt.toUtc(), DateTime.utc(2030, 1, 1));
      expect(entries.single.lastError, 'newer failure');
    });

    test(
      'a cancelled remote create retries the same persisted legacy identity',
      () async {
        _registerTestAuthUser('owner-a');
        await db.isar.writeTxn(() async {
          await db.isar.workLogs.put(
            WorkLog()
              ..ownerUserId = 'owner-a'
              ..date = DateTime(2026, 10, 2)
              ..type = LogType.work
              ..isDirty = true,
          );
        });
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final remoteRows = <String, Map<String, dynamic>>{};
        final sentIdentities = <String>[];
        var oldRunCurrent = true;
        var cancelFirstResponse = true;
        final listener = server.listen((request) async {
          final data =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          final syncId = data['sync_id'] as String;
          sentIdentities.add(syncId);
          final remote = remoteRows.putIfAbsent(
            syncId,
            () => {
              'id': 10,
              'sync_id': syncId,
              'version': 0,
              'updated_at': '2026-10-02T00:00:00Z',
            },
          );
          remote['version'] = (remote['version'] as int) + 1;
          if (cancelFirstResponse) {
            cancelFirstResponse = false;
            oldRunCurrent = false;
          }
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode(remote));
          await request.response.close();
        });
        final previousHttpOverrides = HttpOverrides.current;
        HttpOverrides.global = null;
        final client = SupabaseClient(
          'http://127.0.0.1:${server.port}',
          'test-anon-key',
        );
        try {
          final first = WorkLogSyncAdapter(
            client: client,
            dbService: db,
            userId: 'owner-a',
            context: SyncRunContext(
              ownerId: 'owner-a',
              sessionEpoch: 1,
              databaseGeneration: db.databaseGeneration,
              runId: 1,
              isCurrent: () => oldRunCurrent,
            ),
          );
          final initial = (await first.pendingLocalChanges()).single;
          await expectLater(
            first.pushLocalChange(initial),
            throwsA(isA<SyncRunInvalidated>()),
          );
          expect((await db.getWorkLog(initial.id))!.remoteId, isNull);
          final second = WorkLogSyncAdapter(
            client: client,
            dbService: db,
            userId: 'owner-a',
          );
          final retry = (await second.pendingLocalChanges()).single;
          expect(retry.syncId, initial.syncId);

          expect((await second.pushLocalChange(retry)).success, isTrue);

          expect(sentIdentities, [initial.syncId, initial.syncId]);
          expect(remoteRows, hasLength(1));
          expect((await db.getWorkLog(initial.id))!.remoteId, 10);
          expect((await db.getWorkLog(initial.id))!.isDirty, isFalse);
        } finally {
          await client.dispose();
          await server.close(force: true);
          await listener.cancel();
          HttpOverrides.global = previousHttpOverrides;
        }
      },
    );

    test(
      'interrupted attachment uploads remain retryable for the captured owner',
      () async {
        _registerTestAuthUser('owner-a');
        final at = DateTime.utc(2026, 10, 2);
        await db.isar.writeTxn(() async {
          for (final state in EvidenceAttachmentUploadState.values) {
            await db.isar.evidenceAttachments.put(
              EvidenceAttachment()
                ..ownerUserId = 'owner-a'
                ..syncId = state.name
                ..evidenceSyncId = 'evidence-a'
                ..originalFileName = '${state.name}.pdf'
                ..uploadState = state
                ..createdAt = at
                ..updatedAt = at,
            );
          }
          await db.isar.evidenceAttachments.put(
            EvidenceAttachment()
              ..ownerUserId = 'owner-b'
              ..syncId = 'foreign-uploading'
              ..evidenceSyncId = 'evidence-b'
              ..originalFileName = 'foreign.pdf'
              ..uploadState = EvidenceAttachmentUploadState.uploading
              ..createdAt = at
              ..updatedAt = at,
          );
        });
        var current = true;
        final interrupted = SyncRunContext(
          ownerId: 'owner-a',
          sessionEpoch: 1,
          databaseGeneration: db.databaseGeneration,
          runId: 1,
          isCurrent: () => current,
        );
        current = false;
        await expectLater(
          db.getPendingEvidenceAttachmentsForSync(context: interrupted),
          throwsA(isA<SyncRunInvalidated>()),
        );
        final nextRun = SyncRunContext(
          ownerId: 'owner-a',
          sessionEpoch: 3,
          databaseGeneration: db.databaseGeneration,
          runId: 2,
          isCurrent: () => true,
        );

        final retry = await db.getPendingEvidenceAttachmentsForSync(
          context: nextRun,
        );

        expect(
          retry.map((attachment) => attachment.syncId),
          unorderedEquals(['pending', 'uploading', 'failed', 'deleted']),
        );
      },
    );

    test(
      'an attachment pull preserves pending bytes and a selected parent path',
      () async {
        _registerTestAuthUser('owner-a');
        final at = DateTime.utc(2026, 10, 2);
        final pending = EvidenceAttachment()
          ..ownerUserId = 'owner-a'
          ..syncId = 'pending-local'
          ..evidenceSyncId = 'evidence-a'
          ..originalFileName = 'new.pdf'
          ..contentHash = 'new-hash'
          ..localPath = '/local/new.pdf'
          ..createdAt = at
          ..updatedAt = at;
        final parent = ExpenseEvidence()
          ..ownerUserId = 'owner-a'
          ..syncId = 'evidence-a'
          ..projectName = 'Project'
          ..evidenceDate = at
          ..remoteStoragePath = 'owner-a/selected.pdf';
        await db.isar.writeTxn(() async {
          await db.isar.evidenceAttachments.put(pending);
          await db.isar.expenseEvidences.put(parent);
        });
        Map<String, dynamic> remote(String syncId) => {
          'user_id': 'owner-a',
          'sync_id': syncId,
          'evidence_sync_id': 'evidence-a',
          'remote_storage_path': 'owner-a/old.pdf',
          'original_file_name': 'old.pdf',
          'content_hash': 'old-hash',
          'upload_state': 'uploaded',
          'updated_at': '2026-10-01T00:00:00Z',
        };

        await db.syncRemoteEvidenceAttachmentToLocal(remote(pending.syncId));
        await db.syncRemoteEvidenceAttachmentToLocal(remote('remote-old'));

        final live = (await db.isar.evidenceAttachments.get(pending.id))!;
        expect(live.uploadState, EvidenceAttachmentUploadState.pending);
        expect(live.contentHash, 'new-hash');
        expect(live.localPath, '/local/new.pdf');
        expect(
          (await db.isar.expenseEvidences.get(parent.id))!.remoteStoragePath,
          'owner-a/selected.pdf',
        );
      },
    );

    test(
      'a late parent ACK keeps the path made dirty by attachment upload',
      () async {
        final at = DateTime.utc(2026, 10, 2);
        final parent = ExpenseEvidence()
          ..syncId = 'late-parent'
          ..remoteId = 42
          ..remoteVersion = 1
          ..isDirty = true
          ..projectName = 'Project'
          ..evidenceDate = at
          ..localFilePath = '/local/file.pdf';
        final attachment = EvidenceAttachment()
          ..syncId = 'uploaded-child'
          ..evidenceSyncId = parent.syncId!
          ..originalFileName = 'file.pdf'
          ..localPath = parent.localFilePath
          ..createdAt = at
          ..updatedAt = at;
        await db.isar.writeTxn(() async {
          await db.isar.expenseEvidences.put(parent);
          await db.isar.evidenceAttachments.put(attachment);
        });
        final sent = DbService.snapshotEvidence(
          (await db.getEvidence(parent.id))!,
        );

        await db.markEvidenceAttachmentUploaded(
          attachment,
          remoteStoragePath: 'selected/new-object.pdf',
        );
        await db.updateEvidenceRemoteId(
          DbService.snapshotEvidence(sent)..remoteVersion = 2,
          sentSnapshot: sent,
        );

        final live = (await db.getEvidence(parent.id))!;
        expect(live.remoteStoragePath, 'selected/new-object.pdf');
        expect(live.remoteVersion, 2);
        expect(live.isDirty, isTrue);
      },
    );

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
    });

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
    });

    test(
      'deletes a project cascade in one transaction while preserving photos',
      () async {
        final deletedProjectId = await db.addProject(
          Project()
            ..name = 'Alpha'
            ..createdAt = DateTime(2026, 6, 15)
            ..updatedAt = DateTime(2026, 6, 15),
        );
        final survivorProjectId = await db.addProject(
          Project()
            ..name = 'Beta'
            ..createdAt = DateTime(2026, 6, 15)
            ..updatedAt = DateTime(2026, 6, 15),
        );
        final sameNameProjectId = await db.addProject(
          Project()
            ..name = 'Alpha'
            ..createdAt = DateTime(2026, 6, 15)
            ..updatedAt = DateTime(2026, 6, 15),
        );

        final deletedEvidenceId = await db.addEvidence(
          ExpenseEvidence()
            ..projectId = deletedProjectId
            ..projectName = ' Alpha '
            ..evidenceDate = DateTime(2026, 6, 15)
            ..amount = 42,
        );
        final deletedExpenseId = await db.addExpenseRecord(
          ExpenseRecord()
            ..projectId = deletedProjectId
            ..projectName = ' Alpha '
            ..expenseDate = DateTime(2026, 6, 15)
            ..amount = 18,
        );
        final deletedTrip = WorkLog()
          ..date = DateTime(2026, 6, 15)
          ..type = LogType.businessTrip
          ..projectId = deletedProjectId
          ..projectName = ' Alpha '
          ..location = '上海';
        final deletedTripId = await db.addLog(deletedTrip);
        final deletedPhoto = PhotoItem()
          ..createdAt = DateTime(2026, 6, 15)
          ..dateIndexed = DateTime(2026, 6, 15)
          ..fileName = 'alpha.jpg'
          ..filePath = r'C:\LifeLog\alpha.jpg'
          ..projectId = deletedProjectId
          ..projectName = ' Alpha ';
        await db.addPhoto(deletedPhoto);
        final survivorExpenseId = await db.addExpenseRecord(
          ExpenseRecord()
            ..projectId = survivorProjectId
            ..projectName = 'Beta'
            ..expenseDate = DateTime(2026, 6, 15)
            ..amount = 7,
        );
        final sameNameExpenseId = await db.addExpenseRecord(
          ExpenseRecord()
            ..projectId = sameNameProjectId
            ..projectName = 'Alpha'
            ..expenseDate = DateTime(2026, 6, 15)
            ..amount = 9,
        );

        final result = await db.deleteProjectCascade(
          projectId: deletedProjectId,
          projectName: 'Alpha',
        );

        expect(result, isNotNull);
        expect(result!.deletedProject, isNull);
        expect(await db.isar.projects.get(deletedProjectId), isNull);
        expect(await db.isar.expenseEvidences.get(deletedEvidenceId), isNull);
        expect(await db.isar.expenseRecords.get(deletedExpenseId), isNull);

        final trip = await db.isar.workLogs.get(deletedTripId);
        expect(trip, isNotNull);
        expect(trip!.projectId, isNull);
        expect(trip.projectSyncId, isNull);
        expect(trip.projectName, isNull);
        expect(trip.projectStageName, isNull);
        expect(trip.isDirty, isTrue);

        final photo = await db.isar.photoItems.get(deletedPhoto.id);
        expect(photo, isNotNull);
        expect(photo!.projectId, isNull);
        expect(photo.projectName, isNull);
        expect(photo.filePath, r'C:\LifeLog\alpha.jpg');

        expect((await db.isar.projects.get(survivorProjectId))!.name, 'Beta');
        expect(
          (await db.isar.expenseRecords.get(survivorExpenseId))!.amount,
          7,
        );
        expect((await db.isar.projects.get(sameNameProjectId))!.name, 'Alpha');
        expect(
          (await db.isar.expenseRecords.get(sameNameExpenseId))!.amount,
          9,
        );
      },
    );

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
    });

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
    });

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
  final auth = AuthService(storage: _testAuthStorage);
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
