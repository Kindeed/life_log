import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/statistics/presentation/statistics_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

/// 备份/恢复工具类。
///
/// 设计说明：BackupService 是纯静态工具类，因为它没有需要管理的状态，
/// 仅执行一次性的文件操作。
class BackupService {
  static const databaseOnlyNotice = '当前备份仅包含本地数据库，不包含照片和凭证文件本体。';
  static bool _restoreInProgress = false;

  static Future<void> exportBackup() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final backupName =
          'LifeLog_Backup_${DateTime.now().millisecondsSinceEpoch}.isar';
      final backupPath = p.join(tempDir.path, backupName);

      await serviceLocator<DbService>().isar.copyToFile(backupPath);

      final xFile = XFile(backupPath);
      await Share.shareXFiles([
        xFile,
      ], text: 'LifeLog 数据库备份。$databaseOnlyNotice');
    } catch (e, stackTrace) {
      _logError('备份导出失败: $e', stackTrace);
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
    if (_restoreInProgress) {
      throw StateError('已有恢复任务正在进行，请等待完成');
    }
    _restoreInProgress = true;
    String? dbPath;
    File? existingDb;
    File? rollbackFile;
    File? candidateFile;

    try {
      dbPath = _currentDatabasePath();
      existingDb = File(dbPath);
      final tempDir = await getTemporaryDirectory();
      final rollbackPath = p.join(
        tempDir.path,
        'LifeLog_Rollback_${DateTime.now().millisecondsSinceEpoch}.isar',
      );
      final candidatePath = p.join(
        tempDir.path,
        'LifeLog_Restore_${DateTime.now().millisecondsSinceEpoch}.isar',
      );
      rollbackFile = File(rollbackPath);
      candidateFile = File(candidatePath);

      if (!await backupFile.exists()) {
        throw Exception("备份文件不存在");
      }

      if (await existingDb.exists()) {
        await serviceLocator<DbService>().isar.copyToFile(rollbackPath);
      }
      await backupFile.copy(candidatePath);

      await serviceLocator<DbService>().isar.close();

      if (await existingDb.exists()) {
        await existingDb.delete();
      }
      await candidateFile.copy(dbPath);

      await serviceLocator<DbService>().init();
      await _refreshStatisticsIfRegistered();
    } catch (e, stackTrace) {
      _logError('恢复备份失败: $e', stackTrace);
      try {
        if (rollbackFile != null &&
            existingDb != null &&
            dbPath != null &&
            await rollbackFile.exists()) {
          if (await existingDb.exists()) {
            await existingDb.delete();
          }
          await rollbackFile.copy(dbPath);
          await serviceLocator<DbService>().init();
          await _refreshStatisticsIfRegistered();
        }
      } catch (rollbackError, rollbackStackTrace) {
        _logError('恢复回滚失败: $rollbackError', rollbackStackTrace);
        // Keep the original error visible; the app may need a restart if the
        // platform still holds a database file handle.
      }
      throw Exception("恢复备份失败，已尝试回滚: $e");
    } finally {
      if (candidateFile != null && await candidateFile.exists()) {
        await candidateFile.delete();
      }
      if (rollbackFile != null && await rollbackFile.exists()) {
        await rollbackFile.delete();
      }
      _restoreInProgress = false;
    }
  }

  static String _currentDatabasePath() {
    final dbPath = serviceLocator<DbService>().isar.path;
    if (dbPath == null || dbPath.isEmpty) {
      throw Exception("当前平台不支持数据库文件恢复");
    }
    return dbPath;
  }

  static Future<void> _refreshStatisticsIfRegistered() async {
    if (serviceLocator.isRegistered<StatisticsController>()) {
      await serviceLocator<StatisticsController>().refreshStats();
    }
  }

  static void _logError(String message, StackTrace stackTrace) {
    if (serviceLocator.isRegistered<LogService>()) {
      LogService.to.error('Backup', message, stackTrace);
    }
  }
}
