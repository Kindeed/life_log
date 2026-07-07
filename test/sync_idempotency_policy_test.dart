import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cloud sync idempotency policy', () {
    test('cloud push creates use upsert by user and sync id', () {
      final adapterPaths = [
        'lib/features/work_log/sync/work_log_sync_adapter.dart',
        'lib/features/subscription/sync/subscription_sync_adapter.dart',
        'lib/features/project/sync/project_sync_adapter.dart',
        'lib/features/expense/sync/expense_record_sync_adapter.dart',
        'lib/features/evidence/sync/evidence_sync_adapter.dart',
      ];
      final source = adapterPaths
          .map((path) => File(path).readAsStringSync())
          .join('\n');

      expect(
        RegExp(r'\.insert\(\s*data\s*\)').hasMatch(source),
        isFalse,
        reason: 'Lost insert responses must retry into the same sync_id row.',
      );
      expect(
        'onConflict: \'user_id,sync_id\''.allMatches(source).length,
        greaterThanOrEqualTo(5),
        reason: 'Each cloud-eligible entity needs an idempotent create path.',
      );
      expect(
        RegExp(
          r"\.upsert\(\s*data,\s*onConflict: 'user_id,sync_id'\s*\)",
        ).allMatches(source).length,
        greaterThanOrEqualTo(5),
      );
    });

    test('pending deletes can tombstone by sync id when remote id is missing', () {
      final adapterPaths = [
        'lib/features/work_log/sync/work_log_sync_adapter.dart',
        'lib/features/subscription/sync/subscription_sync_adapter.dart',
        'lib/features/project/sync/project_sync_adapter.dart',
        'lib/features/expense/sync/expense_record_sync_adapter.dart',
        'lib/features/evidence/sync/evidence_sync_adapter.dart',
      ];

      for (final path in adapterPaths) {
        final source = File(path).readAsStringSync();

        expect(
          source,
          isNot(
            contains(
              'if (entity.remoteId == null) {\n'
              '        return const PushResult(success: true, purgeLocalDeleted: true);\n'
              '      }',
            ),
          ),
          reason:
              '$path must not silently purge a pending delete just because remoteId is missing.',
        );
        expect(
          source,
          contains('_deleteRemoteBySyncId(entity)'),
          reason:
              '$path must tombstone the remote row by (user_id, sync_id) when remoteId was not recorded.',
        );
      }
    });

    test('delete entrypoints preserve sync id records for remote tombstone', () {
      final repositoryPaths = [
        'lib/features/work_log/data/work_log_repository.dart',
        'lib/features/subscription/data/subscription_repository.dart',
        'lib/features/project/data/project_repository.dart',
        'lib/features/expense/data/expense_record_repository.dart',
        'lib/features/evidence/data/evidence_repository.dart',
      ];

      for (final path in repositoryPaths) {
        final source = File(path).readAsStringSync();

        expect(
          source,
          contains('remoteId == null &&'),
          reason:
              '$path may purge only records that have no remote id and no sync id.',
        );
        expect(
          source,
          contains('syncId == null'),
          reason:
              '$path must keep remoteId-missing records with syncId for sync tombstone.',
        );
      }
    });

    test('Supabase migrations keep unique sync identity per user', () {
      final migrations = Directory('supabase/migrations')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.sql'))
          .map((file) => file.readAsStringSync())
          .join('\n');

      for (final table in [
        'work_logs',
        'subscriptions',
        'projects',
        'expense_evidence',
        'expense_records',
      ]) {
        expect(
          RegExp(
            'unique index[^\\n]+${RegExp.escape(table)}[^\\n]*[\\s\\S]*?'
            'on public\\.${RegExp.escape(table)}\\(user_id, sync_id\\)',
            caseSensitive: false,
          ).hasMatch(migrations),
          isTrue,
          reason: '$table must enforce unique(user_id, sync_id).',
        );
      }
    });
  });
}
