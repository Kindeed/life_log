import 'dart:io';

/// The file/database boundary is injected so destructive failure paths are
/// exercised without replacing an application's live database in tests.
abstract interface class DatabaseRestoreOperations {
  Future<void> validateCandidate();
  Future<void> quiesce();
  Future<void> snapshot();
  Future<void> replace();
  Future<void> reopen();
  Future<void> resume({required bool databaseAvailable});
  Future<void> restoreSnapshot();
  Future<void> cleanupCandidate();
  Future<void> cleanupSnapshot();
  bool get snapshotAvailable;
  String? get recoveryPath;
  void reportCleanupFailure(Object error, StackTrace stackTrace);
}

final class DatabaseRestoreFailure implements Exception {
  final Object cause;
  final Object? recoveryError;
  final String? recoveryPath;

  const DatabaseRestoreFailure({
    required this.cause,
    this.recoveryError,
    this.recoveryPath,
  });

  @override
  String toString() {
    if (recoveryPath != null) {
      return '恢复失败：$cause。原数据库副本已保留在 $recoveryPath。'
          '恢复原数据库时发生：$recoveryError';
    }
    return '恢复备份失败，当前数据库未被替换或已恢复原数据：$cause';
  }
}

final class DatabaseRestoreCoordinator {
  static const restoreGenerationStorageKey = 'sync_restore_generation';
  static const restoreGenerationFileName = 'LifeLog_Sync_Restore.generation';

  static Future<int> readRestoreGeneration(
    String directory, {
    required int storedGeneration,
  }) async {
    final marker = File('$directory/$restoreGenerationFileName');
    if (!await marker.exists()) return storedGeneration;
    final persisted = int.tryParse((await marker.readAsString()).trim());
    if (persisted == null || persisted < 0) {
      throw StateError('数据库恢复标记损坏，不能继续增量同步');
    }
    return persisted > storedGeneration ? persisted : storedGeneration;
  }

  static Future<int> advanceRestoreGeneration(
    String directory, {
    required int storedGeneration,
  }) async {
    final generation =
        await readRestoreGeneration(
          directory,
          storedGeneration: storedGeneration,
        ) +
        1;
    final marker = File('$directory/$restoreGenerationFileName');
    final staging = File(
      '${marker.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      // A separate flushed marker survives replacing Isar and does not depend
      // on GetStorage's unawaited microtask/flush queue. Rename keeps the old
      // generation valid if the process stops during this write.
      await staging.writeAsString('$generation', flush: true);
      await staging.rename(marker.path);
    } finally {
      try {
        if (await staging.exists()) await staging.delete();
      } catch (_) {
        // Failure to remove a staging marker cannot invalidate the committed
        // marker or hide a failure that correctly prevented replacement.
      }
    }
    return generation;
  }

  bool _inProgress = false;

  Future<void> restore(DatabaseRestoreOperations operations) async {
    if (_inProgress) throw StateError('已有恢复任务正在进行，请等待完成');
    _inProgress = true;
    var quiesceStarted = false;
    var replacementStarted = false;
    var safeToDeleteSnapshot = false;
    try {
      await operations.validateCandidate();
      quiesceStarted = true;
      await operations.quiesce();
      await operations.snapshot();
      replacementStarted = true;
      await operations.replace();
      await operations.reopen();
      await operations.resume(databaseAvailable: true);
      safeToDeleteSnapshot = true;
    } catch (error) {
      Object? recoveryError;
      var databaseAvailable = !replacementStarted;
      try {
        if (replacementStarted && operations.snapshotAvailable) {
          await operations.restoreSnapshot();
          await operations.reopen();
          databaseAvailable = true;
        }
        if (quiesceStarted) {
          await operations.resume(databaseAvailable: databaseAvailable);
        }
        safeToDeleteSnapshot = databaseAvailable;
      } catch (failure) {
        recoveryError = failure;
        // Keep writes and sync suspended if neither database can be reopened.
        try {
          await operations.resume(databaseAvailable: false);
        } catch (_) {}
      }
      throw DatabaseRestoreFailure(
        cause: error,
        recoveryError: recoveryError,
        recoveryPath: !safeToDeleteSnapshot && operations.snapshotAvailable
            ? operations.recoveryPath
            : null,
      );
    } finally {
      // Cleanup is best effort. A cleanup error must never hide a recovery path
      // or leave the concurrency guard permanently set.
      try {
        try {
          await operations.cleanupCandidate();
        } catch (error, stackTrace) {
          _reportCleanupFailure(operations, error, stackTrace);
        }
        if (safeToDeleteSnapshot) {
          try {
            await operations.cleanupSnapshot();
          } catch (error, stackTrace) {
            _reportCleanupFailure(operations, error, stackTrace);
          }
        }
      } finally {
        _inProgress = false;
      }
    }
  }

  static void _reportCleanupFailure(
    DatabaseRestoreOperations operations,
    Object error,
    StackTrace stackTrace,
  ) {
    try {
      operations.reportCleanupFailure(error, stackTrace);
    } catch (_) {
      // Diagnostic failures cannot hide the original restore failure and its
      // retained recovery path, or turn a successful restore into a rollback.
    }
  }
}
