import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';

abstract interface class ExpenseRecordLocalDataSource {
  Future<List<ExpenseRecord>> getAllExpenseRecords();
  Stream<void> watchExpenseRecords();
  Future<int> addExpenseRecord(ExpenseRecord record);
  Future<ExpenseRecord?> markExpenseRecordDeleted(int id);
  Future<void> purgeDeletedExpenseRecord(int id);
}

final class DbExpenseRecordLocalDataSource
    implements ExpenseRecordLocalDataSource {
  const DbExpenseRecordLocalDataSource();

  @override
  Future<int> addExpenseRecord(ExpenseRecord record) {
    return serviceLocator<DbService>().addExpenseRecord(record);
  }

  @override
  Future<List<ExpenseRecord>> getAllExpenseRecords() {
    return serviceLocator<DbService>().getAllExpenseRecords();
  }

  @override
  Future<ExpenseRecord?> markExpenseRecordDeleted(int id) {
    return serviceLocator<DbService>().markExpenseRecordDeleted(id);
  }

  @override
  Future<void> purgeDeletedExpenseRecord(int id) {
    return serviceLocator<DbService>().purgeDeletedExpenseRecord(id);
  }

  @override
  Stream<void> watchExpenseRecords() {
    return serviceLocator<DbService>().watchExpenseRecords();
  }
}
