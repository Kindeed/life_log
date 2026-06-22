import 'package:equatable/equatable.dart';

final class SyncCenterSnapshot extends Equatable {
  final List<SyncQueueEntry> pendingQueueEntries;
  final List<SyncConflictEntry> unresolvedConflicts;

  const SyncCenterSnapshot({
    required this.pendingQueueEntries,
    required this.unresolvedConflicts,
  });

  int get pendingQueueCount => pendingQueueEntries.length;

  int get unresolvedConflictCount => unresolvedConflicts.length;

  @override
  List<Object?> get props => [pendingQueueEntries, unresolvedConflicts];
}

final class SyncQueueEntry extends Equatable {
  final String entityName;
  final String entityKey;
  final int attemptCount;
  final DateTime nextAttemptAt;
  final DateTime? lastAttemptAt;
  final String? lastError;

  const SyncQueueEntry({
    required this.entityName,
    required this.entityKey,
    required this.attemptCount,
    required this.nextAttemptAt,
    this.lastAttemptAt,
    this.lastError,
  });

  @override
  List<Object?> get props => [
    entityName,
    entityKey,
    attemptCount,
    nextAttemptAt,
    lastAttemptAt,
    lastError,
  ];
}

final class SyncConflictEntry extends Equatable {
  final int id;
  final String entityName;
  final String? entitySyncId;
  final String conflictType;
  final String message;
  final DateTime detectedAt;
  final int? localVersion;
  final int? remoteVersion;

  const SyncConflictEntry({
    required this.id,
    required this.entityName,
    required this.entitySyncId,
    required this.conflictType,
    required this.message,
    required this.detectedAt,
    this.localVersion,
    this.remoteVersion,
  });

  @override
  List<Object?> get props => [
    id,
    entityName,
    entitySyncId,
    conflictType,
    message,
    detectedAt,
    localVersion,
    remoteVersion,
  ];
}
