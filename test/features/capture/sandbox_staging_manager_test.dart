import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/capture/data/sandbox_staging_manager.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempRootDir;
  late Directory externalPhotosDir;
  late SandboxStagingManager stagingManager;

  setUp(() {
    tempRootDir = Directory.systemTemp.createTempSync(
      'staging_manager_test_root_',
    );
    externalPhotosDir = Directory.systemTemp.createTempSync(
      'external_photos_mock_',
    );
    stagingManager = SandboxStagingManager(tempRootDir);
  });

  tearDown(() {
    try {
      if (tempRootDir.existsSync()) {
        tempRootDir.deleteSync(recursive: true);
      }
    } catch (_) {}
    try {
      if (externalPhotosDir.existsSync()) {
        externalPhotosDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('SandboxStagingManager - 文件暂存与原图安全保障', () {
    test('将源文件暂存至沙箱，并验证源文件未被删除或修改', () async {
      // 模拟系统相册/外部原图
      final sourceFile = File(
        p.join(externalPhotosDir.path, 'original_camera_photo.jpg'),
      );
      const originalContent = 'BINARY_CAMERA_IMAGE_DATA_12345';
      await sourceFile.writeAsString(originalContent);

      expect(await sourceFile.exists(), isTrue);

      final stagedPath = await stagingManager.stageFile(
        taskId: 'task_sec_01',
        sourcePath: sourceFile.path,
      );

      // 1. 验证暂存文件生成且位于沙箱 staging 目录下
      final stagedFile = File(stagedPath);
      expect(await stagedFile.exists(), isTrue);
      expect(
        p.canonicalize(p.dirname(stagedPath)),
        p.canonicalize(stagingManager.stagingDirectory.path),
      );

      // 2. 验证命名格式为 ${taskId}_${timestamp}_${basename}
      final fileName = p.basename(stagedPath);
      final pattern = RegExp(r'^task_sec_01_\d+_original_camera_photo\.jpg$');
      expect(pattern.hasMatch(fileName), isTrue);

      // 3. 验证暂存文件内容与源文件一致
      expect(await stagedFile.readAsString(), originalContent);

      // 4. 【核心安全断言】：验证外部相册源文件仍然绝对存在，且内容未发生改变
      expect(await sourceFile.exists(), isTrue);
      expect(await sourceFile.readAsString(), originalContent);
    });

    test('源文件不存在时抛出 FileSystemException', () async {
      final nonExistentPath = p.join(externalPhotosDir.path, 'not_found.jpg');

      expect(
        () => stagingManager.stageFile(
          taskId: 'task_02',
          sourcePath: nonExistentPath,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('批量暂存多个文件并能通过 getStagedFiles 检索', () async {
      final sourceFile1 = File(p.join(externalPhotosDir.path, 'evidence_1.pdf'))
        ..writeAsStringSync('pdf1');
      final sourceFile2 = File(p.join(externalPhotosDir.path, 'evidence_2.pdf'))
        ..writeAsStringSync('pdf2');

      final stagedPaths = await stagingManager.stageFiles(
        taskId: 'task_batch',
        sourcePaths: [sourceFile1.path, sourceFile2.path],
      );

      expect(stagedPaths.length, 2);
      for (final path in stagedPaths) {
        expect(await File(path).exists(), isTrue);
      }

      // 验证源文件安然无恙
      expect(await sourceFile1.exists(), isTrue);
      expect(await sourceFile2.exists(), isTrue);

      final fetched = await stagingManager.getStagedFiles('task_batch');
      expect(fetched.length, 2);
      expect(fetched.toSet(), stagedPaths.toSet());
    });
  });

  group('SandboxStagingManager - 任务暂存安全清理与边界隔离', () {
    test('按 taskId 安全清理暂存文件，绝不误伤其他任务的文件或原图', () async {
      // 外部原图
      final external1 = File(p.join(externalPhotosDir.path, 'pic1.jpg'))
        ..writeAsStringSync('p1');
      final external2 = File(p.join(externalPhotosDir.path, 'pic2.jpg'))
        ..writeAsStringSync('p2');

      // 任务 A 暂存 2 个文件
      final stagedA1 = await stagingManager.stageFile(
        taskId: 'task_A',
        sourcePath: external1.path,
      );
      final stagedA2 = await stagingManager.stageFile(
        taskId: 'task_A',
        sourcePath: external2.path,
      );

      // 任务 B 暂存 1 个文件
      final stagedB1 = await stagingManager.stageFile(
        taskId: 'task_B',
        sourcePath: external1.path,
      );

      expect(await File(stagedA1).exists(), isTrue);
      expect(await File(stagedA2).exists(), isTrue);
      expect(await File(stagedB1).exists(), isTrue);

      // 执行清理任务 A 的暂存
      await stagingManager.clearTaskStaging('task_A');

      // 验证任务 A 的暂存文件已被删除
      expect(await File(stagedA1).exists(), isFalse);
      expect(await File(stagedA2).exists(), isFalse);

      // 验证任务 B 的暂存文件完好无损
      expect(await File(stagedB1).exists(), isTrue);
      final taskBFiles = await stagingManager.getStagedFiles('task_B');
      expect(taskBFiles.length, 1);
      expect(taskBFiles.first, stagedB1);

      // 验证外部原图完好无损
      expect(await external1.exists(), isTrue);
      expect(await external2.exists(), isTrue);
    });

    test('移除单个合法暂存文件', () async {
      final external = File(p.join(externalPhotosDir.path, 'pic.jpg'))
        ..writeAsStringSync('data');
      final staged = await stagingManager.stageFile(
        taskId: 'task_single',
        sourcePath: external.path,
      );

      expect(await File(staged).exists(), isTrue);
      await stagingManager.removeStagedFile(staged);
      expect(await File(staged).exists(), isFalse);
      expect(await external.exists(), isTrue);
    });

    test('尝试删除沙箱暂存目录外的文件时触发安全边界校验并抛出 ArgumentError', () async {
      final outsideFile = File(
        p.join(externalPhotosDir.path, 'sensitive_photo.jpg'),
      )..writeAsStringSync('top_secret');

      expect(
        () => stagingManager.removeStagedFile(outsideFile.path),
        throwsA(isA<ArgumentError>()),
      );

      // 外部文件必须未被删除
      expect(await outsideFile.exists(), isTrue);
    });
  });
}
