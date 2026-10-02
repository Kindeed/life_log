import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/db/database_restore_coordinator.dart';

void main() {
  late Directory directory;
  late DatabaseRestoreCoordinator coordinator;
  late _FileRestoreOperations operations;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('lifelog_restore_test_');
    coordinator = DatabaseRestoreCoordinator();
    operations = _FileRestoreOperations(directory);
    await operations.current.writeAsString('original-data');
    await operations.candidate.writeAsString('restored-data');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('invalid backup never pauses or replaces a usable database', () async {
    await operations.candidate.writeAsString('invalid');

    await expectLater(
      coordinator.restore(operations),
      throwsA(isA<DatabaseRestoreFailure>()),
    );

    expect(await operations.current.readAsString(), 'original-data');
    expect(operations.quiesced, isFalse);
    expect(await operations.snapshotFile.exists(), isFalse);
  });

  test(
    'successful restore reopens before writers and sync are resumed',
    () async {
      await coordinator.restore(operations);

      expect(await operations.current.readAsString(), 'restored-data');
      expect(operations.reopenedContents, ['restored-data']);
      expect(operations.resumedAvailable, [true]);
      expect(operations.fullRefreshRequired, isTrue);
      expect(await operations.snapshotFile.exists(), isFalse);
    },
  );

  test(
    'failed reopen restores the original snapshot before resuming',
    () async {
      operations.reopenFailures = 1;

      await expectLater(
        coordinator.restore(operations),
        throwsA(isA<DatabaseRestoreFailure>()),
      );

      expect(await operations.current.readAsString(), 'original-data');
      expect(operations.reopenedContents, ['original-data']);
      expect(operations.resumedAvailable, [true]);
      expect(await operations.snapshotFile.exists(), isFalse);
    },
  );

  test(
    'restore and rollback failures retain the original recovery copy',
    () async {
      operations.reopenFailures = 2;

      await expectLater(
        coordinator.restore(operations),
        throwsA(
          isA<DatabaseRestoreFailure>()
              .having(
                (error) => error.recoveryError,
                'recoveryError',
                isNotNull,
              )
              .having(
                (error) => error.recoveryPath,
                'recoveryPath',
                operations.snapshotFile.path,
              ),
        ),
      );

      expect(await operations.snapshotFile.readAsString(), 'original-data');
      expect(operations.resumedAvailable, [false]);
      expect(operations.writesBlocked, isTrue);
    },
  );

  test('a partial replacement failure also restores original bytes', () async {
    operations.failAfterReplace = true;

    await expectLater(
      coordinator.restore(operations),
      throwsA(isA<DatabaseRestoreFailure>()),
    );

    expect(await operations.current.readAsString(), 'original-data');
    expect(operations.resumedAvailable, [true]);
  });

  test(
    'candidate reopen and rollback copy failures retain original bytes',
    () async {
      operations
        ..reopenFailures = 1
        ..failRollbackCopy = true;
      await expectLater(
        coordinator.restore(operations),
        throwsA(
          isA<DatabaseRestoreFailure>()
              .having(
                (error) => error.recoveryError,
                'rollback copy error',
                isNotNull,
              )
              .having(
                (error) => error.recoveryPath,
                'recovery path',
                operations.snapshotFile.path,
              ),
        ),
      );
      expect(await operations.snapshotFile.readAsString(), 'original-data');
      expect(operations.resumedAvailable, [false]);
      expect(operations.writesBlocked, isTrue);
    },
  );

  test('snapshot failure resumes the still-open original database', () async {
    operations.failSnapshot = true;

    await expectLater(
      coordinator.restore(operations),
      throwsA(isA<DatabaseRestoreFailure>()),
    );

    expect(await operations.current.readAsString(), 'original-data');
    expect(operations.resumedAvailable, [true]);
    expect(operations.writesBlocked, isFalse);
  });

  test(
    'cleanup failures do not fail a restore or retain the busy guard',
    () async {
      operations.failCleanup = true;
      await coordinator.restore(operations);
      expect(operations.cleanupFailures, hasLength(2));

      operations.failCleanup = false;
      await operations.candidate.writeAsString('second-restore');
      await coordinator.restore(operations);
      expect(await operations.current.readAsString(), 'second-restore');
    },
  );

  test(
    'concurrent restore is rejected while an existing restore drains',
    () async {
      final drain = Completer<void>();
      operations.drain = drain.future;
      final first = coordinator.restore(operations);
      await operations.quiesceReached.future;

      await expectLater(coordinator.restore(operations), throwsStateError);
      expect(await operations.current.readAsString(), 'original-data');
      drain.complete();
      await first;
      expect(await operations.current.readAsString(), 'restored-data');
    },
  );

  test(
    'marker survives stale GetStorage after restart and advances monotonically',
    () async {
      final first = await DatabaseRestoreCoordinator.advanceRestoreGeneration(
        directory.path,
        storedGeneration: 7,
      );
      expect(first, 8);
      final marker = File(
        '${directory.path}/${DatabaseRestoreCoordinator.restoreGenerationFileName}',
      );
      expect(await marker.readAsString(), '8');
      expect(
        await DatabaseRestoreCoordinator.readRestoreGeneration(
          directory.path,
          storedGeneration: 0,
        ),
        8,
      );
      expect(
        await DatabaseRestoreCoordinator.advanceRestoreGeneration(
          directory.path,
          storedGeneration: 0,
        ),
        9,
      );
      expect(await marker.readAsString(), '9');
      expect(
        await DatabaseRestoreCoordinator.advanceRestoreGeneration(
          directory.path,
          storedGeneration: 11,
        ),
        12,
      );
      expect(await marker.readAsString(), '12');
      expect(
        (await directory.list().toList()).where(
          (file) => file.path.endsWith('.tmp'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'corrupt marker fails closed without overwriting recovery generation',
    () async {
      final marker = File(
        '${directory.path}/${DatabaseRestoreCoordinator.restoreGenerationFileName}',
      );
      await marker.writeAsString('not-a-generation');
      await expectLater(
        DatabaseRestoreCoordinator.advanceRestoreGeneration(
          directory.path,
          storedGeneration: 2,
        ),
        throwsStateError,
      );
      expect(await marker.readAsString(), 'not-a-generation');
    },
  );

  test(
    'cleanup reporting failure cannot hide the retained recovery copy',
    () async {
      operations
        ..reopenFailures = 2
        ..failCleanup = true
        ..failCleanupReporting = true;
      await expectLater(
        coordinator.restore(operations),
        throwsA(
          isA<DatabaseRestoreFailure>().having(
            (error) => error.recoveryPath,
            'retained recovery path',
            operations.snapshotFile.path,
          ),
        ),
      );
      expect(await operations.snapshotFile.readAsString(), 'original-data');
      operations
        ..failCleanup = false
        ..failCleanupReporting = false;
      await operations.candidate.writeAsString('retry-restored-data');
      await coordinator.restore(operations);
      expect(await operations.current.readAsString(), 'retry-restored-data');
    },
  );
}

final class _FileRestoreOperations implements DatabaseRestoreOperations {
  final Directory directory;
  bool quiesced = false;
  bool writesBlocked = false;
  bool fullRefreshRequired = false;
  bool failAfterReplace = false;
  bool failSnapshot = false;
  bool failRollbackCopy = false;
  bool failCleanup = false;
  bool failCleanupReporting = false;
  int reopenFailures = 0;
  bool _snapshotAvailable = false;
  Future<void>? drain;
  final quiesceReached = Completer<void>();
  final resumedAvailable = <bool>[];
  final reopenedContents = <String>[];
  final cleanupFailures = <Object>[];

  _FileRestoreOperations(this.directory);

  File get current => File('${directory.path}/current.isar');
  File get candidate => File('${directory.path}/candidate.isar');
  File get snapshotFile => File('${directory.path}/original.isar');

  @override
  bool get snapshotAvailable => _snapshotAvailable;

  @override
  String? get recoveryPath => snapshotFile.path;

  @override
  Future<void> validateCandidate() async {
    if (await candidate.readAsString() == 'invalid') {
      throw StateError('Invalid Isar file');
    }
  }

  @override
  Future<void> quiesce() async {
    quiesced = true;
    writesBlocked = true;
    fullRefreshRequired = true;
    if (!quiesceReached.isCompleted) quiesceReached.complete();
    await drain;
  }

  @override
  Future<void> snapshot() async {
    if (failSnapshot) throw const FileSystemException('Injected disk full');
    await current.copy(snapshotFile.path);
    _snapshotAvailable = true;
  }

  @override
  Future<void> replace() async {
    await candidate.copy(current.path);
    if (failAfterReplace) throw StateError('Injected replacement interruption');
  }

  @override
  Future<void> reopen() async {
    if (reopenFailures > 0) {
      reopenFailures--;
      throw StateError('Injected database open failure');
    }
    reopenedContents.add(await current.readAsString());
  }

  @override
  Future<void> resume({required bool databaseAvailable}) async {
    resumedAvailable.add(databaseAvailable);
    writesBlocked = !databaseAvailable;
  }

  @override
  Future<void> restoreSnapshot() async {
    if (failRollbackCopy) {
      throw const FileSystemException('Injected rollback copy failure');
    }
    await snapshotFile.copy(current.path);
  }

  @override
  Future<void> cleanupCandidate() async {
    if (failCleanup) throw const FileSystemException('Cannot delete candidate');
    if (await candidate.exists()) await candidate.delete();
  }

  @override
  Future<void> cleanupSnapshot() async {
    if (failCleanup) throw const FileSystemException('Cannot delete snapshot');
    if (await snapshotFile.exists()) await snapshotFile.delete();
  }

  @override
  void reportCleanupFailure(Object error, StackTrace stackTrace) {
    if (failCleanupReporting) throw StateError('diagnostic reporting failed');
    cleanupFailures.add(error);
  }
}
