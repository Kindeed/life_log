import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/sync/evidence_sync_adapter.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/expense/sync/expense_record_sync_adapter.dart';
import 'package:life_log/features/project/sync/project_sync_adapter.dart';
import 'package:life_log/features/subscription/sync/subscription_sync_adapter.dart';
import 'package:life_log/features/work_log/sync/work_log_sync_adapter.dart';
import 'package:life_log/core/sync/get_storage_sync_cursor_store.dart';
import 'package:life_log/core/sync/isar_sync_conflict_store.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_engine.dart';
import 'package:life_log/core/sync/sync_queue.dart';
import 'package:life_log/core/di/service_locator.dart';
import '../db/db_service.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../utils/sync_id_generator.dart';
import '../utils/sync_id_policy.dart';

class SyncService {
  final _client = Supabase.instance.client;
  final _storage = GetStorage();
  final _syncQueue = InMemorySyncQueue();
  static const _evidenceBucket = 'evidence-files';
  Future<bool>? _activeSync;
  Future<void>? _bootstrapSyncFuture;
  String? _bootstrapSyncUserId;
  DateTime? _lastBootstrapSyncAt;
  AuthService? _listenedAuthService;
  VoidCallback? _authListener;
  bool _syncPaused = false;
  bool _syncCancelRequested = false;
  static const String _workLogsTable = 'work_logs';
  static const String _subscriptionsTable = 'subscriptions';
  static const String _projectsTable = 'projects';
  static const String _expenseEvidenceTable = 'expense_evidence';
  static const String _evidenceAttachmentsTable = 'evidence_attachments';
  static const String _expenseRecordsTable = 'expense_records';

  AuthService? get _authService => serviceLocator.isRegistered<AuthService>()
      ? serviceLocator<AuthService>()
      : null;

  DbService get _dbService => serviceLocator<DbService>();

  User? get _currentUser => _authService?.currentUser.value;

  bool get _isLoggedIn => _authService?.isLoggedIn ?? false;

  String get _lastSyncKey {
    final user = _currentUser;
    return user != null ? 'last_sync_time_${user.id}' : 'last_sync_time';
  }

  String newSyncId() => SyncIdGenerator.newSyncId();

  String _ensureSyncId(String? current) =>
      ensureSyncId(current, generator: newSyncId);

  void pauseSync() {
    _syncPaused = true;
    LogService.to.info('Sync', 'Sync paused');
  }

  void resumeSync() {
    _syncPaused = false;
    LogService.to.info('Sync', 'Sync resumed');
  }

  void cancelSync() {
    _syncCancelRequested = true;
    _syncPaused = false;
    LogService.to.info('Sync', 'Sync cancellation requested');
  }

  Future<void> _waitWhilePaused() async {
    while (_syncPaused && !_syncCancelRequested) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void _handlePossibleSessionExpired(Object error, String source) {
    final authService = _authService;
    if (authService == null) return;
    unawaited(authService.handleSessionExpired(error, source: source));
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

  int _requireRemoteId(Map<String, dynamic> response, String entityName) {
    final id = _parseRemoteInt(response['id']);
    if (id == null) {
      throw StateError('$entityName sync response is missing a valid id');
    }
    return id;
  }

  Future<void> _refreshRemoteWorkLog(WorkLog log) async {
    final user = _currentUser;
    if (user == null || log.remoteId == null) return;

    final remote = await _client
        .from(_workLogsTable)
        .select()
        .eq('id', log.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await _dbService.syncRemoteLogToLocal(remote);
    }
  }

  Future<void> _refreshRemoteSubscription(Subscription sub) async {
    final user = _currentUser;
    if (user == null || sub.remoteId == null) return;

    final remote = await _client
        .from(_subscriptionsTable)
        .select()
        .eq('id', sub.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await _dbService.syncRemoteSubscriptionToLocal(remote);
    }
  }

  Future<void> _refreshRemoteProject(Project project) async {
    final user = _currentUser;
    if (user == null || project.remoteId == null) return;

    final remote = await _client
        .from(_projectsTable)
        .select()
        .eq('id', project.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await _dbService.syncRemoteProjectToLocal(remote);
    }
  }

  Future<void> _refreshRemoteEvidence(ExpenseEvidence evidence) async {
    final user = _currentUser;
    if (user == null || evidence.remoteId == null) return;

    final remote = await _client
        .from(_expenseEvidenceTable)
        .select()
        .eq('id', evidence.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await _dbService.syncRemoteEvidenceToLocal(remote);
    }
  }

  Future<void> _refreshRemoteExpenseRecord(ExpenseRecord record) async {
    final user = _currentUser;
    if (user == null || record.remoteId == null) return;

    final remote = await _client
        .from(_expenseRecordsTable)
        .select()
        .eq('id', record.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await _dbService.syncRemoteExpenseRecordToLocal(remote);
    }
  }

  void _applyWorkLogSyncResult(WorkLog log, Map<String, dynamic> response) {
    log.remoteId = _requireRemoteId(response, 'WorkLog');
    log.syncId = _parseRemoteString(response['sync_id']) ?? log.syncId;
    log.remoteVersion = _parseRemoteInt(response['version']) ?? 0;
    log.remoteUpdatedAt = _parseRemoteDateTime(response['updated_at']);
    log.syncedAt = DateTime.now();
    log.isDirty = false;
    log.pendingDelete = false;
  }

  void _applySubscriptionSyncResult(
    Subscription sub,
    Map<String, dynamic> response,
  ) {
    sub.remoteId = _requireRemoteId(response, 'Subscription');
    sub.syncId = _parseRemoteString(response['sync_id']) ?? sub.syncId;
    sub.remoteVersion = _parseRemoteInt(response['version']) ?? 0;
    sub.remoteUpdatedAt = _parseRemoteDateTime(response['updated_at']);
    sub.syncedAt = DateTime.now();
    sub.isDirty = false;
    sub.pendingDelete = false;
  }

  void _applyProjectSyncResult(Project project, Map<String, dynamic> response) {
    project.remoteId = _requireRemoteId(response, 'Project');
    project.syncId = _parseRemoteString(response['sync_id']) ?? project.syncId;
    project.remoteVersion = _parseRemoteInt(response['version']) ?? 0;
    project.remoteUpdatedAt = _parseRemoteDateTime(response['updated_at']);
    project.syncedAt = DateTime.now();
    project.isDirty = false;
    project.pendingDelete = false;
  }

  void _applyEvidenceSyncResult(
    ExpenseEvidence evidence,
    Map<String, dynamic> response,
  ) {
    evidence.remoteId = _requireRemoteId(response, 'ExpenseEvidence');
    evidence.syncId =
        _parseRemoteString(response['sync_id']) ?? evidence.syncId;
    evidence.remoteVersion = _parseRemoteInt(response['version']) ?? 0;
    evidence.remoteUpdatedAt = _parseRemoteDateTime(response['updated_at']);
    evidence.syncedAt = DateTime.now();
    evidence.isDirty = false;
    evidence.pendingDelete = false;
  }

  void _applyExpenseRecordSyncResult(
    ExpenseRecord record,
    Map<String, dynamic> response,
  ) {
    record.remoteId = _requireRemoteId(response, 'ExpenseRecord');
    record.syncId = _parseRemoteString(response['sync_id']) ?? record.syncId;
    record.remoteVersion = _parseRemoteInt(response['version']) ?? 0;
    record.remoteUpdatedAt = _parseRemoteDateTime(response['updated_at']);
    record.syncedAt = DateTime.now();
    record.isDirty = false;
    record.pendingDelete = false;
  }

  void start() {
    if (_authListener != null) return;
    final authService = _authService;
    if (authService == null) return;

    void handleAuthChange() {
      final user = authService.currentUser.value;
      if (user != null) {
        _bootstrapSync(user.id, reason: 'auth');
      }
    }

    _listenedAuthService = authService;
    _authListener = handleAuthChange;
    authService.currentUser.addListener(handleAuthChange);

    if (authService.isLoggedIn) {
      final userId = authService.currentUser.value!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LogService.to.info('Sync', 'Delay startup sync until first frame');
        _bootstrapSync(userId, reason: 'startup');
      });
    }
  }

  void dispose() {
    final listener = _authListener;
    final authService = _listenedAuthService;
    if (listener != null && authService != null) {
      authService.currentUser.removeListener(listener);
    }
    _authListener = null;
    _listenedAuthService = null;
  }

  Future<void> _bootstrapSync(String userId, {required String reason}) async {
    final activeBootstrap = _bootstrapSyncFuture;
    if (activeBootstrap != null && _bootstrapSyncUserId == userId) {
      LogService.to.debug('Sync', 'Reuse bootstrap sync for $reason');
      return activeBootstrap;
    }

    final lastBootstrapAt = _lastBootstrapSyncAt;
    if (_bootstrapSyncUserId == userId &&
        lastBootstrapAt != null &&
        DateTime.now().difference(lastBootstrapAt) <
            const Duration(seconds: 2)) {
      LogService.to.debug('Sync', 'Skip duplicate bootstrap sync for $reason');
      return;
    }

    _bootstrapSyncUserId = userId;
    _bootstrapSyncFuture = _runBootstrapSync(userId, reason: reason);
    try {
      await _bootstrapSyncFuture;
      _lastBootstrapSyncAt = DateTime.now();
    } finally {
      _bootstrapSyncFuture = null;
    }
  }

  Future<void> _runBootstrapSync(
    String userId, {
    required String reason,
  }) async {
    try {
      await syncAll(reason: reason);
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, '$reason sync bootstrap');
      LogService.to.error(
        'Sync',
        '$reason sync bootstrap failed: $e',
        stackTrace,
      );
    }
  }

  // --- Work Log Sync ---

  /// Push a single WorkLog to Supabase
  Future<bool> pushWorkLog(WorkLog log) async {
    if (!_isLoggedIn) return false;

    if (log.pendingDelete) {
      if (log.remoteId == null) {
        await _dbService.purgeDeletedLog(log.id);
        return true;
      }
      final success = await deleteWorkLog(log);
      if (success) {
        await _dbService.purgeDeletedLog(log.id);
      }
      return success;
    }

    try {
      final user = _currentUser!;
      final syncId = _ensureSyncId(log.syncId);
      log.syncId = syncId;
      final data = {
        'user_id': user.id,
        'local_id': log.id,
        'date': log.date.toIso8601String(),
        'type': log.type.name,
        'duration': log.overtimeHours,
        'project_name': log.type == LogType.businessTrip
            ? log.location
            : null, // Reuse location as project/loc
        'transport': log.transport,
        'expenses': log.expenses,
        'is_reimbursed': log.isReimbursed,
        'notes': log.note,
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'sync_id': syncId,
      };

      final operation = log.remoteId == null ? 'insert' : 'update';

      if (log.remoteId != null) {
        // Update
        var query = _client
            .from(_workLogsTable)
            .update(data)
            .eq('id', log.remoteId!)
            .eq('user_id', user.id);
        if (log.remoteVersion > 0) {
          query = query.eq('version', log.remoteVersion);
        }
        final response = await query
            .select('id, sync_id, version, updated_at')
            .maybeSingle();
        if (response == null) {
          await _refreshRemoteWorkLog(log);
          throw StateError(
            'Remote WorkLog update conflict or not found: ${log.remoteId}',
          );
        }
        _applyWorkLogSyncResult(log, response);
        await _dbService.updateWorkLogRemoteId(log);
      } else {
        // Insert
        final response = await _client
            .from(_workLogsTable)
            .upsert(data, onConflict: 'user_id,sync_id')
            .select('id, sync_id, version, updated_at')
            .single();

        // Update local remoteId
        _applyWorkLogSyncResult(log, response);
        await _dbService.updateWorkLogRemoteId(log);
      }
      LogService.to.info('Sync', 'WorkLog $operation success: ${log.id}');
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'push WorkLog');
      LogService.to.error(
        'Sync',
        'Push WorkLog failed localId=${log.id} remoteId=${log.remoteId}: $e',
        stackTrace,
      );
      // Keep isDirty = true
      return false;
    }
  }

  /// Delete a WorkLog from Supabase
  Future<bool> deleteWorkLog(WorkLog log) async {
    if (!_isLoggedIn) return false;
    if (log.remoteId == null) return true;

    try {
      final user = _currentUser!;
      var query = _client
          .from(_workLogsTable)
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', log.remoteId!)
          .eq('user_id', user.id);
      if (log.remoteVersion > 0) {
        query = query.eq('version', log.remoteVersion);
      }
      final response = await query
          .select('id, sync_id, version, updated_at')
          .maybeSingle();
      if (response == null) {
        await _refreshRemoteWorkLog(log);
        throw StateError(
          'Remote WorkLog delete conflict or not found: ${log.remoteId}',
        );
      }
      _applyWorkLogSyncResult(log, response);
      LogService.to.info('Sync', 'WorkLog delete success: ${log.remoteId}');
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'delete WorkLog');
      LogService.to.error(
        'Sync',
        'Delete WorkLog failed localId=${log.id} remoteId=${log.remoteId}: $e',
        stackTrace,
      );
      // Queue for retry?
      return false;
    }
  }

  // --- Subscription Sync ---

  Future<bool> pushSubscription(Subscription sub) async {
    if (!_isLoggedIn) return false;

    if (sub.pendingDelete) {
      if (sub.remoteId == null) {
        await _dbService.purgeDeletedSubscription(sub.id);
        return true;
      }
      final success = await deleteSubscription(sub);
      if (success) {
        await _dbService.purgeDeletedSubscription(sub.id);
      }
      return success;
    }

    try {
      final user = _currentUser!;
      final syncId = _ensureSyncId(sub.syncId);
      sub.syncId = syncId;
      final data = {
        'user_id': user.id,
        'local_id': sub.id,
        'name': sub.name,
        'price': sub.price,
        'cycle': sub.cycle.name,
        'anchor_date': sub.anchorDate?.toIso8601String(),
        'next_due_date': sub.nextPaymentDate.toIso8601String(),
        'start_date': sub.nextPaymentDate
            .toIso8601String(), // Using nextPaymentDate as the date anchor
        'end_date': sub.endDate?.toIso8601String(),
        'status': sub.status.name,
        'reminder_days': sub.reminderDays,
        'description': sub.note,
        'sort_index': sub.sortIndex,
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'sync_id': syncId,
      };

      final operation = sub.remoteId == null ? 'insert' : 'update';

      if (sub.remoteId != null) {
        var query = _client
            .from(_subscriptionsTable)
            .update(data)
            .eq('id', sub.remoteId!)
            .eq('user_id', user.id);
        if (sub.remoteVersion > 0) {
          query = query.eq('version', sub.remoteVersion);
        }
        final response = await query
            .select('id, sync_id, version, updated_at')
            .maybeSingle();
        if (response == null) {
          await _refreshRemoteSubscription(sub);
          throw StateError(
            'Remote Subscription update conflict or not found: ${sub.remoteId}',
          );
        }
        _applySubscriptionSyncResult(sub, response);
        await _dbService.updateSubscriptionRemoteId(sub);
      } else {
        final response = await _client
            .from(_subscriptionsTable)
            .upsert(data, onConflict: 'user_id,sync_id')
            .select('id, sync_id, version, updated_at')
            .single();

        _applySubscriptionSyncResult(sub, response);
        await _dbService.updateSubscriptionRemoteId(sub);
      }
      LogService.to.info('Sync', 'Subscription $operation success: ${sub.id}');
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'push Subscription');
      LogService.to.error(
        'Sync',
        'Push Subscription failed localId=${sub.id} remoteId=${sub.remoteId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> pushProject(Project project) async {
    if (!_isLoggedIn) return false;

    if (project.pendingDelete) {
      if (project.remoteId == null) {
        await _dbService.purgeDeletedProject(project.id);
        return true;
      }
      final success = await deleteProject(project);
      if (success) {
        await _dbService.purgeDeletedProject(project.id);
      }
      return success;
    }

    try {
      final user = _currentUser!;
      final syncId = _ensureSyncId(project.syncId);
      project.syncId = syncId;
      final data = {
        'user_id': user.id,
        'local_id': project.id,
        'name': project.name,
        'status': project.status.name,
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'created_at': project.createdAt.toUtc().toIso8601String(),
        'sync_id': syncId,
      };

      final operation = project.remoteId == null ? 'insert' : 'update';
      if (project.remoteId != null) {
        var query = _client
            .from(_projectsTable)
            .update(data)
            .eq('id', project.remoteId!)
            .eq('user_id', user.id);
        if (project.remoteVersion > 0) {
          query = query.eq('version', project.remoteVersion);
        }
        final response = await query
            .select('id, sync_id, version, updated_at')
            .maybeSingle();
        if (response == null) {
          await _refreshRemoteProject(project);
          throw StateError(
            'Remote Project update conflict or not found: ${project.remoteId}',
          );
        }
        _applyProjectSyncResult(project, response);
        await _dbService.updateProjectRemoteId(project);
      } else {
        final response = await _client
            .from(_projectsTable)
            .upsert(data, onConflict: 'user_id,sync_id')
            .select('id, sync_id, version, updated_at')
            .single();
        _applyProjectSyncResult(project, response);
        await _dbService.updateProjectRemoteId(project);
      }
      LogService.to.info('Sync', 'Project $operation success: ${project.id}');
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'push Project');
      LogService.to.error(
        'Sync',
        'Push Project failed localId=${project.id} remoteId=${project.remoteId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> deleteProject(Project project) async {
    if (!_isLoggedIn) return false;
    if (project.remoteId == null) return true;

    try {
      final user = _currentUser!;
      var query = _client
          .from(_projectsTable)
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', project.remoteId!)
          .eq('user_id', user.id);
      if (project.remoteVersion > 0) {
        query = query.eq('version', project.remoteVersion);
      }
      final response = await query
          .select('id, sync_id, version, updated_at')
          .maybeSingle();
      if (response == null) {
        await _refreshRemoteProject(project);
        throw StateError(
          'Remote Project delete conflict or not found: ${project.remoteId}',
        );
      }
      _applyProjectSyncResult(project, response);
      LogService.to.info('Sync', 'Project delete success: ${project.remoteId}');
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'delete Project');
      LogService.to.error(
        'Sync',
        'Delete Project failed localId=${project.id} remoteId=${project.remoteId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> deleteSubscription(Subscription sub) async {
    if (!_isLoggedIn) return false;
    if (sub.remoteId == null) return true;

    try {
      final user = _currentUser!;
      var query = _client
          .from(_subscriptionsTable)
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sub.remoteId!)
          .eq('user_id', user.id);
      if (sub.remoteVersion > 0) {
        query = query.eq('version', sub.remoteVersion);
      }
      final response = await query
          .select('id, sync_id, version, updated_at')
          .maybeSingle();
      if (response == null) {
        await _refreshRemoteSubscription(sub);
        throw StateError(
          'Remote Subscription delete conflict or not found: ${sub.remoteId}',
        );
      }
      _applySubscriptionSyncResult(sub, response);
      LogService.to.info(
        'Sync',
        'Subscription delete success: ${sub.remoteId}',
      );
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'delete Subscription');
      LogService.to.error(
        'Sync',
        'Delete Subscription failed localId=${sub.id} remoteId=${sub.remoteId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  // --- Evidence Sync ---

  String _attachmentStoragePath(User user, EvidenceAttachment attachment) {
    final existing = attachment.remoteStoragePath;
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final fileName = attachment.originalFileName;
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex <= 0 ? '' : fileName.substring(dotIndex);
    return '${user.id}/${attachment.evidenceSyncId}/${attachment.syncId}$extension';
  }

  Future<bool> _uploadEvidenceAttachment(EvidenceAttachment attachment) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      await _dbService.markEvidenceAttachmentUploading(attachment);

      final localPath = attachment.localPath;
      if (localPath == null || localPath.trim().isEmpty) {
        throw StateError('Evidence attachment local path is missing');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        throw StateError('Evidence attachment file does not exist: $localPath');
      }

      final storagePath = _attachmentStoragePath(user, attachment);
      await _client.storage
          .from(_evidenceBucket)
          .upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              contentType: attachment.mimeType ?? 'application/octet-stream',
              upsert: true,
            ),
          );

      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from(_evidenceAttachmentsTable)
          .upsert({
            'user_id': user.id,
            'sync_id': attachment.syncId,
            'evidence_sync_id': attachment.evidenceSyncId,
            'local_id': attachment.id,
            'remote_storage_path': storagePath,
            'original_file_name': attachment.originalFileName,
            'content_hash': attachment.contentHash,
            'size_bytes': attachment.sizeBytes,
            'mime_type': attachment.mimeType,
            'upload_state': EvidenceAttachmentUploadState.uploaded.name,
            'deleted_at': null,
            'updated_at': now,
          }, onConflict: 'user_id,sync_id')
          .select('sync_id')
          .single();

      await _dbService.markEvidenceAttachmentUploaded(
        attachment,
        remoteStoragePath: storagePath,
      );
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'upload Evidence attachment');
      await _dbService.markEvidenceAttachmentFailed(attachment, e);
      LogService.to.error(
        'Sync',
        'Upload Evidence attachment failed localId=${attachment.id} '
            'syncId=${attachment.syncId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> _deleteEvidenceAttachment(EvidenceAttachment attachment) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from(_evidenceAttachmentsTable)
          .upsert({
            'user_id': user.id,
            'sync_id': attachment.syncId,
            'evidence_sync_id': attachment.evidenceSyncId,
            'local_id': attachment.id,
            'remote_storage_path': attachment.remoteStoragePath,
            'original_file_name': attachment.originalFileName,
            'content_hash': attachment.contentHash,
            'size_bytes': attachment.sizeBytes,
            'mime_type': attachment.mimeType,
            'upload_state': EvidenceAttachmentUploadState.deleted.name,
            'deleted_at': now,
            'updated_at': now,
          }, onConflict: 'user_id,sync_id')
          .select('sync_id')
          .single();

      final remotePath = attachment.remoteStoragePath;
      if (remotePath != null && remotePath.trim().isNotEmpty) {
        await _client.storage.from(_evidenceBucket).remove([remotePath]);
      }
      await _dbService.purgeEvidenceAttachment(attachment.id);
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'delete Evidence attachment');
      await _dbService.markEvidenceAttachmentFailed(attachment, e);
      LogService.to.error(
        'Sync',
        'Delete Evidence attachment failed localId=${attachment.id} '
            'syncId=${attachment.syncId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> _syncPendingEvidenceAttachments({String? evidenceSyncId}) async {
    final pending = await _dbService.getPendingEvidenceAttachmentsForSync();
    var success = true;
    for (final attachment in pending) {
      if (evidenceSyncId != null &&
          attachment.evidenceSyncId != evidenceSyncId) {
        continue;
      }

      final pushed =
          attachment.uploadState == EvidenceAttachmentUploadState.deleted ||
              attachment.deletedAt != null
          ? await _deleteEvidenceAttachment(attachment)
          : await _uploadEvidenceAttachment(attachment);
      success = pushed && success;
    }
    return success;
  }

  Future<void> downloadEvidenceFile(ExpenseEvidence evidence) async {
    final remotePath = evidence.remoteStoragePath;
    if (remotePath == null || remotePath.isEmpty) return;

    final currentPath = evidence.localFilePath;
    if (currentPath != null && await File(currentPath).exists()) return;

    final bytes = await _client.storage
        .from(_evidenceBucket)
        .download(remotePath);
    final appDir = await getApplicationDocumentsDirectory();
    final safeProject = evidence.projectName.trim().replaceAll(
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
      '_',
    );
    final folder = Directory(
      '${appDir.path}/Evidence/${safeProject.isEmpty ? "DefaultProject" : safeProject}',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final fileName = evidence.fileName ?? remotePath.split('/').last;
    final localPath = '${folder.path}${Platform.pathSeparator}$fileName';
    await File(localPath).writeAsBytes(bytes);
    evidence.localFilePath = localPath;
    await _dbService.updateEvidenceRemoteId(evidence);
  }

  Future<bool> pushEvidence(ExpenseEvidence evidence) async {
    if (!_isLoggedIn) return false;

    if (evidence.pendingDelete) {
      if (evidence.remoteId == null) {
        await _dbService.purgeDeletedEvidence(evidence.id);
        return true;
      }
      final success = await deleteEvidence(evidence);
      if (success) {
        await _dbService.purgeDeletedEvidence(evidence.id);
      }
      return success;
    }

    try {
      final user = _currentUser!;
      final syncId = _ensureSyncId(evidence.syncId);
      evidence.syncId = syncId;
      await _dbService.ensureEvidenceAttachmentForEvidence(evidence);

      final data = {
        'user_id': user.id,
        'local_id': evidence.id,
        'project_name': evidence.projectName,
        'project_sync_id': evidence.projectSyncId,
        'evidence_date': evidence.evidenceDate.toIso8601String(),
        'amount': evidence.amount,
        'currency': evidence.currency,
        'category': evidence.category.name,
        'status': evidence.status.name,
        'merchant': evidence.merchant,
        'note': evidence.note,
        'remote_storage_path': evidence.remoteStoragePath,
        'file_name': evidence.fileName,
        'mime_type': evidence.mimeType,
        'uploaded_at': evidence.uploadedAt?.toIso8601String(),
        'trip_date': evidence.tripDate?.toIso8601String(),
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'sync_id': syncId,
      };

      final operation = evidence.remoteId == null ? 'insert' : 'update';
      if (evidence.remoteId != null) {
        var query = _client
            .from(_expenseEvidenceTable)
            .update(data)
            .eq('id', evidence.remoteId!)
            .eq('user_id', user.id);
        if (evidence.remoteVersion > 0) {
          query = query.eq('version', evidence.remoteVersion);
        }
        final response = await query
            .select('id, sync_id, version, updated_at')
            .maybeSingle();
        if (response == null) {
          await _refreshRemoteEvidence(evidence);
          throw StateError(
            'Remote Evidence update conflict or not found: ${evidence.remoteId}',
          );
        }
        _applyEvidenceSyncResult(evidence, response);
        await _dbService.updateEvidenceRemoteId(evidence);
      } else {
        final response = await _client
            .from(_expenseEvidenceTable)
            .upsert(data, onConflict: 'user_id,sync_id')
            .select('id, sync_id, version, updated_at')
            .single();
        _applyEvidenceSyncResult(evidence, response);
        await _dbService.updateEvidenceRemoteId(evidence);
      }
      LogService.to.info('Sync', 'Evidence $operation success: ${evidence.id}');
      return await _syncPendingEvidenceAttachments(evidenceSyncId: syncId);
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'push Evidence');
      LogService.to.error(
        'Sync',
        'Push Evidence failed localId=${evidence.id} remoteId=${evidence.remoteId} storage=${evidence.remoteStoragePath}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> deleteEvidence(ExpenseEvidence evidence) async {
    if (!_isLoggedIn) return false;
    if (evidence.remoteId == null) return true;

    try {
      final user = _currentUser!;
      var query = _client
          .from(_expenseEvidenceTable)
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', evidence.remoteId!)
          .eq('user_id', user.id);
      if (evidence.remoteVersion > 0) {
        query = query.eq('version', evidence.remoteVersion);
      }
      final response = await query
          .select('id, sync_id, version, updated_at')
          .maybeSingle();
      if (response == null) {
        await _refreshRemoteEvidence(evidence);
        throw StateError(
          'Remote Evidence delete conflict or not found: ${evidence.remoteId}',
        );
      }
      await _dbService.queueEvidenceAttachmentDeleteForEvidence(evidence);
      _applyEvidenceSyncResult(evidence, response);
      LogService.to.info(
        'Sync',
        'Evidence delete success: ${evidence.remoteId}',
      );
      return await _syncPendingEvidenceAttachments(
        evidenceSyncId: evidence.syncId,
      );
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'delete Evidence');
      LogService.to.error(
        'Sync',
        'Delete Evidence failed localId=${evidence.id} remoteId=${evidence.remoteId} storage=${evidence.remoteStoragePath}: $e',
        stackTrace,
      );
      return false;
    }
  }

  // --- Expense Record Sync ---

  Future<bool> pushExpenseRecord(ExpenseRecord record) async {
    if (!_isLoggedIn) return false;

    if (record.pendingDelete) {
      if (record.remoteId == null) {
        await _dbService.purgeDeletedExpenseRecord(record.id);
        return true;
      }
      final success = await deleteExpenseRecord(record);
      if (success) {
        await _dbService.purgeDeletedExpenseRecord(record.id);
      }
      return success;
    }

    try {
      final user = _currentUser!;
      final syncId = _ensureSyncId(record.syncId);
      record.syncId = syncId;
      final data = {
        'user_id': user.id,
        'local_id': record.id,
        'expense_date': record.expenseDate.toIso8601String(),
        'amount': record.amount,
        'currency': record.currency,
        'category': record.category.name,
        'merchant': record.merchant,
        'note': record.note,
        'project_name': record.projectName,
        'project_sync_id': record.projectSyncId,
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'sync_id': syncId,
      };

      final operation = record.remoteId == null ? 'insert' : 'update';
      if (record.remoteId != null) {
        var query = _client
            .from(_expenseRecordsTable)
            .update(data)
            .eq('id', record.remoteId!)
            .eq('user_id', user.id);
        if (record.remoteVersion > 0) {
          query = query.eq('version', record.remoteVersion);
        }
        final response = await query
            .select('id, sync_id, version, updated_at')
            .maybeSingle();
        if (response == null) {
          await _refreshRemoteExpenseRecord(record);
          throw StateError(
            'Remote ExpenseRecord update conflict or not found: ${record.remoteId}',
          );
        }
        _applyExpenseRecordSyncResult(record, response);
        await _dbService.updateExpenseRecordRemoteId(record);
      } else {
        final response = await _client
            .from(_expenseRecordsTable)
            .upsert(data, onConflict: 'user_id,sync_id')
            .select('id, sync_id, version, updated_at')
            .single();
        _applyExpenseRecordSyncResult(record, response);
        await _dbService.updateExpenseRecordRemoteId(record);
      }
      LogService.to.info(
        'Sync',
        'ExpenseRecord $operation success: ${record.id}',
      );
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'push ExpenseRecord');
      LogService.to.error(
        'Sync',
        'Push ExpenseRecord failed localId=${record.id} remoteId=${record.remoteId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> deleteExpenseRecord(ExpenseRecord record) async {
    if (!_isLoggedIn) return false;
    if (record.remoteId == null) return true;

    try {
      final user = _currentUser!;
      var query = _client
          .from(_expenseRecordsTable)
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', record.remoteId!)
          .eq('user_id', user.id);
      if (record.remoteVersion > 0) {
        query = query.eq('version', record.remoteVersion);
      }
      final response = await query
          .select('id, sync_id, version, updated_at')
          .maybeSingle();
      if (response == null) {
        await _refreshRemoteExpenseRecord(record);
        throw StateError(
          'Remote ExpenseRecord delete conflict or not found: ${record.remoteId}',
        );
      }
      _applyExpenseRecordSyncResult(record, response);
      LogService.to.info(
        'Sync',
        'ExpenseRecord delete success: ${record.remoteId}',
      );
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'delete ExpenseRecord');
      LogService.to.error(
        'Sync',
        'Delete ExpenseRecord failed localId=${record.id} remoteId=${record.remoteId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  // --- Pull Everything ---

  // --- Sync All ---

  Future<bool> syncAll({
    String reason = 'manual',
    bool forceFullRefresh = false,
    bool forceNew = false,
  }) async {
    if (!_isLoggedIn) return false;

    if (_activeSync != null && !forceNew) {
      LogService.to.debug('Sync', 'Reuse active sync for $reason');
      return _activeSync!;
    }

    if (forceNew) {
      LogService.to.info('Sync', 'Start independent sync for $reason');
      return _runSyncAll(reason, forceFullRefresh: forceFullRefresh);
    }

    _activeSync = _runSyncAll(reason, forceFullRefresh: forceFullRefresh);

    try {
      return await _activeSync!;
    } finally {
      _activeSync = null;
    }
  }

  Future<bool> _runSyncAll(
    String reason, {
    required bool forceFullRefresh,
  }) async {
    _syncCancelRequested = false;
    LogService.to.info(
      'Sync',
      'Sync started: $reason${forceFullRefresh ? " (full refresh)" : ""}',
    );

    final workLogSuccess = await _syncWorkLogsWithEngine(
      forceFullRefresh: forceFullRefresh,
    );
    final pullSuccess = await _pullAll();
    if (!pullSuccess) return false;

    final pushSuccess = await _pushUnsyncedData();
    final success = workLogSuccess && pushSuccess;
    if (pushSuccess) {
      // Kept for compatibility with older builds and existing debug displays.
      _storage.write(_lastSyncKey, DateTime.now().toUtc().toIso8601String());
    }

    LogService.to.info('Sync', success ? 'Sync complete' : 'Sync incomplete');
    return success;
  }

  Future<bool> _syncWorkLogsWithEngine({required bool forceFullRefresh}) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      final summary =
          await SyncEngine(
            adapters: [
              WorkLogSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
              ),
              SubscriptionSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
              ),
              ProjectSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
              ),
              ExpenseRecordSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
              ),
              EvidenceSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
                syncAttachmentsForEvidence: (evidence) {
                  return _syncPendingEvidenceAttachments(
                    evidenceSyncId: evidence.syncId,
                  );
                },
                downloadEvidenceFile: downloadEvidenceFile,
              ),
            ],
            cursorStore: GetStorageSyncCursorStore(
              storage: _storage,
              namespace: user.id,
            ),
            conflictStore: IsarSyncConflictStore(_dbService.database),
            queue: _syncQueue,
            runControl: SyncRunControl(
              isCancelled: () => _syncCancelRequested,
              isPaused: () => _syncPaused,
              waitWhilePaused: _waitWhilePaused,
            ),
          ).syncAll(
            mode: forceFullRefresh
                ? SyncMode.fullRefresh
                : SyncMode.incremental,
          );
      final workLogSummary = summary.adapters['work_log'];
      final subscriptionSummary = summary.adapters['subscription'];
      final projectSummary = summary.adapters['project'];
      final expenseRecordSummary = summary.adapters['expense_record'];
      final evidenceSummary = summary.adapters['evidence'];
      LogService.to.info(
        'Sync',
        'WorkLog adapter sync ${summary.success ? "complete" : "incomplete"}: '
            '${workLogSummary?.pulledRows ?? 0} pulled, '
            '${workLogSummary?.pushedChanges ?? 0} pushed, '
            '${workLogSummary?.failedPushes ?? 0} failed; '
            'Subscription adapter: '
            '${subscriptionSummary?.pulledRows ?? 0} pulled, '
            '${subscriptionSummary?.pushedChanges ?? 0} pushed, '
            '${subscriptionSummary?.failedPushes ?? 0} failed; '
            'Project adapter: '
            '${projectSummary?.pulledRows ?? 0} pulled, '
            '${projectSummary?.pushedChanges ?? 0} pushed, '
            '${projectSummary?.failedPushes ?? 0} failed; '
            'ExpenseRecord adapter: '
            '${expenseRecordSummary?.pulledRows ?? 0} pulled, '
            '${expenseRecordSummary?.pushedChanges ?? 0} pushed, '
            '${expenseRecordSummary?.failedPushes ?? 0} failed; '
            'Evidence adapter: '
            '${evidenceSummary?.pulledRows ?? 0} pulled, '
            '${evidenceSummary?.pushedChanges ?? 0} pushed, '
            '${evidenceSummary?.failedPushes ?? 0} failed',
      );
      return summary.success;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'WorkLog adapter sync');
      LogService.to.error(
        'Sync',
        'WorkLog adapter sync failed: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> _pullAll() async {
    try {
      final user = _currentUser;
      if (user == null) return false;

      LogService.to.info('Sync', 'Legacy pull skipped; adapters own pull');
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'pull');
      LogService.to.error('Sync', 'Pull failed: $e', stackTrace);
      return false;
    }
  }

  Future<bool> _pushUnsyncedData() async {
    try {
      var success = true;

      final attachmentsPushed = await _syncPendingEvidenceAttachments();
      if (!attachmentsPushed) {
        success = false;
      }

      LogService.to.info(
        'Sync',
        'Push ${success ? "complete" : "incomplete"}: '
            'evidenceAttachments ${attachmentsPushed ? "complete" : "incomplete"}',
      );
      return success;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'push pending data');
      LogService.to.error('Sync', 'Push failed: $e', stackTrace);
      return false;
    }
  }
}
