import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';

abstract interface class ExpenseRecordSyncGateway {
  bool get isAvailable;
  Future<bool> pushExpenseRecord(ExpenseRecord record);
  Future<bool> deleteExpenseRecord(ExpenseRecord record);
}

final class ServiceLocatorExpenseRecordSyncGateway
    implements ExpenseRecordSyncGateway {
  const ServiceLocatorExpenseRecordSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncService>();

  @override
  Future<bool> deleteExpenseRecord(ExpenseRecord record) {
    return serviceLocator<SyncService>().deleteExpenseRecord(record);
  }

  @override
  Future<bool> pushExpenseRecord(ExpenseRecord record) {
    return serviceLocator<SyncService>().pushExpenseRecord(record);
  }
}
