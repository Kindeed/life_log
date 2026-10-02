import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_pull_page.dart';
import 'package:life_log/core/sync/sync_queue.dart';
import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef EvidenceAttachmentRowSync =
    Future<bool> Function(EvidenceAttachment attachment);
typedef EvidenceAttachmentDownload =
    Future<void> Function(EvidenceAttachment attachment);

final class EvidenceAttachmentSyncAdapter
    implements
        SyncAdapter<EvidenceAttachment>,
        SyncEntityKeyResolver<EvidenceAttachment> {
  final SupabaseClient client;
  final DbService dbService;
  final String userId;
  final EvidenceAttachmentRowSync syncAttachment;
  final EvidenceAttachmentDownload? downloadAttachment;
  final int pageSize;
  final SyncRunContext? context;

  EvidenceAttachmentSyncAdapter({
    required this.client,
    required this.dbService,
    required this.userId,
    required this.syncAttachment,
    this.downloadAttachment,
    this.pageSize = 500,
    this.context,
  });

  @override
  String get entityName => 'evidence_attachment';

  @override
  String get tableName => 'evidence_attachments';

  @override
  Future<List<EvidenceAttachment>> pendingLocalChanges() async {
    context?.checkCurrent();
    final pending = await dbService.getPendingEvidenceAttachmentsForSync(
      context: context,
    );
    context?.checkCurrent();
    return pending.where((entity) => entity.ownerUserId == userId).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> pullRemoteRows(
    SyncPullRequest request,
  ) async {
    final rows = <Map<String, dynamic>>[];
    var pullPage = SyncPullPage.start(
      cursor: request.mode == SyncMode.incremental ? request.cursor : null,
      pageSize: pageSize,
    );

    while (true) {
      context?.checkCurrent();
      dynamic query = client.from(tableName).select().eq('user_id', userId);
      query = pullPage.applyTo(query);

      final page = await query
          .order('updated_at', ascending: true)
          .order('id', ascending: true)
          .limit(pullPage.pageSize);
      context?.checkCurrent();
      final pageRows = (page as List)
          .cast<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      rows.addAll(pageRows.where(pullPage.isAfterCursor));

      if (pageRows.length < pullPage.pageSize) break;
      final nextCursor = SyncPullPage.cursorFromRow(pageRows.last);
      if (nextCursor == null) break;
      pullPage = pullPage.advance(nextCursor);
    }

    return rows;
  }

  @override
  Future<void> mergeRemoteRow(Map<String, dynamic> row) async {
    context?.checkCurrent();
    if (row['user_id'] != userId) {
      throw StateError('Remote attachment belongs to a different owner');
    }
    await dbService.syncRemoteEvidenceAttachmentToLocal(row, context: context);
    context?.checkCurrent();
    if (row['deleted_at'] != null || downloadAttachment == null) return;

    final syncId = _parseRemoteString(row['sync_id']);
    if (syncId == null) return;
    final attachment = await dbService.getEvidenceAttachmentBySyncId(syncId);
    context?.checkCurrent();
    if (attachment != null) {
      await downloadAttachment!(attachment);
    }
  }

  @override
  Future<PushResult> pushLocalChange(EvidenceAttachment entity) async {
    context?.checkCurrent();
    if (entity.ownerUserId != userId) {
      throw StateError('Local attachment belongs to a different owner');
    }
    final success = await syncAttachment(entity);
    context?.checkCurrent();
    return PushResult(success: success);
  }

  @override
  Future<void> purgeLocalDeleted(EvidenceAttachment entity) async {}

  @override
  String syncQueueKey(EvidenceAttachment entity) => ownerScopedSyncEntityKey(
    ownerId: userId,
    syncId: entity.syncId,
    localId: entity.id,
  );

  String? _parseRemoteString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
}
