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
      final dbService = File(
        'lib/common/db/db_service.dart',
      ).readAsStringSync();

      for (final source in [evidenceAdapter, expenseAdapter]) {
        expect(source, contains("'project_sync_id'"));
      }
      expect(
        File('lib/common/services/sync_service.dart').readAsStringSync(),
        isNot(contains("'project_sync_id'")),
      );
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
      expect(photoModel, isNot(contains('projectStageName')));
      expect(photoModel, isNot(contains('syncId')));
      expect(photoModel, isNot(contains('remoteId')));
    });

    test(
      'project stages sync through project and syncable relation records',
      () {
        final projectModel = File(
          'lib/features/project/data/project_model.dart',
        ).readAsStringSync();
        final projectEntry = File(
          'lib/features/project/domain/entities/project_entry.dart',
        ).readAsStringSync();
        final workLogModel = File(
          'lib/features/work_log/data/work_log_model.dart',
        ).readAsStringSync();
        final evidenceModel = File(
          'lib/features/evidence/data/evidence_model.dart',
        ).readAsStringSync();
        final expenseModel = File(
          'lib/features/expense/data/expense_record_model.dart',
        ).readAsStringSync();
        final workLogEntry = File(
          'lib/features/work_log/domain/entities/work_log_entry.dart',
        ).readAsStringSync();
        final evidenceEntry = File(
          'lib/features/evidence/domain/entities/evidence_entry.dart',
        ).readAsStringSync();
        final expenseEntry = File(
          'lib/features/expense/domain/entities/expense_record_entry.dart',
        ).readAsStringSync();
        final projectAdapter = File(
          'lib/features/project/sync/project_sync_adapter.dart',
        ).readAsStringSync();
        final workLogAdapter = File(
          'lib/features/work_log/sync/work_log_sync_adapter.dart',
        ).readAsStringSync();
        final evidenceAdapter = File(
          'lib/features/evidence/sync/evidence_sync_adapter.dart',
        ).readAsStringSync();
        final expenseAdapter = File(
          'lib/features/expense/sync/expense_record_sync_adapter.dart',
        ).readAsStringSync();
        final dbService = File(
          'lib/common/db/db_service.dart',
        ).readAsStringSync();
        final migrations = Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.sql'))
            .map((file) => file.readAsStringSync())
            .join('\n');

        expect(projectModel, contains('List<String> stageNames'));
        expect(projectEntry, contains('List<String> stageNames'));

        for (final source in [
          workLogModel,
          evidenceModel,
          expenseModel,
          workLogEntry,
          evidenceEntry,
          expenseEntry,
        ]) {
          expect(source, contains('String? projectStageName'));
        }

        expect(projectAdapter, contains("'stage_names'"));
        for (final source in [
          workLogAdapter,
          evidenceAdapter,
          expenseAdapter,
        ]) {
          expect(source, contains("'project_stage_name'"));
        }
        expect(dbService, contains("data['stage_names']"));
        expect(dbService, contains("data['project_stage_name']"));
        expect(migrations, contains('stage_names'));
        expect(migrations, contains('project_stage_name'));
      },
    );
  });
}
