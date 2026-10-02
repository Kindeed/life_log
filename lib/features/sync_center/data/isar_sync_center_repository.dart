import 'dart:async';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:life_log/common/utils/sync_id_generator.dart';
import 'package:life_log/common/utils/evidence_storage_policy.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/sync/isar_sync_conflict_store.dart';
import 'package:life_log/core/sync/isar_sync_queue.dart';
import 'package:life_log/core/sync/sync_conflict_model.dart';
import 'package:life_log/core/sync/sync_queue_record.dart';
import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/sync_center/data/conflict_entity.dart';
import 'package:life_log/features/sync_center/data/sync_conflict_remote_gateway.dart';
import 'package:life_log/features/sync_center/domain/sync_center_repository_port.dart';
import 'package:life_log/features/sync_center/domain/sync_center_snapshot.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

final class IsarSyncCenterRepository implements SyncCenterRepositoryPort {
  final IsarSyncQueue queue;
  final IsarSyncConflictStore conflictStore;
  final IsarDatabase database;
  final String? Function() currentOwnerId;
  final SyncRunContext? Function()? captureContext;
  final SyncConflictRemoteGateway? remoteGateway;
  final int Function(String entityName, int id)? currentMutationRevision;
  final Future<void> Function(String entityName, String entityKey)? requestSync;
  final Future<void> Function(Future<void> Function() action)?
  runWithSyncSuspended;

  IsarSyncCenterRepository(
    this.database, {
    String? Function()? currentOwnerId,
    this.captureContext,
    this.remoteGateway,
    this.currentMutationRevision,
    this.requestSync,
    this.runWithSyncSuspended,
  }) : queue = IsarSyncQueue(database),
       conflictStore = IsarSyncConflictStore(database),
       currentOwnerId = currentOwnerId ?? _noOwner;

  static String? _noOwner() => null;

  @override
  Future<SyncCenterSnapshot> loadSnapshot() async {
    final owner = currentOwnerId();
    final queueRecords = await queue.pendingEntries();
    final conflictRecords = await conflictStore.unresolvedConflicts();
    final visibleConflicts = <SyncConflictRecord>[];
    if (owner != null) {
      for (final record in conflictRecords) {
        if (record.ownerUserId == owner) {
          visibleConflicts.add(record);
        } else if (record.ownerUserId == null) {
          // Old conflicts did not persist their owner. Recover scope only from
          // a still-existing entity, never from the active account alone.
          final entity = await _findEntity(record);
          if (entity?.row.ownerUserId == owner) visibleConflicts.add(record);
        }
      }
    }
    if (owner != currentOwnerId()) return loadSnapshot();
    return SyncCenterSnapshot(
      pendingQueueEntries: queueRecords
          .where(
            (record) => owner != null && record.entityKey.startsWith('$owner:'),
          )
          .map(
            (record) => SyncQueueEntry(
              entityName: record.entityName,
              entityKey: record.entityKey,
              attemptCount: record.attemptCount,
              nextAttemptAt: record.nextAttemptAt,
              lastAttemptAt: record.lastAttemptAt,
              lastError: record.lastError,
            ),
          )
          .toList(growable: false),
      unresolvedConflicts: visibleConflicts
          .map(
            (record) => SyncConflictEntry(
              id: record.id,
              entityName: record.entityName,
              entitySyncId: record.entitySyncId,
              conflictType: record.conflictType,
              message: record.message,
              detectedAt: record.detectedAt,
              localVersion: record.localVersion,
              remoteVersion: record.remoteVersion,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> resolveConflict(int id, {required String resolution}) async {
    if (!const {'keep-local', 'use-remote', 'copy'}.contains(resolution)) {
      throw ArgumentError.value(resolution, 'resolution', 'Unknown action');
    }
    final suspend = runWithSyncSuspended;
    late ({String entityName, String entityKey, bool needsSync}) result;
    if (suspend != null) {
      await suspend(() async {
        result = await _resolveConflict(id, resolution: resolution);
      });
    } else {
      result = await _resolveConflict(id, resolution: resolution);
    }
    if (result.needsSync && requestSync != null) {
      unawaited(
        requestSync!(
          result.entityName,
          result.entityKey,
        ).catchError((Object _) {}),
      );
    }
  }

  Future<({String entityName, String entityKey, bool needsSync})>
  _resolveConflict(int id, {required String resolution}) async {
    final context = captureContext?.call();
    final remote = remoteGateway;
    if (context == null || remote == null) {
      throw StateError('请登录并连接云端后处理同步冲突');
    }
    context.checkCurrent();
    final conflict = await database.isar.syncConflictRecords.get(id);
    context.checkCurrent();
    if (conflict == null || conflict.resolvedAt != null) {
      throw StateError('该冲突已处理，请刷新同步状态');
    }
    final entity = await _findEntity(conflict);
    context.checkCurrent();
    if (entity == null ||
        entity.row.ownerUserId != context.ownerId ||
        (conflict.ownerUserId != null &&
            conflict.ownerUserId != context.ownerId)) {
      throw StateError('冲突记录不属于当前账号或本地记录已不存在');
    }
    final snapshot = entity.snapshot();
    final mutationRevision = currentMutationRevision?.call(
      entity.name,
      snapshot.row.id as int,
    );
    final syncId = snapshot.row.syncId as String?;
    if (syncId == null || syncId.isEmpty || syncId != conflict.entitySyncId) {
      throw StateError('冲突记录身份无效，请重新同步');
    }
    if (conflict.localVersion != null &&
        conflict.localVersion != snapshot.row.remoteVersion) {
      throw StateError('本地同步版本已变更，请重新同步后处理');
    }
    if (conflict.localUpdatedAt != null &&
        snapshot.updatedAt != null &&
        conflict.localUpdatedAt != snapshot.updatedAt) {
      throw StateError('发现冲突后本地记录已修改，请重新同步后处理');
    }
    final row = await remote.fetch(
      context: context,
      table: entity.table,
      syncId: syncId,
    );
    context.checkCurrent();
    _validateRemote(conflict, snapshot, row, context);
    final createdFiles = <File>[];
    var attachmentCleanup = false;
    try {
      await database.writeTxn(() async {
        context.checkCurrent();
        final isar = database.isar;
        final liveConflict = await isar.syncConflictRecords.get(id);
        final live = await _findEntity(conflict);
        context.checkCurrent();
        if (liveConflict == null ||
            liveConflict.resolvedAt != null ||
            live == null ||
            currentMutationRevision?.call(
                  entity.name,
                  snapshot.row.id as int,
                ) !=
                mutationRevision ||
            !live.unchangedSince(snapshot)) {
          throw StateError('处理期间本地记录已变更，请刷新后重试');
        }
        final now = DateTime.now().toUtc();
        if (resolution == 'keep-local') {
          // Deliberate user-authorized rebase. The next ordinary push uses this
          // exact version in its CAS; a newer server edit creates a new conflict.
          live.row
            ..remoteId = conflictRemoteInt(row?['id'])
            ..remoteVersion = conflictRemoteInt(row?['version']) ?? 0
            ..remoteUpdatedAt = _optionalTime(row?['updated_at'])
            ..isDirty = true;
          await live.put(isar);
        } else {
          if (resolution == 'copy') {
            await _copyWithRelations(live, context, now, createdFiles);
          }
          if (live.value is ExpenseEvidence) {
            attachmentCleanup = await _retireEvidenceAttachments(
              live.value as ExpenseEvidence,
              row,
              context,
              now,
            );
          }
          if (row != null && row['deleted_at'] == null) {
            live.applyRemote(row);
            await _relink(live, context.ownerId);
          }
          live.row
            ..remoteId = conflictRemoteInt(row?['id'])
            ..remoteVersion = conflictRemoteInt(row?['version']) ?? 0
            ..remoteUpdatedAt = _optionalTime(row?['updated_at'])
            ..syncedAt = now
            ..isDirty = false
            ..pendingDelete = false
            ..deletedAt = row == null ? now : _optionalTime(row['deleted_at']);
          // Keep a clean tombstone instead of cascading into local media.
          await live.put(isar);
        }
        final retryKeys = {
          syncId,
          snapshot.row.id.toString(),
          ownerScopedSyncEntityKey(
            ownerId: context.ownerId,
            syncId: syncId,
            localId: snapshot.row.id as int,
          ),
        };
        final retries = await isar.syncQueueRecords.where().anyId().findAll();
        for (final retry in retries) {
          if (retry.entityName == entity.name &&
              retryKeys.contains(retry.entityKey)) {
            await isar.syncQueueRecords.delete(retry.id);
          }
        }
        context.checkCurrent();
        // Closing the conflict shares the business transaction. Exceptions,
        // local edit races and account changes leave the conflict unresolved.
        liveConflict
          ..ownerUserId = context.ownerId
          ..resolvedAt = now
          ..resolution = resolution;
        await isar.syncConflictRecords.put(liveConflict);
        context.checkCurrent();
      });
    } catch (_) {
      for (final file in createdFiles) {
        if (await file.exists()) await file.delete();
      }
      rethrow;
    }
    return (
      entityName: entity.name,
      entityKey: syncId,
      needsSync: resolution != 'use-remote' || attachmentCleanup,
    );
  }

  Future<bool> _retireEvidenceAttachments(
    ExpenseEvidence original,
    Map<String, dynamic>? remote,
    SyncRunContext context,
    DateTime now,
  ) async {
    final selectedPath = remote != null && remote['deleted_at'] == null
        ? remote['remote_storage_path'] as String?
        : null;
    final attachments = await database.isar.evidenceAttachments
        .filter()
        .evidenceSyncIdEqualTo(original.syncId!)
        .findAll();
    var cleanup = false;
    for (final attachment in attachments) {
      if (attachment.ownerUserId != context.ownerId) continue;
      if (selectedPath != null &&
          evidenceAttachmentStoragePath(
                ownerId: context.ownerId,
                evidenceSyncId: attachment.evidenceSyncId,
                attachmentSyncId: attachment.syncId,
                originalFileName: attachment.originalFileName,
                remoteStoragePath: attachment.remoteStoragePath,
              ) ==
              selectedPath) {
        if (attachment.uploadState != EvidenceAttachmentUploadState.uploaded) {
          if (original.localFilePath == attachment.localPath) {
            original.localFilePath = null;
          }
          attachment.localPath = null;
        }
        attachment
          ..remoteStoragePath = selectedPath
          ..uploadState = EvidenceAttachmentUploadState.uploaded
          ..deletedAt = null
          ..failureMessage = null;
        await database.isar.evidenceAttachments.put(attachment);
        continue;
      }
      cleanup = true;
      // Retain local files. Retry only the cloud tombstone, never upload the
      // discarded bytes again; copied attachments have different identities.
      attachment
        ..deletedAt = now
        ..uploadState = EvidenceAttachmentUploadState.deleted
        ..failureMessage = null
        ..updatedAt = now;
      await database.isar.evidenceAttachments.put(attachment);
    }
    context.checkCurrent();
    return cleanup;
  }

  Future<ConflictEntity?> _findEntity(SyncConflictRecord conflict) async {
    final id = int.tryParse(conflict.localId ?? '');
    if (id == null) return null;
    final entity = await ConflictEntity.find(
      database.isar,
      conflict.entityName,
      id,
    );
    if (entity?.row.syncId != conflict.entitySyncId) return null;
    return entity;
  }

  void _validateRemote(
    SyncConflictRecord conflict,
    ConflictEntity local,
    Map<String, dynamic>? remote,
    SyncRunContext context,
  ) {
    if (remote == null) {
      if (conflict.remoteVersion != null) {
        throw StateError('远端记录已变更或不存在，请重新同步后处理');
      }
      return;
    }
    context.checkRemoteRow(remote);
    final version = conflictRemoteInt(remote['version']);
    if (remote['sync_id'] != local.row.syncId ||
        conflictRemoteInt(remote['id']) == null ||
        version == null ||
        version <= 0 ||
        version != conflict.remoteVersion) {
      throw StateError('远端记录已变更，请重新同步后处理');
    }
    if (local.row.remoteId != null &&
        local.row.remoteId != conflictRemoteInt(remote['id'])) {
      throw StateError('远端记录身份已变更，请重新同步');
    }
  }

  Future<void> _relink(ConflictEntity entity, String owner) async {
    final value = entity.value;
    if (value is! WorkLog &&
        value is! ExpenseRecord &&
        value is! ExpenseEvidence) {
      return;
    }
    final row = entity.row;
    final projectSyncId = row.projectSyncId as String?;
    final projects = projectSyncId == null
        ? <Project>[]
        : await database.isar.projects
              .filter()
              .syncIdEqualTo(projectSyncId)
              .findAll();
    final project = projects
        .where((item) => item.ownerUserId == owner && item.deletedAt == null)
        .firstOrNull;
    row.projectId = project?.id;
    if (project != null) row.projectName = project.name;
    if (value is ExpenseRecord) {
      final tripSyncId = value.tripWorkLogSyncId;
      final logs = tripSyncId == null
          ? <WorkLog>[]
          : await database.isar.workLogs
                .filter()
                .syncIdEqualTo(tripSyncId)
                .findAll();
      value.tripWorkLogId = logs
          .where((item) => item.ownerUserId == owner && item.deletedAt == null)
          .firstOrNull
          ?.id;
    }
  }

  Future<void> _copyWithRelations(
    ConflictEntity entity,
    SyncRunContext context,
    DateTime now,
    List<File> createdFiles,
  ) async {
    final isar = database.isar;
    final copy = entity.snapshot();
    copy.resetAsCopy(SyncIdGenerator.newSyncId(), now);
    if (copy.value is ExpenseEvidence) {
      await _copyEvidenceFiles(
        entity.value as ExpenseEvidence,
        copy.value as ExpenseEvidence,
        context,
        createdFiles,
      );
    }
    await copy.put(isar);
    context.checkCurrent();
    if (copy.value is ExpenseEvidence) {
      await _copyAttachments(
        entity.value as ExpenseEvidence,
        copy.value as ExpenseEvidence,
        context,
        now,
        createdFiles,
      );
    }
    if (entity.value is WorkLog) {
      final original = entity.value as WorkLog;
      final expenses = await isar.expenseRecords.where().anyId().findAll();
      for (final expense in expenses) {
        if (expense.ownerUserId != context.ownerId ||
            expense.deletedAt != null ||
            !(expense.tripWorkLogId == original.id ||
                expense.tripWorkLogSyncId == original.syncId)) {
          continue;
        }
        final child = ConflictEntity('expense_record', expense).snapshot();
        child.resetAsCopy(SyncIdGenerator.newSyncId(), now);
        (child.value as ExpenseRecord)
          ..tripWorkLogId = copy.row.id as int
          ..tripWorkLogSyncId = copy.row.syncId as String;
        await child.put(isar);
      }
    }
    if (entity.value is! Project) return;
    final original = entity.value as Project;
    final project = copy.value as Project;
    bool belongs(dynamic item) =>
        item.ownerUserId == context.ownerId &&
        item.deletedAt == null &&
        (item.projectId == original.id ||
            (original.syncId != null && item.projectSyncId == original.syncId));
    final copiedLogs = <int, WorkLog>{};
    final copiedLogSyncIds = <String, WorkLog>{};
    for (final log in await isar.workLogs.where().anyId().findAll()) {
      if (!belongs(log)) continue;
      final child = ConflictEntity('work_log', log).snapshot();
      child.resetAsCopy(SyncIdGenerator.newSyncId(), now);
      _linkCopyToProject(child, project);
      await child.put(isar);
      copiedLogs[log.id] = child.value as WorkLog;
      if (log.syncId != null) {
        copiedLogSyncIds[log.syncId!] = child.value as WorkLog;
      }
    }
    for (final expense in await isar.expenseRecords.where().anyId().findAll()) {
      if (!belongs(expense)) continue;
      final child = ConflictEntity('expense_record', expense).snapshot();
      child.resetAsCopy(SyncIdGenerator.newSyncId(), now);
      _linkCopyToProject(child, project);
      final trip =
          copiedLogs[expense.tripWorkLogId] ??
          copiedLogSyncIds[expense.tripWorkLogSyncId];
      if (trip != null) {
        (child.value as ExpenseRecord)
          ..tripWorkLogId = trip.id
          ..tripWorkLogSyncId = trip.syncId;
      }
      await child.put(isar);
    }
    for (final evidence
        in await isar.expenseEvidences.where().anyId().findAll()) {
      if (!belongs(evidence)) continue;
      final child = ConflictEntity('evidence', evidence).snapshot();
      child.resetAsCopy(SyncIdGenerator.newSyncId(), now);
      _linkCopyToProject(child, project);
      final evidenceCopy = child.value as ExpenseEvidence;
      await _copyEvidenceFiles(evidence, evidenceCopy, context, createdFiles);
      await child.put(isar);
      await _copyAttachments(
        evidence,
        evidenceCopy,
        context,
        now,
        createdFiles,
      );
    }
    context.checkCurrent();
  }

  void _linkCopyToProject(ConflictEntity child, Project project) {
    child.row
      ..projectId = project.id
      ..projectSyncId = project.syncId
      ..projectName = project.name;
  }

  Future<void> _copyEvidenceFiles(
    ExpenseEvidence original,
    ExpenseEvidence copy,
    SyncRunContext context,
    List<File> createdFiles,
  ) async {
    copy.localFilePath = await _copyFile(
      original.localFilePath,
      original.remoteStoragePath,
      context,
      createdFiles,
    );
  }

  Future<void> _copyAttachments(
    ExpenseEvidence original,
    ExpenseEvidence copy,
    SyncRunContext context,
    DateTime now,
    List<File> createdFiles,
  ) async {
    final isar = database.isar;
    final attachments = await isar.evidenceAttachments
        .where()
        .anyId()
        .findAll();
    for (final attachment in attachments) {
      if (attachment.ownerUserId != context.ownerId ||
          attachment.deletedAt != null ||
          attachment.uploadState == EvidenceAttachmentUploadState.deleted ||
          attachment.evidenceSyncId != original.syncId) {
        continue;
      }
      final localPath =
          attachment.localPath == original.localFilePath &&
              copy.localFilePath != null
          ? copy.localFilePath
          : await _copyFile(
              attachment.localPath,
              attachment.remoteStoragePath,
              context,
              createdFiles,
            );
      if (localPath == null) throw StateError('请先下载凭证附件，再复制为新记录');
      final child = EvidenceAttachment()
        ..ownerUserId = context.ownerId
        ..syncId = SyncIdGenerator.newSyncId()
        ..evidenceSyncId = copy.syncId!
        ..evidenceLocalId = copy.id
        ..localPath = localPath
        ..originalFileName = attachment.originalFileName
        ..contentHash = attachment.contentHash
        ..sizeBytes = attachment.sizeBytes
        ..mimeType = attachment.mimeType
        ..uploadState = EvidenceAttachmentUploadState.pending
        ..createdAt = now
        ..updatedAt = now;
      await isar.evidenceAttachments.put(child);
      context.checkCurrent();
    }
  }

  Future<String?> _copyFile(
    String? source,
    String? remotePath,
    SyncRunContext context,
    List<File> createdFiles,
  ) async {
    if (source == null || source.isEmpty) {
      if (remotePath != null && remotePath.isNotEmpty) {
        throw StateError('请先下载凭证附件，再复制为新记录');
      }
      return null;
    }
    final file = File(source);
    if (!await file.exists()) throw StateError('凭证本地文件不存在，请先下载或恢复文件');
    context.checkCurrent();
    final fileName = file.uri.pathSegments.last;
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? '' : fileName.substring(dot);
    File destination;
    do {
      destination = File(
        '${file.parent.path}${Platform.pathSeparator}conflict-copy-${SyncIdGenerator.newSyncId()}$extension',
      );
    } while (await destination.exists());
    createdFiles.add(destination);
    await file.copy(destination.path);
    context.checkCurrent();
    return destination.path;
  }
}

DateTime? _optionalTime(dynamic value) => value == null
    ? null
    : value is DateTime
    ? value.toUtc()
    : DateTime.tryParse(value.toString())?.toUtc();
