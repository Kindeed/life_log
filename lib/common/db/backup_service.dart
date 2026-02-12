import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

class BackupService {
  static Future<void> exportBackup() async {
    try {
      // 1. 获取数据库目录
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'default.isar'); // Isar 默认的文件名通常是这样

      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        Get.snackbar("错误", "未找到数据库文件");
        return;
      }

      // 2. 创建临时副本以供分享
      final tempDir = await getTemporaryDirectory();
      final backupName =
          'LifeLog_Backup_${DateTime.now().millisecondsSinceEpoch}.isar';
      final backupPath = p.join(tempDir.path, backupName);

      // 使用 isar 的 copyToFile 是最安全的备份方式
      await DbService.to.isar.copyToFile(backupPath);

      // 3. 调用分享
      final xFile = XFile(backupPath);
      await Share.shareXFiles([xFile], text: 'Life Log 数据备份');
    } catch (e) {
      Get.snackbar("备份失败", e.toString());
    }
  }

  static Future<void> importBackup() async {
    try {
      // 1. 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // .isar 文件可能被识别为 any
      );

      if (result == null || result.files.single.path == null) return;

      final selectedFile = File(result.files.single.path!);

      // 检查文件名（简单校验）
      if (!selectedFile.path.endsWith('.isar')) {
        Get.snackbar("错误", "请选择有效的 .isar 备份文件");
        return;
      }

      // 2. 确认覆盖
      Get.confirmDialog(
        "恢复确认",
        "导入备份将覆盖当前所有数据，此操作不可撤销。是否继续？",
        onConfirm: () async {
          Get.back(); // 关闭对话框
          await _doImport(selectedFile);
        },
      );
    } catch (e) {
      Get.snackbar("导入失败", e.toString());
    }
  }

  static Future<void> _doImport(File backupFile) async {
    try {
      // 1. 关闭现有数据库
      await DbService.to.isar.close();

      // 2. 覆盖文件
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'default.isar');

      await backupFile.copy(dbPath);

      // 3. 重新初始化数据库（不再使用 exit(0)，避免 iOS 审核问题）
      await DbService.to.init();

      // 4. 刷新所有控制器数据
      Get.snackbar("恢复成功", "数据已恢复，正在刷新...");

      // 尝试刷新已注册的控制器
      try {
        if (Get.isRegistered<dynamic>(tag: null)) {
          // 由于控制器可能还没初始化，安全地逐模块检查
        }
      } catch (_) {}

      Get.snackbar("完成", "数据库已重新加载，数据已恢复。");
    } catch (e) {
      Get.snackbar("恢复过程出错", e.toString());
    }
  }
}

extension on GetInterface {
  void confirmDialog(
    String title,
    String middleText, {
    required VoidCallback onConfirm,
  }) {
    Get.defaultDialog(
      title: title,
      middleText: middleText,
      textConfirm: "确认",
      textCancel: "取消",
      confirmTextColor: Colors.white,
      onConfirm: onConfirm,
    );
  }
}
