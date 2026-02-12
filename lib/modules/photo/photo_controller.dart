import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:life_log/modules/photo/views/capture_dialog.dart';
import 'package:path_provider/path_provider.dart';
import '../../common/services/log_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PhotoController extends GetxController {
  static PhotoController get to => Get.find();

  // Observable state
  final photos = <PhotoItem>[].obs;
  final isLoading = false.obs;
  final isFabVisible = true.obs;

  // Device info
  String _deviceName = "UnknownDevice";

  @override
  void onInit() {
    super.onInit();
    _initDeviceInfo();
    loadPhotos();
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
      final allPhotos = await DbService.to.getAllPhotos();
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

  Future<void> _processAndSavePhoto(
    String tempPath,
    String projectName,
    String description,
  ) async {
    try {
      isLoading.value = true;
      final appDir = await getApplicationDocumentsDirectory();

      final safeProjectName = projectName.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final safeDeviceName = _deviceName.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final safeDesc = description.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      final folderPath = Directory(
        '${appDir.path}/$safeProjectName/$safeDeviceName',
      );
      if (!await folderPath.exists()) {
        await folderPath.create(recursive: true);
      }

      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);

      // Filename: {Description}_{Date} or {Project}_{Date}
      final filePrefix = safeDesc.isNotEmpty ? safeDesc : safeProjectName;
      final fileName = "${filePrefix}_$dateStr.jpg";

      final savePath = "${folderPath.path}/$fileName";

      // Move file from temp to project folder
      await File(tempPath).copy(savePath);
      await File(tempPath).delete(); // Clean up

      // Save to DB
      final photoItem = PhotoItem()
        ..createdAt = now
        ..fileName = fileName
        ..filePath = savePath
        ..deviceName = _deviceName
        ..projectName = projectName
        ..description = description
        ..dateIndexed = DateTime(now.year, now.month, now.day);

      await DbService.to.addPhoto(photoItem);
      photos.add(photoItem);

      Get.snackbar(
        "归档成功",
        "照片已保存至: $safeProjectName",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      LogService.to.info('Photo', '保存照片: $fileName ($projectName)');
    } catch (e) {
      Get.snackbar("错误", "保存照片失败: $e");
    } finally {
      isLoading.value = false;
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
      for (var photo in itemsToDelete) {
        // 1. Delete file
        final file = File(photo.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        // 2. Delete from DB
        await DbService.to.deletePhoto(photo.id);
        // 3. Update state
        photos.remove(photo);
      }
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
      final oldFile = File(photo.filePath);
      if (!await oldFile.exists()) {
        // Just update DB if file missing
        photo.description = newDescription;
        await DbService.to.addPhoto(photo); // addPhoto works for update in Isar
        photos.refresh();
        return;
      }

      // Generate new filename: {Desc}_{Date}.jpg
      final safeDesc = newDescription.trim().replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final safeProject = (photo.projectName ?? "Doc").replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );

      // Use description if available, otherwise project name
      final prefix = safeDesc.isNotEmpty ? safeDesc : safeProject;
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(photo.createdAt);
      final newFileName = "${prefix}_$dateStr.jpg";

      final newPath = "${oldFile.parent.path}/$newFileName";

      if (newPath != photo.filePath) {
        // Rename file
        await oldFile.rename(newPath);
        photo.fileName = newFileName;
        photo.filePath = newPath;

        // Evict from cache to refresh UI
        imageCache.evict(FileImage(File(newPath)));
        imageCache.evict(FileImage(oldFile));
      }

      photo.description = newDescription;
      await DbService.to.addPhoto(photo);
      photos.refresh();

      Get.back();
      Get.snackbar("成功", "照片信息已更新");
    } catch (e) {
      Get.snackbar("更新失败", "无法重命名文件: $e");
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

      int successCount = 0;
      for (var photo in photosToExport) {
        final sourceFile = File(photo.filePath);
        if (await sourceFile.exists()) {
          // Keep structure: selectedDir / ProjectName / FileName
          final projectDir = Directory(
            '$selectedDirectory/${photo.projectName ?? "Exported"}',
          );
          if (!await projectDir.exists()) {
            await projectDir.create(recursive: true);
          }

          final targetPath = '${projectDir.path}/${photo.fileName}';
          await sourceFile.copy(targetPath);
          successCount++;
        }
      }

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
