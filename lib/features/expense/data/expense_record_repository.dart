import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/utils/record_validators.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/features/expense/data/expense_record_local_data_source.dart';
import 'package:life_log/features/expense/data/expense_record_project_linker.dart';
import 'package:life_log/features/expense/data/expense_record_sync_gateway.dart';

import 'expense_record_model.dart';

class ExpenseRecordRepository {
  ExpenseRecordRepository({
    ExpenseRecordLocalDataSource? localDataSource,
    ExpenseRecordSyncGateway? syncGateway,
    ExpenseRecordProjectLinker? projectLinker,
  }) : _localDataSource =
           localDataSource ?? const DbExpenseRecordLocalDataSource(),
       _syncGateway =
           syncGateway ?? const ServiceLocatorExpenseRecordSyncGateway(),
       _projectLinker =
           projectLinker ?? const GetItExpenseRecordProjectLinker();

  final ExpenseRecordLocalDataSource _localDataSource;
  final ExpenseRecordSyncGateway _syncGateway;
  final ExpenseRecordProjectLinker _projectLinker;

  Future<List<ExpenseRecord>> getAllExpenseRecords() {
    return _localDataSource.getAllExpenseRecords();
  }

  Stream<void> watchExpenseRecords() {
    return _localDataSource.watchExpenseRecords();
  }

  Future<ExpenseRecord> saveExpenseRecord(ExpenseRecord record) async {
    validateExpenseRecord(record);
    record.syncId = ensureSyncId(record.syncId);
    if (record.projectName?.trim().isNotEmpty == true) {
      final project = await _projectLinker.ensureSyncableProject(
        record.projectName!.trim(),
      );
      record.projectId = project.id;
      record.projectName = project.name;
      record.projectSyncId = project.syncId;
    }

    await _localDataSource.addExpenseRecord(record);
    if (!_syncGateway.isAvailable) {
      LogService.to.info('ExpenseRecordRepository', '本地模式：跳过云端同步');
      return record;
    }

    if (record.remoteId != null && !record.isDirty && !record.pendingDelete) {
      return record;
    }

    try {
      final success = await _syncGateway.requestSync(
        record,
        reason: 'expense-record-save',
      );
      if (!success) {
        LogService.to.error('ExpenseRecordRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e, stackTrace) {
      LogService.to.error('ExpenseRecordRepository', '云端同步失败: $e', stackTrace);
    }
    return record;
  }

  Future<void> deleteExpenseRecord(int id) async {
    final record = await _localDataSource.markExpenseRecordDeleted(id);
    if (record == null) return;

    if (record.remoteId == null && record.syncId == null) {
      await _localDataSource.purgeDeletedExpenseRecord(id);
      return;
    }

    if (!_syncGateway.isAvailable) {
      LogService.to.info('ExpenseRecordRepository', '本地模式：跳过云端删除');
      return;
    }

    final success = await _syncGateway.requestSync(
      record,
      reason: 'expense-record-delete',
    );
    if (success) {
      await _localDataSource.purgeDeletedExpenseRecord(id);
    }
  }
}
