import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('photo local-only architecture boundary', () {
    test('PhotoItem does not expose cloud sync fields', () {
      final source = File(
        'lib/features/photo/data/photo_model.dart',
      ).readAsStringSync();
      const forbiddenFields = {
        'syncId',
        'remoteId',
        'isDirty',
        'remoteVersion',
        'deletedAt',
        'pendingDelete',
      };

      for (final field in forbiddenFields) {
        expect(
          RegExp('\\b$field\\b').hasMatch(source),
          isFalse,
          reason: 'PhotoItem must stay local-only and not define $field.',
        );
      }
    });

    test('SyncService does not contain photo sync paths', () {
      final source = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(
        RegExp(
          r'\b(PhotoItem|photoItem|photos?|photo_files?)\b',
        ).hasMatch(source),
        isFalse,
        reason: 'Photos must not enter Supabase pull/push/merge flows.',
      );
    });

    test('SyncAdapter cloud table inventory is exact', () {
      final adapterSources = [
        'lib/features/work_log/sync/work_log_sync_adapter.dart',
        'lib/features/subscription/sync/subscription_sync_adapter.dart',
        'lib/features/project/sync/project_sync_adapter.dart',
        'lib/features/expense/sync/expense_record_sync_adapter.dart',
        'lib/features/evidence/sync/evidence_sync_adapter.dart',
        'lib/features/evidence/sync/evidence_attachment_sync_adapter.dart',
      ].map((path) => File(path).readAsStringSync()).join('\n');
      final tablePattern = RegExp(r"tableName => '([^']+)';");
      final tables = tablePattern
          .allMatches(adapterSources)
          .map((match) => match.group(1)!)
          .toSet();

      expect(tables, {
        'work_logs',
        'subscriptions',
        'projects',
        'expense_evidence',
        'evidence_attachments',
        'expense_records',
      });
    });

    test('SyncService push pending helpers are exact', () {
      final source = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();
      final helperPattern = RegExp(r'\b(getPending\w+ForSync)\(');
      final helpers = helperPattern
          .allMatches(source)
          .map((match) => match.group(1)!)
          .toSet();

      expect(helpers, {'getPendingEvidenceAttachmentsForSync'});
    });

    test(
      'DbService sync helper region does not include photo remote helpers',
      () {
        final source = File('lib/common/db/db_service.dart').readAsStringSync();
        const syncMarker = '// --- 6. Sync Helpers (Called by SyncService) ---';
        final syncStart = source.indexOf(syncMarker);

        expect(
          syncStart,
          isNot(-1),
          reason: 'The sync helper region marker documents the sync boundary.',
        );

        final syncRegion = source.substring(syncStart);
        expect(
          RegExp(r'\b(PhotoItem|photoItem|Photo)\b').hasMatch(syncRegion),
          isFalse,
          reason:
              'DbService cloud-sync protocol helpers must not cover photos.',
        );
      },
    );

    test(
      'DbService cloud sync helper inventory excludes photo-like records',
      () {
        final source = File('lib/common/db/db_service.dart').readAsStringSync();
        final publicHelperPattern = RegExp(
          r'^\s*Future<[^\n]+>\s+((?:getPending|syncRemote|update)\w+)\(',
          multiLine: true,
        );
        final helpers = publicHelperPattern
            .allMatches(source)
            .map((match) => match.group(1)!)
            .where(
              (name) =>
                  name.startsWith('getPending') ||
                  name.startsWith('syncRemote') ||
                  name.endsWith('RemoteId'),
            )
            .toSet();

        expect(helpers, {
          'getPendingLogsForSync',
          'getPendingSubscriptionsForSync',
          'getPendingEvidenceForSync',
          'getPendingEvidenceAttachmentsForSync',
          'getPendingProjectsForSync',
          'getPendingExpenseRecordsForSync',
          'syncRemoteLogsToLocal',
          'syncRemoteLogToLocal',
          'syncRemoteSubscriptionsToLocal',
          'syncRemoteSubscriptionToLocal',
          'syncRemoteEvidenceRowsToLocal',
          'syncRemoteEvidenceToLocal',
          'syncRemoteEvidenceAttachmentToLocal',
          'syncRemoteExpenseRecordsToLocal',
          'syncRemoteExpenseRecordToLocal',
          'syncRemoteProjectsToLocal',
          'syncRemoteProjectToLocal',
          'updateWorkLogRemoteId',
          'updateSubscriptionRemoteId',
          'updateEvidenceRemoteId',
          'updateProjectRemoteId',
          'updateExpenseRecordRemoteId',
        });
        expect(
          helpers.any(
            (name) => RegExp(
              'photo|media|image',
              caseSensitive: false,
            ).hasMatch(name),
          ),
          isFalse,
        );
      },
    );

    test('production sources do not couple photos to cloud sync terms', () {
      final forbiddenCloudTerms = RegExp(
        r'\b(supabase|syncservice|remoteid|syncid|isdirty|remoteversion|pendingdelete|deletedat|push|pull|merge)\b',
        caseSensitive: false,
      );
      final photoTerm = RegExp(
        r'\b(photoitem|photoentry|photos?)\b',
        caseSensitive: false,
      );
      final violations = <String>[];

      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          if (photoTerm.hasMatch(line) && forbiddenCloudTerms.hasMatch(line)) {
            violations.add('${file.path}:${index + 1}: ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Photos are local-only; production code must not connect photo types or photo paths to cloud-sync terms.',
      );
    });
  });
}
