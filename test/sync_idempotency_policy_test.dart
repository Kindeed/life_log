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
