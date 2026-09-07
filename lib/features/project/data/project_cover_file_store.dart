import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores project cover copies in an app-private directory.
class ProjectCoverFileStore {
  const ProjectCoverFileStore();

  Future<String> copyToPrivateStorage({
    required int projectId,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) throw StateError('封面文件不存在');
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'project_covers'));
    await dir.create(recursive: true);
    final ext = p.extension(source.path).isEmpty
        ? '.jpg'
        : p.extension(source.path);
    final target = File(p.join(dir.path, 'project_$projectId$ext'));
    final copied = await source.copy(target.path);
    return copied.path;
  }
}
