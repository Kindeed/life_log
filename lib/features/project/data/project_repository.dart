import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';
import 'package:life_log/features/project/data/project_local_data_source.dart';
import 'package:life_log/features/project/data/project_sync_gateway.dart';

import 'project_model.dart';

class ProjectRepository {
  ProjectRepository({
    ProjectLocalDataSource? localDataSource,
    ProjectSyncGateway? syncGateway,
  }) : _localDataSource = localDataSource ?? const DbProjectLocalDataSource(),
       _syncGateway = syncGateway ?? const ServiceLocatorProjectSyncGateway();

  final ProjectLocalDataSource _localDataSource;
  final ProjectSyncGateway _syncGateway;

  Future<List<Project>> getAllProjects() {
    return _localDataSource.getAllProjects();
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
    if (project.id == 0) {
      project.createdAt = now;
    }
    project.updatedAt = now;
    project.syncId = ensureSyncId(project.syncId);
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
      final success = await _syncGateway.pushProject(project);
      if (!success) {
        LogService.to.error('ProjectRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e, stackTrace) {
      LogService.to.error('ProjectRepository', '云端同步失败: $e', stackTrace);
    }
  }

  Future<void> deleteProject(Project project) async {
    final deleted = await _localDataSource.markProjectDeleted(project.id);
    if (deleted == null) return;

    try {
      if (deleted.remoteId == null) {
        await _localDataSource.purgeDeletedProject(project.id);
      } else if (!_syncGateway.isAvailable) {
        LogService.to.info('ProjectRepository', '本地模式：跳过云端删除');
      } else {
        final success = await _syncGateway.deleteProject(deleted);
        if (success) {
          await _localDataSource.purgeDeletedProject(project.id);
        }
      }
    } catch (e, stackTrace) {
      LogService.to.error('ProjectRepository', '云端删除失败: $e', stackTrace);
      rethrow;
    }
  }
}
