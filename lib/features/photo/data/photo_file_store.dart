import 'dart:io';

import 'package:life_log/common/utils/file_path_utils.dart' as file_paths;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class PhotoFileStore {
  Future<String> appDocumentsPath();
  Future<void> ensureDirectory(String path);
  Future<String> availablePath(String directoryPath, String fileName);
  Future<void> copyFile(String sourcePath, String targetPath);
  Future<void> deleteSourceFile(String path);
  Future<void> deleteFileIfExists(String path);
  Future<bool> fileExists(String path);
  Future<String> renameFile(String sourcePath, String targetPath);
  String basename(String path);
  String dirname(String path);
}

final class IoPhotoFileStore implements PhotoFileStore {
  const IoPhotoFileStore();

  @override
  Future<String> appDocumentsPath() async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  @override
  Future<String> availablePath(String directoryPath, String fileName) {
    return file_paths.availablePath(directoryPath, fileName);
  }

  @override
  String basename(String path) => p.basename(path);

  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {
    await File(sourcePath).copy(targetPath);
  }

  @override
  Future<void> deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteSourceFile(String path) async {
    await File(path).delete();
  }

  @override
  String dirname(String path) => p.dirname(path);

  @override
  Future<void> ensureDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  @override
  Future<bool> fileExists(String path) {
    return File(path).exists();
  }

  @override
  Future<String> renameFile(String sourcePath, String targetPath) async {
    final file = await File(sourcePath).rename(targetPath);
    return file.path;
  }
}
