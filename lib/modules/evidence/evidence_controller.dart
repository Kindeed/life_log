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
  final _summaryCacheVersion = 0.obs;
  Map<String, List<ExpenseEvidence>> _groupedEvidenceCache = const {};
  List<EvidenceProjectSummary> _projectSummariesCache = const [];
  List<EvidenceProjectSummary> _filteredProjectSummariesCache = const [];
  double _totalPendingAmountCache = 0;

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
      _rebuildSummaryCaches();
    } catch (e) {
      LogService.to.error('Evidence', '加载凭证失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, List<ExpenseEvidence>> get groupedEvidence {
    _summaryCacheVersion.value;
    return _groupedEvidenceCache;
  }

  List<EvidenceProjectSummary> get projectSummaries {
    _summaryCacheVersion.value;
    return _projectSummariesCache;
  }

  List<EvidenceProjectSummary> get filteredProjectSummaries {
    _summaryCacheVersion.value;
    return _filteredProjectSummariesCache;
  }

  int get totalEvidenceCount => evidence.length;

  double get totalPendingAmount {
    _summaryCacheVersion.value;
    return _totalPendingAmountCache;
  }

  void rebuildSummaryCachesForTest() {
    _rebuildSummaryCaches();
  }

  void _rebuildSummaryCaches() {
    final groups = <String, List<ExpenseEvidence>>{};
    for (final item in evidence) {
      groups.putIfAbsent(item.projectName, () => []).add(item);
    }

    final summaries = groups.entries
        .map(
          (entry) => EvidenceProjectSummary(
            projectName: entry.key,
            items: entry.value,
          ),
        )
        .toList();

    _groupedEvidenceCache = groups;
    _projectSummariesCache = summaries;
    _totalPendingAmountCache = evidence.totalPendingAmount;
    _resortProjectSummaries();
    _rebuildFilteredProjectSummaries();
    _summaryCacheVersion.value++;
  }

  void _resortProjectSummaries() {
    switch (sortMode.value) {
      case EvidenceSortMode.recent:
        _projectSummariesCache.sort(
          (a, b) => b.latest.evidenceDate.compareTo(a.latest.evidenceDate),
        );
        break;
      case EvidenceSortMode.amount:
        _projectSummariesCache.sort(
          (a, b) => b.pendingAmount.compareTo(a.pendingAmount),
        );
        break;
      case EvidenceSortMode.project:
        _projectSummariesCache.sort(
          (a, b) => a.projectName.compareTo(b.projectName),
        );
        break;
    }
  }

  void _rebuildFilteredProjectSummaries() {
    final query = searchQuery.value.trim().toLowerCase();
    _filteredProjectSummariesCache = query.isEmpty
        ? _projectSummariesCache
        : _projectSummariesCache
              .where(
                (summary) => summary.projectName.toLowerCase().contains(query),
              )
              .toList();
  }

  void updateSearch(String value) {
    searchQuery.value = value;
    _rebuildFilteredProjectSummaries();
    _summaryCacheVersion.value++;
  }

  void setSortMode(EvidenceSortMode mode) {
    sortMode.value = mode;
    _resortProjectSummaries();
    _rebuildFilteredProjectSummaries();
    _summaryCacheVersion.value++;
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
    } catch (e, stackTrace) {
      LogService.to.error('Evidence', '无法打开系统相机: $e', stackTrace);
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
    } catch (e, stackTrace) {
      LogService.to.error('Evidence', '无法导入凭证图片: $e', stackTrace);
      Get.snackbar('错误', '无法导入凭证图片: $e');
    }
  }

  Future<void> importEvidenceFile({String? initialProject}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );
      final file = result?.files.single;
      final path = file?.path;
      if (path == null || path.isEmpty) return;
      showEvidenceEditorSheet(
        initialProject: initialProject,
        sourcePath: path,
        sourceExtension: file?.extension,
      );
    } catch (e, stackTrace) {
      LogService.to.error('Evidence', '无法导入凭证文件: $e', stackTrace);
      Get.snackbar('错误', '无法导入凭证文件: $e');
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
    } catch (e, stackTrace) {
      LogService.to.error('Evidence', '保存凭证失败: $e', stackTrace);
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
    } catch (e, stackTrace) {
      LogService.to.error('Evidence', '删除凭证失败: $e', stackTrace);
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

    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return;

      final fileName = item.fileName ?? path.split(Platform.pathSeparator).last;
      await File(
        path,
      ).copy('$selectedDirectory${Platform.pathSeparator}$fileName');
      Get.snackbar('导出成功', '凭证文件已导出');
    } catch (e, stackTrace) {
      LogService.to.error('Evidence', '导出凭证文件失败: $e', stackTrace);
      Get.snackbar('导出失败', e.toString());
    }
  }
}
