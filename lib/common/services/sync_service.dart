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
  final _lastSyncKey = 'last_sync_time';

  @override
  void onInit() {
    super.onInit();
    // Auto-pull on login
    ever(AuthService.to.currentUser, (user) {
      if (user != null) {
        syncAll();
      }
    });

    // Initial check
    if (AuthService.to.isLoggedIn) {
      syncAll();
    }
  }

  // --- Work Log Sync ---

  /// Push a single WorkLog to Supabase
  Future<void> pushWorkLog(WorkLog log) async {
    if (!AuthService.to.isLoggedIn) return;

    try {
      final user = AuthService.to.currentUser.value!;
      final data = {
        'user_id': user.id,
        'local_id': log.id,
        'date': log.date.toIso8601String(),
        'type': log.type.name,
        'duration': log.overtimeHours,
        'project_name': log.type == LogType.businessTrip
            ? log.location
            : null, // Reuse location as project/loc
        'notes': log.note,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (log.remoteId != null) {
        // Update
        await _client.from('work_logs').update(data).eq('id', log.remoteId!);
      } else {
        // Insert
        final response = await _client
            .from('work_logs')
            .insert(data)
            .select('id')
            .single();

        // Update local remoteId
        log.remoteId = response['id'] as int;
        log.syncedAt = DateTime.now();
        log.isDirty = false;
        await DbService.to.updateWorkLogRemoteId(log);
      }
      LogService.to.info(
        'Sync',
        'WorkLog ${log.isDirty ? "update" : "push"} success: ${log.id}',
      );
    } catch (e) {
      LogService.to.error('Sync', 'Push WorkLog failed: $e');
      // Keep isDirty = true
    }
  }

  /// Delete a WorkLog from Supabase
  Future<void> deleteWorkLog(int remoteId) async {
    if (!AuthService.to.isLoggedIn) return;

    try {
      await _client.from('work_logs').delete().eq('id', remoteId);
      LogService.to.info('Sync', 'WorkLog delete success: $remoteId');
    } catch (e) {
      LogService.to.error('Sync', 'Delete WorkLog failed: $e');
      // Queue for retry?
    }
  }

  // --- Subscription Sync ---

  Future<void> pushSubscription(Subscription sub) async {
    if (!AuthService.to.isLoggedIn) return;

    try {
      final user = AuthService.to.currentUser.value!;
      final data = {
        'user_id': user.id,
        'name': sub.name,
        'price': sub.price,
        'cycle': sub.cycle.name,
        'start_date': sub.nextPaymentDate
            .toIso8601String(), // Using nextPaymentDate as the date anchor
        'description': sub.note,
        'sort_index': sub.sortIndex,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (sub.remoteId != null) {
        await _client
            .from('subscriptions')
            .update(data)
            .eq('id', sub.remoteId!);
      } else {
        final response = await _client
            .from('subscriptions')
            .insert(data)
            .select('id')
            .single();

        sub.remoteId = response['id'] as int;
        sub.syncedAt = DateTime.now();
        sub.isDirty = false;
        await DbService.to.updateSubscriptionRemoteId(sub);
      }
      LogService.to.info(
        'Sync',
        'Subscription ${sub.isDirty ? "update" : "push"} success: ${sub.id}',
      );
    } catch (e) {
      LogService.to.error('Sync', 'Push Subscription failed: $e');
    }
  }

  Future<void> deleteSubscription(int remoteId) async {
    if (!AuthService.to.isLoggedIn) return;

    try {
      await _client.from('subscriptions').delete().eq('id', remoteId);
      LogService.to.info('Sync', 'Subscription delete success: $remoteId');
    } catch (e) {
      LogService.to.error('Sync', 'Delete Subscription failed: $e');
    }
  }

  // --- Pull Everything ---

  // --- Sync All ---

  Future<bool> syncAll() async {
    if (!AuthService.to.isLoggedIn) return false;

    // 1. Pull (Download)
    final pullSuccess = await _pullAll();
    if (!pullSuccess) return false;

    // 2. Push (Upload dirty/new data)
    final pushSuccess = await _pushUnsyncedData();
    return pushSuccess;
  }

  Future<bool> _pullAll() async {
    final lastSyncStr = _storage.read(_lastSyncKey);
    final lastSync = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime(1970);

    try {
      // 1. Pull Work Logs
      final logsData = await _client
          .from('work_logs')
          .select()
          .gt('updated_at', lastSync.toIso8601String());

      for (var map in logsData) {
        await DbService.to.syncRemoteLogToLocal(map);
      }

      // 2. Pull Subscriptions
      final subsData = await _client
          .from('subscriptions')
          .select()
          .gt('updated_at', lastSync.toIso8601String());

      for (var map in subsData) {
        await DbService.to.syncRemoteSubscriptionToLocal(map);
      }

      // Update Last Sync
      _storage.write(_lastSyncKey, DateTime.now().toUtc().toIso8601String());
      LogService.to.info('Sync', 'Pull complete');
      return true;
    } catch (e) {
      LogService.to.error('Sync', 'Pull failed: $e');
      return false;
    }
  }

  Future<bool> _pushUnsyncedData() async {
    try {
      // Work Logs: unsynced (remoteId == null) or dirty
      final allLogs = await DbService.to.getAllLogs();
      for (var log in allLogs) {
        if (log.remoteId == null || log.isDirty) {
          await pushWorkLog(log);
        }
      }

      // Subscriptions
      final allSubs = await DbService.to.getAllSubscriptions();
      for (var sub in allSubs) {
        if (sub.remoteId == null || sub.isDirty) {
          await pushSubscription(sub);
        }
      }

      LogService.to.info('Sync', 'Push complete');
      return true;
    } catch (e) {
      LogService.to.error('Sync', 'Push failed: $e');
      return false;
    }
  }
}
