import 'package:isar/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';

class EvidenceDao {
  final IsarDatabase database;

  const EvidenceDao(this.database);

  Isar get _isar => database.isar;

  Future<ExpenseEvidence?> getById(int id) {
    return _isar.expenseEvidences.get(id);
  }

  Future<ExpenseEvidence?> getBySyncId(String syncId) {
    return _isar.expenseEvidences.filter().syncIdEqualTo(syncId).findFirst();
  }

  Future<List<ExpenseEvidence>> getAllSorted() {
    return _isar.expenseEvidences.where().sortByEvidenceDateDesc().findAll();
  }

  Future<List<ExpenseEvidence>> getActiveSortedForOwner(String? ownerUserId) {
    return _isar.expenseEvidences
        .filter()
        .ownerVisibleTo(ownerUserId)
        .and()
        .deletedAtIsNull()
        .sortByEvidenceDateDesc()
        .findAll();
  }

  Future<List<ExpenseEvidence>> getPendingForSync() {
    return _isar.expenseEvidences
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByEvidenceDateDesc()
        .findAll();
  }

  Future<List<ExpenseEvidence>> getPendingForSyncForOwner(
    String? ownerUserId,
  ) async {
    final byId = <int, ExpenseEvidence>{};
    for (final items in [
      await _pendingRemoteMissingForOwner(ownerUserId),
      await _pendingDirtyForOwner(ownerUserId),
      await _pendingDeleteForOwner(ownerUserId),
    ]) {
      for (final item in items) {
        byId[item.id] = item;
      }
    }
    final pending = byId.values.toList()
      ..sort((a, b) => b.evidenceDate.compareTo(a.evidenceDate));
    return pending;
  }

  Future<List<ExpenseEvidence>> _pendingRemoteMissingForOwner(
    String? ownerUserId,
  ) {
    return _isar.expenseEvidences
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .remoteIdIsNull()
        .findAll();
  }

  Future<List<ExpenseEvidence>> _pendingDirtyForOwner(String? ownerUserId) {
    return _isar.expenseEvidences
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .isDirtyEqualTo(true)
        .findAll();
  }

  Future<List<ExpenseEvidence>> _pendingDeleteForOwner(String? ownerUserId) {
    return _isar.expenseEvidences
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .pendingDeleteEqualTo(true)
        .findAll();
  }

  Stream<void> watch() {
    return _isar.expenseEvidences.watchLazy();
  }

  Future<void> delete(int id) async {
    await database.writeTxn(() async {
      await _isar.expenseEvidences.delete(id);
    });
  }
}

extension _EvidenceOwnerFilter
    on QueryBuilder<ExpenseEvidence, ExpenseEvidence, QFilterCondition> {
  QueryBuilder<ExpenseEvidence, ExpenseEvidence, QAfterFilterCondition>
  ownerVisibleTo(String? ownerUserId) {
    return ownerUserId == null
        ? ownerUserIdIsNull()
        : group(
            (query) =>
                query.ownerUserIdIsNull().or().ownerUserIdEqualTo(ownerUserId),
          );
  }

  QueryBuilder<ExpenseEvidence, ExpenseEvidence, QAfterFilterCondition>
  ownerMatches(String? ownerUserId) {
    return ownerUserId == null
        ? ownerUserIdIsNull()
        : ownerUserIdEqualTo(ownerUserId);
  }
}
