import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pull cursor policy', () {
    test(
      'SyncEngine stores independent updated_at plus id cursor per adapter',
      () {
        final syncService = File(
          'lib/common/services/sync_service.dart',
        ).readAsStringSync();
        final cursorStore = File(
          'lib/core/sync/get_storage_sync_cursor_store.dart',
        ).readAsStringSync();
        final cursorContract = File(
          'lib/core/sync/sync_cursor_store.dart',
        ).readAsStringSync();
        final engine = File(
          'lib/core/sync/sync_engine.dart',
        ).readAsStringSync();

        expect(
          syncService,
          isNot(contains('String get _lastPullCursorKey')),
          reason: 'Pull cursors must not be one global timestamp per user.',
        );
        expect(syncService, contains('GetStorageSyncCursorStore('));
        expect(syncService, isNot(contains('class _PullCursor')));

        expect(cursorContract, contains('class SyncCursor'));
        expect(cursorContract, contains('DateTime updatedAt'));
        expect(cursorContract, contains('String rowId'));
        expect(
          cursorContract,
          contains('abstract interface class SyncCursorStore'),
        );
        expect(cursorStore, contains(r'sync_cursor_${namespace}_$entityName'));
        expect(cursorStore, contains("split('|')"));
        expect(
          cursorStore,
          contains('SyncCursor(updatedAt: updatedAt, rowId: parts[1])'),
        );
        expect(
          cursorStore,
          contains(r"'${cursor.updatedAt.toIso8601String()}|${cursor.rowId}'"),
        );
        expect(engine, contains('cursorStore.read(adapter.entityName)'));
        expect(
          engine,
          contains('cursorStore.write(adapter.entityName, nextCursor)'),
        );
        expect(engine, contains("final rawUpdatedAt = row['updated_at'];"));
        expect(engine, contains("final rawId = row['id'];"));
      },
    );

    test('legacy single timestamp cursor is not used for adapter pulls', () {
      final source = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(source, contains('last_sync_time'));
      expect(source, contains('Legacy pull skipped; adapters own pull'));
      expect(source, isNot(contains('_legacyLastSyncKey')));
      expect(
        source,
        isNot(contains("_storage.read(_lastSyncKey")),
        reason: 'Legacy pull cursor must not keep being advanced.',
      );
    });

    test('sync adapters order and filter by updated_at plus row id', () {
      final adapterPaths = [
        'lib/features/work_log/sync/work_log_sync_adapter.dart',
        'lib/features/subscription/sync/subscription_sync_adapter.dart',
        'lib/features/project/sync/project_sync_adapter.dart',
        'lib/features/expense/sync/expense_record_sync_adapter.dart',
        'lib/features/evidence/sync/evidence_sync_adapter.dart',
        'lib/features/evidence/sync/evidence_attachment_sync_adapter.dart',
      ];
      final pullPage = File(
        'lib/core/sync/sync_pull_page.dart',
      ).readAsStringSync();

      for (final path in adapterPaths) {
        final source = File(path).readAsStringSync();
        expect(source, contains('SyncPullPage'), reason: path);
        expect(source, contains('pullPage.applyTo(query)'), reason: path);
        expect(
          source,
          contains(".order('updated_at', ascending: true)"),
          reason: path,
        );
        expect(source, contains(".order('id', ascending: true)"), reason: path);
        expect(source, contains('.limit(pullPage.pageSize)'), reason: path);
        expect(source, contains('pullPage.isAfterCursor'), reason: path);
      }
      expect(pullPage, contains("query.lte('updated_at'"));
      expect(pullPage, contains('updated_at.gt.'));
      expect(pullPage, contains('id.gt.'));
      expect(pullPage, contains('isAfterCursor'));
    });
  });
}
