import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/core/di/service_locator.dart';
import '../db/db_service.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../utils/sync_id_generator.dart';
import '../utils/sync_id_policy.dart';

class SyncService {
  final _client = Supabase.instance.client;
  final _storage = GetStorage();
  static const _evidenceBucket = 'evidence-files';
  Future<bool>? _activeSync;
  Future<void>? _claimUnownedRecordsFuture;
  String? _claimUnownedRecordsUserId;
  Future<void>? _bootstrapSyncFuture;
  String? _bootstrapSyncUserId;
  DateTime? _lastBootstrapSyncAt;
  AuthService? _listenedAuthService;
  VoidCallback? _authListener;
  static const int _pullPageSize = 500;
  static const Duration _serverTimeTimeout = Duration(seconds: 10);
  static const String _workLogsTable = 'work_logs';
  static const String _subscriptionsTable = 'subscriptions';
  static const String _projectsTable = 'projects';
  static const String _expenseEvidenceTable = 'expense_evidence';
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

  String get _lastPullCursorKey {
    final user = _currentUser;
    return user != null ? 'last_pull_cursor_${user.id}' : 'last_pull_cursor';
  }

  String get _legacyLastSyncKey => _lastSyncKey;

  String newSyncId() => SyncIdGenerator.newSyncId();

  String _ensureSyncId(String? current) =>
      ensureSyncId(current, generator: newSyncId);

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
        _claimUnownedRecordsThenSync(user.id, reason: 'auth');
      } else {
        _claimUnownedRecordsFuture = null;
        _claimUnownedRecordsUserId = null;
      }
    }

    _listenedAuthService = authService;
    _authListener = handleAuthChange;
    authService.currentUser.addListener(handleAuthChange);

    if (authService.isLoggedIn) {
      final userId = authService.currentUser.value!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LogService.to.info('Sync', 'Delay startup sync until first frame');
        _claimUnownedRecordsThenSync(userId, reason: 'startup');
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

  Future<void> _claimUnownedRecordsThenSync(
    String userId, {
    required String reason,
  }) async {
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
      await _claimUnownedRecordsForCurrentUser(userId);
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

  Future<void> _claimUnownedRecordsForCurrentUser(String userId) {
    if (_claimUnownedRecordsUserId != userId) {
      _claimUnownedRecordsUserId = userId;
      _claimUnownedRecordsFuture = null;
    }

    return _claimUnownedRecordsFuture ??= _dbService
        .claimUnownedRecordsForCurrentUser()
        .catchError((Object e, StackTrace stackTrace) {
          _claimUnownedRecordsFuture = null;
          _handlePossibleSessionExpired(e, 'claim unowned records');
          LogService.to.error(
            'Sync',
            'Claim unowned records failed: $e',
            stackTrace,
          );
          throw e;
        });
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
      log.syncId = _ensureSyncId(log.syncId);
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
      };
      if (log.syncId != null) {
        data['sync_id'] = log.syncId;
      }

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
            .insert(data)
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
      sub.syncId = _ensureSyncId(sub.syncId);
      final data = {
        'user_id': user.id,
        'local_id': sub.id,
        'name': sub.name,
        'price': sub.price,
        'cycle': sub.cycle.name,
        'start_date': sub.nextPaymentDate
            .toIso8601String(), // Using nextPaymentDate as the date anchor
        'description': sub.note,
        'sort_index': sub.sortIndex,
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (sub.syncId != null) {
        data['sync_id'] = sub.syncId;
      }

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
            .insert(data)
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
      project.syncId = _ensureSyncId(project.syncId);
      final data = {
        'user_id': user.id,
        'local_id': project.id,
        'name': project.name,
        'status': project.status.name,
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'created_at': project.createdAt.toUtc().toIso8601String(),
        'sync_id': project.syncId,
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
            .insert(data)
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

  Future<String?> _uploadEvidenceFile(ExpenseEvidence evidence) async {
    final user = _currentUser;
    final localPath = evidence.localFilePath;
    if (user == null || localPath == null) return evidence.remoteStoragePath;

    final file = File(localPath);
    if (!await file.exists()) return evidence.remoteStoragePath;

    evidence.syncId = _ensureSyncId(evidence.syncId);
    final fileName =
        evidence.fileName ?? localPath.split(Platform.pathSeparator).last;
    final storagePath = '${user.id}/${evidence.syncId}/$fileName';

    await _client.storage
        .from(_evidenceBucket)
        .upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: evidence.mimeType ?? 'image/jpeg',
            upsert: true,
          ),
        );

    evidence.remoteStoragePath = storagePath;
    evidence.uploadedAt = DateTime.now().toUtc();
    return storagePath;
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
      evidence.syncId = _ensureSyncId(evidence.syncId);
      await _uploadEvidenceFile(evidence);

      final data = {
        'user_id': user.id,
        'local_id': evidence.id,
        'project_name': evidence.projectName,
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
        'sync_id': evidence.syncId,
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
            .insert(data)
            .select('id, sync_id, version, updated_at')
            .single();
        _applyEvidenceSyncResult(evidence, response);
        await _dbService.updateEvidenceRemoteId(evidence);
      }
      LogService.to.info('Sync', 'Evidence $operation success: ${evidence.id}');
      return true;
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
      if (evidence.remoteStoragePath != null) {
        await _client.storage.from(_evidenceBucket).remove([
          evidence.remoteStoragePath!,
        ]);
      }
      _applyEvidenceSyncResult(evidence, response);
      LogService.to.info(
        'Sync',
        'Evidence delete success: ${evidence.remoteId}',
      );
      return true;
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
      record.syncId = _ensureSyncId(record.syncId);
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
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (record.syncId != null) {
        data['sync_id'] = record.syncId;
      }

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
            .insert(data)
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
    LogService.to.info(
      'Sync',
      'Sync started: $reason${forceFullRefresh ? " (full refresh)" : ""}',
    );

    final pullSuccess = await _pullAll(forceFullRefresh: forceFullRefresh);
    if (!pullSuccess) return false;

    final pushSuccess = await _pushUnsyncedData();
    if (pushSuccess) {
      // Kept for compatibility with older builds and existing debug displays.
      _storage.write(_lastSyncKey, DateTime.now().toUtc().toIso8601String());
    }

    LogService.to.info(
      'Sync',
      pushSuccess ? 'Sync complete' : 'Sync incomplete',
    );
    return pushSuccess;
  }

  Future<DateTime> _getServerNow() async {
    final response = await _client
        .rpc('get_server_time')
        .timeout(_serverTimeTimeout);
    if (response == null) {
      throw StateError('get_server_time returned null');
    }
    final parsed = _parseRemoteDateTime(response);
    if (parsed == null) {
      throw StateError('get_server_time returned an invalid timestamp');
    }
    return parsed;
  }

  Future<List<Map<String, dynamic>>> _pullPagedRows({
    required String table,
    required String userId,
    required bool fullRefresh,
    required DateTime? lastCursor,
    required DateTime pullStartedAt,
  }) async {
    final rows = <Map<String, dynamic>>[];
    var start = 0;

    while (true) {
      dynamic query = _client.from(table).select().eq('user_id', userId);
      if (!fullRefresh && lastCursor != null) {
        query = query
            .gte('updated_at', lastCursor.toIso8601String())
            .lte('updated_at', pullStartedAt.toIso8601String());
      }

      final page = await query
          .order('updated_at', ascending: true)
          .order('id', ascending: true)
          .range(start, start + _pullPageSize - 1);
      final pageRows = (page as List)
          .cast<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      rows.addAll(pageRows);

      if (pageRows.length < _pullPageSize) break;
      start += _pullPageSize;
    }

    return rows;
  }

  Future<bool> _pullAll({required bool forceFullRefresh}) async {
    try {
      final user = _currentUser;
      if (user == null) return false;

      final pullStartedAt = await _getServerNow();
      final cursorStr =
          _storage.read(_lastPullCursorKey) ??
          _storage.read(_legacyLastSyncKey);
      final lastCursor = _parseRemoteDateTime(cursorStr);
      final fullRefresh = forceFullRefresh || lastCursor == null;

      final logsData = await _pullPagedRows(
        table: _workLogsTable,
        userId: user.id,
        fullRefresh: fullRefresh,
        lastCursor: lastCursor,
        pullStartedAt: pullStartedAt,
      );

      await _dbService.syncRemoteLogsToLocal(logsData);

      final subsData = await _pullPagedRows(
        table: _subscriptionsTable,
        userId: user.id,
        fullRefresh: fullRefresh,
        lastCursor: lastCursor,
        pullStartedAt: pullStartedAt,
      );

      await _dbService.syncRemoteSubscriptionsToLocal(subsData);

      final projectsData = await _pullPagedRows(
        table: _projectsTable,
        userId: user.id,
        fullRefresh: fullRefresh,
        lastCursor: lastCursor,
        pullStartedAt: pullStartedAt,
      );

      await _dbService.syncRemoteProjectsToLocal(projectsData);

      final evidenceData = await _pullPagedRows(
        table: _expenseEvidenceTable,
        userId: user.id,
        fullRefresh: fullRefresh,
        lastCursor: lastCursor,
        pullStartedAt: pullStartedAt,
      );

      await _dbService.syncRemoteEvidenceRowsToLocal(evidenceData);
      for (var map in evidenceData) {
        final syncId = _parseRemoteString(map['sync_id']);
        if (map['deleted_at'] == null && syncId != null) {
          final evidence = await _dbService.getEvidenceBySyncId(syncId);
          if (evidence != null) {
            try {
              await downloadEvidenceFile(evidence);
            } catch (e, stackTrace) {
              _handlePossibleSessionExpired(e, 'download Evidence file');
              LogService.to.error(
                'Sync',
                'Download Evidence file failed syncId=${evidence.syncId} remoteId=${evidence.remoteId} storage=${evidence.remoteStoragePath}: $e',
                stackTrace,
              );
            }
          }
        }
      }

      final expenseRecordsData = await _pullPagedRows(
        table: _expenseRecordsTable,
        userId: user.id,
        fullRefresh: fullRefresh,
        lastCursor: lastCursor,
        pullStartedAt: pullStartedAt,
      );

      await _dbService.syncRemoteExpenseRecordsToLocal(expenseRecordsData);

      _storage.write(_lastPullCursorKey, pullStartedAt.toIso8601String());

      LogService.to.info(
        'Sync',
        'Pull complete (${fullRefresh ? "full" : "incremental"}): '
            '${logsData.length} logs, ${subsData.length} subscriptions, '
            '${projectsData.length} projects, '
            '${evidenceData.length} evidence, '
            '${expenseRecordsData.length} expenseRecords',
      );
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'pull');
      LogService.to.error('Sync', 'Pull failed: $e', stackTrace);
      return false;
    }
  }

  Future<bool> _pushUnsyncedData() async {
    try {
      // Work Logs: unsynced (remoteId == null) or dirty
      final allLogs = await _dbService.getPendingLogsForSync();
      var success = true;
      var workLogAttempts = 0;
      var workLogFailures = 0;
      for (var log in allLogs) {
        workLogAttempts++;
        final pushed = await pushWorkLog(log);
        if (!pushed) workLogFailures++;
        success = pushed && success;
      }

      // Subscriptions
      final allSubs = await _dbService.getPendingSubscriptionsForSync();
      var subscriptionAttempts = 0;
      var subscriptionFailures = 0;
      for (var sub in allSubs) {
        subscriptionAttempts++;
        final pushed = await pushSubscription(sub);
        if (!pushed) subscriptionFailures++;
        success = pushed && success;
      }

      final allProjects = await _dbService.getPendingProjectsForSync();
      var projectAttempts = 0;
      var projectFailures = 0;
      for (var project in allProjects) {
        projectAttempts++;
        final pushed = await pushProject(project);
        if (!pushed) projectFailures++;
        success = pushed && success;
      }

      final allEvidence = await _dbService.getPendingEvidenceForSync();
      var evidenceAttempts = 0;
      var evidenceFailures = 0;
      for (var item in allEvidence) {
        evidenceAttempts++;
        final pushed = await pushEvidence(item);
        if (!pushed) evidenceFailures++;
        success = pushed && success;
      }

      final allExpenseRecords = await _dbService
          .getPendingExpenseRecordsForSync();
      var expenseRecordAttempts = 0;
      var expenseRecordFailures = 0;
      for (var item in allExpenseRecords) {
        expenseRecordAttempts++;
        final pushed = await pushExpenseRecord(item);
        if (!pushed) expenseRecordFailures++;
        success = pushed && success;
      }

      LogService.to.info(
        'Sync',
        'Push ${success ? "complete" : "incomplete"}: '
            'workLogs $workLogAttempts attempted/$workLogFailures failed, '
            'subscriptions $subscriptionAttempts attempted/$subscriptionFailures failed, '
            'projects $projectAttempts attempted/$projectFailures failed, '
            'evidence $evidenceAttempts attempted/$evidenceFailures failed, '
            'expenseRecords $expenseRecordAttempts attempted/$expenseRecordFailures failed',
      );
      return success;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'push pending data');
      LogService.to.error('Sync', 'Push failed: $e', stackTrace);
      return false;
    }
  }
}
