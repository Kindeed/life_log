import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:life_log/modules/photo/photo_repository.dart';
import 'package:life_log/modules/photo/views/capture_dialog.dart';
import 'package:life_log/modules/photo/views/gallery_import_view.dart';
import '../../common/services/log_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoController extends GetxController {
  static PhotoController get to => Get.find();

  // Observable state
  final photos = <PhotoItem>[].obs;
  final isLoading = false.obs;
  final isFabVisible = true.obs;

  // Device info
  String _deviceName = "UnknownDevice";

  StreamSubscription? _dbSub;

  @override
  void onInit() {
    super.onInit();
    _initDeviceInfo();
    loadPhotos();
    _dbSub = PhotoRepository.to.watchPhotos().listen((_) {
      loadPhotos();
    });
  }

  @override
  void onClose() {
    _dbSub?.cancel();
    super.onClose();
  }

  // --- 滚动监听 ---
  void onScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      if (!isFabVisible.value) isFabVisible.value = true;
    } else if (notification.direction == ScrollDirection.reverse) {
      if (isFabVisible.value) isFabVisible.value = false;
    }
  }

  Future<void> _initDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceName = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _deviceName = iosInfo.name;
    }
  }

  Future<void> loadPhotos() async {
    isLoading.value = true;
    try {
      final allPhotos = await PhotoRepository.to.getAllPhotos();
      photos.assignAll(allPhotos);
    } catch (e) {
      debugPrint("Load photos error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- 核心逻辑: 调用系统相机并保存 ---
  Future<void> captureWithSystemCamera({String? initialProject}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95, // High quality
      );

      if (image != null) {
        showCaptureDialog(
          tempPath: image.path,
          initialProject: initialProject,
          onConfirm: (projectName, description) {
            _processAndSavePhoto(image.path, projectName, description);
          },
        );
      }
    } catch (e) {
      Get.snackbar("错误", "无法打开系统相机: $e");
    }
  }

  Future<void> importFromGallery({String? initialProject}) async {
    try {
      final result = await Get.to<GalleryImportResult>(
        () => const GalleryImportView(),
      );
      if (result == null) return;

      showCaptureDialog(
        tempPath: result.file.path,
        initialProject: initialProject,
        onConfirm: (projectName, description) {
          _processAndSavePhoto(
            result.file.path,
            projectName,
            description,
            sourceAssetId: result.asset.id,
          );
        },
      );
    } catch (e) {
      Get.snackbar("错误", "无法导入相册照片: $e");
    }
  }

  Future<void> _processAndSavePhoto(
    String tempPath,
    String projectName,
    String description, {
    String? sourceAssetId,
  }) async {
    try {
      isLoading.value = true;
      final photoItem = await PhotoRepository.to.processAndSavePhoto(
        tempPath: tempPath,
        projectName: projectName,
        description: description,
        deviceName: _deviceName,
        deleteSource: sourceAssetId == null,
      );

      if (sourceAssetId != null) {
        await _deleteSourceGalleryAsset(sourceAssetId);
      }

      Get.snackbar(
        "归档成功",
        "照片已保存至: ${photoItem.projectName}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      LogService.to.info(
        'Photo',
        '保存照片 ${photoItem.fileName} (${photoItem.projectName})',
      );
    } catch (e) {
      Get.snackbar("错误", "保存照片失败: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _deleteSourceGalleryAsset(String sourceAssetId) async {
    try {
      final deletedIds = await PhotoManager.editor.deleteWithIds([
        sourceAssetId,
      ]);
      if (deletedIds.isEmpty) {
        Get.snackbar(
          "原图未删除",
          "照片已归档，但系统相册原图仍保留",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        "原图未删除",
        "照片已归档，但删除系统相册原图失败: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // --- Grouping logic ---
  Map<String, List<PhotoItem>> get groupedPhotos {
    final Map<String, List<PhotoItem>> groups = {};
    for (var photo in photos) {
      final name = photo.projectName ?? "Default";
      if (!groups.containsKey(name)) {
        groups[name] = [];
      }
      groups[name]!.add(photo);
    }
    return groups;
  }

  // --- Delete logic (Single) ---
  Future<void> deletePhoto(PhotoItem photo) async {
    await deletePhotos([photo]);
    Get.back(); // Close detail dialog if open
  }

  // --- Delete logic (Batch) ---
  Future<void> deletePhotos(List<PhotoItem> itemsToDelete) async {
    try {
      isLoading.value = true;
      await PhotoRepository.to.deletePhotos(itemsToDelete);
      Get.snackbar("已删除", "成功删除 ${itemsToDelete.length} 张照片");
      LogService.to.info('Photo', '删除 ${itemsToDelete.length} 张照片');
    } catch (e) {
      Get.snackbar("删除失败", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // --- Update Description & Rename File ---
  Future<void> updatePhotoDescription(
    PhotoItem photo,
    String newDescription,
  ) async {
    try {
      final oldPathToEvict = await PhotoRepository.to.updatePhotoDescription(
        photo,
        newDescription,
      );
      if (oldPathToEvict != null) {
        imageCache.evict(FileImage(File(photo.filePath)));
        imageCache.evict(FileImage(File(oldPathToEvict)));
      }

      Get.back();
      Get.snackbar("成功", "照片信息已更新");
    } catch (e) {
      Get.snackbar("更新失败", "照片信息更新失败: $e");
    }
  }

  // --- Export logic ---
  Future<void> exportPhotos(List<PhotoItem> photosToExport) async {
    if (photosToExport.isEmpty) return;

    try {
      isLoading.value = true;

      // 1. Pick Directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        isLoading.value = false;
        return;
      }

      final successCount = await PhotoRepository.to.exportPhotos(
        photosToExport,
        selectedDirectory,
      );

      Get.snackbar(
        "导出成功",
        "成功导出 $successCount 张照片至 $selectedDirectory",
        snackPosition: SnackPosition.BOTTOM,
      );
      LogService.to.info('Photo', '导出 $successCount 张照片至 $selectedDirectory');
    } catch (e) {
      Get.snackbar("导出错误", "导出照片失败: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
