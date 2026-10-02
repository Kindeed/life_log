import 'dart:async';

import 'package:isar_community/isar.dart';

class IsarDatabase {
  Isar _isar;
  final String? directory;
  final String name;
  bool _restoring = false;
  final Set<Future<dynamic>> _writes = {};
  final Set<_DatabaseWatcher> _watchers = {};

  IsarDatabase(Isar isar)
    : _isar = isar,
      directory = isar.directory,
      name = isar.name;

  /// A stable dependency-injection handle. Consumers never retain a replaced
  /// database instance after a backup restore.
  Isar get isar => _isar;

  static Future<IsarDatabase> open({
    required List<CollectionSchema<dynamic>> schemas,
    required String directory,
    String name = Isar.defaultName,
    int maxSizeMiB = Isar.defaultMaxSizeMiB,
    bool relaxedDurability = true,
    CompactCondition? compactOnLaunch,
    bool inspector = true,
  }) async {
    final isar = await Isar.open(
      schemas,
      directory: directory,
      name: name,
      maxSizeMiB: maxSizeMiB,
      relaxedDurability: relaxedDurability,
      compactOnLaunch: compactOnLaunch,
      inspector: inspector,
    );
    return IsarDatabase(isar);
  }

  Future<T> readTxn<T>(Future<T> Function() callback) {
    return isar.txn(callback);
  }

  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    if (_restoring) {
      return Future<T>.error(StateError('数据库正在恢复，请稍后重试'));
    }
    final write = isar.writeTxn(callback, silent: silent);
    _writes.add(write);
    return write.whenComplete(() => _writes.remove(write));
  }

  /// Existing subscriptions survive Isar.close() and reconnect on completion.
  Stream<void> watch(Stream<void> Function(Isar) watchFactory) {
    late _DatabaseWatcher watcher;
    late StreamController<void> controller;
    controller = StreamController<void>.broadcast(
      onListen: () {
        watcher = _DatabaseWatcher(controller, watchFactory);
        _watchers.add(watcher);
        if (!_restoring) watcher.bind(isar);
      },
      onCancel: () {
        _watchers.remove(watcher);
        unawaited(watcher.suspend());
      },
    );
    return controller.stream;
  }

  Future<void> prepareForRestore() async {
    _restoring = true;
    await Future.wait(
      _writes.toList().map((write) async {
        try {
          await write;
        } catch (_) {
          // The writer receives its own error; replacement still waits for it.
        }
      }),
    );
    await Future.wait(_watchers.map((watcher) => watcher.suspend()));
  }

  void rebind(Isar replacement) {
    _isar = replacement;
  }

  void finishRestore() {
    if (!_restoring) return;
    if (!isar.isOpen) throw StateError('恢复后的数据库尚未打开');
    for (final watcher in _watchers) {
      watcher.bind(isar);
    }
    // A broken watch factory must leave writes gated so the coordinator can
    // retry recovery without accepting edits into a database being replaced.
    _restoring = false;
    for (final watcher in _watchers) {
      watcher.controller.add(null);
    }
  }

  Future<void> close({bool deleteFromDisk = false}) async {
    await isar.close(deleteFromDisk: deleteFromDisk);
  }
}

final class _DatabaseWatcher {
  final StreamController<void> controller;
  final Stream<void> Function(Isar) watchFactory;
  StreamSubscription<void>? _subscription;

  _DatabaseWatcher(this.controller, this.watchFactory);

  void bind(Isar isar) {
    _subscription = watchFactory(
      isar,
    ).listen(controller.add, onError: controller.addError);
  }

  Future<void> suspend() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }
}
