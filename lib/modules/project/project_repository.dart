import 'package:get/get.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/common/utils/sync_id_generator.dart';

import 'project_model.dart';

class ProjectRepository extends GetxService {
  static ProjectRepository get to => Get.find();

  Future<List<Project>> getAllProjects() {
    return DbService.to.getAllProjects();
  }

  Stream<void> watchProjects() {
    return DbService.to.watchProjects();
  }

  Future<Project> ensureProject(String name, {bool syncable = false}) {
    return DbService.to.ensureProject(name, syncable: syncable);
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
    project.syncId ??= SyncIdGenerator.newSyncId();
    project.isDirty = true;
    await DbService.to.addProject(project);
    await _pushIfNeeded(project);
    return project;
  }

  Future<void> _pushIfNeeded(Project project) async {
    if (!Get.isRegistered<SyncService>()) return;
    if (project.remoteId != null &&
        !project.isDirty &&
        !project.pendingDelete) {
      return;
    }

    try {
      final success = await SyncService.to.pushProject(project);
      if (!success) {
        LogService.to.error('ProjectRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e) {
      LogService.to.error('ProjectRepository', '云端同步失败: $e');
    }
  }

  Future<void> deleteProject(Project project) async {
    final deleted = await DbService.to.markProjectDeleted(project.id);
    if (deleted == null) return;

    try {
      if (deleted.remoteId == null) {
        await DbService.to.purgeDeletedProject(project.id);
      } else if (!Get.isRegistered<SyncService>()) {
        LogService.to.info('ProjectRepository', '本地模式：跳过云端删除');
      } else {
        final success = await SyncService.to.deleteProject(deleted);
        if (success) {
          await DbService.to.purgeDeletedProject(project.id);
        }
      }
    } catch (e) {
      LogService.to.error('ProjectRepository', '云端删除失败: $e');
      rethrow;
    }
  }
}
