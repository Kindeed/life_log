import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

/// 备份/恢复工具类。
///
/// 设计说明：与其他 Service（GetxService）不同，BackupService 是纯静态工具类，
/// 因为它没有需要管理的状态，仅执行一次性的文件操作。
class BackupService {
  static Future<void> exportBackup() async {
    try {
      // 1. 获取数据库目录
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'default.isar'); // Isar 默认的文件名通常是这样

      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception("未找到数据库文件");
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
      await Share.shareXFiles([xFile], text: 'LifeLog 数据备份');
    } catch (e) {
      throw Exception("备份异常: $e");
    }
  }

  static Future<File?> pickBackupFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // .isar 文件可能被识别为 any
    );

    if (result == null || result.files.single.path == null) return null;

    final selectedFile = File(result.files.single.path!);

    // 检查文件名（简单校验）
    if (!selectedFile.path.endsWith('.isar')) {
      throw Exception("请选择有效的 .isar 备份文件");
    }

    return selectedFile;
  }

  static Future<void> restoreFromBackup(File backupFile) async {
    // 1. 关闭现有数据库
    await DbService.to.isar.close();

    // 2. 覆盖文件
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'default.isar');

    final existingDb = File(dbPath);
    if (await existingDb.exists()) {
      await existingDb.delete();
    }

    await backupFile.copy(dbPath);

    // 3. 重新初始化数据库
    await DbService.to.init();
  }
}
