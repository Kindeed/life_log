import 'package:isar_community/isar.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/features/evidence/data/evidence_file_store.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/project/data/project_local_data_source.dart';
import 'package:life_log/features/project/data/project_sync_gateway.dart';

import 'project_model.dart';

class ProjectRepository {
  ProjectRepository({
    ProjectLocalDataSource? localDataSource,
    ProjectSyncGateway? syncGateway,
    EvidenceFileStore? evidenceFileStore,
  }) : _localDataSource = localDataSource ?? const DbProjectLocalDataSource(),
       _syncGateway = syncGateway ?? const ServiceLocatorProjectSyncGateway(),
       _evidenceFileStore = evidenceFileStore ?? const AppEvidenceFileStore();

  final ProjectLocalDataSource _localDataSource;
  final ProjectSyncGateway _syncGateway;
  final EvidenceFileStore _evidenceFileStore;

  Future<List<Project>> getAllProjects() {
    return _localDataSource.getAllProjects();
  }

  Future<Project?> findProject(int id, String name) async {
    for (final project in await getAllProjects()) {
      if (project.id == id ||
          project.name.toLowerCase() == name.trim().toLowerCase()) {
        return project;
      }
    }
    return null;
  }

  Stream<void> watchProjects() {
    return _localDataSource.watchProjects();
  }

  Future<Project> ensureProject(String name, {bool syncable = false}) {
    return _localDataSource.ensureProject(name, syncable: syncable);
  }

  Future<Project> ensureSyncableProject(String name) async {
    final project = await ensureProject(name, syncable: true);
    await _pushIfNeeded(project);
    return project;
  }

  Future<Project> saveProject(Project project) async {
    final now = DateTime.now();
    project.name = project.name.trim();
    if (project.name.isEmpty) {
      throw ArgumentError.value(project.name, 'name', '项目名称不能为空');
    }
    if (project.id == 0 || project.id == Isar.autoIncrement) {
      project.id = Isar.autoIncrement;
      project.createdAt = now;
    }
    project.updatedAt = now;
    project.syncId = ensureSyncId(project.syncId);
    project.stageNames = _normalizeStageNames(project.stageNames);
    project.isDirty = true;
    await _localDataSource.addProject(project);
    await _pushIfNeeded(project);
    return project;
  }

  Future<void> _pushIfNeeded(Project project) async {
    if (!_syncGateway.isAvailable) return;
    if (project.remoteId != null &&
        !project.isDirty &&
        !project.pendingDelete) {
      return;
    }

    try {
      final success = await _syncGateway.requestSync(
        project,
        reason: 'project-save',
      );
      if (!success) {
        LogService.to.error('ProjectRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e, stackTrace) {
      LogService.to.error('ProjectRepository', '云端同步失败: $e', stackTrace);
    }
  }

  Future<Project> saveLocalProjectCover(Project project) async {
    final saved = await _localDataSource.updateProjectCover(project);
    if (saved == null) throw StateError('Project not found: ${project.name}');
    return saved;
  }

  Future<void> deleteProject(Project project) async {
    final result = await _localDataSource.deleteProjectCascade(
      project.id,
      project.name,
    );
    if (result == null) return;

    await _deleteEvidenceFiles(result.localEvidenceFiles);

    try {
      final deleted = result.deletedProject;
      if (deleted == null) return;

      if (!_syncGateway.isAvailable) {
        LogService.to.info('ProjectRepository', '本地模式：保留级联删除待同步状态');
        return;
      }

      final success = await _syncGateway.requestSync(
        deleted,
        reason: 'project-delete',
      );
      if (!success) {
        LogService.to.error('ProjectRepository', '项目级联删除云端同步未完成，保留待同步状态');
        return;
      }

      await _deleteEvidenceFiles(result.pendingEvidenceFiles);
      await _localDataSource.purgeDeletedProject(project.id);
    } catch (e, stackTrace) {
      LogService.to.error('ProjectRepository', '项目级联删除云端同步失败: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> _deleteEvidenceFiles(Iterable<ExpenseEvidence> evidence) async {
    for (final item in evidence) {
      try {
        await _evidenceFileStore.deleteEvidenceFile(item);
      } catch (e, stackTrace) {
        LogService.to.error(
          'ProjectRepository',
          '项目级联删除凭证文件失败: $e',
          stackTrace,
        );
      }
    }
  }
}

List<String> _normalizeStageNames(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) continue;
    final key = trimmed.toLowerCase();
    if (seen.add(key)) result.add(trimmed);
  }
  return result;
}
