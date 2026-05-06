import 'dart:async';

import 'package:get/get.dart';
import 'package:life_log/common/services/log_service.dart';

import 'project_model.dart';
import 'project_repository.dart';

class ProjectController extends GetxController {
  static ProjectController get to => Get.find();

  final projects = <Project>[].obs;
  final isLoading = false.obs;

  StreamSubscription? _dbSub;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
    _dbSub = ProjectRepository.to.watchProjects().listen((_) {
      loadProjects();
    });
  }

  @override
  void onClose() {
    _dbSub?.cancel();
    super.onClose();
  }

  Future<void> loadProjects() async {
    isLoading.value = true;
    try {
      projects.assignAll(await ProjectRepository.to.getAllProjects());
    } catch (e, stackTrace) {
      LogService.to.error('Project', '加载项目失败: $e', stackTrace);
    } finally {
      isLoading.value = false;
    }
  }
}
