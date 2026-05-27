import 'dart:async';

import 'package:get/get.dart';
import '../../../common/db/db_service.dart';
import '../../../common/services/sync_service.dart';
import '../../../common/services/log_service.dart';
import '../../../common/utils/date_utils.dart';
import '../../../common/utils/record_validators.dart';
import '../../../common/utils/sync_id_generator.dart';
import 'work_log_model.dart';

class WorkLogRepository extends GetxService {
  static WorkLogRepository get to => Get.find();
  Future<void>? _duplicateDayMutationFuture;

  // --- 查询业务 ---
  Future<List<WorkLog>> getAllLogs() async {
    return await DbService.to.getAllLogs();
  }

  Future<List<WorkLog>> getLogsByMonth(DateTime month) async {
    return await DbService.to.getLogsByMonth(month);
  }

  Stream<void> watchLogs() {
    return DbService.to.watchWorkLogs();
  }

  Future<void> normalizeDuplicateDays() =>
      _runDuplicateDayMutation(_normalizeDuplicateDays);

  Future<void> _runDuplicateDayMutation(Future<void> Function() operation) {
    final previous = _duplicateDayMutationFuture;

    Future<void> runAfterPrevious() async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {
          // Keep later duplicate-day work from being permanently blocked.
        }
      }
      await operation();
    }

    late final Future<void> tracked;
    tracked = runAfterPrevious().whenComplete(() {
      if (identical(_duplicateDayMutationFuture, tracked)) {
        _duplicateDayMutationFuture = null;
      }
    });
    _duplicateDayMutationFuture = tracked;
    return tracked;
  }

  Future<void> _normalizeDuplicateDays() async {
    final allLogs = await getAllLogs();
    final grouped = <DateTime, List<WorkLog>>{};
    for (final log in allLogs) {
      grouped.putIfAbsent(dateOnlyLocal(log.date), () => <WorkLog>[]).add(log);
    }

    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      final canonical = entry.value.latestByLocalDate()[entry.key];
      if (canonical == null) continue;

      for (final duplicate in entry.value) {
        if (duplicate.id == canonical.id) continue;
        await _deleteStoredLog(duplicate);
      }
      LogService.to.info(
        'WorkLogRepository',
        '归并同日重复工时记录: ${entry.key}，保留 ID ${canonical.id}',
      );
    }
  }

  // --- 修改业务 ---
  Future<void> saveLog(WorkLog log) {
    return _runDuplicateDayMutation(() => _saveLog(log));
  }

  Future<void> _saveLog(WorkLog log) async {
    log.date = dateOnlyLocal(log.date);
    final sameDayLogs = await _sameDayLogs(log.date);
    final existing = _resolveCanonicalLog(log, sameDayLogs);
    if (existing != null) {
      _adoptCanonicalIdentity(log, existing);
    }

    validateWorkLog(log);
    log.syncId ??= SyncIdGenerator.newSyncId();

    // 1. 本地存储 (包含产生 dirty/remoteId)
    await DbService.to.addLog(log);

    for (final duplicate in sameDayLogs) {
      if (duplicate.id == log.id) continue;
      await _deleteStoredLog(duplicate);
    }

    _pushWorkLogInBackground(log);
  }

  void _pushWorkLogInBackground(WorkLog log) {
    if (!Get.isRegistered<SyncService>()) {
      LogService.to.info('WorkLogRepository', '本地模式：跳过云端同步');
      return;
    }

    if (log.remoteId != null && !log.isDirty && !log.pendingDelete) {
      return;
    }

    unawaited(_pushWorkLogSafely(log));
  }

  Future<void> _pushWorkLogSafely(WorkLog log) async {
    try {
      final success = await SyncService.to.pushWorkLog(log);
      if (!success) {
        LogService.to.error('WorkLogRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e) {
      LogService.to.error('WorkLogRepository', '云端同步失败: $e');
    }
  }

  Future<List<WorkLog>> _sameDayLogs(DateTime date) async {
    return DbService.to.getLogsForDay(date);
  }

  WorkLog? _resolveCanonicalLog(WorkLog incoming, List<WorkLog> sameDayLogs) {
    for (final item in sameDayLogs) {
      if (item.id == incoming.id) {
        return item;
      }
    }
    if (sameDayLogs.isEmpty) return null;
    final day = dateOnlyLocal(incoming.date);
    return sameDayLogs.latestByLocalDate()[day] ?? sameDayLogs.first;
  }

  void _adoptCanonicalIdentity(WorkLog incoming, WorkLog existing) {
    incoming.id = existing.id;
    incoming.ownerUserId = existing.ownerUserId;
    incoming.remoteId = existing.remoteId;
    incoming.syncId = existing.syncId;
    incoming.remoteVersion = existing.remoteVersion;
    incoming.remoteUpdatedAt = existing.remoteUpdatedAt;
    incoming.syncedAt = existing.syncedAt;
    incoming.createdAt ??= existing.createdAt;
    incoming.updatedAt ??= existing.updatedAt;
    incoming.deletedAt = existing.deletedAt;
    incoming.pendingDelete = existing.pendingDelete;
    incoming.isDirty = incoming.isDirty || existing.isDirty;
  }

  // 删除业务逻辑
  Future<void> deleteLog(int id) async {
    final log = await DbService.to.getWorkLog(id);
    if (log == null) return;

    final sameDayLogs = await _sameDayLogs(log.date);

    for (final item in sameDayLogs) {
      await _deleteStoredLog(item);
    }
  }

  Future<void> _deleteStoredLog(WorkLog target) async {
    final log = await DbService.to.markLogDeleted(target.id);

    try {
      if (log == null || log.remoteId == null) {
        await DbService.to.purgeDeletedLog(target.id);
      } else if (!Get.isRegistered<SyncService>()) {
        LogService.to.info('WorkLogRepository', '本地模式：跳过云端删除');
      } else {
        final success = await SyncService.to.deleteWorkLog(log);
        if (success) {
          await DbService.to.purgeDeletedLog(target.id);
        }
      }
    } catch (e) {
      LogService.to.error('WorkLogRepository', '云端删除失败: $e');
    }
  }
}
