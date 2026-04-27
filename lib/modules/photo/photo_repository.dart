import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../common/db/db_service.dart';
import 'photo_model.dart';

class PhotoRepository extends GetxService {
  static PhotoRepository get to => Get.find();

  String _sanitizePathSegment(String value, {String fallback = 'Untitled'}) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (sanitized.isEmpty) return fallback;
    return sanitized;
  }

  Future<String> _availablePath(String directory, String fileName) async {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex <= 0 ? fileName : fileName.substring(0, dotIndex);
    final extension = dotIndex <= 0 ? '' : fileName.substring(dotIndex);

    var candidate = '$directory/$fileName';
    var suffix = 1;
    while (await File(candidate).exists()) {
      candidate = '$directory/${baseName}_$suffix$extension';
      suffix++;
    }
    return candidate;
  }

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
    bool deleteSource = true,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final safeProjectName = _sanitizePathSegment(
      projectName,
      fallback: 'DefaultProject',
    );
    final safeDeviceName = _sanitizePathSegment(
      deviceName,
      fallback: 'UnknownDevice',
    );
    final safeDesc = _sanitizePathSegment(description, fallback: '');

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
    final savePath = await _availablePath(folderPath.path, fileName);

    // Copy into the app-private archive. Gallery imports must keep the source
    // until the platform media delete request has completed.
    await File(tempPath).copy(savePath);
    if (deleteSource) {
      await File(tempPath).delete();
    }

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

    final safeDesc = _sanitizePathSegment(newDescription, fallback: '');
    final safeProject = _sanitizePathSegment(
      photo.projectName ?? "Doc",
      fallback: 'Doc',
    );

    String prefix = safeDesc.isNotEmpty ? safeDesc : safeProject;
    if (prefix.length > 50) {
      prefix = prefix.substring(0, 50);
    }
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(photo.createdAt);
    final newFileName = "${prefix}_$dateStr.jpg";

    final newPath = photo.fileName == newFileName
        ? photo.filePath
        : await _availablePath(oldFile.parent.path, newFileName);
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
          '$targetDirectory/${_sanitizePathSegment(photo.projectName ?? "Exported", fallback: "Exported")}',
        );
        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        }

        final targetPath = await _availablePath(
          projectDir.path,
          photo.fileName,
        );
        await sourceFile.copy(targetPath);
        successCount++;
      }
    }
    return successCount;
  }
}
