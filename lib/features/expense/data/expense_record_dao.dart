import 'package:isar/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';

class ExpenseRecordDao {
  final IsarDatabase database;

  const ExpenseRecordDao(this.database);

  Isar get _isar => database.isar;

  Future<ExpenseRecord?> getById(int id) {
    return _isar.expenseRecords.get(id);
  }

  Future<List<ExpenseRecord>> getAllSorted() {
    return _isar.expenseRecords.where().sortByExpenseDateDesc().findAll();
  }

  Future<List<ExpenseRecord>> getActiveSortedForOwner(String? ownerUserId) {
    return _isar.expenseRecords
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .deletedAtIsNull()
        .sortByExpenseDateDesc()
        .findAll();
  }

  Future<List<ExpenseRecord>> getPendingForSync() {
    return _isar.expenseRecords
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByExpenseDateDesc()
        .findAll();
  }

  Future<List<ExpenseRecord>> getPendingForSyncForOwner(
    String? ownerUserId,
  ) async {
    final byId = <int, ExpenseRecord>{};
    for (final records in [
      await _pendingRemoteMissingForOwner(ownerUserId),
      await _pendingDirtyForOwner(ownerUserId),
      await _pendingDeleteForOwner(ownerUserId),
    ]) {
      for (final record in records) {
        byId[record.id] = record;
      }
    }
    final pending = byId.values.toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return pending;
  }

  Future<List<ExpenseRecord>> _pendingRemoteMissingForOwner(
    String? ownerUserId,
  ) {
    return _isar.expenseRecords
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .remoteIdIsNull()
        .findAll();
  }

  Future<List<ExpenseRecord>> _pendingDirtyForOwner(String? ownerUserId) {
    return _isar.expenseRecords
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .isDirtyEqualTo(true)
        .findAll();
  }

  Future<List<ExpenseRecord>> _pendingDeleteForOwner(String? ownerUserId) {
    return _isar.expenseRecords
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .pendingDeleteEqualTo(true)
        .findAll();
  }

  Stream<void> watch() {
    return _isar.expenseRecords.watchLazy();
  }

  Future<void> delete(int id) async {
    await database.writeTxn(() async {
      await _isar.expenseRecords.delete(id);
    });
  }
}

extension _ExpenseRecordOwnerFilter
    on QueryBuilder<ExpenseRecord, ExpenseRecord, QFilterCondition> {
  QueryBuilder<ExpenseRecord, ExpenseRecord, QAfterFilterCondition>
  ownerMatches(String? ownerUserId) {
    return ownerUserId == null
        ? ownerUserIdIsNull()
        : ownerUserIdEqualTo(ownerUserId);
  }
}
