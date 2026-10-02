import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/db/database_restore_coordinator.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/statistics/presentation/statistics_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

/// 备份/恢复工具类。
///
/// 恢复期间停止同步和数据库写入，并保留可恢复的原数据库快照。
class BackupService {
  static const databaseOnlyNotice = '当前备份仅包含本地数据库，不包含照片和凭证文件本体。';
  static bool _restoreInProgress = false;
  static final _restoreCoordinator = DatabaseRestoreCoordinator();

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
    try {
      final operations = await _BackupRestoreOperations.create(
        backupFile: backupFile,
        dbPath: _currentDatabasePath(),
        db: serviceLocator<DbService>(),
        sync: serviceLocator.isRegistered<SyncService>()
            ? serviceLocator<SyncService>()
            : null,
      );
      await _restoreCoordinator.restore(operations);
    } catch (error, stackTrace) {
      _logError('恢复备份失败: $error', stackTrace);
      rethrow;
    } finally {
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

final class _BackupRestoreOperations implements DatabaseRestoreOperations {
  final File backupFile;
  final String dbPath;
  final DbService db;
  final SyncService? sync;
  final Directory candidateDirectory;
  final String candidateName;
  final File candidateFile;
  final Directory recoveryDirectory;
  final File snapshotFile;
  final File stagingFile;
  bool _snapshotAvailable = false;

  _BackupRestoreOperations({
    required this.backupFile,
    required this.dbPath,
    required this.db,
    required this.sync,
    required this.candidateDirectory,
    required this.candidateName,
    required this.candidateFile,
    required this.recoveryDirectory,
    required this.snapshotFile,
    required this.stagingFile,
  });

  static Future<_BackupRestoreOperations> create({
    required File backupFile,
    required String dbPath,
    required DbService db,
    required SyncService? sync,
  }) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final temporaryDirectory = await getTemporaryDirectory();
    final candidateDirectory = await temporaryDirectory.createTemp(
      'LifeLog_Restore_',
    );
    final candidateName = 'LifeLog_Validate_$stamp';
    // Recovery copies live beside the database, rather than in an OS-managed
    // temporary directory that may discard the only valid copy after failure.
    final recoveryDirectory = Directory(
      p.join(p.dirname(dbPath), 'LifeLog_Recovery', '$stamp'),
    );
    return _BackupRestoreOperations(
      backupFile: backupFile,
      dbPath: dbPath,
      db: db,
      sync: sync,
      candidateDirectory: candidateDirectory,
      candidateName: candidateName,
      candidateFile: File(
        p.join(candidateDirectory.path, '$candidateName.isar'),
      ),
      recoveryDirectory: recoveryDirectory,
      snapshotFile: File(p.join(recoveryDirectory.path, 'original.isar')),
      stagingFile: File(
        p.join(p.dirname(dbPath), 'LifeLog_Restore_stage_$stamp.isar'),
      ),
    );
  }

  @override
  bool get snapshotAvailable => _snapshotAvailable;

  @override
  String? get recoveryPath => _snapshotAvailable ? snapshotFile.path : null;

  @override
  Future<void> validateCandidate() async {
    if (!await backupFile.exists()) throw StateError('备份文件不存在');
    // MDBX needs its metadata pages to identify an existing database. Isar
    // treats a tiny/truncated file as a request to create a new empty database,
    // which would otherwise turn a corrupt import into silent data erasure.
    if (await backupFile.length() < 8192) {
      throw StateError('备份文件不完整，不能恢复');
    }
    await backupFile.copy(candidateFile.path);
    final candidate = await IsarDatabase.open(
      schemas: DbService.schemas,
      directory: candidateDirectory.path,
      name: candidateName,
      inspector: false,
    );
    // Isar validates the file header and collection schema without touching
    // the currently open database. Migrations only affect this isolated copy.
    await candidate.close();
  }

  @override
  Future<void> quiesce() async {
    if (sync != null) {
      await sync!.prepareForDatabaseRestore();
    } else {
      // Offline restores invalidate cursors retained from an earlier cloud
      // session. All accounts observe this durable marker on their next sync.
      final storage = GetStorage();
      const key = DatabaseRestoreCoordinator.restoreGenerationStorageKey;
      final generation =
          await DatabaseRestoreCoordinator.advanceRestoreGeneration(
            db.database.directory ?? (throw StateError('当前数据库不支持文件恢复')),
            storedGeneration: storage.read<int>(key) ?? 0,
          );
      await storage.write(key, generation);
    }
    await db.prepareForDatabaseRestore();
  }

  @override
  Future<void> snapshot() async {
    await recoveryDirectory.create(recursive: true);
    await db.isar.copyToFile(snapshotFile.path);
    _snapshotAvailable = true;
  }

  @override
  Future<void> replace() async {
    // Copy before closing, then replace through a same-directory rename. A
    // process interruption during the copy leaves the original database valid.
    await candidateFile.copy(stagingFile.path);
    await db.isar.close();
    await stagingFile.rename(dbPath);
  }

  @override
  Future<void> reopen() => db.reopenAfterRestore();

  @override
  Future<void> resume({required bool databaseAvailable}) async {
    await sync?.databaseRestoreCompleted(
      databaseAvailable: databaseAvailable,
      forceFullRefresh: true,
    );
    if (databaseAvailable) {
      // Cursor cleanup can fail and require rollback. Keep writers blocked
      // until that fallible recovery work has finished.
      db.finishDatabaseRestore();
      try {
        await BackupService._refreshStatisticsIfRegistered();
      } catch (error, stackTrace) {
        // A presentation refresh must not undo a successful restore after
        // writers have resumed and could already have accepted new edits.
        BackupService._logError('恢复后刷新统计失败: $error', stackTrace);
      }
    }
  }

  @override
  Future<void> restoreSnapshot() async {
    await quiesce();
    await snapshotFile.copy(stagingFile.path);
    if (db.isar.isOpen) await db.isar.close();
    await stagingFile.rename(dbPath);
  }

  @override
  Future<void> cleanupCandidate() async {
    if (await stagingFile.exists()) await stagingFile.delete();
    if (await candidateDirectory.exists()) {
      await candidateDirectory.delete(recursive: true);
    }
  }

  @override
  Future<void> cleanupSnapshot() async {
    if (await snapshotFile.exists()) await snapshotFile.delete();
    if (await recoveryDirectory.exists()) await recoveryDirectory.delete();
  }

  @override
  void reportCleanupFailure(Object error, StackTrace stackTrace) {
    BackupService._logError('清理恢复临时文件失败: $error', stackTrace);
  }
}
