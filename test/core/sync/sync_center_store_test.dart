import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/isar_sync_conflict_store.dart';
import 'package:life_log/core/sync/isar_sync_queue.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_queue.dart';

import '../../../tool/isar_test_runtime.dart' show initializeTestIsar;

void main() {
  setUpAll(() async {
    await initializeTestIsar();
  });

  group('Sync center stores', () {
    test(
      'IsarSyncQueue lists pending entries and scopes lookup by entity name',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'life_log_sync_center_queue_test_',
        );
        final database = await IsarDatabase.open(
          schemas: DbService.schemas,
          directory: tempDir.path,
          name: 'sync_center_queue_${DateTime.now().microsecondsSinceEpoch}',
        );
        final clock = _MutableClock(DateTime.utc(2026, 6, 21));

        try {
          final queue = IsarSyncQueue(
            database,
            clock: clock,
            baseDelay: const Duration(minutes: 1),
          );
          await queue.recordFailure('work_log', 'same-key', error: 'offline');
          await queue.recordFailure('project', 'same-key', error: 'conflict');

          final pending = await queue.pendingEntries();
          expect(pending.map((entry) => entry.entityName).toSet(), {
            'work_log',
            'project',
          });
          expect(await queue.peek('work_log', 'same-key'), isNotNull);
          expect(await queue.peek('project', 'same-key'), isNotNull);

          await queue.recordSuccess('work_log', 'same-key');
          expect(await queue.peek('work_log', 'same-key'), isNull);
          expect(await queue.peek('project', 'same-key'), isNotNull);
        } finally {
          await database.isar.close(deleteFromDisk: true);
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'IsarSyncConflictStore lists and resolves unresolved conflicts',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'life_log_sync_center_conflict_test_',
        );
        final database = await IsarDatabase.open(
          schemas: DbService.schemas,
          directory: tempDir.path,
          name: 'sync_center_conflict_${DateTime.now().microsecondsSinceEpoch}',
        );

        try {
          final store = IsarSyncConflictStore(database);
          await store.record(
            SyncConflictDraft(
              entityName: 'work_log',
              entitySyncId: 'sync-1',
              conflictType: SyncConflictType.updateConflict,
              message: 'remote is newer',
              detectedAt: DateTime.utc(2026, 6, 21),
            ),
          );

          final unresolved = await store.unresolvedConflicts();
          expect(unresolved, hasLength(1));
          expect(unresolved.single.entityName, 'work_log');
          expect(await store.unresolvedCount(), 1);

          await store.resolve(unresolved.single.id, resolution: 'keep-local');

          expect(await store.unresolvedConflicts(), isEmpty);
          expect(await store.unresolvedCount(), 0);
        } finally {
          await database.isar.close(deleteFromDisk: true);
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );
  });
}

final class _MutableClock implements SyncClock {
  @override
  DateTime now;

  _MutableClock(this.now);
}
