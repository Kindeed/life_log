import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';

abstract interface class ExpenseRecordSyncGateway {
  bool get isAvailable;
  Future<bool> requestSync(ExpenseRecord record, {required String reason});
}

final class ServiceLocatorExpenseRecordSyncGateway
    implements ExpenseRecordSyncGateway {
  const ServiceLocatorExpenseRecordSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncScheduler>();

  @override
  Future<bool> requestSync(ExpenseRecord record, {required String reason}) {
    return serviceLocator<SyncScheduler>().requestSync(
      reason: reason,
      entityName: 'expense_record',
      entityKey: record.syncId ?? record.id.toString(),
    );
  }
}
