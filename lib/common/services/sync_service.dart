import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../../modules/work_log/work_log_model.dart';
import '../../modules/subscription/subscription_model.dart';
import '../../modules/evidence/evidence_model.dart';
import '../../modules/expense/expense_record_model.dart';
import '../db/db_service.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../utils/sync_id_generator.dart';

class SyncService extends GetxService {
  static SyncService get to => Get.find();

  final _client = Supabase.instance.client;
  final _storage = GetStorage();
  static const _evidenceBucket = 'evidence-files';
  Future<bool>? _activeSync;
  DateTime? _lastSyncStartedAt;
  Future<void>? _claimUnownedRecordsFuture;
  String? _claimUnownedRecordsUserId;

  String get _lastSyncKey {
    final user = AuthService.to.currentUser.value;
    return user != null ? 'last_sync_time_${user.id}' : 'last_sync_time';
  }

  String get _lastPullCursorKey {
    final user = AuthService.to.currentUser.value;
    return user != null ? 'last_pull_cursor_${user.id}' : 'last_pull_cursor';
  }

  String get _legacyLastSyncKey => _lastSyncKey;

  String newSyncId() => SyncIdGenerator.newSyncId();

  Future<void> _refreshRemoteWorkLog(WorkLog log) async {
    final user = AuthService.to.currentUser.value;
    if (user == null || log.remoteId == null) return;

    final remote = await _client
        .from('work_logs')
        .select()
        .eq('id', log.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await DbService.to.syncRemoteLogToLocal(remote);
    }
  }

  Future<void> _refreshRemoteSubscription(Subscription sub) async {
    final user = AuthService.to.currentUser.value;
    if (user == null || sub.remoteId == null) return;

    final remote = await _client
        .from('subscriptions')
        .select()
        .eq('id', sub.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await DbService.to.syncRemoteSubscriptionToLocal(remote);
    }
  }

  Future<void> _refreshRemoteEvidence(ExpenseEvidence evidence) async {
    final user = AuthService.to.currentUser.value;
    if (user == null || evidence.remoteId == null) return;

    final remote = await _client
        .from('expense_evidence')
        .select()
        .eq('id', evidence.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await DbService.to.syncRemoteEvidenceToLocal(remote);
    }
  }

  Future<void> _refreshRemoteExpenseRecord(ExpenseRecord record) async {
    final user = AuthService.to.currentUser.value;
    if (user == null || record.remoteId == null) return;

    final remote = await _client
        .from('expense_records')
        .select()
        .eq('id', record.remoteId!)
        .eq('user_id', user.id)
        .maybeSingle();
    if (remote != null) {
      await DbService.to.syncRemoteExpenseRecordToLocal(remote);
    }
  }

  void _applyWorkLogSyncResult(WorkLog log, Map<String, dynamic> response) {
    log.remoteId = response['id'] as int;
    log.syncId = response['sync_id'] as String? ?? log.syncId;
    log.remoteVersion = (response['version'] as num?)?.toInt() ?? 0;
    log.remoteUpdatedAt = response['updated_at'] == null
        ? null
        : DateTime.parse(response['updated_at'] as String);
    log.syncedAt = DateTime.now();
    log.isDirty = false;
    log.pendingDelete = false;
  }

  void _applySubscriptionSyncResult(
    Subscription sub,
    Map<String, dynamic> response,
  ) {
    sub.remoteId = response['id'] as int;
    sub.syncId = response['sync_id'] as String? ?? sub.syncId;
    sub.remoteVersion = (response['version'] as num?)?.toInt() ?? 0;
    sub.remoteUpdatedAt = response['updated_at'] == null
        ? null
        : DateTime.parse(response['updated_at'] as String);
    sub.syncedAt = DateTime.now();
    sub.isDirty = false;
    sub.pendingDelete = false;
  }

  void _applyEvidenceSyncResult(
    ExpenseEvidence evidence,
    Map<String, dynamic> response,
  ) {
    evidence.remoteId = response['id'] as int;
    evidence.syncId = response['sync_id'] as String? ?? evidence.syncId;
    evidence.remoteVersion = (response['version'] as num?)?.toInt() ?? 0;
    evidence.remoteUpdatedAt = response['updated_at'] == null
        ? null
        : DateTime.parse(response['updated_at'] as String);
    evidence.syncedAt = DateTime.now();
    evidence.isDirty = false;
    evidence.pendingDelete = false;
  }

  void _applyExpenseRecordSyncResult(
    ExpenseRecord record,
    Map<String, dynamic> response,
  ) {
    record.remoteId = response['id'] as int;
    record.syncId = response['sync_id'] as String? ?? record.syncId;
    record.remoteVersion = (response['version'] as num?)?.toInt() ?? 0;
    record.remoteUpdatedAt = response['updated_at'] == null
        ? null
        : DateTime.parse(response['updated_at'] as String);
    record.syncedAt = DateTime.now();
    record.isDirty = false;
    record.pendingDelete = false;
  }

  @override
  void onInit() {
    super.onInit();
    ever(AuthService.to.currentUser, (user) {
      if (user != null) {
        _claimUnownedRecordsThenSync(user.id, reason: 'auth');
      } else {
        _claimUnownedRecordsFuture = null;
        _claimUnownedRecordsUserId = null;
      }
    });

    if (AuthService.to.isLoggedIn) {
      final userId = AuthService.to.currentUser.value!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LogService.to.info('Sync', 'Delay startup sync until first frame');
        _claimUnownedRecordsThenSync(userId, reason: 'startup');
      });
    }
  }

  Future<void> _claimUnownedRecordsThenSync(
    String userId, {
    required String reason,
  }) async {
    try {
      await _claimUnownedRecordsForCurrentUser(userId);
      await syncAll(reason: reason);
    } catch (e) {
      LogService.to.error('Sync', '$reason sync bootstrap failed: $e');
    }
  }

  Future<void> _claimUnownedRecordsForCurrentUser(String userId) {
    if (_claimUnownedRecordsUserId != userId) {
      _claimUnownedRecordsUserId = userId;
      _claimUnownedRecordsFuture = null;
    }

    return _claimUnownedRecordsFuture ??= DbService.to
        .claimUnownedRecordsForCurrentUser()
        .catchError((Object e) {
          _claimUnownedRecordsFuture = null;
          LogService.to.error('Sync', 'Claim unowned records failed: $e');
          throw e;
        });
  }

  // --- Work Log Sync ---

  /// Push a single WorkLog to Supabase
  Future<bool> pushWorkLog(WorkLog log) async {
    if (!AuthService.to.isLoggedIn) return false;

    if (log.pendingDelete) {
      if (log.remoteId == null) {
        await DbService.to.purgeDeletedLog(log.id);
        return true;
      }
      final success = await deleteWorkLog(log);
      if (success) {
        await DbService.to.purgeDeletedLog(log.id);
      }
      return success;
    }

    try {
      final user = AuthService.to.currentUser.value!;
      if (log.remoteId == null) {
        log.syncId ??= newSyncId();
      }
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
            .from('work_logs')
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
        await DbService.to.updateWorkLogRemoteId(log);
      } else {
        // Insert
        final response = await _client
            .from('work_logs')
            .insert(data)
            .select('id, sync_id, version, updated_at')
            .single();

        // Update local remoteId
        _applyWorkLogSyncResult(log, response);
        await DbService.to.updateWorkLogRemoteId(log);
      }
      LogService.to.info('Sync', 'WorkLog $operation success: ${log.id}');
      return true;
    } catch (e) {
      LogService.to.error('Sync', 'Push WorkLog failed: $e');
      // Keep isDirty = true
      return false;
    }
  }

  /// Delete a WorkLog from Supabase
  Future<bool> deleteWorkLog(WorkLog log) async {
    if (!AuthService.to.isLoggedIn) return false;
    if (log.remoteId == null) return true;

    try {
      final user = AuthService.to.currentUser.value!;
      var query = _client
          .from('work_logs')
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
    } catch (e) {
      LogService.to.error('Sync', 'Delete WorkLog failed: $e');
      // Queue for retry?
      return false;
    }
  }

  // --- Subscription Sync ---

  Future<bool> pushSubscription(Subscription sub) async {
    if (!AuthService.to.isLoggedIn) return false;

    if (sub.pendingDelete) {
      if (sub.remoteId == null) {
        await DbService.to.purgeDeletedSubscription(sub.id);
        return true;
      }
      final success = await deleteSubscription(sub);
      if (success) {
        await DbService.to.purgeDeletedSubscription(sub.id);
      }
      return success;
    }

    try {
      final user = AuthService.to.currentUser.value!;
      if (sub.remoteId == null) {
        sub.syncId ??= newSyncId();
      }
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
            .from('subscriptions')
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
        await DbService.to.updateSubscriptionRemoteId(sub);
      } else {
        final response = await _client
            .from('subscriptions')
            .insert(data)
            .select('id, sync_id, version, updated_at')
            .single();

        _applySubscriptionSyncResult(sub, response);
        await DbService.to.updateSubscriptionRemoteId(sub);
      }
      LogService.to.info('Sync', 'Subscription $operation success: ${sub.id}');
      return true;
    } catch (e) {
      LogService.to.error('Sync', 'Push Subscription failed: $e');
      return false;
    }
  }

  Future<bool> deleteSubscription(Subscription sub) async {
    if (!AuthService.to.isLoggedIn) return false;
    if (sub.remoteId == null) return true;

    try {
      final user = AuthService.to.currentUser.value!;
      var query = _client
          .from('subscriptions')
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
    } catch (e) {
      LogService.to.error('Sync', 'Delete Subscription failed: $e');
      return false;
    }
  }

  // --- Evidence Sync ---

  Future<String?> _uploadEvidenceFile(ExpenseEvidence evidence) async {
    final user = AuthService.to.currentUser.value;
    final localPath = evidence.localFilePath;
    if (user == null || localPath == null) return evidence.remoteStoragePath;

    final file = File(localPath);
    if (!await file.exists()) return evidence.remoteStoragePath;

    evidence.syncId ??= newSyncId();
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
    await DbService.to.updateEvidenceRemoteId(evidence);
  }

  Future<bool> pushEvidence(ExpenseEvidence evidence) async {
    if (!AuthService.to.isLoggedIn) return false;

    if (evidence.pendingDelete) {
      if (evidence.remoteId == null) {
        await DbService.to.purgeDeletedEvidence(evidence.id);
        return true;
      }
      final success = await deleteEvidence(evidence);
      if (success) {
        await DbService.to.purgeDeletedEvidence(evidence.id);
      }
      return success;
    }

    try {
      final user = AuthService.to.currentUser.value!;
      evidence.syncId ??= newSyncId();
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
            .from('expense_evidence')
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
        await DbService.to.updateEvidenceRemoteId(evidence);
      } else {
        final response = await _client
            .from('expense_evidence')
            .insert(data)
            .select('id, sync_id, version, updated_at')
            .single();
        _applyEvidenceSyncResult(evidence, response);
        await DbService.to.updateEvidenceRemoteId(evidence);
      }
      LogService.to.info('Sync', 'Evidence $operation success: ${evidence.id}');
      return true;
    } catch (e) {
      LogService.to.error('Sync', 'Push Evidence failed: $e');
      return false;
    }
  }

  Future<bool> deleteEvidence(ExpenseEvidence evidence) async {
    if (!AuthService.to.isLoggedIn) return false;
    if (evidence.remoteId == null) return true;

    try {
      final user = AuthService.to.currentUser.value!;
      var query = _client
          .from('expense_evidence')
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
    } catch (e) {
      LogService.to.error('Sync', 'Delete Evidence failed: $e');
      return false;
    }
  }

  // --- Expense Record Sync ---

  Future<bool> pushExpenseRecord(ExpenseRecord record) async {
    if (!AuthService.to.isLoggedIn) return false;

    if (record.pendingDelete) {
      if (record.remoteId == null) {
        await DbService.to.purgeDeletedExpenseRecord(record.id);
        return true;
      }
      final success = await deleteExpenseRecord(record);
      if (success) {
        await DbService.to.purgeDeletedExpenseRecord(record.id);
      }
      return success;
    }

    try {
      final user = AuthService.to.currentUser.value!;
      if (record.remoteId == null) {
        record.syncId ??= newSyncId();
      }
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
            .from('expense_records')
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
        await DbService.to.updateExpenseRecordRemoteId(record);
      } else {
        final response = await _client
            .from('expense_records')
            .insert(data)
            .select('id, sync_id, version, updated_at')
            .single();
        _applyExpenseRecordSyncResult(record, response);
        await DbService.to.updateExpenseRecordRemoteId(record);
      }
      LogService.to.info(
        'Sync',
        'ExpenseRecord $operation success: ${record.id}',
      );
      return true;
    } catch (e) {
      LogService.to.error('Sync', 'Push ExpenseRecord failed: $e');
      return false;
    }
  }

  Future<bool> deleteExpenseRecord(ExpenseRecord record) async {
    if (!AuthService.to.isLoggedIn) return false;
    if (record.remoteId == null) return true;

    try {
      final user = AuthService.to.currentUser.value!;
      var query = _client
          .from('expense_records')
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
    } catch (e) {
      LogService.to.error('Sync', 'Delete ExpenseRecord failed: $e');
      return false;
    }
  }

  // --- Pull Everything ---

  // --- Sync All ---

  Future<bool> syncAll({
    String reason = 'manual',
    bool forceFullRefresh = false,
  }) async {
    if (!AuthService.to.isLoggedIn) return false;

    if (_activeSync != null) {
      LogService.to.debug('Sync', 'Reuse active sync for $reason');
      return _activeSync!;
    }

    final now = DateTime.now();
    final lastStartedAt = _lastSyncStartedAt;
    if (lastStartedAt != null &&
        now.difference(lastStartedAt) < const Duration(seconds: 2)) {
      LogService.to.debug('Sync', 'Skip duplicate sync trigger: $reason');
      return true;
    }

    _lastSyncStartedAt = now;
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
    final response = await _client.rpc('get_server_time');
    if (response == null) {
      throw StateError('get_server_time returned null');
    }
    if (response is String) return DateTime.parse(response);
    return DateTime.parse(response.toString());
  }

  Future<bool> _pullAll({required bool forceFullRefresh}) async {
    try {
      final user = AuthService.to.currentUser.value;
      if (user == null) return false;

      final pullStartedAt = await _getServerNow();
      final cursorStr =
          _storage.read(_lastPullCursorKey) ??
          _storage.read(_legacyLastSyncKey);
      final lastCursor = cursorStr == null ? null : DateTime.parse(cursorStr);
      final fullRefresh = forceFullRefresh || lastCursor == null;

      // 1. Pull Work Logs
      var logsQuery = _client.from('work_logs').select().eq('user_id', user.id);
      final logsData = fullRefresh
          ? await logsQuery
          : await logsQuery
                .gte('updated_at', lastCursor.toIso8601String())
                .lte('updated_at', pullStartedAt.toIso8601String());

      for (var map in logsData) {
        await DbService.to.syncRemoteLogToLocal(map);
      }

      // 2. Pull Subscriptions
      var subsQuery = _client
          .from('subscriptions')
          .select()
          .eq('user_id', user.id);
      final subsData = fullRefresh
          ? await subsQuery
          : await subsQuery
                .gte('updated_at', lastCursor.toIso8601String())
                .lte('updated_at', pullStartedAt.toIso8601String());

      for (var map in subsData) {
        await DbService.to.syncRemoteSubscriptionToLocal(map);
      }

      // 3. Pull Evidence
      var evidenceQuery = _client
          .from('expense_evidence')
          .select()
          .eq('user_id', user.id);
      final evidenceData = fullRefresh
          ? await evidenceQuery
          : await evidenceQuery
                .gte('updated_at', lastCursor.toIso8601String())
                .lte('updated_at', pullStartedAt.toIso8601String());

      for (var map in evidenceData) {
        await DbService.to.syncRemoteEvidenceToLocal(map);
        final syncId = map['sync_id'] as String?;
        if (map['deleted_at'] == null && syncId != null) {
          ExpenseEvidence? evidence;
          for (final item in await DbService.to.getAllEvidence()) {
            if (item.syncId == syncId) {
              evidence = item;
              break;
            }
          }
          if (evidence != null) {
            await downloadEvidenceFile(evidence);
          }
        }
      }

      // 4. Pull one-time expense records
      var expenseRecordsQuery = _client
          .from('expense_records')
          .select()
          .eq('user_id', user.id);
      final expenseRecordsData = fullRefresh
          ? await expenseRecordsQuery
          : await expenseRecordsQuery
                .gte('updated_at', lastCursor.toIso8601String())
                .lte('updated_at', pullStartedAt.toIso8601String());

      for (var map in expenseRecordsData) {
        await DbService.to.syncRemoteExpenseRecordToLocal(map);
      }

      _storage.write(_lastPullCursorKey, pullStartedAt.toIso8601String());

      LogService.to.info(
        'Sync',
        'Pull complete (${fullRefresh ? "full" : "incremental"}): '
            '${logsData.length} logs, ${subsData.length} subscriptions, '
            '${evidenceData.length} evidence, '
            '${expenseRecordsData.length} expenseRecords',
      );
      return true;
    } catch (e) {
      LogService.to.error('Sync', 'Pull failed: $e');
      return false;
    }
  }

  Future<bool> _pushUnsyncedData() async {
    try {
      // Work Logs: unsynced (remoteId == null) or dirty
      final allLogs = await DbService.to.getAllLogsForSync();
      var success = true;
      var workLogAttempts = 0;
      var workLogFailures = 0;
      for (var log in allLogs) {
        if (log.remoteId == null || log.isDirty || log.pendingDelete) {
          workLogAttempts++;
          final pushed = await pushWorkLog(log);
          if (!pushed) workLogFailures++;
          success = pushed && success;
        }
      }

      // Subscriptions
      final allSubs = await DbService.to.getAllSubscriptionsForSync();
      var subscriptionAttempts = 0;
      var subscriptionFailures = 0;
      for (var sub in allSubs) {
        if (sub.remoteId == null || sub.isDirty || sub.pendingDelete) {
          subscriptionAttempts++;
          final pushed = await pushSubscription(sub);
          if (!pushed) subscriptionFailures++;
          success = pushed && success;
        }
      }

      final allEvidence = await DbService.to.getAllEvidenceForSync();
      var evidenceAttempts = 0;
      var evidenceFailures = 0;
      for (var item in allEvidence) {
        if (item.remoteId == null || item.isDirty || item.pendingDelete) {
          evidenceAttempts++;
          final pushed = await pushEvidence(item);
          if (!pushed) evidenceFailures++;
          success = pushed && success;
        }
      }

      final allExpenseRecords = await DbService.to
          .getAllExpenseRecordsForSync();
      var expenseRecordAttempts = 0;
      var expenseRecordFailures = 0;
      for (var item in allExpenseRecords) {
        if (item.remoteId == null || item.isDirty || item.pendingDelete) {
          expenseRecordAttempts++;
          final pushed = await pushExpenseRecord(item);
          if (!pushed) expenseRecordFailures++;
          success = pushed && success;
        }
      }

      LogService.to.info(
        'Sync',
        'Push ${success ? "complete" : "incomplete"}: '
            'workLogs $workLogAttempts attempted/$workLogFailures failed, '
            'subscriptions $subscriptionAttempts attempted/$subscriptionFailures failed, '
            'evidence $evidenceAttempts attempted/$evidenceFailures failed, '
            'expenseRecords $expenseRecordAttempts attempted/$expenseRecordFailures failed',
      );
      return success;
    } catch (e) {
      LogService.to.error('Sync', 'Push failed: $e');
      return false;
    }
  }
}
