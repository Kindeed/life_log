import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../common/db/db_service.dart';
import '../../common/utils/file_path_utils.dart';
import '../project/project_repository.dart';
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
    bool deleteSource = true,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final safeProjectName = sanitizePathSegment(
      projectName,
      fallback: 'DefaultProject',
    );
    final project = await ProjectRepository.to.ensureProject(safeProjectName);
    final safeDeviceName = sanitizePathSegment(
      deviceName,
      fallback: 'UnknownDevice',
    );
    final safeDesc = sanitizePathSegment(description, fallback: '');

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
    final savePath = await availablePath(folderPath.path, fileName);

    // Copy into the app-private archive. Gallery imports must keep the source
    // until the platform media delete request has completed.
    await File(tempPath).copy(savePath);
    if (deleteSource) {
      await File(tempPath).delete();
    }

    // Save to DB
    final photoItem = PhotoItem()
      ..createdAt = now
      ..fileName = p.basename(savePath)
      ..filePath = savePath
      ..deviceName = deviceName
      ..projectId = project.id
      ..projectName = project.name
      ..description = description
      ..dateIndexed = DateTime(now.year, now.month, now.day);

    await DbService.to.addPhoto(photoItem);
    return photoItem;
  }

  Future<void> deletePhotos(List<PhotoItem> itemsToDelete) async {
    for (var photo in itemsToDelete) {
      final currentPhoto = await DbService.to.getPhoto(photo.id);
      if (currentPhoto == null) continue;

      // 1. Delete file
      final file = File(currentPhoto.filePath);
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
    final currentPhoto = await DbService.to.getPhoto(photo.id);
    if (currentPhoto == null) {
      throw StateError('照片不存在或不属于当前用户');
    }

    final oldFile = File(currentPhoto.filePath);
    if (!await oldFile.exists()) {
      // Just update DB if file missing
      currentPhoto.description = newDescription;
      await DbService.to.addPhoto(currentPhoto);
      _copyPhotoFields(currentPhoto, photo);
      return null;
    }

    final safeDesc = sanitizePathSegment(newDescription, fallback: '');
    final safeProject = sanitizePathSegment(
      currentPhoto.projectName ?? "Doc",
      fallback: 'Doc',
    );

    String prefix = safeDesc.isNotEmpty ? safeDesc : safeProject;
    if (prefix.length > 50) {
      prefix = prefix.substring(0, 50);
    }
    final dateStr = DateFormat(
      'yyyyMMdd_HHmmss',
    ).format(currentPhoto.createdAt);
    final newFileName = "${prefix}_$dateStr.jpg";

    final newPath = currentPhoto.fileName == newFileName
        ? currentPhoto.filePath
        : await availablePath(oldFile.parent.path, newFileName);
    String? oldPathToEvict;

    if (newPath != currentPhoto.filePath) {
      oldPathToEvict = currentPhoto.filePath;
      await oldFile.rename(newPath);
      currentPhoto.fileName = p.basename(newPath);
      currentPhoto.filePath = newPath;
    }

    currentPhoto.description = newDescription;
    await DbService.to.addPhoto(currentPhoto);
    _copyPhotoFields(currentPhoto, photo);
    return oldPathToEvict;
  }

  void _copyPhotoFields(PhotoItem source, PhotoItem target) {
    target.ownerUserId = source.ownerUserId;
    target.createdAt = source.createdAt;
    target.fileName = source.fileName;
    target.filePath = source.filePath;
    target.description = source.description;
    target.deviceName = source.deviceName;
    target.projectName = source.projectName;
    target.projectId = source.projectId;
    target.dateIndexed = source.dateIndexed;
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
          '$targetDirectory/${sanitizePathSegment(photo.projectName ?? "Exported", fallback: "Exported")}',
        );
        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        }

        final targetPath = await availablePath(projectDir.path, photo.fileName);
        await sourceFile.copy(targetPath);
        successCount++;
      }
    }
    return successCount;
  }
}
