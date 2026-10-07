import 'dart:async';

/// Refreshes the first change immediately, then batches bursts into one trailing
/// read. Watcher reads never overlap and continuous changes cannot starve them.
final class CoalescedRefresh {
  final Future<void> Function() _refresh;
  final Duration delay;
  final void Function(Object, StackTrace)? onError;
  Timer? _timer;
  bool _running = false;
  bool _pending = false;
  bool _disposed = false;

  CoalescedRefresh({
    required Future<void> Function() refresh,
    this.delay = const Duration(milliseconds: 120),
    this.onError,
  }) : _refresh = refresh;

  void schedule() {
    if (_disposed) return;
    _pending = true;
    if (_running || _timer != null) return;
    unawaited(_run());
  }

  Future<void> _run() async {
    _timer = null;
    if (_disposed) return;
    _pending = false;
    _running = true;
    try {
      await _refresh();
    } catch (error, stackTrace) {
      final handleError = onError ?? Zone.current.handleUncaughtError;
      handleError(error, stackTrace);
    } finally {
      _running = false;
      if (!_disposed) {
        _timer = Timer(delay, () {
          _timer = null;
          if (_pending) unawaited(_run());
        });
      }
    }
  }

  void dispose() {
    _disposed = true;
    _pending = false;
    _timer?.cancel();
    _timer = null;
  }
}
