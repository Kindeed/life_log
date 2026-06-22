typedef SyncRequestRunner =
    Future<bool> Function({
      required String reason,
      bool forceFullRefresh,
      bool forceNew,
    });

final class SyncScheduler {
  final SyncRequestRunner _runSync;
  Future<bool>? _activeRequest;

  SyncScheduler({required SyncRequestRunner runSync}) : _runSync = runSync;

  Future<bool> requestSync({
    required String reason,
    String? entityName,
    String? entityKey,
    bool forceFullRefresh = false,
    bool forceNew = false,
  }) {
    if (_activeRequest != null && !forceNew) {
      return _activeRequest!;
    }

    final syncReason = _formatReason(reason, entityName, entityKey);
    final request = _runSync(
      reason: syncReason,
      forceFullRefresh: forceFullRefresh,
      forceNew: forceNew,
    );

    if (forceNew) return request;

    _activeRequest = request.whenComplete(() {
      _activeRequest = null;
    });
    return _activeRequest!;
  }

  String _formatReason(String reason, String? entityName, String? entityKey) {
    return [
      reason,
      if (entityName != null && entityName.trim().isNotEmpty) entityName,
      if (entityKey != null && entityKey.trim().isNotEmpty) entityKey,
    ].join(':');
  }
}
