import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/common/services/log_service.dart';

import 'evidence_model.dart';
import 'evidence_repository.dart';
import 'views/evidence_editor_sheet.dart';

enum EvidenceSortMode { recent, amount, project }

class EvidenceProjectSummary {
  final String projectName;
  final List<ExpenseEvidence> items;

  const EvidenceProjectSummary({
    required this.projectName,
    required this.items,
  });

  ExpenseEvidence get latest => items.first;
  int get count => items.length;
  double get pendingAmount => items.totalPendingAmount;
  double get reimbursedAmount => items.totalReimbursedAmount;
}

class EvidenceController extends GetxController {
  static EvidenceController get to => Get.find();

  final evidence = <ExpenseEvidence>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final sortMode = EvidenceSortMode.recent.obs;

  StreamSubscription? _dbSub;

  @override
  void onInit() {
    super.onInit();
    loadEvidence();
    _dbSub = EvidenceRepository.to.watchEvidence().listen((_) {
      loadEvidence();
    });
  }

  @override
  void onClose() {
    _dbSub?.cancel();
    super.onClose();
  }

  Future<void> loadEvidence() async {
    isLoading.value = true;
    try {
      final allEvidence = await EvidenceRepository.to.getAllEvidence();
      evidence.assignAll(allEvidence);
    } catch (e) {
      LogService.to.error('Evidence', '加载凭证失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, List<ExpenseEvidence>> get groupedEvidence {
    final groups = <String, List<ExpenseEvidence>>{};
    for (final item in evidence) {
      groups.putIfAbsent(item.projectName, () => []).add(item);
    }
    for (final items in groups.values) {
      items.sort((a, b) => b.evidenceDate.compareTo(a.evidenceDate));
    }
    return groups;
  }

  List<EvidenceProjectSummary> get projectSummaries {
    final summaries = groupedEvidence.entries
        .map(
          (entry) => EvidenceProjectSummary(
            projectName: entry.key,
            items: entry.value,
          ),
        )
        .toList();

    switch (sortMode.value) {
      case EvidenceSortMode.recent:
        summaries.sort(
          (a, b) => b.latest.evidenceDate.compareTo(a.latest.evidenceDate),
        );
        break;
      case EvidenceSortMode.amount:
        summaries.sort((a, b) => b.pendingAmount.compareTo(a.pendingAmount));
        break;
      case EvidenceSortMode.project:
        summaries.sort((a, b) => a.projectName.compareTo(b.projectName));
        break;
    }
    return summaries;
  }

  List<EvidenceProjectSummary> get filteredProjectSummaries {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return projectSummaries;
    return projectSummaries
        .where((summary) => summary.projectName.toLowerCase().contains(query))
        .toList();
  }

  int get totalEvidenceCount => evidence.length;
  double get totalPendingAmount => evidence.totalPendingAmount;

  void updateSearch(String value) {
    searchQuery.value = value;
  }

  void setSortMode(EvidenceSortMode mode) {
    sortMode.value = mode;
  }

  Future<void> captureEvidence({String? initialProject}) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (image == null) return;
      showEvidenceEditorSheet(
        initialProject: initialProject,
        sourcePath: image.path,
      );
    } catch (e) {
      Get.snackbar('错误', '无法打开系统相机: $e');
    }
  }

  Future<void> importEvidence({String? initialProject}) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (image == null) return;
      showEvidenceEditorSheet(
        initialProject: initialProject,
        sourcePath: image.path,
      );
    } catch (e) {
      Get.snackbar('错误', '无法导入凭证图片: $e');
    }
  }

  void createManualEvidence({String? initialProject}) {
    showEvidenceEditorSheet(initialProject: initialProject);
  }

  void editEvidence(ExpenseEvidence item) {
    showEvidenceEditorSheet(existing: item);
  }

  Future<void> saveEvidence(
    ExpenseEvidence item, {
    String? sourcePath,
    String? sourceExtension,
  }) async {
    try {
      isLoading.value = true;
      await EvidenceRepository.to.saveEvidence(
        item,
        sourcePath: sourcePath,
        sourceExtension: sourceExtension,
      );
      Get.back();
      Get.snackbar('已保存', '凭证记录已更新');
    } catch (e) {
      Get.snackbar('保存失败', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEvidence(ExpenseEvidence item) async {
    try {
      isLoading.value = true;
      await EvidenceRepository.to.deleteEvidence(item.id);
      Get.back();
      Get.snackbar('已删除', '凭证已删除');
    } catch (e) {
      Get.snackbar('删除失败', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportEvidenceFile(ExpenseEvidence item) async {
    final path = item.localFilePath;
    if (path == null || !await File(path).exists()) {
      Get.snackbar('无法导出', '本机没有可导出的凭证文件');
      return;
    }

    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    final fileName = item.fileName ?? path.split(Platform.pathSeparator).last;
    await File(
      path,
    ).copy('$selectedDirectory${Platform.pathSeparator}$fileName');
    Get.snackbar('导出成功', '凭证文件已导出');
  }
}
