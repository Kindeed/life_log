import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/utils/record_validators.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/features/evidence/data/evidence_file_store.dart';
import 'package:life_log/features/evidence/data/evidence_local_data_source.dart';
import 'package:life_log/features/evidence/data/evidence_project_linker.dart';
import 'package:life_log/features/evidence/data/evidence_sync_gateway.dart';

import 'evidence_model.dart';

class EvidenceRepository {
  EvidenceRepository({
    EvidenceLocalDataSource? localDataSource,
    EvidenceSyncGateway? syncGateway,
    EvidenceProjectLinker? projectLinker,
    EvidenceFileStore? fileStore,
  }) : _localDataSource = localDataSource ?? const DbEvidenceLocalDataSource(),
       _syncGateway = syncGateway ?? const ServiceLocatorEvidenceSyncGateway(),
       _projectLinker = projectLinker ?? const GetItEvidenceProjectLinker(),
       _fileStore = fileStore ?? const AppEvidenceFileStore();

  final EvidenceLocalDataSource _localDataSource;
  final EvidenceSyncGateway _syncGateway;
  final EvidenceProjectLinker _projectLinker;
  final EvidenceFileStore _fileStore;

  Future<List<ExpenseEvidence>> getAllEvidence() {
    return _localDataSource.getAllEvidence();
  }

  Stream<void> watchEvidence() {
    return _localDataSource.watchEvidence();
  }

  Future<ExpenseEvidence> saveEvidence(
    ExpenseEvidence evidence, {
    String? sourcePath,
    String? sourceExtension,
  }) async {
    validateExpenseEvidence(evidence);
    evidence.syncId = ensureSyncId(evidence.syncId);
    final project = await _projectLinker.ensureSyncableProject(
      evidence.projectName.trim(),
    );
    evidence.projectId = project.id;
    evidence.projectName = project.name;
    evidence.projectSyncId = project.syncId;

    if (sourcePath != null && sourcePath.isNotEmpty) {
      await _fileStore.copyEvidenceFile(
        evidence,
        sourcePath: sourcePath,
        sourceExtension: sourceExtension,
      );
    }

    await _localDataSource.addEvidence(evidence);
    if (!_syncGateway.isAvailable) {
      LogService.to.info('EvidenceRepository', '本地模式：跳过云端同步');
      return evidence;
    }

    if (evidence.remoteId != null &&
        !evidence.isDirty &&
        !evidence.pendingDelete) {
      return evidence;
    }

    try {
      final success = await _syncGateway.requestSync(
        evidence,
        reason: 'evidence-save',
      );
      if (!success) {
        LogService.to.error('EvidenceRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e, stackTrace) {
      LogService.to.error('EvidenceRepository', '云端同步失败: $e', stackTrace);
    }
    return evidence;
  }

  Future<void> deleteEvidence(int id) async {
    final evidence = await _localDataSource.markEvidenceDeleted(id);

    try {
      if (evidence == null ||
          (evidence.remoteId == null && evidence.syncId == null)) {
        await _fileStore.deleteEvidenceFile(evidence);
        await _localDataSource.purgeDeletedEvidence(id);
      } else if (!_syncGateway.isAvailable) {
        LogService.to.info('EvidenceRepository', '本地模式：跳过云端删除');
      } else {
        final success = await _syncGateway.requestSync(
          evidence,
          reason: 'evidence-delete',
        );
        if (success) {
          await _fileStore.deleteEvidenceFile(evidence);
          await _localDataSource.purgeDeletedEvidence(id);
        }
      }
    } catch (e, stackTrace) {
      LogService.to.error('EvidenceRepository', '云端删除失败: $e', stackTrace);
    }
  }
}
