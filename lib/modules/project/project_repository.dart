import 'package:get/get.dart';
import 'package:life_log/common/db/db_service.dart';

import 'project_model.dart';

class ProjectRepository extends GetxService {
  static ProjectRepository get to => Get.find();

  Future<List<Project>> getAllProjects() {
    return DbService.to.getAllProjects();
  }

  Stream<void> watchProjects() {
    return DbService.to.watchProjects();
  }

  Future<Project> ensureProject(String name) {
    return DbService.to.ensureProject(name);
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
    await DbService.to.addProject(project);
    return project;
  }
}
