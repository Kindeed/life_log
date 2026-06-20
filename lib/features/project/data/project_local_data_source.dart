import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/data/project_model.dart';

abstract interface class ProjectLocalDataSource {
  Future<List<Project>> getAllProjects();
  Stream<void> watchProjects();
  Future<Project> ensureProject(String name, {bool syncable = false});
  Future<void> addProject(Project project);
  Future<Project?> markProjectDeleted(int id);
  Future<void> purgeDeletedProject(int id);
}

final class DbProjectLocalDataSource implements ProjectLocalDataSource {
  const DbProjectLocalDataSource();

  @override
  Future<void> addProject(Project project) {
    return serviceLocator<DbService>().addProject(project);
  }

  @override
  Future<Project> ensureProject(String name, {bool syncable = false}) {
    return serviceLocator<DbService>().ensureProject(name, syncable: syncable);
  }

  @override
  Future<List<Project>> getAllProjects() {
    return serviceLocator<DbService>().getAllProjects();
  }

  @override
  Future<Project?> markProjectDeleted(int id) {
    return serviceLocator<DbService>().markProjectDeleted(id);
  }

  @override
  Future<void> purgeDeletedProject(int id) {
    return serviceLocator<DbService>().purgeDeletedProject(id);
  }

  @override
  Stream<void> watchProjects() => serviceLocator<DbService>().watchProjects();
}
