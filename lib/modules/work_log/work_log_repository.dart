import 'package:get/get.dart';
import '../../../common/db/db_service.dart';
import '../../../common/services/sync_service.dart';
import '../../../common/services/log_service.dart';
import '../../../common/utils/record_validators.dart';
import '../../../common/utils/sync_id_generator.dart';
import 'work_log_model.dart';

class WorkLogRepository extends GetxService {
  static WorkLogRepository get to => Get.find();

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

  // --- 修改业务 ---
  Future<void> saveLog(WorkLog log) async {
    validateWorkLog(log);
    log.syncId ??= SyncIdGenerator.newSyncId();

    // 1. 本地存储 (包含产生 dirty/remoteId)
    await DbService.to.addLog(log);

    if (!Get.isRegistered<SyncService>()) {
      LogService.to.info('WorkLogRepository', '本地模式：跳过云端同步');
      return;
    }

    if (log.remoteId != null && !log.isDirty && !log.pendingDelete) {
      return;
    }

    // 2. 触发云端同步 (不抛出异常以保证离线可用)
    try {
      final success = await SyncService.to.pushWorkLog(log);
      if (!success) {
        LogService.to.error('WorkLogRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e) {
      LogService.to.error('WorkLogRepository', '云端同步失败: $e');
    }
  }

  // 删除业务逻辑
  Future<void> deleteLog(int id) async {
    final log = await DbService.to.markLogDeleted(id);

    try {
      if (log == null || log.remoteId == null) {
        await DbService.to.purgeDeletedLog(id);
      } else if (!Get.isRegistered<SyncService>()) {
        LogService.to.info('WorkLogRepository', '本地模式：跳过云端删除');
      } else {
        final success = await SyncService.to.deleteWorkLog(log);
        if (success) {
          await DbService.to.purgeDeletedLog(id);
        }
      }
    } catch (e) {
      LogService.to.error('WorkLogRepository', '云端删除失败: $e');
    }
  }
}
