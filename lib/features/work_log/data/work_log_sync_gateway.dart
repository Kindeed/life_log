import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

abstract interface class WorkLogSyncGateway {
  bool get isAvailable;
  Future<bool> requestSync(WorkLog log, {required String reason});
}

final class ServiceLocatorWorkLogSyncGateway implements WorkLogSyncGateway {
  const ServiceLocatorWorkLogSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncScheduler>();

  @override
  Future<bool> requestSync(WorkLog log, {required String reason}) {
    return serviceLocator<SyncScheduler>().requestSync(
      reason: reason,
      entityName: 'work_log',
      entityKey: log.syncId ?? log.id.toString(),
    );
  }
}
