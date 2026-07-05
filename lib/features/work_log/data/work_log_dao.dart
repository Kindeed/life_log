import 'package:isar/isar.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

class WorkLogDao {
  final IsarDatabase database;

  const WorkLogDao(this.database);

  Isar get _isar => database.isar;

  Future<WorkLog?> getById(int id) {
    return _isar.workLogs.get(id);
  }

  Future<List<WorkLog>> getByMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _isar.workLogs
        .filter()
        .dateGreaterThan(start, include: true)
        .and()
        .dateLessThan(end, include: false)
        .sortByDate()
        .findAll();
  }

  Future<List<WorkLog>> getActiveByMonthForOwner(
    DateTime month,
    String? ownerUserId,
  ) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final query = _isar.workLogs
        .filter()
        .ownerVisibleTo(ownerUserId)
        .and()
        .deletedAtIsNull()
        .and()
        .dateGreaterThan(start, include: true)
        .and()
        .dateLessThan(end, include: false);
    return query.sortByDate().findAll();
  }

  Future<List<WorkLog>> getAllSorted() {
    return _isar.workLogs.where().sortByDate().findAll();
  }

  Future<List<WorkLog>> getActiveSortedForOwner(String? ownerUserId) {
    return _isar.workLogs
        .filter()
        .ownerVisibleTo(ownerUserId)
        .and()
        .deletedAtIsNull()
        .sortByDate()
        .findAll();
  }

  Future<List<WorkLog>> getByDay(DateTime date) {
    final day = dateOnlyLocal(date);
    final nextDay = day.add(const Duration(days: 1));
    return _isar.workLogs
        .filter()
        .dateGreaterThan(day, include: true)
        .and()
        .dateLessThan(nextDay, include: false)
        .sortByDate()
        .findAll();
  }

  Future<List<WorkLog>> getActiveByDayForOwner(
    DateTime date,
    String? ownerUserId,
  ) {
    final day = dateOnlyLocal(date);
    final nextDay = day.add(const Duration(days: 1));
    return _isar.workLogs
        .filter()
        .ownerVisibleTo(ownerUserId)
        .and()
        .deletedAtIsNull()
        .and()
        .dateGreaterThan(day, include: true)
        .and()
        .dateLessThan(nextDay, include: false)
        .sortByDate()
        .findAll();
  }

  Future<List<WorkLog>> getAllForSync() {
    return _isar.workLogs.where().sortByDate().findAll();
  }

  Future<List<WorkLog>> getPendingForSync() {
    return _isar.workLogs
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByDate()
        .findAll();
  }

  Future<List<WorkLog>> getPendingForSyncForOwner(String? ownerUserId) async {
    final byId = <int, WorkLog>{};
    for (final logs in [
      await _pendingRemoteMissingForOwner(ownerUserId),
      await _pendingDirtyForOwner(ownerUserId),
      await _pendingDeleteForOwner(ownerUserId),
    ]) {
      for (final log in logs) {
        byId[log.id] = log;
      }
    }
    final pending = byId.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return pending;
  }

  Future<List<WorkLog>> _pendingRemoteMissingForOwner(String? ownerUserId) {
    return _isar.workLogs
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .remoteIdIsNull()
        .findAll();
  }

  Future<List<WorkLog>> _pendingDirtyForOwner(String? ownerUserId) {
    return _isar.workLogs
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .isDirtyEqualTo(true)
        .findAll();
  }

  Future<List<WorkLog>> _pendingDeleteForOwner(String? ownerUserId) {
    return _isar.workLogs
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .pendingDeleteEqualTo(true)
        .findAll();
  }

  Stream<void> watch() {
    return _isar.workLogs.watchLazy();
  }

  Future<void> delete(int id) async {
    await database.writeTxn(() async {
      await _isar.workLogs.delete(id);
    });
  }
}

extension _WorkLogOwnerFilter
    on QueryBuilder<WorkLog, WorkLog, QFilterCondition> {
  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerVisibleTo(
    String? ownerUserId,
  ) {
    return ownerUserId == null
        ? ownerUserIdIsNull()
        : group(
            (query) =>
                query.ownerUserIdIsNull().or().ownerUserIdEqualTo(ownerUserId),
          );
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerMatches(
    String? ownerUserId,
  ) {
    return ownerUserId == null
        ? ownerUserIdIsNull()
        : ownerUserIdEqualTo(ownerUserId);
  }
}
