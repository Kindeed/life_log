import 'package:get/get.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/common/utils/record_validators.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/modules/project/project_repository.dart';

import 'expense_record_model.dart';

class ExpenseRecordRepository extends GetxService {
  static ExpenseRecordRepository get to => Get.find();

  Future<List<ExpenseRecord>> getAllExpenseRecords() {
    return DbService.to.getAllExpenseRecords();
  }

  Stream<void> watchExpenseRecords() {
    return DbService.to.watchExpenseRecords();
  }

  Future<ExpenseRecord> saveExpenseRecord(ExpenseRecord record) async {
    validateExpenseRecord(record);
    record.syncId = ensureSyncId(record.syncId);
    if (record.projectName?.trim().isNotEmpty == true) {
      final project = await ProjectRepository.to.ensureSyncableProject(
        record.projectName!.trim(),
      );
      record.projectId = project.id;
      record.projectName = project.name;
    }

    await DbService.to.addExpenseRecord(record);
    if (!Get.isRegistered<SyncService>()) {
      LogService.to.info('ExpenseRecordRepository', '本地模式：跳过云端同步');
      return record;
    }

    if (record.remoteId != null && !record.isDirty && !record.pendingDelete) {
      return record;
    }

    try {
      final success = await SyncService.to.pushExpenseRecord(record);
      if (!success) {
        LogService.to.error('ExpenseRecordRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e) {
      LogService.to.error('ExpenseRecordRepository', '云端同步失败: $e');
    }
    return record;
  }

  Future<void> deleteExpenseRecord(int id) async {
    final record = await DbService.to.markExpenseRecordDeleted(id);
    if (record == null) return;

    if (record.remoteId == null) {
      await DbService.to.purgeDeletedExpenseRecord(id);
      return;
    }

    if (!Get.isRegistered<SyncService>()) {
      LogService.to.info('ExpenseRecordRepository', '本地模式：跳过云端删除');
      return;
    }

    final success = await SyncService.to.deleteExpenseRecord(record);
    if (success) {
      await DbService.to.purgeDeletedExpenseRecord(id);
    }
  }
}
