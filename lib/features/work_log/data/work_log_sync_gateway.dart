import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

abstract interface class WorkLogSyncGateway {
  bool get isAvailable;
  Future<bool> pushWorkLog(WorkLog log);
  Future<bool> deleteWorkLog(WorkLog log);
}

final class ServiceLocatorWorkLogSyncGateway implements WorkLogSyncGateway {
  const ServiceLocatorWorkLogSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncService>();

  @override
  Future<bool> pushWorkLog(WorkLog log) {
    return serviceLocator<SyncService>().pushWorkLog(log);
  }

  @override
  Future<bool> deleteWorkLog(WorkLog log) {
    return serviceLocator<SyncService>().deleteWorkLog(log);
  }
}
