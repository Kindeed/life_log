import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/utils/sync_id_generator.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_pull_page.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef EvidenceAttachmentSync =
    Future<bool> Function(ExpenseEvidence evidence);
typedef EvidenceDownload = Future<void> Function(ExpenseEvidence evidence);

final class EvidenceSyncAdapter implements SyncAdapter<ExpenseEvidence> {
  final SupabaseClient client;
  final DbService dbService;
  final String userId;
  final EvidenceAttachmentSync syncAttachmentsForEvidence;
  final EvidenceDownload? downloadEvidenceFile;
  final int pageSize;

  EvidenceSyncAdapter({
    required this.client,
    required this.dbService,
    required this.userId,
    required this.syncAttachmentsForEvidence,
    this.downloadEvidenceFile,
    this.pageSize = 500,
  });

  @override
  String get entityName => 'evidence';

  @override
  String get tableName => 'expense_evidence';

  @override
  Future<List<ExpenseEvidence>> pendingLocalChanges() {
    return dbService.getPendingEvidenceForSync();
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
      dynamic query = client.from(tableName).select().eq('user_id', userId);
      query = pullPage.applyTo(query);

      final page = await query
          .order('updated_at', ascending: true)
          .order('id', ascending: true)
          .limit(pullPage.pageSize);
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
    await dbService.syncRemoteEvidenceToLocal(row);
    if (row['deleted_at'] != null || downloadEvidenceFile == null) return;

    final syncId = _parseRemoteString(row['sync_id']);
    if (syncId == null) return;
    final evidence = await dbService.getEvidenceBySyncId(syncId);
    if (evidence != null) {
      await downloadEvidenceFile!(evidence);
    }
  }

  @override
  Future<PushResult> pushLocalChange(ExpenseEvidence entity) async {
    if (entity.pendingDelete) {
      if (entity.remoteId == null) {
        return _deleteRemoteBySyncId(entity);
      }
      return _deleteRemote(entity);
    }

    final syncId = ensureSyncId(
      entity.syncId,
      generator: SyncIdGenerator.newSyncId,
    );
    entity.syncId = syncId;
    await dbService.ensureEvidenceAttachmentForEvidence(entity);

    final data = {
      'user_id': userId,
      'local_id': entity.id,
      'project_name': entity.projectName,
      'project_sync_id': entity.projectSyncId,
      'project_stage_name': entity.projectStageName,
      'evidence_date': entity.evidenceDate.toIso8601String(),
      'amount': entity.amount,
      'currency': entity.currency,
      'category': entity.category.name,
      'status': entity.status.name,
      'merchant': entity.merchant,
      'note': entity.note,
      'remote_storage_path': entity.remoteStoragePath,
      'file_name': entity.fileName,
      'mime_type': entity.mimeType,
      'uploaded_at': entity.uploadedAt?.toIso8601String(),
      'trip_date': entity.tripDate?.toIso8601String(),
      'deleted_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'sync_id': syncId,
    };

    final response = entity.remoteId == null
        ? await client
              .from(tableName)
              .upsert(data, onConflict: 'user_id,sync_id')
              .select('id, sync_id, version, updated_at')
              .single()
        : await _updateRemote(entity, data);
    if (response == null) {
      final remote = await _refreshRemote(entity);
      return PushResult(
        success: false,
        conflict: _buildConflict(
          entity,
          SyncConflictType.updateConflict,
          'Remote Evidence update conflict or not found',
          remote,
        ),
      );
    }

    _applySyncResult(entity, response);
    await dbService.updateEvidenceRemoteId(entity);
    final attachmentsSynced = await syncAttachmentsForEvidence(entity);
    return PushResult(success: attachmentsSynced);
  }

  @override
  Future<void> purgeLocalDeleted(ExpenseEvidence entity) {
    return dbService.purgeDeletedEvidence(entity.id);
  }

  Future<Map<String, dynamic>?> _updateRemote(
    ExpenseEvidence entity,
    Map<String, dynamic> data,
  ) async {
    var query = client
        .from(tableName)
        .update(data)
        .eq('id', entity.remoteId!)
        .eq('user_id', userId);
    if (entity.remoteVersion > 0) {
      query = query.eq('version', entity.remoteVersion);
    }
    return await query.select('id, sync_id, version, updated_at').maybeSingle();
  }

  Future<PushResult> _deleteRemote(ExpenseEvidence entity) async {
    var query = client
        .from(tableName)
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', entity.remoteId!)
        .eq('user_id', userId);
    if (entity.remoteVersion > 0) {
      query = query.eq('version', entity.remoteVersion);
    }
    final response = await query
        .select('id, sync_id, version, updated_at')
        .maybeSingle();
    if (response == null) {
      final remote = await _refreshRemote(entity);
      return PushResult(
        success: false,
        conflict: _buildConflict(
          entity,
          SyncConflictType.deleteConflict,
          'Remote Evidence delete conflict or not found',
          remote,
        ),
      );
    }

    await dbService.queueEvidenceAttachmentDeleteForEvidence(entity);
    _applySyncResult(entity, response);
    final attachmentsSynced = await syncAttachmentsForEvidence(entity);
    return PushResult(
      success: attachmentsSynced,
      purgeLocalDeleted: attachmentsSynced,
    );
  }

  Future<PushResult> _deleteRemoteBySyncId(ExpenseEvidence entity) async {
    final syncId = entity.syncId?.trim();
    if (syncId == null || syncId.isEmpty) {
      return const PushResult(success: true, purgeLocalDeleted: true);
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final response = await client
        .from(tableName)
        .update({'deleted_at': now, 'updated_at': now})
        .eq('user_id', userId)
        .eq('sync_id', syncId)
        .select('id, sync_id, version, updated_at')
        .maybeSingle();
    if (response != null) {
      _applySyncResult(entity, response);
    }

    await dbService.queueEvidenceAttachmentDeleteForEvidence(entity);
    final attachmentsSynced = await syncAttachmentsForEvidence(entity);
    return PushResult(
      success: attachmentsSynced,
      purgeLocalDeleted: attachmentsSynced,
    );
  }

  Future<Map<String, dynamic>?> _refreshRemote(ExpenseEvidence entity) async {
    dynamic query = client.from(tableName).select().eq('user_id', userId);
    if (entity.remoteId != null) {
      query = query.eq('id', entity.remoteId!);
    } else {
      final syncId = entity.syncId?.trim();
      if (syncId == null || syncId.isEmpty) return null;
      query = query.eq('sync_id', syncId);
    }
    final remote = await query.maybeSingle();
    if (remote != null) {
      await dbService.syncRemoteEvidenceToLocal(remote);
    }
    return remote == null ? null : Map<String, dynamic>.from(remote);
  }

  SyncConflictDraft _buildConflict(
    ExpenseEvidence entity,
    SyncConflictType conflictType,
    String message,
    Map<String, dynamic>? remote,
  ) {
    return SyncConflictDraft(
      entityName: entityName,
      entitySyncId: entity.syncId,
      localId: entity.id.toString(),
      remoteId: entity.remoteId?.toString(),
      conflictType: conflictType,
      localVersion: entity.remoteVersion,
      remoteVersion: _parseRemoteInt(remote?['version']),
      localUpdatedAt: entity.updatedAt,
      remoteUpdatedAt: _parseRemoteDateTime(remote?['updated_at']),
      message: '$message: ${entity.remoteId}',
    );
  }

  void _applySyncResult(ExpenseEvidence entity, Map<String, dynamic> response) {
    entity.remoteId = _requireRemoteId(response);
    entity.syncId = _parseRemoteString(response['sync_id']) ?? entity.syncId;
    entity.remoteVersion = _parseRemoteInt(response['version']) ?? 0;
    entity.remoteUpdatedAt = _parseRemoteDateTime(response['updated_at']);
    entity.syncedAt = DateTime.now();
    entity.isDirty = false;
    entity.pendingDelete = false;
  }

  int _requireRemoteId(Map<String, dynamic> response) {
    final id = _parseRemoteInt(response['id']);
    if (id == null) {
      throw StateError('Evidence sync response is missing a valid id');
    }
    return id;
  }

  int? _parseRemoteInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _parseRemoteDateTime(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
  }

  String? _parseRemoteString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
}
