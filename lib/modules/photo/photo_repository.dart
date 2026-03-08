import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../common/db/db_service.dart';
import 'photo_model.dart';

class PhotoRepository extends GetxService {
  static PhotoRepository get to => Get.find();

  // --- 查询业务 ---
  Future<List<PhotoItem>> getAllPhotos() async {
    return await DbService.to.getAllPhotos();
  }

  Stream<void> watchPhotos() {
    return DbService.to.watchPhotos();
  }

  // --- 修改业务 ---
  Future<PhotoItem> processAndSavePhoto({
    required String tempPath,
    required String projectName,
    required String description,
    required String deviceName,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final safeProjectName = projectName.replaceAll(
      RegExp(r'[<>:"/\\|?*]'),
      '_',
    );
    final safeDeviceName = deviceName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final safeDesc = description.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    final folderPath = Directory(
      '${appDir.path}/$safeProjectName/$safeDeviceName',
    );
    if (!await folderPath.exists()) {
      await folderPath.create(recursive: true);
    }

    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);

    String filePrefix = safeDesc.isNotEmpty ? safeDesc : safeProjectName;
    if (filePrefix.length > 50) {
      filePrefix = filePrefix.substring(0, 50);
    }
    final fileName = "${filePrefix}_$dateStr.jpg";
    final savePath = "${folderPath.path}/$fileName";

    // Move file
    await File(tempPath).copy(savePath);
    await File(tempPath).delete();

    // Save to DB
    final photoItem = PhotoItem()
      ..createdAt = now
      ..fileName = fileName
      ..filePath = savePath
      ..deviceName = deviceName
      ..projectName = projectName
      ..description = description
      ..dateIndexed = DateTime(now.year, now.month, now.day);

    await DbService.to.addPhoto(photoItem);
    return photoItem;
  }

  Future<void> deletePhotos(List<PhotoItem> itemsToDelete) async {
    for (var photo in itemsToDelete) {
      // 1. Delete file
      final file = File(photo.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      // 2. Delete from DB
      await DbService.to.deletePhoto(photo.id);
    }
  }

  /// 更新照片信息，如果有需要则重命名文件
  /// 返回更新前的旧路径（如果重命名了），用于告诉 UI 清理旧图片缓存。
  Future<String?> updatePhotoDescription(
    PhotoItem photo,
    String newDescription,
  ) async {
    final oldFile = File(photo.filePath);
    if (!await oldFile.exists()) {
      // Just update DB if file missing
      photo.description = newDescription;
      await DbService.to.addPhoto(photo);
      return null;
    }

    final safeDesc = newDescription.trim().replaceAll(
      RegExp(r'[<>:"/\\|?*]'),
      '_',
    );
    final safeProject = (photo.projectName ?? "Doc").replaceAll(
      RegExp(r'[<>:"/\\|?*]'),
      '_',
    );

    String prefix = safeDesc.isNotEmpty ? safeDesc : safeProject;
    if (prefix.length > 50) {
      prefix = prefix.substring(0, 50);
    }
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(photo.createdAt);
    final newFileName = "${prefix}_$dateStr.jpg";

    final newPath = "${oldFile.parent.path}/$newFileName";
    String? oldPathToEvict;

    if (newPath != photo.filePath) {
      oldPathToEvict = photo.filePath;
      await oldFile.rename(newPath);
      photo.fileName = newFileName;
      photo.filePath = newPath;
    }

    photo.description = newDescription;
    await DbService.to.addPhoto(photo);
    return oldPathToEvict;
  }

  Future<int> exportPhotos(
    List<PhotoItem> photosToExport,
    String targetDirectory,
  ) async {
    int successCount = 0;
    for (var photo in photosToExport) {
      final sourceFile = File(photo.filePath);
      if (await sourceFile.exists()) {
        final projectDir = Directory(
          '$targetDirectory/${photo.projectName ?? "Exported"}',
        );
        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        }

        final targetPath = '${projectDir.path}/${photo.fileName}';
        await sourceFile.copy(targetPath);
        successCount++;
      }
    }
    return successCount;
  }
}
