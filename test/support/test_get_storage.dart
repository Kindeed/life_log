import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as path;

/// Owns the real files/handles of one test-only GetStorage container.
/// GetStorage 2.1.1 keeps its native handle open and has no public close API.
/// The override only instruments this container's two exact file paths; reads,
/// writes, locks and flushes still use dart:io's real filesystem.
final class TestGetStorage {
  static final _io = _StorageFiles();
  static final _active = <TestGetStorage>{};
  static final _containers = <String>{};

  final GetStorage storage;
  final Directory directory;
  final List<String> _paths;
  final _handles = <RandomAccessFile>{};
  final _writes = <Future<File>>[];
  var _expectedBackups = 0;
  var _startedBackups = 0;
  var _backupStarted = Completer<void>();
  bool _closed = false;

  TestGetStorage._(this.storage, this.directory, this._paths);

  static Future<TestGetStorage> open(
    String container,
    Directory directory,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(container)) {
      throw ArgumentError.value(container, 'container', 'Unsafe test filename');
    }
    final absolute = path.normalize(directory.absolute.path);
    final resolved = path.normalize(await directory.resolveSymbolicLinks());
    if (!path.equals(absolute, resolved) ||
        await FileSystemEntity.type(absolute, followLinks: false) !=
            FileSystemEntityType.directory) {
      throw StateError('GetStorage test directory must be a real directory');
    }
    final paths = [
      path.join(resolved, '$container.gs'),
      path.join(resolved, '$container.bak'),
    ];
    for (final file in paths) {
      if (await FileSystemEntity.type(file, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw StateError('Test storage files must not already exist');
      }
    }
    if (_active.isEmpty && IOOverrides.current != null) {
      throw StateError('An existing IOOverrides must not be replaced');
    }
    if (!_containers.add(container)) {
      throw StateError('A closed GetStorage container cannot be reopened');
    }
    if (_active.isEmpty) IOOverrides.global = _io;
    final fixture = TestGetStorage._(
      GetStorage(container, resolved),
      Directory(resolved),
      paths,
    );
    _active.add(fixture);
    for (final file in paths) {
      _io.owners[path.normalize(file)] = fixture;
    }
    try {
      await fixture.storage.initStorage;
    } catch (error, stack) {
      final failures = <(Object, StackTrace)>[(error, stack)];
      try {
        await fixture._closeHandles(failures);
      } finally {
        fixture._releaseInstrumentation();
      }
      _throwFailures(failures);
    }
    return fixture;
  }

  Future<void> close() async {
    if (_closed) return;
    final failures = <(Object, StackTrace)>[];
    try {
      // GetStorage schedules flushes in a microtask and does not return them
      // from write/save. Drain those jobs without issuing another write.
      await Future<void>.delayed(Duration.zero);
      await storage.queue.add<void>(() async {});
      // Each successful native unlock is followed by one detached backup.
      // Await those writes even if the driver's path lookup is delayed.
      while (_startedBackups < _expectedBackups) {
        await _backupStarted.future.timeout(const Duration(seconds: 5));
      }
      await Future.wait(_writes);
    } catch (error, stack) {
      failures.add((error, stack));
    }
    try {
      await _closeHandles(failures);
      // On failure retain disk evidence, but always release instrumentation.
      if (failures.isEmpty) await _deleteOwnedFiles();
    } catch (error, stack) {
      failures.add((error, stack));
    } finally {
      _releaseInstrumentation();
    }
    if (failures.isNotEmpty) _throwFailures(failures);
  }

  Future<void> _closeHandles(List<(Object, StackTrace)> failures) async {
    for (final handle in _handles) {
      try {
        await handle.close();
      } catch (error, stack) {
        failures.add((error, stack));
      }
    }
    _handles.clear();
  }

  Future<void> _deleteOwnedFiles() async {
    if (await FileSystemEntity.type(directory.path, followLinks: false) !=
            FileSystemEntityType.directory ||
        !path.equals(
          path.normalize(await directory.resolveSymbolicLinks()),
          path.normalize(directory.path),
        )) {
      throw StateError(
        'Refusing to remove files from a changed test directory',
      );
    }
    final existingFiles = <String>[];
    for (final file in _paths) {
      final type = await FileSystemEntity.type(file, followLinks: false);
      if (type == FileSystemEntityType.notFound) continue;
      if (type != FileSystemEntityType.file ||
          !path.equals(
            path.normalize(await File(file).resolveSymbolicLinks()),
            path.normalize(file),
          )) {
        throw StateError('Refusing to remove an unexpected test storage file');
      }
      existingFiles.add(file);
    }
    for (final file in existingFiles) {
      await File(file).delete();
    }
  }

  void _releaseInstrumentation() {
    for (final file in _paths) {
      _io.owners.remove(path.normalize(file));
    }
    _closed = true;
    _active.remove(this);
    if (_active.isEmpty) IOOverrides.global = null;
  }

  static Never _throwFailures(List<(Object, StackTrace)> failures) {
    final first = failures.first;
    Error.throwWithStackTrace(
      failures.length == 1 ? first.$1 : _StorageCleanupFailure(failures),
      first.$2,
    );
  }

  void _didStartBackup(Future<File> write) {
    _writes.add(write);
    _startedBackups++;
    _backupStarted.complete();
    _backupStarted = Completer<void>();
  }
}

final class _StorageFiles extends IOOverrides {
  final owners = <String, TestGetStorage>{};

  // Dart 3.10's default IOOverrides omits the NUL terminator required by its
  // native type query. Preserve the real query, including followLinks, while
  // correcting that encoding so safety checks never report files as absent.
  @override
  Future<FileSystemEntityType> fseGetType(String name, bool followLinks) =>
      super.fseGetType('$name\u0000', followLinks);

  @override
  FileSystemEntityType fseGetTypeSync(String name, bool followLinks) =>
      super.fseGetTypeSync('$name\u0000', followLinks);

  @override
  File createFile(String name) {
    final file = super.createFile(name);
    final owner = owners[path.normalize(path.absolute(name))];
    return owner == null ? file : _StorageFile(file, owner);
  }
}

final class _StorageFile implements File {
  final File _file;
  final TestGetStorage _owner;

  _StorageFile(this._file, this._owner);

  @override
  String get path => _file.path;

  @override
  bool existsSync() => _file.existsSync();

  @override
  void createSync({bool recursive = false, bool exclusive = false}) =>
      _file.createSync(recursive: recursive, exclusive: exclusive);

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    final handle = await _file.open(mode: mode);
    _owner._handles.add(handle);
    return _StorageHandle(handle, _owner);
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      _file.readAsString(encoding: encoding);

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    final write = _file.writeAsString(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
    if (path.endsWith('.bak')) _owner._didStartBackup(write);
    return write;
  }

  @override
  Future<String> resolveSymbolicLinks() => _file.resolveSymbolicLinks();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      _file.delete(recursive: recursive);

  // Only GetStorage's known File operations are instrumented. Unexpected
  // operations fail visibly instead of receiving fake filesystem behavior.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _StorageCleanupFailure implements Exception {
  final List<(Object, StackTrace)> failures;

  _StorageCleanupFailure(this.failures);

  @override
  String toString() => failures
      .map((failure) => '${failure.$1}\n${failure.$2}')
      .join('\nAdditional GetStorage cleanup failure:\n');
}

/// Keeps the same real handle through the driver's fluent assignments and
/// records when its flush releases the native lock before scheduling backup.
final class _StorageHandle implements RandomAccessFile {
  final RandomAccessFile _file;
  final TestGetStorage _owner;

  _StorageHandle(this._file, this._owner);

  @override
  String get path => _file.path;

  @override
  int lengthSync() => _file.lengthSync();

  @override
  Future<int> length() => _file.length();

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) =>
      _file.readInto(buffer, start, end);

  @override
  Future<RandomAccessFile> lock([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) async {
    await _file.lock(mode, start, end);
    return this;
  }

  @override
  Future<RandomAccessFile> setPosition(int position) async {
    await _file.setPosition(position);
    return this;
  }

  @override
  Future<RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    await _file.writeFrom(buffer, start, end);
    return this;
  }

  @override
  Future<RandomAccessFile> truncate(int length) async {
    await _file.truncate(length);
    return this;
  }

  @override
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) async {
    await _file.unlock(start, end);
    _owner._expectedBackups++;
    return this;
  }

  @override
  Future<void> close() => _file.close();

  @override
  void closeSync() => _file.closeSync();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
