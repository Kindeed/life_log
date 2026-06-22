import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';
import 'package:life_log/features/project/data/project_model.dart';

abstract interface class ProjectSyncGateway {
  bool get isAvailable;
  Future<bool> requestSync(Project project, {required String reason});
}

final class ServiceLocatorProjectSyncGateway implements ProjectSyncGateway {
  const ServiceLocatorProjectSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncScheduler>();

  @override
  Future<bool> requestSync(Project project, {required String reason}) {
    return serviceLocator<SyncScheduler>().requestSync(
      reason: reason,
      entityName: 'project',
      entityKey: project.syncId ?? project.id.toString(),
    );
  }
}
