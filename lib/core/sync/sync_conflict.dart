enum SyncConflictType { updateConflict, deleteConflict, mergeConflict }

class SyncConflictDraft {
  final String entityName;
  final String? entitySyncId;
  final String? localId;
  final String? remoteId;
  final SyncConflictType conflictType;
  final int? localVersion;
  final int? remoteVersion;
  final DateTime? localUpdatedAt;
  final DateTime? remoteUpdatedAt;
  final String message;
  final DateTime detectedAt;

  SyncConflictDraft({
    required this.entityName,
    required this.conflictType,
    required this.message,
    this.entitySyncId,
    this.localId,
    this.remoteId,
    this.localVersion,
    this.remoteVersion,
    this.localUpdatedAt,
    this.remoteUpdatedAt,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now().toUtc();
}

abstract interface class SyncConflictStore {
  Future<void> record(SyncConflictDraft conflict);
}

final class NoopSyncConflictStore implements SyncConflictStore {
  const NoopSyncConflictStore();

  @override
  Future<void> record(SyncConflictDraft conflict) async {}
}

final class InMemorySyncConflictStore implements SyncConflictStore {
  final conflicts = <SyncConflictDraft>[];

  @override
  Future<void> record(SyncConflictDraft conflict) async {
    conflicts.add(conflict);
  }
}
