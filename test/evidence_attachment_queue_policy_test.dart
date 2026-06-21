import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evidence attachment queue policy', () {
    test('EvidenceAttachment is a local Isar queue model', () {
      final file = File(
        'lib/features/evidence/data/evidence_attachment_model.dart',
      );

      expect(file.existsSync(), isTrue);

      final source = file.readAsStringSync();
      expect(source, contains('@collection'));
      expect(source, contains('class EvidenceAttachment'));
      expect(source, contains('syncId'));
      expect(source, contains('evidenceSyncId'));
      expect(source, contains('ownerUserId'));
      expect(source, contains('localPath'));
      expect(source, contains('remoteStoragePath'));
      expect(source, contains('originalFileName'));
      expect(source, contains('contentHash'));
      expect(source, contains('sizeBytes'));
      expect(source, contains('mimeType'));
      expect(source, contains('uploadState'));
      expect(source, contains('pending'));
      expect(source, contains('uploading'));
      expect(source, contains('uploaded'));
      expect(source, contains('failed'));
      expect(source, contains('deleted'));
      expect(
        RegExp(r'\b(PhotoItem|PhotoEntry)\b').hasMatch(source),
        isFalse,
        reason: 'Evidence attachment queue must not include photos.',
      );
    });

    test('DbService owns local attachment queue state transitions', () {
      final dbService = File(
        'lib/common/db/db_service.dart',
      ).readAsStringSync();

      expect(dbService, contains('EvidenceAttachmentSchema'));
      expect(dbService, contains('ensureEvidenceAttachmentForEvidence('));
      expect(dbService, contains('getPendingEvidenceAttachmentsForSync('));
      expect(dbService, contains('markEvidenceAttachmentUploading('));
      expect(dbService, contains('markEvidenceAttachmentUploaded('));
      expect(dbService, contains('markEvidenceAttachmentFailed('));
      expect(dbService, contains('queueEvidenceAttachmentDeleteForEvidence('));
      expect(dbService, contains('purgeEvidenceAttachment('));
    });

    test('SyncService syncs evidence attachments through the queue', () {
      final source = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(
        source,
        contains("_evidenceAttachmentsTable = 'evidence_attachments'"),
      );
      expect(source, contains('_syncPendingEvidenceAttachments('));
      expect(source, contains('_uploadEvidenceAttachment('));
      expect(source, contains('_deleteEvidenceAttachment('));
      expect(source, contains('getPendingEvidenceAttachmentsForSync('));
      expect(source, contains('markEvidenceAttachmentUploaded('));
      expect(source, isNot(contains('_uploadEvidenceFile(')));
      expect(
        source,
        isNot(contains('remove([evidence.remoteStoragePath!]')),
        reason:
            'Evidence deletion must confirm the remote attachment row before Storage deletion.',
      );
    });

    test('Supabase migration creates remote evidence attachments table', () {
      final migration = File(
        'supabase/migrations/20260621_evidence_attachments.sql',
      );

      expect(migration.existsSync(), isTrue);

      final source = migration.readAsStringSync();
      expect(
        source,
        contains('create table if not exists public.evidence_attachments'),
      );
      expect(source, contains('evidence_sync_id uuid not null'));
      expect(source, contains('remote_storage_path text'));
      expect(source, contains('content_hash text'));
      expect(source, contains('size_bytes bigint'));
      expect(source, contains('upload_state text'));
      expect(
        source,
        contains(
          'unique index if not exists uq_evidence_attachments_user_sync_id',
        ),
      );
      expect(
        source,
        contains(
          'alter table public.evidence_attachments enable row level security',
        ),
      );
      expect(source, contains('evidence_attachments_select_own'));
      expect(
        RegExp(
          r'\b(photo|photos|photo_item)\b',
          caseSensitive: false,
        ).hasMatch(source),
        isFalse,
        reason: 'Photo sync must remain invalidated by AGENTS.md.',
      );
    });
  });
}
