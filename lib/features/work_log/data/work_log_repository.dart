import 'dart:async';

import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/record_validators.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/features/work_log/data/work_log_local_data_source.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:life_log/features/work_log/data/work_log_sync_gateway.dart';

class WorkLogRepository {
  WorkLogRepository({
    WorkLogLocalDataSource? localDataSource,
    WorkLogSyncGateway? syncGateway,
  }) : _localDataSource = localDataSource ?? const DbWorkLogLocalDataSource(),
       _syncGateway = syncGateway ?? const ServiceLocatorWorkLogSyncGateway();

  final WorkLogLocalDataSource _localDataSource;
  final WorkLogSyncGateway _syncGateway;
  Future<void>? _duplicateDayMutationFuture;

  // --- 查询业务 ---
  Future<List<WorkLog>> getAllLogs() async {
    return await _localDataSource.getAllLogs();
  }

  Future<List<WorkLog>> getLogsByMonth(DateTime month) async {
    return await _localDataSource.getLogsByMonth(month);
  }

  Stream<void> watchLogs() {
    return _localDataSource.watchWorkLogs();
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
    log.syncId = ensureSyncId(log.syncId);

    // 1. 本地存储 (包含产生 dirty/remoteId)
    await _localDataSource.addLog(log);

    for (final duplicate in sameDayLogs) {
      if (duplicate.id == log.id) continue;
      await _deleteStoredLog(duplicate);
    }

    _pushWorkLogInBackground(log);
  }

  void _pushWorkLogInBackground(WorkLog log) {
    if (!_syncGateway.isAvailable) {
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
      final success = await _syncGateway.pushWorkLog(log);
      if (!success) {
        LogService.to.error('WorkLogRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e, stackTrace) {
      LogService.to.error('WorkLogRepository', '云端同步失败: $e', stackTrace);
    }
  }

  Future<List<WorkLog>> _sameDayLogs(DateTime date) async {
    return _localDataSource.getLogsForDay(date);
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
    final log = await _localDataSource.getWorkLog(id);
    if (log == null) return;

    final sameDayLogs = await _sameDayLogs(log.date);

    for (final item in sameDayLogs) {
      await _deleteStoredLog(item);
    }
  }

  Future<void> _deleteStoredLog(WorkLog target) async {
    final log = await _localDataSource.markLogDeleted(target.id);

    try {
      if (log == null || log.remoteId == null) {
        await _localDataSource.purgeDeletedLog(target.id);
      } else if (!_syncGateway.isAvailable) {
        LogService.to.info('WorkLogRepository', '本地模式：跳过云端删除');
      } else {
        final success = await _syncGateway.deleteWorkLog(log);
        if (success) {
          await _localDataSource.purgeDeletedLog(target.id);
        }
      }
    } catch (e, stackTrace) {
      LogService.to.error('WorkLogRepository', '云端删除失败: $e', stackTrace);
    }
  }
}
