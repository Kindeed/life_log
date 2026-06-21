import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';

abstract interface class EvidenceSyncGateway {
  bool get isAvailable;
  Future<bool> pushEvidence(ExpenseEvidence evidence);
  Future<bool> deleteEvidence(ExpenseEvidence evidence);
}

final class ServiceLocatorEvidenceSyncGateway implements EvidenceSyncGateway {
  const ServiceLocatorEvidenceSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncService>();

  @override
  Future<bool> deleteEvidence(ExpenseEvidence evidence) {
    return serviceLocator<SyncService>().deleteEvidence(evidence);
  }

  @override
  Future<bool> pushEvidence(ExpenseEvidence evidence) {
    return serviceLocator<SyncService>().pushEvidence(evidence);
  }
}
