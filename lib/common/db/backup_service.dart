import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/project/project_controller.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/statistics/statistics_controller.dart';
import 'package:life_log/modules/subscription/subscription_controller.dart';
import 'package:life_log/modules/tabs/tabs_controller.dart';
import 'package:life_log/modules/work_log/work_log_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

/// 备份/恢复工具类。
///
/// 设计说明：与其他 Service（GetxService）不同，BackupService 是纯静态工具类，
/// 因为它没有需要管理的状态，仅执行一次性的文件操作。
class BackupService {
  static const databaseOnlyNotice = '当前备份仅包含本地数据库，不包含照片和凭证文件本体。';

  static Future<void> exportBackup() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final backupName =
          'LifeLog_Backup_${DateTime.now().millisecondsSinceEpoch}.isar';
      final backupPath = p.join(tempDir.path, backupName);

      await DbService.to.isar.copyToFile(backupPath);

      final xFile = XFile(backupPath);
      await Share.shareXFiles(
        [xFile],
        text: 'LifeLog 数据库备份。$databaseOnlyNotice',
      );
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
    final dbPath = _currentDatabasePath();
    final existingDb = File(dbPath);
    final tempDir = await getTemporaryDirectory();
    final rollbackPath = p.join(
      tempDir.path,
      'LifeLog_Rollback_${DateTime.now().millisecondsSinceEpoch}.isar',
    );
    final candidatePath = p.join(
      tempDir.path,
      'LifeLog_Restore_${DateTime.now().millisecondsSinceEpoch}.isar',
    );
    final rollbackFile = File(rollbackPath);
    final candidateFile = File(candidatePath);

    if (!await backupFile.exists()) {
      throw Exception("备份文件不存在");
    }

    if (await existingDb.exists()) {
      await DbService.to.isar.copyToFile(rollbackPath);
    }
    await backupFile.copy(candidatePath);

    try {
      await DbService.to.isar.close();

      if (await existingDb.exists()) {
        await existingDb.delete();
      }
      await candidateFile.copy(dbPath);

      await DbService.to.init();
      await _rebuildDatabaseControllers();
    } catch (e) {
      try {
        if (await rollbackFile.exists()) {
          if (await existingDb.exists()) {
            await existingDb.delete();
          }
          await rollbackFile.copy(dbPath);
          await DbService.to.init();
          await _rebuildDatabaseControllers();
        }
      } catch (_) {
        // Keep the original error visible; the app may need a restart if the
        // platform still holds a database file handle.
      }
      throw Exception("恢复备份失败，已尝试回滚: $e");
    } finally {
      if (await candidateFile.exists()) {
        await candidateFile.delete();
      }
      if (await rollbackFile.exists()) {
        await rollbackFile.delete();
      }
    }
  }

  static String _currentDatabasePath() {
    final dbPath = DbService.to.isar.path;
    if (dbPath == null || dbPath.isEmpty) {
      throw Exception("当前平台不支持数据库文件恢复");
    }
    return dbPath;
  }

  static Future<void> _rebuildDatabaseControllers() async {
    await _deleteIfRegistered<WorkLogController>();
    await _deleteIfRegistered<SubscriptionController>();
    await _deleteIfRegistered<ProjectController>();
    await _deleteIfRegistered<PhotoController>();
    await _deleteIfRegistered<EvidenceController>();
    await _deleteIfRegistered<StatisticsController>();
    await _deleteIfRegistered<TabsController>();
  }

  static Future<void> _deleteIfRegistered<T>() async {
    if (Get.isRegistered<T>()) {
      await Get.delete<T>(force: true);
    }
  }
}
