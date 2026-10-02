import 'dart:async';

/// Serializes conflict decisions while the ordinary sync runner is suspended.
/// The caller invalidates and drains issued requests before reading the server.
final class SyncOperationGate {
  Future<void> _tail = Future<void>.value();
  bool _blocked = false;

  bool get isBlocked => _blocked;

  Future<void> get drained => _tail.catchError((Object _) {});

  Future<void> run({
    required Future<void> Function() invalidateAndDrain,
    required Future<void> Function() action,
  }) {
    final operation = drained.then((_) async {
      _blocked = true;
      try {
        await invalidateAndDrain();
        await action();
      } finally {
        _blocked = false;
      }
    });
    _tail = operation;
    return operation;
  }
}
