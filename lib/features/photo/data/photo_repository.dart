import 'package:intl/intl.dart';
import 'package:life_log/common/utils/file_path_utils.dart';
import 'package:life_log/features/photo/data/photo_file_store.dart';
import 'package:life_log/features/photo/data/photo_local_data_source.dart';
import 'package:life_log/features/photo/data/photo_project_resolver.dart';
import 'photo_model.dart';

class PhotoRepository {
  PhotoRepository({
    PhotoLocalDataSource? localDataSource,
    PhotoProjectResolver? projectResolver,
    PhotoFileStore? fileStore,
  }) : _localDataSource = localDataSource ?? const DbPhotoLocalDataSource(),
       _projectResolver = projectResolver ?? const GetItPhotoProjectResolver(),
       _fileStore = fileStore ?? const IoPhotoFileStore();

  final PhotoLocalDataSource _localDataSource;
  final PhotoProjectResolver _projectResolver;
  final PhotoFileStore _fileStore;

  // --- 查询业务 ---
  Future<List<PhotoItem>> getAllPhotos() async {
    return await _localDataSource.getAllPhotos();
  }

  Stream<void> watchPhotos() {
    return _localDataSource.watchPhotos();
  }

  // --- 修改业务 ---
  Future<PhotoItem> processAndSavePhoto({
    required String tempPath,
    required String projectName,
    required String description,
    required String deviceName,
    bool deleteSource = true,
  }) async {
    final appDocumentsPath = await _fileStore.appDocumentsPath();

    final safeProjectName = sanitizePathSegment(
      projectName,
      fallback: 'DefaultProject',
    );
    final project = await _projectResolver.ensureProject(safeProjectName);
    final safeDeviceName = sanitizePathSegment(
      deviceName,
      fallback: 'UnknownDevice',
    );
    final safeDesc = sanitizePathSegment(description, fallback: '');

    final folderPath = '$appDocumentsPath/$safeProjectName/$safeDeviceName';
    await _fileStore.ensureDirectory(folderPath);

    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);

    String filePrefix = safeDesc.isNotEmpty ? safeDesc : safeProjectName;
    if (filePrefix.length > 50) {
      filePrefix = filePrefix.substring(0, 50);
    }
    final fileName = "${filePrefix}_$dateStr.jpg";
    final savePath = await _fileStore.availablePath(folderPath, fileName);

    // Copy into the app-private archive. Gallery imports must keep the source
    // until the platform media delete request has completed.
    await _fileStore.copyFile(tempPath, savePath);
    if (deleteSource) {
      await _fileStore.deleteSourceFile(tempPath);
    }

    // Save to DB
    final photoItem = PhotoItem()
      ..createdAt = now
      ..fileName = _fileStore.basename(savePath)
      ..filePath = savePath
      ..deviceName = deviceName
      ..projectId = project.id
      ..projectName = project.name
      ..description = description
      ..dateIndexed = DateTime(now.year, now.month, now.day);

    await _localDataSource.addPhoto(photoItem);
    return photoItem;
  }

  Future<void> deletePhotos(List<PhotoItem> itemsToDelete) async {
    for (var photo in itemsToDelete) {
      final currentPhoto = await _localDataSource.getPhoto(photo.id);
      if (currentPhoto == null) continue;

      // 1. Delete file
      await _fileStore.deleteFileIfExists(currentPhoto.filePath);
      // 2. Delete from DB
      await _localDataSource.deletePhoto(photo.id);
    }
  }

  /// 更新照片信息，如果有需要则重命名文件
  /// 返回更新前的旧路径（如果重命名了），用于告诉 UI 清理旧图片缓存。
  Future<String?> updatePhotoDescription(
    PhotoItem photo,
    String newDescription,
  ) async {
    final currentPhoto = await _localDataSource.getPhoto(photo.id);
    if (currentPhoto == null) {
      throw StateError('照片不存在或不属于当前用户');
    }

    if (!await _fileStore.fileExists(currentPhoto.filePath)) {
      // Just update DB if file missing
      currentPhoto.description = newDescription;
      await _localDataSource.addPhoto(currentPhoto);
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
        : await _fileStore.availablePath(
            _fileStore.dirname(currentPhoto.filePath),
            newFileName,
          );
    String? oldPathToEvict;

    if (newPath != currentPhoto.filePath) {
      oldPathToEvict = currentPhoto.filePath;
      final renamedPath = await _fileStore.renameFile(
        currentPhoto.filePath,
        newPath,
      );
      currentPhoto.fileName = _fileStore.basename(renamedPath);
      currentPhoto.filePath = renamedPath;
    }

    currentPhoto.description = newDescription;
    await _localDataSource.addPhoto(currentPhoto);
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
      if (await _fileStore.fileExists(photo.filePath)) {
        final projectDir =
            '$targetDirectory/${sanitizePathSegment(photo.projectName ?? "Exported", fallback: "Exported")}';
        await _fileStore.ensureDirectory(projectDir);

        final targetPath = await _fileStore.availablePath(
          projectDir,
          photo.fileName,
        );
        await _fileStore.copyFile(photo.filePath, targetPath);
        successCount++;
      }
    }
    return successCount;
  }
}
