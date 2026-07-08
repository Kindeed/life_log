import 'dart:async';

import 'package:isar/isar.dart';
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
    for (final log in allLogs) {
      final normalizedDate = dateOnlyLocal(log.date);
      if (log.date != normalizedDate) {
        log.date = normalizedDate;
        await _localDataSource.addLog(log);
      }
    }
  }

  // --- 修改业务 ---
  Future<void> saveLog(WorkLog log) {
    return _runDuplicateDayMutation(() => _saveLog(log));
  }

  Future<void> _saveLog(WorkLog log) async {
    log.date = dateOnlyLocal(log.date);

    await _adoptExistingSameDayWorkIdentity(log);

    validateWorkLog(log);
    log.syncId = ensureSyncId(log.syncId);

    // 1. 本地存储 (包含产生 dirty/remoteId)
    await _localDataSource.addLog(log);

    _requestWorkLogSyncInBackground(log, reason: 'work-log-save');
  }

  void _requestWorkLogSyncInBackground(WorkLog log, {required String reason}) {
    if (!_syncGateway.isAvailable) {
      LogService.to.info('WorkLogRepository', '本地模式：跳过云端同步');
      return;
    }

    if (log.remoteId != null && !log.isDirty && !log.pendingDelete) {
      return;
    }

    unawaited(_requestWorkLogSyncSafely(log, reason: reason));
  }

  Future<void> _requestWorkLogSyncSafely(
    WorkLog log, {
    required String reason,
  }) async {
    try {
      final success = await _syncGateway.requestSync(log, reason: reason);
      if (!success) {
        LogService.to.error('WorkLogRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e, stackTrace) {
      LogService.to.error('WorkLogRepository', '云端同步失败: $e', stackTrace);
    }
  }

  Future<void> _adoptExistingSameDayWorkIdentity(WorkLog log) async {
    if (!_isNewRecordId(log.id) || log.type != LogType.work) return;

    final sameDayLogs = await _localDataSource.getLogsForDay(log.date);
    WorkLog? existingWork;
    for (final existing in sameDayLogs) {
      if (existing.type != LogType.work) continue;
      if (existingWork == null ||
          _isNewerStoredWorkLog(existing, existingWork)) {
        existingWork = existing;
      }
    }
    if (existingWork == null) return;

    log
      ..id = existingWork.id
      ..ownerUserId = existingWork.ownerUserId
      ..remoteId = existingWork.remoteId
      ..syncId = existingWork.syncId
      ..remoteVersion = existingWork.remoteVersion
      ..remoteUpdatedAt = existingWork.remoteUpdatedAt
      ..syncedAt = existingWork.syncedAt
      ..createdAt = existingWork.createdAt
      ..isDirty = log.isDirty || existingWork.isDirty;
  }

  // 删除业务逻辑
  Future<void> deleteLog(int id) async {
    final log = await _localDataSource.getWorkLog(id);
    if (log == null) return;

    await _deleteStoredLog(log);
  }

  Future<void> _deleteStoredLog(WorkLog target) async {
    final log = await _localDataSource.markLogDeleted(target.id);

    try {
      if (log == null || (log.remoteId == null && log.syncId == null)) {
        await _localDataSource.purgeDeletedLog(target.id);
      } else if (!_syncGateway.isAvailable) {
        LogService.to.info('WorkLogRepository', '本地模式：跳过云端删除');
      } else {
        final success = await _syncGateway.requestSync(
          log,
          reason: 'work-log-delete',
        );
        if (success) {
          await _localDataSource.purgeDeletedLog(target.id);
        }
      }
    } catch (e, stackTrace) {
      LogService.to.error('WorkLogRepository', '云端删除失败: $e', stackTrace);
    }
  }
}

bool _isNewRecordId(Id id) => id == Isar.autoIncrement || id == 0;

bool _isNewerStoredWorkLog(WorkLog next, WorkLog current) {
  final nextTime = next.updatedAt ?? next.createdAt ?? next.date;
  final currentTime = current.updatedAt ?? current.createdAt ?? current.date;
  final timeCompare = nextTime.compareTo(currentTime);
  if (timeCompare != 0) return timeCompare > 0;
  return next.id > current.id;
}
