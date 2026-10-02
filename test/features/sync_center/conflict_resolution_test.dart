import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_conflict_model.dart';
import 'package:life_log/core/sync/sync_queue_record.dart';
import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/sync_center/data/conflict_entity.dart';
import 'package:life_log/features/sync_center/data/isar_sync_center_repository.dart';
import 'package:life_log/features/sync_center/data/sync_conflict_remote_gateway.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../tool/isar_test_runtime.dart' show initializeTestIsar;

final _day = DateTime(2026, 10, 1);
final _updated = DateTime.utc(2026, 10, 1, 10);
const _entities = [
  'work_log',
  'subscription',
  'project',
  'expense_record',
  'evidence',
];
const _pathChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Fixture fixture;
  setUpAll(initializeTestIsar);
  setUp(() async => fixture = await _Fixture.open());
  tearDown(() => fixture.close());

  for (final name in _entities) {
    test(
      '$name: keep local rebases and schedules its existing identity',
      () async {
        final local = await fixture.seed(name);
        final conflict = await fixture.conflict(local);
        await fixture.retry(name, 'owner-a:sync:${local.row.syncId}');
        await fixture.retry(name, 'owner-b:sync:${local.row.syncId}');

        await fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'keep-local',
        );

        final kept = (await fixture.find(local))!;
        expect(_label(kept), 'local');
        expect(kept.row.remoteVersion, 2);
        expect(kept.row.isDirty, isTrue);
        expect(kept.row.pendingDelete, isFalse);
        expect(await fixture.count(name), 1);
        await fixture.expectResolved(conflict, 'keep-local');
        expect(fixture.requests, [(name, local.row.syncId)]);
        final retries = await fixture.database.isar.syncQueueRecords
            .where()
            .findAll();
        expect(retries.single.entityKey, 'owner-b:sync:${local.row.syncId}');
      },
    );

    test(
      '$name: use remote replaces business data in the original row',
      () async {
        final local = await fixture.seed(name);
        final conflict = await fixture.conflict(local);

        await fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'use-remote',
        );

        final replaced = (await fixture.find(local))!;
        expect(_label(replaced), 'remote');
        expect(replaced.row.id, local.row.id);
        expect(replaced.row.syncId, local.row.syncId);
        expect(replaced.row.ownerUserId, 'owner-a');
        expect(replaced.row.remoteVersion, 2);
        expect(replaced.row.isDirty, isFalse);
        expect(replaced.row.pendingDelete, isFalse);
        expect(replaced.row.deletedAt, isNull);
        expect(await fixture.count(name), 1);
        await fixture.expectResolved(conflict, 'use-remote');
        expect(fixture.requests, isEmpty);
      },
    );

    test(
      '$name: copy preserves local data under a fresh sync identity',
      () async {
        final local = await fixture.seed(name);
        final conflict = await fixture.conflict(local);

        await fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'copy',
        );

        final original = (await fixture.find(local))!;
        expect(_label(original), 'remote');
        expect(original.row.isDirty, isFalse);
        final copies = (await fixture.all(
          name,
        )).where((item) => item.row.id != local.row.id);
        final copy = copies.single;
        expect(_label(copy), name == 'project' ? 'local（副本）' : 'local');
        expect(copy.row.ownerUserId, 'owner-a');
        expect(copy.row.syncId, isNot(local.row.syncId));
        expect(copy.row.syncId, isNotEmpty);
        expect(copy.row.remoteId, isNull);
        expect(copy.row.remoteVersion, 0);
        expect(copy.row.isDirty, isTrue);
        expect(copy.row.deletedAt, isNull);
        expect(copy.row.pendingDelete, isFalse);
        await fixture.expectResolved(conflict, 'copy');
        expect(fixture.requests, [(name, local.row.syncId)]);
      },
    );
  }

  test(
    'project copy relinks non-photo children and preserves original media',
    () async {
      final projectEntity = await fixture.seed('project');
      final project = projectEntity.value as Project;
      project
        ..localCoverPath = '${fixture.directory.path}/cover.jpg'
        ..coverImagePath = '${fixture.directory.path}/photo.jpg';
      final trip =
          (await fixture.seed('work_log', syncId: 'trip')).value as WorkLog;
      trip
        ..type = LogType.businessTrip
        ..projectId = project.id
        ..projectSyncId = project.syncId
        ..projectName = project.name;
      final expense =
          (await fixture.seed('expense_record')).value as ExpenseRecord;
      expense
        ..projectId = project.id
        ..projectSyncId = project.syncId
        ..projectName = project.name
        ..tripWorkLogId = trip.id
        ..tripWorkLogSyncId = trip.syncId;
      final evidence =
          (await fixture.seed('evidence')).value as ExpenseEvidence;
      evidence
        ..projectId = project.id
        ..projectSyncId = project.syncId
        ..projectName = project.name;
      final foreign =
          (await fixture.seed(
                'work_log',
                syncId: 'foreign-trip',
                owner: 'owner-b',
              )).value
              as WorkLog;
      foreign
        ..projectId = project.id
        ..projectSyncId = project.syncId;
      final photo = PhotoItem()
        ..ownerUserId = 'owner-a'
        ..filePath = project.coverImagePath!
        ..fileName = 'photo.jpg'
        ..projectId = project.id
        ..projectName = project.name
        ..createdAt = _updated
        ..dateIndexed = _day;
      await fixture.database.writeTxn(() async {
        await fixture.database.isar.projects.put(project);
        await fixture.database.isar.workLogs.putAll([trip, foreign]);
        await fixture.database.isar.expenseRecords.put(expense);
        await fixture.database.isar.expenseEvidences.put(evidence);
        await fixture.database.isar.photoItems.put(photo);
      });
      final conflict = await fixture.conflict(projectEntity);

      await fixture.repository.resolveConflict(conflict.id, resolution: 'copy');

      final copiedProject =
          (await fixture.all(
                'project',
              )).singleWhere((item) => item.row.id != project.id).value
              as Project;
      expect(copiedProject.localCoverPath, isNull);
      expect(copiedProject.coverImagePath, isNull);
      final copiedTrip =
          (await fixture.all('work_log'))
                  .singleWhere((item) => item.row.projectId == copiedProject.id)
                  .value
              as WorkLog;
      expect(copiedTrip.projectSyncId, copiedProject.syncId);
      expect(copiedTrip.projectName, copiedProject.name);
      final copiedExpense =
          (await fixture.all('expense_record'))
                  .singleWhere((item) => item.row.projectId == copiedProject.id)
                  .value
              as ExpenseRecord;
      expect(copiedExpense.tripWorkLogId, copiedTrip.id);
      expect(copiedExpense.tripWorkLogSyncId, copiedTrip.syncId);
      expect(copiedExpense.projectSyncId, copiedProject.syncId);
      final copiedEvidence = (await fixture.all(
        'evidence',
      )).singleWhere((item) => item.row.projectId == copiedProject.id);
      expect(copiedEvidence.row.projectSyncId, copiedProject.syncId);
      expect(await fixture.count('work_log'), 3);
      expect(await fixture.count('expense_record'), 2);
      expect(await fixture.count('evidence'), 2);
      expect(
        (await fixture.database.isar.photoItems.where().findAll()).single.id,
        photo.id,
      );
      expect(
        (await fixture.database.isar.photoItems.get(photo.id))!.projectId,
        project.id,
      );
      expect(
        (await fixture.database.isar.projects.get(project.id))!.localCoverPath,
        project.localCoverPath,
      );
    },
  );

  test('work log copy relinks only its own active expense records', () async {
    final log = await fixture.seed('work_log');
    final expense =
        (await fixture.seed('expense_record')).value as ExpenseRecord;
    expense
      ..tripWorkLogId = log.row.id as int
      ..tripWorkLogSyncId = log.row.syncId as String;
    await fixture.database.writeTxn(
      () => fixture.database.isar.expenseRecords.put(expense),
    );
    final conflict = await fixture.conflict(log);

    await fixture.repository.resolveConflict(conflict.id, resolution: 'copy');

    final copy = (await fixture.all(
      'work_log',
    )).singleWhere((item) => item.row.id != log.row.id);
    final expenses = await fixture.database.isar.expenseRecords
        .where()
        .findAll();
    final copiedExpense = expenses.singleWhere((item) => item.id != expense.id);
    expect(copiedExpense.tripWorkLogId, copy.row.id);
    expect(copiedExpense.tripWorkLogSyncId, copy.row.syncId);
    expect(copiedExpense.syncId, isNot(expense.syncId));
    expect(copiedExpense.isDirty, isTrue);
  });

  test(
    'evidence copy owns independent bytes and independent pending attachment',
    () async {
      final entity = await fixture.seed('evidence');
      final evidence = entity.value as ExpenseEvidence;
      final source = File('${fixture.directory.path}/receipt.pdf');
      await source.writeAsBytes([1, 2, 3, 4]);
      evidence
        ..localFilePath = source.path
        ..remoteStoragePath = 'owner-a/original/receipt.pdf'
        ..fileName = 'receipt.pdf';
      final attachment = _attachment(evidence, source.path);
      await fixture.database.writeTxn(() async {
        await fixture.database.isar.expenseEvidences.put(evidence);
        await fixture.database.isar.evidenceAttachments.put(attachment);
      });
      final conflict = await fixture.conflict(entity);

      await fixture.repository.resolveConflict(conflict.id, resolution: 'copy');

      final copy =
          (await fixture.all(
                'evidence',
              )).singleWhere((item) => item.row.id != evidence.id).value
              as ExpenseEvidence;
      expect(copy.localFilePath, isNot(source.path));
      expect(await File(copy.localFilePath!).readAsBytes(), [1, 2, 3, 4]);
      expect(await source.readAsBytes(), [1, 2, 3, 4]);
      expect(copy.remoteStoragePath, isNull);
      final copiedAttachment =
          (await fixture.database.isar.evidenceAttachments.where().findAll())
              .singleWhere((item) => item.evidenceSyncId == copy.syncId);
      expect(copiedAttachment.syncId, isNot(attachment.syncId));
      expect(copiedAttachment.evidenceLocalId, copy.id);
      expect(copiedAttachment.localPath, copy.localFilePath);
      expect(copiedAttachment.remoteStoragePath, isNull);
      expect(
        copiedAttachment.uploadState,
        EvidenceAttachmentUploadState.pending,
      );
      final retired = (await fixture.database.isar.evidenceAttachments.get(
        attachment.id,
      ))!;
      expect(retired.uploadState, EvidenceAttachmentUploadState.deleted);
      expect(retired.deletedAt, isNotNull);
      await File(copy.localFilePath!).delete();
      expect(await source.exists(), isTrue);
    },
  );

  for (final state in [
    EvidenceAttachmentUploadState.pending,
    EvidenceAttachmentUploadState.uploading,
  ]) {
    test(
      'choose remote retires $state bytes and rejects late upload/pull',
      () async {
        final entity = await fixture.seed('evidence');
        final evidence = entity.value as ExpenseEvidence;
        final source = File('${fixture.directory.path}/discarded-local.pdf');
        await source.writeAsBytes([11, 12]);
        evidence
          ..localFilePath = source.path
          ..remoteStoragePath = 'owner-a/old/receipt.pdf';
        final staleUpload = _attachment(evidence, source.path)
          ..uploadState = state;
        await fixture.database.writeTxn(() async {
          await fixture.database.isar.expenseEvidences.put(evidence);
          await fixture.database.isar.evidenceAttachments.put(staleUpload);
        });
        final conflict = await fixture.conflict(entity);
        final db = await fixture.openDbService();

        await fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'use-remote',
        );

        final retired = (await fixture.database.isar.evidenceAttachments.get(
          staleUpload.id,
        ))!;
        expect(retired.uploadState, EvidenceAttachmentUploadState.deleted);
        expect(retired.deletedAt, isNotNull);
        expect(await source.readAsBytes(), [11, 12]);
        expect(fixture.requests, [('evidence', evidence.syncId)]);
        await db.markEvidenceAttachmentUploaded(
          staleUpload,
          remoteStoragePath: 'owner-a/old/receipt.pdf',
          context: fixture.repository.captureContext!(),
        );
        for (final remoteAttachmentSyncId in [
          staleUpload.syncId,
          'another-old-remote-upload',
        ]) {
          await db.syncRemoteEvidenceAttachmentToLocal({
            'user_id': 'owner-a',
            'sync_id': remoteAttachmentSyncId,
            'evidence_sync_id': evidence.syncId,
            'remote_storage_path': 'owner-a/old/receipt.pdf',
            'original_file_name': 'old.pdf',
            'upload_state': 'uploaded',
            'updated_at': _updated.toIso8601String(),
          }, context: fixture.repository.captureContext!());
        }

        final selected = (await fixture.find(entity))!.value as ExpenseEvidence;
        expect(selected.remoteStoragePath, 'owner-a/remote/receipt.pdf');
        expect(selected.fileName, 'remote.pdf');
        expect(selected.isDirty, isFalse);
        expect(selected.localFilePath, isNull);
        expect(
          (await fixture.database.isar.evidenceAttachments.get(
            staleUpload.id,
          ))!.uploadState,
          EvidenceAttachmentUploadState.deleted,
        );
        await fixture.expectResolved(conflict, 'use-remote');
      },
    );
  }

  test(
    'same remote path discards unuploaded local bytes without deleting selected object',
    () async {
      final entity = await fixture.seed('evidence');
      final evidence = entity.value as ExpenseEvidence;
      final source = File('${fixture.directory.path}/changed-local.pdf');
      await source.writeAsBytes([88, 99]);
      evidence
        ..localFilePath = source.path
        ..remoteStoragePath = 'owner-a/remote/receipt.pdf';
      final attachment = _attachment(evidence, source.path)
        ..uploadState = EvidenceAttachmentUploadState.pending;
      await fixture.database.writeTxn(() async {
        await fixture.database.isar.expenseEvidences.put(evidence);
        await fixture.database.isar.evidenceAttachments.put(attachment);
      });
      final conflict = await fixture.conflict(entity);

      await fixture.repository.resolveConflict(
        conflict.id,
        resolution: 'use-remote',
      );

      final selected = (await fixture.find(entity))!.value as ExpenseEvidence;
      final kept = (await fixture.database.isar.evidenceAttachments.get(
        attachment.id,
      ))!;
      expect(selected.remoteStoragePath, 'owner-a/remote/receipt.pdf');
      expect(selected.localFilePath, isNull);
      expect(kept.remoteStoragePath, selected.remoteStoragePath);
      expect(kept.uploadState, EvidenceAttachmentUploadState.uploaded);
      expect(kept.deletedAt, isNull);
      expect(kept.localPath, isNull);
      expect(await source.readAsBytes(), [88, 99]);
      expect(fixture.requests, isEmpty);
    },
  );

  test(
    'missing evidence bytes rolls back copy and keeps conflict unresolved',
    () async {
      final entity = await fixture.seed('evidence');
      (entity.value as ExpenseEvidence).remoteStoragePath =
          'owner-a/remote/receipt.pdf';
      await fixture.database.writeTxn(() => entity.put(fixture.database.isar));
      final conflict = await fixture.conflict(entity);

      await expectLater(
        fixture.repository.resolveConflict(conflict.id, resolution: 'copy'),
        throwsStateError,
      );

      expect(await fixture.count('evidence'), 1);
      expect(_label((await fixture.find(entity))!), 'local');
      await fixture.expectUnresolved(conflict);
    },
  );

  test(
    'remote decoding failure rolls back copied files and business rows',
    () async {
      final entity = await fixture.seed('evidence');
      final evidence = entity.value as ExpenseEvidence;
      final source = File('${fixture.directory.path}/rollback-receipt.pdf');
      await source.writeAsBytes([5, 6, 7]);
      evidence
        ..localFilePath = source.path
        ..remoteStoragePath = 'owner-a/old/receipt.pdf';
      await fixture.database.writeTxn(() => entity.put(fixture.database.isar));
      final conflict = await fixture.conflict(entity);
      fixture.remote.row!['amount'] = 'invalid amount';

      await expectLater(
        fixture.repository.resolveConflict(conflict.id, resolution: 'copy'),
        throwsStateError,
      );

      expect(await fixture.count('evidence'), 1);
      expect(_label((await fixture.find(entity))!), 'local');
      expect(await source.readAsBytes(), [5, 6, 7]);
      expect(
        await fixture.directory
            .list()
            .where((file) => file.path.contains('conflict-copy-'))
            .toList(),
        isEmpty,
      );
      await fixture.expectUnresolved(conflict);
    },
  );

  test('remote relations relink to the active owner local project', () async {
    final project =
        (await fixture.seed('project', syncId: 'linked-project')).value
            as Project;
    await fixture.seed('project', syncId: 'linked-project', owner: 'owner-b');
    final entity = await fixture.seed('work_log');
    final conflict = await fixture.conflict(entity);
    fixture.remote.row!
      ..['project_sync_id'] = project.syncId
      ..['linked_project_name'] = 'remote stale project name';

    await fixture.repository.resolveConflict(
      conflict.id,
      resolution: 'use-remote',
    );

    final replaced = (await fixture.find(entity))!.value as WorkLog;
    expect(replaced.projectId, project.id);
    expect(replaced.projectSyncId, project.syncId);
    expect(replaced.projectName, project.name);
  });

  test(
    'network failure leaves local row and conflict available for retry',
    () async {
      final entity = await fixture.seed('project');
      final conflict = await fixture.conflict(entity);
      fixture.remote.onFetch = () async =>
          throw const SocketException('offline');

      await expectLater(
        fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'keep-local',
        ),
        throwsA(isA<SocketException>()),
      );

      expect(_label((await fixture.find(entity))!), 'local');
      expect((await fixture.find(entity))!.row.remoteVersion, 1);
      expect(fixture.requests, isEmpty);
      await fixture.expectUnresolved(conflict);
    },
  );

  test('remote tombstone retains original local photos and cover', () async {
    final entity = await fixture.seed('project');
    final project = entity.value as Project;
    final cover = File('${fixture.directory.path}/cover.jpg');
    await cover.writeAsBytes([9, 8, 7]);
    project.localCoverPath = cover.path;
    await fixture.database.writeTxn(() => entity.put(fixture.database.isar));
    final conflict = await fixture.conflict(entity);
    fixture.remote.row!['deleted_at'] = _updated.toIso8601String();

    await fixture.repository.resolveConflict(
      conflict.id,
      resolution: 'use-remote',
    );

    final tombstone = (await fixture.find(entity))!;
    expect((tombstone.row.deletedAt as DateTime).toUtc(), _updated);
    expect(tombstone.row.isDirty, isFalse);
    expect(tombstone.row.pendingDelete, isFalse);
    expect(tombstone.row.localCoverPath, cover.path);
    expect(await cover.readAsBytes(), [9, 8, 7]);
    await fixture.expectResolved(conflict, 'use-remote');
  });

  test(
    'local tombstone keep-local preserves deliberate delete intent',
    () async {
      final entity = await fixture.seed('work_log');
      entity.row
        ..pendingDelete = true
        ..deletedAt = _updated;
      await fixture.database.writeTxn(() => entity.put(fixture.database.isar));
      final conflict = await fixture.conflict(entity);

      await fixture.repository.resolveConflict(
        conflict.id,
        resolution: 'keep-local',
      );

      final kept = (await fixture.find(entity))!;
      expect(kept.row.pendingDelete, isTrue);
      expect((kept.row.deletedAt as DateTime).toUtc(), _updated);
      expect(kept.row.remoteVersion, 2);
      expect(kept.row.isDirty, isTrue);
    },
  );

  test(
    'owner B cannot resolve owner A conflict or fetch its remote row',
    () async {
      final entity = await fixture.seed('subscription');
      final conflict = await fixture.conflict(entity);
      fixture.owner = 'owner-b';

      await expectLater(
        fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'use-remote',
        ),
        throwsStateError,
      );

      expect(fixture.remote.fetchCount, 0);
      expect(_label((await fixture.find(entity))!), 'local');
      await fixture.expectUnresolved(conflict);
    },
  );

  test(
    'foreign remote owner leaves local row and conflict untouched',
    () async {
      final entity = await fixture.seed('subscription');
      final conflict = await fixture.conflict(entity);
      fixture.remote.row!['user_id'] = 'owner-b';

      await expectLater(
        fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'use-remote',
        ),
        throwsStateError,
      );

      expect(_label((await fixture.find(entity))!), 'local');
      await fixture.expectUnresolved(conflict);
    },
  );

  test(
    'new server version requires a refreshed conflict before overwriting',
    () async {
      final entity = await fixture.seed('expense_record');
      final conflict = await fixture.conflict(entity);
      fixture.remote.row!['version'] = 3;

      await expectLater(
        fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'keep-local',
        ),
        throwsStateError,
      );

      final kept = (await fixture.find(entity))!;
      expect(kept.row.remoteVersion, 1);
      expect(_label(kept), 'local');
      expect(fixture.requests, isEmpty);
      await fixture.expectUnresolved(conflict);
    },
  );

  test(
    'session invalidation during fetch leaves the conflict unresolved',
    () async {
      final entity = await fixture.seed('project');
      final conflict = await fixture.conflict(entity);
      fixture.remote.onFetch = () async => fixture.current = false;

      await expectLater(
        fixture.repository.resolveConflict(conflict.id, resolution: 'copy'),
        throwsA(isA<SyncRunInvalidated>()),
      );

      expect(await fixture.count('project'), 1);
      expect(_label((await fixture.find(entity))!), 'local');
      await fixture.expectUnresolved(conflict);
    },
  );

  test(
    'edit while remote fetch is pending survives and blocks resolution',
    () async {
      final entity = await fixture.seed('work_log');
      final conflict = await fixture.conflict(entity);
      final entered = Completer<void>();
      final release = Completer<void>();
      fixture.remote.onFetch = () async {
        entered.complete();
        await release.future;
      };
      final resolving = fixture.repository.resolveConflict(
        conflict.id,
        resolution: 'use-remote',
      );
      final rejection = expectLater(resolving, throwsStateError);
      await entered.future;
      final edited = (await fixture.find(entity))!.value as WorkLog;
      edited
        ..note = 'edited during fetch'
        ..updatedAt = _updated.add(const Duration(seconds: 1));
      await fixture.database.writeTxn(
        () => fixture.database.isar.workLogs.put(edited),
      );
      release.complete();
      await rejection;

      expect(
        ((await fixture.find(entity))!.value as WorkLog).note,
        'edited during fetch',
      );
      await fixture.expectUnresolved(conflict);
    },
  );

  test(
    'snapshot scopes legacy conflicts by entity owner and retries by owner key',
    () async {
      final owned = await fixture.seed('work_log', syncId: 'owned');
      final foreign = await fixture.seed(
        'project',
        owner: 'owner-b',
        syncId: 'foreign',
      );
      final legacyOwned = await fixture.conflict(owned, persistedOwner: false);
      await fixture.conflict(foreign, persistedOwner: false);
      await fixture.retry('work_log', 'owner-a:sync:owned');
      await fixture.retry('project', 'owner-b:sync:foreign');
      await fixture.retry('work_log', 'unknown-old-key');

      final snapshot = await fixture.repository.loadSnapshot();

      expect(snapshot.unresolvedConflicts.single.id, legacyOwned.id);
      expect(
        snapshot.pendingQueueEntries.single.entityKey,
        'owner-a:sync:owned',
      );
    },
  );

  test(
    'same-value local edit and revert invalidates an earlier remote choice',
    () async {
      final entity = await fixture.seed('subscription');
      final conflict = await fixture.conflict(entity);
      fixture.remote.onFetch = () async {
        final item = (await fixture.find(entity))!.value as Subscription;
        item.name = 'intermediate edit';
        await fixture.database.writeTxn(
          () => fixture.database.isar.subscriptions.put(item),
        );
        fixture.mutationRevision++;
        item.name = 'local';
        await fixture.database.writeTxn(
          () => fixture.database.isar.subscriptions.put(item),
        );
        fixture.mutationRevision++;
      };

      await expectLater(
        fixture.repository.resolveConflict(
          conflict.id,
          resolution: 'use-remote',
        ),
        throwsStateError,
      );

      expect(_label((await fixture.find(entity))!), 'local');
      expect((await fixture.find(entity))!.row.isDirty, isTrue);
      await fixture.expectUnresolved(conflict);
    },
  );
}

final class _Fixture {
  final Directory directory;
  final IsarDatabase database;
  final _Remote remote = _Remote();
  final List<(String, String)> requests = [];
  String owner = 'owner-a';
  bool current = true;
  int mutationRevision = 0;
  SupabaseClient? _client;
  AuthService? _auth;
  late final repository = IsarSyncCenterRepository(
    database,
    currentOwnerId: () => owner,
    captureContext: () {
      final captured = owner;
      return SyncRunContext(
        ownerId: captured,
        sessionEpoch: 1,
        databaseGeneration: 1,
        runId: 1,
        isCurrent: () => current && owner == captured,
      );
    },
    remoteGateway: remote,
    currentMutationRevision: (_, _) => mutationRevision,
    requestSync: (entity, key) async => requests.add((entity, key)),
  );

  _Fixture(this.directory, this.database);

  static Future<_Fixture> open() async {
    final directory = await Directory.systemTemp.createTemp(
      'conflict_resolution_',
    );
    final database = await IsarDatabase.open(
      schemas: DbService.schemas,
      directory: directory.path,
      name: 'conflict_${DateTime.now().microsecondsSinceEpoch}',
      inspector: false,
    );
    return _Fixture(directory, database);
  }

  Future<void> close() async {
    final auth = _auth;
    if (auth != null) {
      await serviceLocator.unregister<AuthService>();
      auth.dispose();
      await _client!.dispose();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathChannel, null);
    await database.close();
    await directory.delete(recursive: true);
  }

  Future<DbService> openDbService() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathChannel, (_) async => directory.path);
    final storage = GetStorage(
      'conflict_auth_${DateTime.now().microsecondsSinceEpoch}',
      directory.path,
    );
    await storage.initStorage;
    final client = SupabaseClient('https://example.supabase.co', 'test-key');
    final auth = AuthService(client: client, storage: storage);
    auth.currentUser.value = User(
      id: owner,
      appMetadata: const {},
      userMetadata: null,
      aud: 'authenticated',
      createdAt: '2026-10-01T00:00:00Z',
    );
    _client = client;
    _auth = auth;
    serviceLocator.registerSingleton<AuthService>(auth);
    return DbService().initWithDatabaseForTest(database, runBackfills: false);
  }

  Future<ConflictEntity> seed(
    String name, {
    String? syncId,
    String owner = 'owner-a',
  }) async {
    final Object value = switch (name) {
      'work_log' =>
        WorkLog()
          ..date = _day
          ..type = LogType.work
          ..overtimeHours = 1
          ..note = 'local'
          ..createdAt = _updated
          ..updatedAt = _updated,
      'subscription' =>
        Subscription()
          ..name = 'local'
          ..price = 10
          ..nextPaymentDate = _day,
      'project' =>
        Project()
          ..name = 'local'
          ..stageNames = ['local stage']
          ..createdAt = _updated
          ..updatedAt = _updated,
      'expense_record' =>
        ExpenseRecord()
          ..expenseDate = _day
          ..amount = 10
          ..note = 'local'
          ..createdAt = _updated
          ..updatedAt = _updated,
      'evidence' =>
        ExpenseEvidence()
          ..projectName = 'local project'
          ..evidenceDate = _day
          ..amount = 10
          ..note = 'local'
          ..createdAt = _updated
          ..updatedAt = _updated,
      _ => throw ArgumentError(name),
    };
    final entity = ConflictEntity(name, value);
    entity.row
      ..ownerUserId = owner
      ..syncId = syncId ?? '$name-local'
      ..remoteId = 101
      ..remoteVersion = 1
      ..isDirty = true;
    await database.writeTxn(() => entity.put(database.isar));
    return entity;
  }

  Future<SyncConflictRecord> conflict(
    ConflictEntity entity, {
    bool persistedOwner = true,
  }) async {
    final conflict = SyncConflictRecord()
      ..ownerUserId = persistedOwner ? entity.row.ownerUserId as String : null
      ..entityName = entity.name
      ..entitySyncId = entity.row.syncId as String
      ..localId = entity.row.id.toString()
      ..remoteId = '101'
      ..conflictType = 'version-mismatch'
      ..localVersion = 1
      ..remoteVersion = 2
      ..localUpdatedAt = entity.updatedAt
      ..message = 'Changed on another device'
      ..detectedAt = _updated;
    await database.writeTxn(
      () => database.isar.syncConflictRecords.put(conflict),
    );
    remote.row = {
      'id': 101,
      'sync_id': entity.row.syncId,
      'user_id': entity.row.ownerUserId,
      'version': 2,
      'updated_at': _updated.add(const Duration(minutes: 1)).toIso8601String(),
      'created_at': _updated.toIso8601String(),
      'deleted_at': null,
      ...switch (entity.name) {
        'work_log' => {
          'date': '2026-10-02',
          'type': 'work',
          'duration': 3,
          'notes': 'remote',
        },
        'subscription' => {
          'name': 'remote',
          'price': 20,
          'next_due_date': '2026-10-02',
        },
        'project' => {
          'name': 'remote',
          'stage_names': ['remote stage'],
        },
        'expense_record' => {
          'expense_date': '2026-10-02',
          'amount': 20,
          'note': 'remote',
        },
        'evidence' => {
          'project_name': 'remote project',
          'evidence_date': '2026-10-02',
          'amount': 20,
          'note': 'remote',
          'remote_storage_path': 'owner-a/remote/receipt.pdf',
          'file_name': 'remote.pdf',
        },
        _ => throw ArgumentError(entity.name),
      },
    };
    return conflict;
  }

  Future<ConflictEntity?> find(ConflictEntity entity) =>
      ConflictEntity.find(database.isar, entity.name, entity.row.id as int);

  Future<List<ConflictEntity>> all(String name) async {
    final List<Object> items = switch (name) {
      'work_log' => await database.isar.workLogs.where().findAll(),
      'subscription' => await database.isar.subscriptions.where().findAll(),
      'project' => await database.isar.projects.where().findAll(),
      'expense_record' => await database.isar.expenseRecords.where().findAll(),
      'evidence' => await database.isar.expenseEvidences.where().findAll(),
      _ => throw ArgumentError(name),
    };
    return items.map((item) => ConflictEntity(name, item)).toList();
  }

  Future<int> count(String name) async => (await all(name)).length;

  Future<void> retry(String name, String key) => database.writeTxn(() async {
    await database.isar.syncQueueRecords.put(
      SyncQueueRecord()
        ..entityName = name
        ..entityKey = key
        ..attemptCount = 1
        ..nextAttemptAt = _updated,
    );
  });

  Future<void> expectResolved(
    SyncConflictRecord conflict,
    String action,
  ) async {
    final actual = (await database.isar.syncConflictRecords.get(conflict.id))!;
    expect(actual.resolvedAt, isNotNull);
    expect(actual.resolution, action);
    expect(actual.ownerUserId, 'owner-a');
  }

  Future<void> expectUnresolved(SyncConflictRecord conflict) async {
    final actual = (await database.isar.syncConflictRecords.get(conflict.id))!;
    expect(actual.resolvedAt, isNull);
    expect(actual.resolution, isNull);
  }
}

final class _Remote implements SyncConflictRemoteGateway {
  Map<String, dynamic>? row;
  Future<void> Function()? onFetch;
  int fetchCount = 0;

  @override
  Future<Map<String, dynamic>?> fetch({
    required SyncRunContext context,
    required String table,
    required String syncId,
  }) async {
    fetchCount++;
    await onFetch?.call();
    return row == null ? null : Map<String, dynamic>.from(row!);
  }
}

String _label(ConflictEntity entity) => switch (entity.value) {
  WorkLog item => item.note!,
  Subscription item => item.name,
  Project item => item.name,
  ExpenseRecord item => item.note!,
  ExpenseEvidence item => item.note!,
  _ => throw ArgumentError(entity.name),
};

EvidenceAttachment _attachment(ExpenseEvidence evidence, String path) =>
    EvidenceAttachment()
      ..ownerUserId = 'owner-a'
      ..syncId = 'original-attachment'
      ..evidenceSyncId = evidence.syncId!
      ..evidenceLocalId = evidence.id
      ..localPath = path
      ..remoteStoragePath = evidence.remoteStoragePath
      ..originalFileName = 'receipt.pdf'
      ..contentHash = 'example-content-hash'
      ..sizeBytes = 4
      ..mimeType = 'application/pdf'
      ..uploadState = EvidenceAttachmentUploadState.uploaded
      ..createdAt = _updated
      ..updatedAt = _updated;
