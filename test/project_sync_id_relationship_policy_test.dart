import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('projectSyncId relationship policy', () {
    test(
      'syncable expense and evidence records carry stable projectSyncId',
      () {
        final evidenceModel = File(
          'lib/features/evidence/data/evidence_model.dart',
        ).readAsStringSync();
        final expenseModel = File(
          'lib/features/expense/data/expense_record_model.dart',
        ).readAsStringSync();
        final evidenceEntry = File(
          'lib/features/evidence/domain/entities/evidence_entry.dart',
        ).readAsStringSync();
        final expenseEntry = File(
          'lib/features/expense/domain/entities/expense_record_entry.dart',
        ).readAsStringSync();

        for (final source in [
          evidenceModel,
          expenseModel,
          evidenceEntry,
          expenseEntry,
        ]) {
          expect(source, contains('String? projectSyncId'));
        }
      },
    );

    test('project linkers return the stable project sync identity', () {
      final evidenceLinker = File(
        'lib/features/evidence/data/evidence_project_linker.dart',
      ).readAsStringSync();
      final expenseLinker = File(
        'lib/features/expense/data/expense_record_project_linker.dart',
      ).readAsStringSync();

      expect(evidenceLinker, contains('final String? syncId'));
      expect(expenseLinker, contains('final String? syncId'));
      expect(evidenceLinker, contains('syncId: project.syncId'));
      expect(expenseLinker, contains('syncId: project.syncId'));
    });

    test('cloud sync payloads and merge paths preserve project_sync_id', () {
      final evidenceAdapter = File(
        'lib/features/evidence/sync/evidence_sync_adapter.dart',
      ).readAsStringSync();
      final expenseAdapter = File(
        'lib/features/expense/sync/expense_record_sync_adapter.dart',
      ).readAsStringSync();
      final syncService = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();
      final dbService = File(
        'lib/common/db/db_service.dart',
      ).readAsStringSync();

      for (final source in [evidenceAdapter, expenseAdapter, syncService]) {
        expect(source, contains("'project_sync_id'"));
      }
      expect(dbService, contains("data['project_sync_id']"));
      expect(dbService, contains('projectSyncId'));
    });

    test(
      'Supabase migration adds project_sync_id to syncable relation tables',
      () {
        final migrations = Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.sql'))
            .map((file) => file.readAsStringSync())
            .join('\n');

        expect(migrations, contains('alter table public.expense_evidence'));
        expect(migrations, contains('alter table public.expense_records'));
        expect(migrations, contains('project_sync_id'));
      },
    );

    test('PhotoItem remains local-only and does not gain projectSyncId', () {
      final photoModel = File(
        'lib/features/photo/data/photo_model.dart',
      ).readAsStringSync();

      expect(photoModel, isNot(contains('projectSyncId')));
      expect(photoModel, isNot(contains('syncId')));
      expect(photoModel, isNot(contains('remoteId')));
    });
  });
}
