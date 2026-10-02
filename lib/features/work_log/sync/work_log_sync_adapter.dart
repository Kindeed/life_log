import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/utils/sync_id_generator.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_pull_page.dart';
import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class WorkLogSyncAdapter implements SyncAdapter<WorkLog> {
  final SupabaseClient client;
  final DbService dbService;
  final String userId;
  final int pageSize;
  final SyncRunContext? context;
  final _sentSnapshots = <int, WorkLog>{};

  WorkLogSyncAdapter({
    required this.client,
    required this.dbService,
    required this.userId,
    this.pageSize = 500,
    this.context,
  });

  @override
  String get entityName => 'work_log';

  @override
  String get tableName => 'work_logs';

  @override
  Future<List<WorkLog>> pendingLocalChanges() async {
    _checkCurrent();
    final entities = await dbService.getPendingLogsForSync(context: context);
    _checkCurrent();
    return entities.where((entity) => entity.ownerUserId == userId).toList();
  }

  @override
  String syncQueueKey(WorkLog entity) => ownerScopedSyncEntityKey(
    ownerId: userId,
    syncId: entity.syncId,
    localId: entity.id,
  );

  void _checkCurrent() => context?.checkCurrent();

  void _checkRemoteRow(Map<String, dynamic> row) {
    _checkCurrent();
    if (row['user_id'] != userId) {
      throw StateError('Remote sync row belongs to a different owner');
    }
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
      _checkCurrent();
      dynamic query = client.from(tableName).select().eq('user_id', userId);
      query = pullPage.applyTo(query);

      final page = await query
          .order('updated_at', ascending: true)
          .order('id', ascending: true)
          .limit(pullPage.pageSize);
      _checkCurrent();
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
    _checkRemoteRow(row);
    return dbService.syncRemoteLogToLocal(row, context: context);
  }

  @override
  Future<PushResult> pushLocalChange(WorkLog entity) async {
    _checkCurrent();
    if (entity.ownerUserId != userId) {
      throw StateError('Local sync entity belongs to a different owner');
    }
    _sentSnapshots[entity.id] = DbService.snapshotWorkLog(entity);
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
      'date': entity.date.toIso8601String(),
      'type': entity.type.name,
      'duration': entity.overtimeHours,
      'project_name': entity.type == LogType.businessTrip
          ? entity.location
          : null,
      'linked_project_name': entity.projectName,
      'project_sync_id': entity.projectSyncId,
      'project_stage_name': entity.projectStageName,
      'transport': entity.transport,
      'expenses': entity.expenses,
      'is_reimbursed': entity.isReimbursed,
      'notes': entity.note,
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
    _checkCurrent();
    if (response == null) {
      final remote = await _refreshRemote(entity);
      return PushResult(
        success: false,
        conflict: _buildConflict(
          entity,
          SyncConflictType.updateConflict,
          'Remote WorkLog update conflict or not found',
          remote,
        ),
      );
    }

    _applySyncResult(entity, response);
    await dbService.updateWorkLogRemoteId(
      entity,
      context: context,
      sentSnapshot: _sentSnapshots[entity.id],
    );
    _checkCurrent();
    return const PushResult(success: true);
  }

  @override
  Future<void> purgeLocalDeleted(WorkLog entity) {
    _checkCurrent();
    return dbService.purgeDeletedLog(
      entity.id,
      context: context,
      sentSnapshot: _sentSnapshots[entity.id],
    );
  }

  Future<Map<String, dynamic>?> _updateRemote(
    WorkLog entity,
    Map<String, dynamic> data,
  ) async {
    var query = client
        .from(tableName)
        .update(data)
        .eq('id', entity.remoteId!)
        .eq('user_id', userId);
    query = query.eq('version', entity.remoteVersion);
    final response = await query
        .select('id, sync_id, version, updated_at')
        .maybeSingle();
    return response;
  }

  Future<PushResult> _deleteRemote(WorkLog entity) async {
    var query = client
        .from(tableName)
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', entity.remoteId!)
        .eq('user_id', userId);
    query = query.eq('version', entity.remoteVersion);
    final response = await query
        .select('id, sync_id, version, updated_at')
        .maybeSingle();
    _checkCurrent();
    if (response == null) {
      final remote = await _refreshRemote(entity);
      return PushResult(
        success: false,
        conflict: _buildConflict(
          entity,
          SyncConflictType.deleteConflict,
          'Remote WorkLog delete conflict or not found',
          remote,
        ),
      );
    }

    _applySyncResult(entity, response);
    return const PushResult(success: true, purgeLocalDeleted: true);
  }

  Future<PushResult> _deleteRemoteBySyncId(WorkLog entity) async {
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
    _checkCurrent();
    if (response == null) {
      return const PushResult(success: true, purgeLocalDeleted: true);
    }

    _applySyncResult(entity, response);
    return const PushResult(success: true, purgeLocalDeleted: true);
  }

  Future<Map<String, dynamic>?> _refreshRemote(WorkLog entity) async {
    dynamic query = client.from(tableName).select().eq('user_id', userId);
    if (entity.remoteId != null) {
      query = query.eq('id', entity.remoteId!);
    } else {
      final syncId = entity.syncId?.trim();
      if (syncId == null || syncId.isEmpty) return null;
      query = query.eq('sync_id', syncId);
    }
    _checkCurrent();
    final remote = await query.maybeSingle();
    _checkCurrent();
    if (remote != null) {
      _checkRemoteRow(remote);
      await dbService.syncRemoteLogToLocal(remote, context: context);
      _checkCurrent();
    }
    return remote == null ? null : Map<String, dynamic>.from(remote);
  }

  SyncConflictDraft _buildConflict(
    WorkLog entity,
    SyncConflictType conflictType,
    String message,
    Map<String, dynamic>? remote,
  ) {
    return SyncConflictDraft(
      entityName: entityName,
      ownerUserId: userId,
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

  void _applySyncResult(WorkLog entity, Map<String, dynamic> response) {
    _checkCurrent();
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
      throw StateError('WorkLog sync response is missing a valid id');
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
