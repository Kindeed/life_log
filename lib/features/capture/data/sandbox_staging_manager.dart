import 'dart:io';

import 'package:life_log/common/utils/file_path_utils.dart';
import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';
import 'package:path/path.dart' as p;

/// 采集任务的私有沙箱暂存区管理器。
///
/// 严格遵循以下原则：
/// - 复制外部文件至沙箱暂存目录，生成安全唯一文件名，严禁修改或删除原图；
/// - 按任务 ID 前缀进行沙箱文件隔离；
/// - 仅清理带有指定任务前缀的暂存文件，绝不触碰任何其他文件；
/// - 删除单个暂存文件时严格校验路径是否处于沙箱暂存目录内，防止越界删除。
class SandboxStagingManager implements StagingPort {
  /// 暂存目录相对根目录的子目录名称。
  static const String stagingSubDir = 'staging';

  /// 沙箱根存储目录。
  final Directory rootDirectory;

  SandboxStagingManager(this.rootDirectory);

  /// 沙箱暂存目录对象。
  Directory get stagingDirectory =>
      Directory(p.join(rootDirectory.path, stagingSubDir));

  /// 确保沙箱暂存目录存在。
  Future<Directory> _ensureStagingDirectory() async {
    final dir = stagingDirectory;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<String> stageFile({
    required String taskId,
    required String sourcePath,
    CapturePurpose? purpose,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    final stagingDir = await _ensureStagingDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalBaseName = p.basename(sourcePath);
    final safeBaseName = sanitizePathSegment(
      originalBaseName,
      fallback: 'media_file',
    );
    final targetFileName = '${taskId}_${timestamp}_$safeBaseName';
    final targetPath = p.join(stagingDir.path, targetFileName);

    // 仅执行文件复制，严禁修改或删除源文件！
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  @override
  Future<List<String>> stageFiles({
    required String taskId,
    required List<String> sourcePaths,
    CapturePurpose? purpose,
  }) async {
    final stagedPaths = <String>[];
    for (final sourcePath in sourcePaths) {
      final staged = await stageFile(
        taskId: taskId,
        sourcePath: sourcePath,
        purpose: purpose,
      );
      stagedPaths.add(staged);
    }
    return stagedPaths;
  }

  @override
  Future<List<String>> getStagedFiles(String taskId) async {
    final dir = stagingDirectory;
    if (!await dir.exists()) return const [];

    final prefix = '${taskId}_';
    final result = <String>[];

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name.startsWith(prefix)) {
          result.add(entity.path);
        }
      }
    }
    return result;
  }

  @override
  Future<void> clearTaskStaging(String taskId) async {
    final dir = stagingDirectory;
    if (!await dir.exists()) return;

    final prefix = '${taskId}_';

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name.startsWith(prefix)) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }

  @override
  Future<void> removeStagedFile(String stagedPath) async {
    final dir = stagingDirectory;
    final canonicalStagingPath = p.canonicalize(dir.path);
    final canonicalTarget = p.canonicalize(stagedPath);

    // 严格检查目标文件是否位于沙箱暂存目录内，防止目录遍历与越界删除
    if (!p.isWithin(canonicalStagingPath, canonicalTarget)) {
      throw ArgumentError(
        'Security boundary violation: target path is outside sandbox staging directory: $stagedPath',
      );
    }

    final file = File(stagedPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
