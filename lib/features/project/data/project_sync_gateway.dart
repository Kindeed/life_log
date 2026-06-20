import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/data/project_model.dart';

abstract interface class ProjectSyncGateway {
  bool get isAvailable;
  Future<bool> pushProject(Project project);
  Future<bool> deleteProject(Project project);
}

final class ServiceLocatorProjectSyncGateway implements ProjectSyncGateway {
  const ServiceLocatorProjectSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncService>();

  @override
  Future<bool> deleteProject(Project project) {
    return serviceLocator<SyncService>().deleteProject(project);
  }

  @override
  Future<bool> pushProject(Project project) {
    return serviceLocator<SyncService>().pushProject(project);
  }
}
