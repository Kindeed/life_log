import 'package:isar/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/features/project/data/project_model.dart';

class ProjectDao {
  final IsarDatabase database;

  const ProjectDao(this.database);

  Isar get _isar => database.isar;

  Future<Project?> getById(int id) {
    return _isar.projects.get(id);
  }

  Future<List<Project>> getAllSorted() {
    return _isar.projects.where().sortByUpdatedAtDesc().findAll();
  }

  Future<List<Project>> getActiveSortedForOwner(String? ownerUserId) {
    return _isar.projects
        .filter()
        .ownerVisibleTo(ownerUserId)
        .and()
        .deletedAtIsNull()
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<Project>> getPendingForSync() {
    return _isar.projects
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<Project>> getPendingForSyncForOwner(String? ownerUserId) async {
    final byId = <int, Project>{};
    for (final projects in [
      await _pendingRemoteMissingForOwner(ownerUserId),
      await _pendingDirtyForOwner(ownerUserId),
      await _pendingDeleteForOwner(ownerUserId),
    ]) {
      for (final project in projects) {
        byId[project.id] = project;
      }
    }
    final pending = byId.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return pending;
  }

  Future<List<Project>> _pendingRemoteMissingForOwner(String? ownerUserId) {
    return _isar.projects
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .remoteIdIsNull()
        .findAll();
  }

  Future<List<Project>> _pendingDirtyForOwner(String? ownerUserId) {
    return _isar.projects
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .isDirtyEqualTo(true)
        .findAll();
  }

  Future<List<Project>> _pendingDeleteForOwner(String? ownerUserId) {
    return _isar.projects
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .pendingDeleteEqualTo(true)
        .findAll();
  }

  Stream<void> watch() {
    return _isar.projects.watchLazy();
  }

  Future<void> delete(int id) async {
    await database.writeTxn(() async {
      await _isar.projects.delete(id);
    });
  }
}

extension _ProjectOwnerFilter
    on QueryBuilder<Project, Project, QFilterCondition> {
  QueryBuilder<Project, Project, QAfterFilterCondition> ownerVisibleTo(
    String? ownerUserId,
  ) {
    return ownerUserId == null
        ? ownerUserIdIsNull()
        : group(
            (query) =>
                query.ownerUserIdIsNull().or().ownerUserIdEqualTo(ownerUserId),
          );
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> ownerMatches(
    String? ownerUserId,
  ) {
    return ownerUserId == null
        ? ownerUserIdIsNull()
        : ownerUserIdEqualTo(ownerUserId);
  }
}
