typedef SyncRequestRunner =
    Future<bool> Function({
      required String reason,
      bool forceFullRefresh,
      bool forceNew,
    });

final class SyncScheduler {
  final SyncRequestRunner _runSync;
  Future<bool>? _activeRequest;
  Future<bool>? _queuedEntityRequest;
  String? _queuedEntityReason;
  bool _queuedEntityForceFullRefresh = false;

  SyncScheduler({required SyncRequestRunner runSync}) : _runSync = runSync;

  Future<bool> requestSync({
    required String reason,
    String? entityName,
    String? entityKey,
    bool forceFullRefresh = false,
    bool forceNew = false,
  }) {
    final syncReason = _formatReason(reason, entityName, entityKey);
    if (forceNew) {
      return _runSync(
        reason: syncReason,
        forceFullRefresh: forceFullRefresh,
        forceNew: true,
      );
    }

    final queuedEntityRequest = _queuedEntityRequest;
    if (queuedEntityRequest != null) {
      // Keep requests in the hand-off window on the already queued follow-up
      // instead of starting a third sync between the two scheduled runs.
      if (entityName != null || entityKey != null) {
        _queuedEntityReason ??= syncReason;
        _queuedEntityForceFullRefresh =
            _queuedEntityForceFullRefresh || forceFullRefresh;
      }
      return queuedEntityRequest;
    }

    final activeRequest = _activeRequest;
    if (activeRequest != null) {
      // Generic refreshes may share the active request. An entity mutation
      // needs a follow-up request because the active sync may have already
      // taken its pending-change snapshot before this mutation was persisted.
      if (entityName == null && entityKey == null) {
        return activeRequest;
      }
      return _queueEntityRequest(
        activeRequest,
        reason: syncReason,
        forceFullRefresh: forceFullRefresh,
      );
    }

    return _startRequest(
      reason: syncReason,
      forceFullRefresh: forceFullRefresh,
    );
  }

  Future<bool> _startRequest({
    required String reason,
    required bool forceFullRefresh,
  }) {
    final request = _runSync(
      reason: reason,
      forceFullRefresh: forceFullRefresh,
      forceNew: false,
    );
    late final Future<bool> activeRequest;
    activeRequest = request.whenComplete(() {
      if (identical(_activeRequest, activeRequest)) {
        _activeRequest = null;
      }
    });
    _activeRequest = activeRequest;
    return activeRequest;
  }

  Future<bool> _queueEntityRequest(
    Future<bool> activeRequest, {
    required String reason,
    required bool forceFullRefresh,
  }) {
    _queuedEntityReason ??= reason;
    _queuedEntityForceFullRefresh =
        _queuedEntityForceFullRefresh || forceFullRefresh;

    final queuedRequest = _queuedEntityRequest;
    if (queuedRequest != null) return queuedRequest;

    late final Future<bool> result;
    final nextRequest = activeRequest.then((_) {
      final nextReason = _queuedEntityReason ?? reason;
      final nextForceFullRefresh =
          _queuedEntityForceFullRefresh || forceFullRefresh;
      _queuedEntityReason = null;
      _queuedEntityForceFullRefresh = false;
      _queuedEntityRequest = null;
      return _startRequest(
        reason: nextReason,
        forceFullRefresh: nextForceFullRefresh,
      );
    });
    result = nextRequest.whenComplete(() {
      if (identical(_queuedEntityRequest, result)) {
        _queuedEntityRequest = null;
        _queuedEntityReason = null;
        _queuedEntityForceFullRefresh = false;
      }
    });
    _queuedEntityRequest = result;
    return result;
  }

  String _formatReason(String reason, String? entityName, String? entityKey) {
    return [
      reason,
      if (entityName != null && entityName.trim().isNotEmpty) entityName,
      if (entityKey != null && entityKey.trim().isNotEmpty) entityKey,
    ].join(':');
  }
}
