import 'dart:math';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import '../../modules/work_log/work_log_model.dart';
import '../../modules/subscription/subscription_model.dart';
import '../db/db_service.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';

class SyncService extends GetxService {
  static SyncService get to => Get.find();

  final _client = Supabase.instance.client;
  final _storage = GetStorage();
  final _random = Random.secure();
  Future<bool>? _activeSync;
  DateTime? _lastSyncStartedAt;

  String get _lastSyncKey {
    final user = AuthService.to.currentUser.value;
    return user != null ? 'last_sync_time_${user.id}' : 'last_sync_time';
  }

  String get _lastPullCursorKey {
    final user = AuthService.to.currentUser.value;
    return user != null ? 'last_pull_cursor_${user.id}' : 'last_pull_cursor';
  }

  String get _legacyLastSyncKey => _lastSyncKey;

  String newSyncId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

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

  @override
  void onInit() {
    super.onInit();
    ever(AuthService.to.currentUser, (user) {
      if (user != null) {
        syncAll(reason: 'auth');
      }
    });

    if (AuthService.to.isLoggedIn) {
      syncAll(reason: 'startup');
    }
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

      _storage.write(_lastPullCursorKey, pullStartedAt.toIso8601String());

      LogService.to.info(
        'Sync',
        'Pull complete (${fullRefresh ? "full" : "incremental"}): '
            '${logsData.length} logs, ${subsData.length} subscriptions',
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

      LogService.to.info(
        'Sync',
        'Push ${success ? "complete" : "incomplete"}: '
            'workLogs $workLogAttempts attempted/$workLogFailures failed, '
            'subscriptions $subscriptionAttempts attempted/$subscriptionFailures failed',
      );
      return success;
    } catch (e) {
      LogService.to.error('Sync', 'Push failed: $e');
      return false;
    }
  }
}
