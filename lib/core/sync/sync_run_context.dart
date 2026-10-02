/// Immutable identity and lifetime of one cloud operation.
///
/// A continuation must never infer its owner from the currently logged-in user.
/// The callback also fences logout/relogin and replacement of the local database.
final class SyncRunContext {
  final String ownerId;
  final int sessionEpoch;
  final int databaseGeneration;
  final int runId;
  final bool Function() _isCurrent;

  const SyncRunContext({
    required this.ownerId,
    required this.sessionEpoch,
    required this.databaseGeneration,
    required this.runId,
    required bool Function() isCurrent,
  }) : _isCurrent = isCurrent;

  bool get isCurrent => _isCurrent();

  void checkCurrent() {
    if (!isCurrent) throw const SyncRunInvalidated();
  }

  bool ownsRemoteRow(Map<String, dynamic> row) => row['user_id'] == ownerId;

  void checkRemoteRow(Map<String, dynamic> row) {
    checkCurrent();
    if (!ownsRemoteRow(row)) {
      throw StateError('Remote sync row belongs to a different owner');
    }
  }
}

final class SyncRunInvalidated implements Exception {
  const SyncRunInvalidated();

  @override
  String toString() => 'Sync run invalidated by account or database change';
}

/// Includes the owner even though sync IDs are normally globally unique.
/// Legacy rows without a sync ID retain a stable device-local retry identity.
String ownerScopedSyncEntityKey({
  required String ownerId,
  required String? syncId,
  required int localId,
}) {
  final identity = syncId?.trim();
  return '$ownerId:${identity == null || identity.isEmpty ? 'local:$localId' : 'sync:$identity'}';
}
