import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';

abstract interface class EvidenceSyncGateway {
  bool get isAvailable;
  Future<bool> requestSync(ExpenseEvidence evidence, {required String reason});
}

final class ServiceLocatorEvidenceSyncGateway implements EvidenceSyncGateway {
  const ServiceLocatorEvidenceSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncScheduler>();

  @override
  Future<bool> requestSync(ExpenseEvidence evidence, {required String reason}) {
    return serviceLocator<SyncScheduler>().requestSync(
      reason: reason,
      entityName: 'evidence',
      entityKey: evidence.syncId ?? evidence.id.toString(),
    );
  }
}
