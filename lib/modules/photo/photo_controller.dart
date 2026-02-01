import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PhotoController extends GetxController {
  static PhotoController get to => Get.find();

  // Observable state
  final photos = <PhotoItem>[].obs;
  final isLoading = false.obs;

  // Device info
  String _deviceName = "UnknownDevice";

  @override
  void onInit() {
    super.onInit();
    _initDeviceInfo();
    loadPhotos();
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
        _showCaptureDialog(image.path, initialProject);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to open system camera: $e");
    }
  }

  void _showCaptureDialog(String tempPath, String? initialProject) {
    final projectCtrl = TextEditingController(
      text: initialProject ?? "DefaultProject",
    );
    final descCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "归档照片",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Project Selector (Instagram Style)
            GestureDetector(
              onTap: () => _showProjectPicker(projectCtrl),
              child: AbsorbPointer(
                child: TextField(
                  controller: projectCtrl,
                  decoration: InputDecoration(
                    labelText: "选择归档项目",
                    prefixIcon: const Icon(Icons.folder_special_rounded),
                    suffixIcon: const Icon(
                      Icons.arrow_drop_down_circle_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F9FC),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Input
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: "添加备注 (可选)",
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9FC),
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final projectName = projectCtrl.text.trim();
                  if (projectName.isEmpty) {
                    Get.snackbar("错误", "项目名称不能为空");
                    return;
                  }
                  Get.back(); // Close bottom sheet
                  _processAndSavePhoto(
                    tempPath,
                    projectName,
                    descCtrl.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "确认录入",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showProjectPicker(TextEditingController controller) {
    final searchCtrl = TextEditingController();
    final allProjects = groupedPhotos.keys.toList();
    final filteredProjects = <String>[...allProjects].obs;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "搜索或创建新项目...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                if (val.isEmpty) {
                  filteredProjects.assignAll(allProjects);
                } else {
                  filteredProjects.assignAll(
                    allProjects
                        .where(
                          (p) => p.toLowerCase().contains(val.toLowerCase()),
                        )
                        .toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: Obx(() {
                // Determine if we need to show "Create New"
                final query = searchCtrl.text.trim();
                final showCreate =
                    query.isNotEmpty && !filteredProjects.contains(query);

                if (filteredProjects.isEmpty && !showCreate) {
                  return const Center(child: Text("暂无项目历史"));
                }

                return ListView.builder(
                  itemCount: filteredProjects.length + (showCreate ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (showCreate && index == 0) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.add, color: Colors.blue),
                        ),
                        title: Text("创建新项目: \"$query\""),
                        onTap: () {
                          controller.text = query;
                          Get.back(); // Close picker
                        },
                      );
                    }

                    final dataIndex = showCreate ? index - 1 : index;
                    final pName = filteredProjects[dataIndex];
                    return ListTile(
                      leading: const Icon(Icons.folder, color: Colors.grey),
                      title: Text(pName),
                      trailing: controller.text == pName
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () {
                        controller.text = pName;
                        Get.back(); // Close picker
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
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
    } catch (e) {
      Get.snackbar("Error", "Failed to save photo: $e");
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
        "Export Success",
        "Successfully exported $successCount photos to $selectedDirectory",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Export Error", "Failed to export photos: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
