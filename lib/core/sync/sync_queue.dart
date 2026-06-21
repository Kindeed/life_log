abstract interface class SyncClock {
  DateTime get now;
}

final class SystemSyncClock implements SyncClock {
  const SystemSyncClock();

  @override
  DateTime get now => DateTime.now().toUtc();
}

class SyncQueueEntry {
  final String entityName;
  final String entityKey;
  final int attemptCount;
  final DateTime nextAttemptAt;
  final String? lastError;

  const SyncQueueEntry({
    required this.entityName,
    required this.entityKey,
    required this.attemptCount,
    required this.nextAttemptAt,
    this.lastError,
  });
}

abstract interface class SyncQueue {
  Future<bool> canAttempt(String entityName, String entityKey);

  Future<void> recordFailure(
    String entityName,
    String entityKey, {
    Object? error,
  });

  Future<void> recordSuccess(String entityName, String entityKey);
}

abstract interface class SyncEntityKeyResolver<T> {
  String syncQueueKey(T entity);
}

final class NoopSyncQueue implements SyncQueue {
  const NoopSyncQueue();

  @override
  Future<bool> canAttempt(String entityName, String entityKey) async => true;

  @override
  Future<void> recordFailure(
    String entityName,
    String entityKey, {
    Object? error,
  }) async {}

  @override
  Future<void> recordSuccess(String entityName, String entityKey) async {}
}

final class InMemorySyncQueue implements SyncQueue {
  SyncClock clock;
  final Duration baseDelay;
  final Duration maxDelay;
  final _entries = <String, SyncQueueEntry>{};

  InMemorySyncQueue({
    this.clock = const SystemSyncClock(),
    this.baseDelay = const Duration(seconds: 30),
    this.maxDelay = const Duration(minutes: 30),
  });

  SyncQueueEntry? peek(String entityName, String entityKey) {
    return _entries[_key(entityName, entityKey)];
  }

  @override
  Future<bool> canAttempt(String entityName, String entityKey) async {
    final entry = peek(entityName, entityKey);
    if (entry == null) return true;
    return !clock.now.isBefore(entry.nextAttemptAt);
  }

  @override
  Future<void> recordFailure(
    String entityName,
    String entityKey, {
    Object? error,
  }) async {
    final previous = peek(entityName, entityKey);
    final attemptCount = (previous?.attemptCount ?? 0) + 1;
    final delay = _delayForAttempt(attemptCount);
    _entries[_key(entityName, entityKey)] = SyncQueueEntry(
      entityName: entityName,
      entityKey: entityKey,
      attemptCount: attemptCount,
      nextAttemptAt: clock.now.add(delay),
      lastError: error?.toString(),
    );
  }

  @override
  Future<void> recordSuccess(String entityName, String entityKey) async {
    _entries.remove(_key(entityName, entityKey));
  }

  Duration _delayForAttempt(int attemptCount) {
    final exponent = (attemptCount - 1).clamp(0, 20).toInt();
    final multiplier = 1 << exponent;
    final delay = baseDelay * multiplier;
    return delay > maxDelay ? maxDelay : delay;
  }

  String _key(String entityName, String entityKey) {
    return '$entityName:$entityKey';
  }
}

final class SyncRunControl {
  final bool Function() _isCancelled;
  final bool Function() _isPaused;
  final Future<void> Function()? _waitWhilePaused;

  SyncRunControl({
    bool Function()? isCancelled,
    bool Function()? isPaused,
    Future<void> Function()? waitWhilePaused,
  }) : _isCancelled = isCancelled ?? (() => false),
       _isPaused = isPaused ?? (() => false),
       _waitWhilePaused = waitWhilePaused;

  factory SyncRunControl.cancelled() {
    return SyncRunControl(isCancelled: () => true);
  }

  bool get isCancelled => _isCancelled();

  bool get isPaused => _isPaused();

  Future<void> waitIfPaused() async {
    if (!isPaused) return;
    final waiter = _waitWhilePaused;
    if (waiter != null) {
      await waiter();
    }
  }
}
