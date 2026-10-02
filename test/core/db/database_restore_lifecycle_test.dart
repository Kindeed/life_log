import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/isar_sync_conflict_store.dart';
import 'package:life_log/core/sync/isar_sync_queue.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/features/sync_center/data/isar_sync_center_repository.dart';
import 'package:life_log/features/work_log/data/work_log_dao.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

import '../../../tool/isar_test_runtime.dart' show initializeTestIsar;

void main() {
  setUpAll(initializeTestIsar);

  test(
    'database holder, existing DAO, queue and watcher reconnect after restore',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'restore_isar_test_',
      );
      final opened = await IsarDatabase.open(
        schemas: DbService.schemas,
        directory: directory.path,
        name: 'restore_${DateTime.now().microsecondsSinceEpoch}',
        inspector: false,
      );
      final db = await DbService().initWithDatabaseForTest(opened);
      final holder = db.database;
      final dao = WorkLogDao(holder);
      final queue = IsarSyncQueue(holder);
      final conflictStore = IsarSyncConflictStore(holder);
      final syncCenter = IsarSyncCenterRepository(
        holder,
        currentOwnerId: () => 'restore-owner',
      );
      final events = StreamIterator<void>(dao.watch());
      final backup = File('${directory.path}/backup.isar');

      try {
        final firstChange = events.moveNext();
        await holder.writeTxn(() async {
          await holder.isar.workLogs.put(_workLog('before backup'));
        });
        expect(await firstChange.timeout(const Duration(seconds: 5)), isTrue);
        await holder.isar.copyToFile(backup.path);
        await queue.recordFailure(
          'work_log',
          'restore-owner:post-backup-retry',
        );
        await conflictStore.record(
          SyncConflictDraft(
            ownerUserId: 'restore-owner',
            entityName: 'work_log',
            entitySyncId: 'post-backup-conflict',
            conflictType: SyncConflictType.updateConflict,
            message: 'post-backup conflict',
          ),
        );
        final secondChange = events.moveNext();
        await holder.writeTxn(() async {
          await holder.isar.workLogs.put(_workLog('after backup'));
        });
        expect(await secondChange.timeout(const Duration(seconds: 5)), isTrue);
        expect(await dao.getAllSorted(), hasLength(2));
        expect(
          (await syncCenter.loadSnapshot()).pendingQueueEntries,
          hasLength(1),
        );
        expect(
          (await syncCenter.loadSnapshot()).unresolvedConflicts,
          hasLength(1),
        );

        final livePath = holder.isar.path!;
        await db.prepareForDatabaseRestore();
        await holder.isar.close();
        await backup.copy(livePath);
        await db.reopenAfterRestore();
        db.finishDatabaseRestore();

        expect(identical(db.database, holder), isTrue);
        expect(holder.isar.isOpen, isTrue);
        expect((await dao.getAllSorted()).single.note, 'before backup');
        expect(await queue.pendingCount(), 0);
        expect(await conflictStore.unresolvedCount(), 0);
        expect((await syncCenter.loadSnapshot()).pendingQueueEntries, isEmpty);
        expect((await syncCenter.loadSnapshot()).unresolvedConflicts, isEmpty);

        // Restore invalidates the existing stream before new writes occur.
        expect(
          await events.moveNext().timeout(const Duration(seconds: 5)),
          isTrue,
        );
        final restoredChange = events.moveNext();
        await holder.writeTxn(() async {
          await holder.isar.workLogs.put(_workLog('write after restore'));
        });
        expect(
          await restoredChange.timeout(const Duration(seconds: 5)),
          isTrue,
        );
        expect(await dao.getAllSorted(), hasLength(2));
        await queue.recordFailure('work_log', 'restore-owner:new-retry');
        expect(await queue.pendingCount(), 1);
        expect(
          (await syncCenter.loadSnapshot()).pendingQueueEntries,
          hasLength(1),
        );
      } finally {
        await events.cancel();
        if (holder.isar.isOpen) await holder.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'restore waits for an accepted write and rejects new writes until resume',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'restore_drain_test_',
      );
      final database = await IsarDatabase.open(
        schemas: DbService.schemas,
        directory: directory.path,
        name: 'drain_${DateTime.now().microsecondsSinceEpoch}',
        inspector: false,
      );
      final started = Completer<void>();
      final release = Completer<void>();

      try {
        final write = database.writeTxn(() async {
          started.complete();
          await release.future;
          await database.isar.workLogs.put(_workLog('accepted write'));
        });
        await started.future;
        var drained = false;
        final prepare = database.prepareForRestore().then(
          (_) => drained = true,
        );
        await expectLater(
          database.writeTxn(() async {
            await database.isar.workLogs.put(_workLog('blocked write'));
          }),
          throwsStateError,
        );
        expect(drained, isFalse);
        release.complete();
        await write;
        await prepare;
        expect(await database.isar.workLogs.count(), 1);

        database.finishRestore();
        await database.writeTxn(() async {
          await database.isar.workLogs.put(_workLog('resumed write'));
        });
        expect(await database.isar.workLogs.count(), 2);
      } finally {
        if (!release.isCompleted) release.complete();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'failed watcher reconnection keeps writes suspended until recovery',
    () async {
      final directory = await Directory.systemTemp.createTemp('restore_watch_');
      final database = await IsarDatabase.open(
        schemas: DbService.schemas,
        directory: directory.path,
        name: 'watch_${DateTime.now().microsecondsSinceEpoch}',
        inspector: false,
      );
      var failWatch = false;
      final subscription = database
          .watch((isar) {
            if (failWatch) throw StateError('watch source unavailable');
            return isar.workLogs.watchLazy();
          })
          .listen((_) {});
      try {
        await database.prepareForRestore();
        failWatch = true;
        expect(database.finishRestore, throwsStateError);
        await expectLater(
          database.writeTxn(() async {
            await database.isar.workLogs.put(
              _workLog('blocked after failed watch'),
            );
          }),
          throwsStateError,
        );
        expect(await database.isar.workLogs.count(), 0);

        failWatch = false;
        await database.prepareForRestore();
        database.finishRestore();
        await database.writeTxn(() async {
          await database.isar.workLogs.put(_workLog('accepted after recovery'));
        });
        expect(await database.isar.workLogs.count(), 1);
      } finally {
        await subscription.cancel();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

WorkLog _workLog(String note) => WorkLog()
  ..date = DateTime(2026, 10, 1)
  ..type = LogType.work
  ..overtimeHours = 0
  ..note = note;
