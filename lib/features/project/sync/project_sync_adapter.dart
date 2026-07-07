import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/utils/sync_id_generator.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_pull_page.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class ProjectSyncAdapter implements SyncAdapter<Project> {
  final SupabaseClient client;
  final DbService dbService;
  final String userId;
  final int pageSize;

  ProjectSyncAdapter({
    required this.client,
    required this.dbService,
    required this.userId,
    this.pageSize = 500,
  });

  @override
  String get entityName => 'project';

  @override
  String get tableName => 'projects';

  @override
  Future<List<Project>> pendingLocalChanges() {
    return dbService.getPendingProjectsForSync();
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
  Future<void> mergeRemoteRow(Map<String, dynamic> row) {
    return dbService.syncRemoteProjectToLocal(row);
  }

  @override
  Future<PushResult> pushLocalChange(Project entity) async {
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
    final data = {
      'user_id': userId,
      'local_id': entity.id,
      'name': entity.name,
      'status': entity.status.name,
      'stage_names': entity.stageNames,
      'deleted_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'created_at': entity.createdAt.toUtc().toIso8601String(),
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
          'Remote Project update conflict or not found',
          remote,
        ),
      );
    }

    _applySyncResult(entity, response);
    await dbService.updateProjectRemoteId(entity);
    return const PushResult(success: true);
  }

  @override
  Future<void> purgeLocalDeleted(Project entity) {
    return dbService.purgeDeletedProject(entity.id);
  }

  Future<Map<String, dynamic>?> _updateRemote(
    Project entity,
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

  Future<PushResult> _deleteRemote(Project entity) async {
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
          'Remote Project delete conflict or not found',
          remote,
        ),
      );
    }

    _applySyncResult(entity, response);
    return const PushResult(success: true, purgeLocalDeleted: true);
  }

  Future<PushResult> _deleteRemoteBySyncId(Project entity) async {
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
    if (response == null) {
      return const PushResult(success: true, purgeLocalDeleted: true);
    }

    _applySyncResult(entity, response);
    return const PushResult(success: true, purgeLocalDeleted: true);
  }

  Future<Map<String, dynamic>?> _refreshRemote(Project entity) async {
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
      await dbService.syncRemoteProjectToLocal(remote);
    }
    return remote == null ? null : Map<String, dynamic>.from(remote);
  }

  SyncConflictDraft _buildConflict(
    Project entity,
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

  void _applySyncResult(Project entity, Map<String, dynamic> response) {
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
      throw StateError('Project sync response is missing a valid id');
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
