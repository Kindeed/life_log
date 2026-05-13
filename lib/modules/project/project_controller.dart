import 'dart:async';

import 'package:get/get.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/modules/evidence/evidence_repository.dart';
import 'package:life_log/modules/expense/expense_record_repository.dart';
import 'package:life_log/modules/photo/photo_repository.dart';

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

  Future<Project> createProject(String name) async {
    try {
      final saved = await ProjectRepository.to.ensureProject(name);
      await loadProjects();
      return saved;
    } catch (e, stackTrace) {
      LogService.to.error('Project', '创建项目失败: $e', stackTrace);
      Get.snackbar('创建失败', e.toString());
      rethrow;
    }
  }

  Future<void> deleteProject(Project project) async {
    try {
      final photos = (await PhotoRepository.to.getAllPhotos())
          .where((photo) => photo.projectName == project.name)
          .toList();
      final evidence = (await EvidenceRepository.to.getAllEvidence())
          .where((item) => item.projectName == project.name)
          .toList();
      final records = (await ExpenseRecordRepository.to.getAllExpenseRecords())
          .where((record) => record.projectName == project.name)
          .toList();

      if (photos.isNotEmpty) {
        await PhotoRepository.to.deletePhotos(photos);
      }
      for (final item in evidence) {
        await EvidenceRepository.to.deleteEvidence(item.id);
      }
      for (final record in records) {
        await ExpenseRecordRepository.to.deleteExpenseRecord(record.id);
      }

      await ProjectRepository.to.deleteProject(project);
      await loadProjects();
    } catch (e, stackTrace) {
      LogService.to.error('Project', '删除项目失败: $e', stackTrace);
      Get.snackbar('删除失败', e.toString());
      rethrow;
    }
  }
}
