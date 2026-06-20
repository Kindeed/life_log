import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';

abstract interface class EvidenceLocalDataSource {
  Future<List<ExpenseEvidence>> getAllEvidence();
  Stream<void> watchEvidence();
  Future<int> addEvidence(ExpenseEvidence evidence);
  Future<ExpenseEvidence?> markEvidenceDeleted(int id);
  Future<void> purgeDeletedEvidence(int id);
}

final class DbEvidenceLocalDataSource implements EvidenceLocalDataSource {
  const DbEvidenceLocalDataSource();

  @override
  Future<int> addEvidence(ExpenseEvidence evidence) {
    return serviceLocator<DbService>().addEvidence(evidence);
  }

  @override
  Future<List<ExpenseEvidence>> getAllEvidence() {
    return serviceLocator<DbService>().getAllEvidence();
  }

  @override
  Future<ExpenseEvidence?> markEvidenceDeleted(int id) {
    return serviceLocator<DbService>().markEvidenceDeleted(id);
  }

  @override
  Future<void> purgeDeletedEvidence(int id) {
    return serviceLocator<DbService>().purgeDeletedEvidence(id);
  }

  @override
  Stream<void> watchEvidence() {
    return serviceLocator<DbService>().watchEvidence();
  }
}
