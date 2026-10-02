import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/sync/evidence_attachment_sync_adapter.dart';
import 'package:life_log/features/evidence/sync/evidence_sync_adapter.dart';
import 'package:life_log/features/expense/sync/expense_record_sync_adapter.dart';
import 'package:life_log/features/project/sync/project_sync_adapter.dart';
import 'package:life_log/features/subscription/sync/subscription_sync_adapter.dart';
import 'package:life_log/features/work_log/sync/work_log_sync_adapter.dart';
import 'package:life_log/core/sync/get_storage_sync_cursor_store.dart';
import 'package:life_log/core/sync/isar_sync_queue.dart';
import 'package:life_log/core/sync/isar_sync_conflict_store.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_engine.dart';
import 'package:life_log/core/sync/sync_queue.dart';
import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:life_log/core/sync/sync_operation_gate.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/db/database_restore_coordinator.dart';
import '../db/db_service.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../utils/sync_id_generator.dart';
import '../utils/evidence_storage_policy.dart';

class SyncService {
  final _client = Supabase.instance.client;
  final _storage = GetStorage();
  IsarSyncQueue? _syncQueue;
  static const _evidenceBucket = 'evidence-files';
  Future<bool>? _activeSync;
  SyncRunContext? _activeSyncContext;
  final _runningSyncs = <Future<bool>>{};
  final _conflictGate = SyncOperationGate();
  int _databaseGeneration = 0;
  int _cancelGeneration = 0;
  int _nextRunId = 0;
  bool _databaseRestoreInProgress = false;
  static const _restoreGenerationKey =
      DatabaseRestoreCoordinator.restoreGenerationStorageKey;
  static const _entityNames = [
    'work_log',
    'subscription',
    'project',
    'expense_record',
    'evidence',
    'evidence_attachment',
  ];
  Future<void>? _bootstrapSyncFuture;
  String? _bootstrapSyncUserId;
  DateTime? _lastBootstrapSyncAt;
  AuthService? _listenedAuthService;
  VoidCallback? _authListener;
  bool _syncPaused = false;
  bool _syncCancelRequested = false;
  static const String _evidenceAttachmentsTable = 'evidence_attachments';

  AuthService? get _authService => serviceLocator.isRegistered<AuthService>()
      ? serviceLocator<AuthService>()
      : null;

  DbService get _dbService => serviceLocator<DbService>();

  bool get _isLoggedIn => _authService?.isLoggedIn ?? false;

  SyncRunContext? captureRunContext() {
    final auth = _authService;
    final ownerId = auth?.userId;
    if (auth == null || ownerId == null || _databaseRestoreInProgress) {
      return null;
    }
    final epoch = auth.sessionEpoch;
    final generation = _dbService.databaseGeneration;
    final runGeneration = _databaseGeneration;
    final cancellation = _cancelGeneration;
    return SyncRunContext(
      ownerId: ownerId,
      sessionEpoch: epoch,
      databaseGeneration: generation,
      runId: ++_nextRunId,
      isCurrent: () =>
          !_databaseRestoreInProgress &&
          auth.userId == ownerId &&
          auth.sessionEpoch == epoch &&
          _dbService.databaseGeneration == generation &&
          _databaseGeneration == runGeneration &&
          _cancelGeneration == cancellation,
    );
  }

  /// Drain every cloud continuation before the database is closed or replaced.
  /// The durable marker is written first so a crash cannot reuse newer cursors
  /// against a restored, older database, including for another account.
  Future<void> prepareForDatabaseRestore() async {
    _databaseRestoreInProgress = true;
    _databaseGeneration++;
    cancelSync();
    final directory = _dbService.database.directory;
    if (directory == null) throw StateError('Database directory missing');
    final generation =
        await DatabaseRestoreCoordinator.advanceRestoreGeneration(
          directory,
          storedGeneration: _storage.read<int>(_restoreGenerationKey) ?? 0,
        );
    await _storage.write(_restoreGenerationKey, generation);
    await Future.wait(_runningSyncs.toList());
    await _conflictGate.drained;
  }

  Future<void> withSyncSuspended(Future<void> Function() action) {
    return _conflictGate.run(
      invalidateAndDrain: () async {
        if (_databaseRestoreInProgress) {
          throw StateError('正在恢复备份，请稍后处理冲突');
        }
        cancelSync();
        await Future.wait(_runningSyncs.toList());
        if (_databaseRestoreInProgress) {
          throw StateError('正在恢复备份，请稍后处理冲突');
        }
        _syncCancelRequested = false;
      },
      action: action,
    );
  }

  Future<void> databaseRestoreCompleted({
    required bool databaseAvailable,
    required bool forceFullRefresh,
  }) async {
    if (!databaseAvailable) return;
    _syncQueue = null;
    _bootstrapSyncFuture = null;
    _bootstrapSyncUserId = null;
    _lastBootstrapSyncAt = null;
    final ownerId = _authService?.userId;
    if (forceFullRefresh && ownerId != null) {
      await GetStorageSyncCursorStore(
        storage: _storage,
        namespace: ownerId,
      ).clear(_entityNames);
      await _storage.remove('sync_restored_generation_$ownerId');
    }
    _syncCancelRequested = false;
    _databaseRestoreInProgress = false;
  }

  String newSyncId() => SyncIdGenerator.newSyncId();

  void pauseSync() {
    _syncPaused = true;
    LogService.to.info('Sync', 'Sync paused');
  }

  void resumeSync() {
    _syncPaused = false;
    LogService.to.info('Sync', 'Sync resumed');
  }

  void cancelSync() {
    _cancelGeneration++;
    _syncCancelRequested = true;
    _syncPaused = false;
    LogService.to.info('Sync', 'Sync cancellation requested');
  }

  Future<void> _waitWhilePaused(SyncRunContext context) async {
    while (_syncPaused && !_syncCancelRequested && context.isCurrent) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void _handlePossibleSessionExpired(Object error, String source) {
    final authService = _authService;
    if (authService == null) return;
    unawaited(authService.handleSessionExpired(error, source: source));
  }

  void start() {
    if (_authListener != null) return;
    final authService = _authService;
    if (authService == null) return;

    var lastOwnerId = authService.userId;
    void handleAuthChange() {
      final user = authService.currentUser.value;
      if (lastOwnerId != user?.id) {
        cancelSync();
        lastOwnerId = user?.id;
      }
      if (user != null) {
        _bootstrapSync(user.id, reason: 'auth');
      }
    }

    _listenedAuthService = authService;
    _authListener = handleAuthChange;
    authService.currentUser.addListener(handleAuthChange);

    if (authService.isLoggedIn) {
      final userId = authService.currentUser.value!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LogService.to.info('Sync', 'Delay startup sync until first frame');
        _bootstrapSync(userId, reason: 'startup');
      });
    }
  }

  void dispose() {
    cancelSync();
    final listener = _authListener;
    final authService = _listenedAuthService;
    if (listener != null && authService != null) {
      authService.currentUser.removeListener(listener);
    }
    _authListener = null;
    _listenedAuthService = null;
  }

  Future<void> _bootstrapSync(String userId, {required String reason}) async {
    final activeBootstrap = _bootstrapSyncFuture;
    if (activeBootstrap != null && _bootstrapSyncUserId == userId) {
      LogService.to.debug('Sync', 'Reuse bootstrap sync for $reason');
      return activeBootstrap;
    }

    final lastBootstrapAt = _lastBootstrapSyncAt;
    if (_bootstrapSyncUserId == userId &&
        lastBootstrapAt != null &&
        DateTime.now().difference(lastBootstrapAt) <
            const Duration(seconds: 2)) {
      LogService.to.debug('Sync', 'Skip duplicate bootstrap sync for $reason');
      return;
    }

    _bootstrapSyncUserId = userId;
    final future = _runBootstrapSync(userId, reason: reason);
    _bootstrapSyncFuture = future;
    try {
      await future;
      if (_authService?.userId == userId) {
        _lastBootstrapSyncAt = DateTime.now();
      }
    } finally {
      if (identical(_bootstrapSyncFuture, future)) _bootstrapSyncFuture = null;
    }
  }

  Future<void> _runBootstrapSync(
    String userId, {
    required String reason,
  }) async {
    if (_authService?.userId != userId) return;
    try {
      await syncAll(reason: reason);
    } catch (e, stackTrace) {
      if (_authService?.userId != userId) return;
      _handlePossibleSessionExpired(e, '$reason sync bootstrap');
      LogService.to.error(
        'Sync',
        '$reason sync bootstrap failed: $e',
        stackTrace,
      );
    }
  }

  // --- Evidence Sync ---

  String _attachmentStoragePath(String ownerId, EvidenceAttachment attachment) {
    return evidenceAttachmentStoragePath(
      ownerId: ownerId,
      evidenceSyncId: attachment.evidenceSyncId,
      attachmentSyncId: attachment.syncId,
      originalFileName: attachment.originalFileName,
      remoteStoragePath: attachment.remoteStoragePath,
    );
  }

  Future<bool> _uploadEvidenceAttachment(
    EvidenceAttachment attachment, {
    required SyncRunContext context,
  }) async {
    context.checkCurrent();
    if (attachment.ownerUserId != context.ownerId) return false;

    try {
      await _dbService.markEvidenceAttachmentUploading(
        attachment,
        context: context,
      );
      context.checkCurrent();

      final localPath = attachment.localPath;
      if (localPath == null || localPath.trim().isEmpty) {
        throw StateError('Evidence attachment local path is missing');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        throw StateError('Evidence attachment file does not exist: $localPath');
      }

      context.checkCurrent();
      final storagePath = _attachmentStoragePath(context.ownerId, attachment);
      await _client.storage
          .from(_evidenceBucket)
          .upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              contentType: attachment.mimeType ?? 'application/octet-stream',
              upsert: true,
            ),
          );

      context.checkCurrent();
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from(_evidenceAttachmentsTable)
          .upsert({
            'user_id': context.ownerId,
            'sync_id': attachment.syncId,
            'evidence_sync_id': attachment.evidenceSyncId,
            'local_id': attachment.id,
            'remote_storage_path': storagePath,
            'original_file_name': attachment.originalFileName,
            'content_hash': attachment.contentHash,
            'size_bytes': attachment.sizeBytes,
            'mime_type': attachment.mimeType,
            'upload_state': EvidenceAttachmentUploadState.uploaded.name,
            'deleted_at': null,
            'updated_at': now,
          }, onConflict: 'user_id,sync_id')
          .select('sync_id')
          .single();

      context.checkCurrent();
      await _dbService.markEvidenceAttachmentUploaded(
        attachment,
        context: context,
        remoteStoragePath: storagePath,
      );
      context.checkCurrent();
      if (serviceLocator.isRegistered<SyncScheduler>()) {
        unawaited(
          serviceLocator<SyncScheduler>()
              .requestSync(
                reason: 'attachment-parent-path',
                entityName: 'evidence',
                entityKey: attachment.evidenceSyncId,
              )
              .catchError((Object _) => false),
        );
      }
      return true;
    } on SyncRunInvalidated {
      return false;
    } catch (e, stackTrace) {
      if (!context.isCurrent) return false;
      _handlePossibleSessionExpired(e, 'upload Evidence attachment');
      await _dbService.markEvidenceAttachmentFailed(
        attachment,
        e,
        context: context,
      );
      LogService.to.error(
        'Sync',
        'Upload Evidence attachment failed localId=${attachment.id} '
            'syncId=${attachment.syncId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> _deleteEvidenceAttachment(
    EvidenceAttachment attachment, {
    required SyncRunContext context,
  }) async {
    context.checkCurrent();
    if (attachment.ownerUserId != context.ownerId) return false;

    try {
      context.checkCurrent();
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from(_evidenceAttachmentsTable)
          .upsert({
            'user_id': context.ownerId,
            'sync_id': attachment.syncId,
            'evidence_sync_id': attachment.evidenceSyncId,
            'local_id': attachment.id,
            'remote_storage_path': attachment.remoteStoragePath,
            'original_file_name': attachment.originalFileName,
            'content_hash': attachment.contentHash,
            'size_bytes': attachment.sizeBytes,
            'mime_type': attachment.mimeType,
            'upload_state': EvidenceAttachmentUploadState.deleted.name,
            'deleted_at': now,
            'updated_at': now,
          }, onConflict: 'user_id,sync_id')
          .select('sync_id')
          .single();

      context.checkCurrent();
      final remotePath = _attachmentStoragePath(context.ownerId, attachment);
      if (remotePath.trim().isNotEmpty) {
        if (!evidenceStoragePathBelongsToOwner(remotePath, context.ownerId)) {
          throw StateError('Evidence storage path belongs to another owner');
        }
        await _client.storage.from(_evidenceBucket).remove([remotePath]);
      }
      context.checkCurrent();
      await _dbService.purgeEvidenceAttachment(attachment.id, context: context);
      return true;
    } on SyncRunInvalidated {
      return false;
    } catch (e, stackTrace) {
      if (!context.isCurrent) return false;
      _handlePossibleSessionExpired(e, 'delete Evidence attachment');
      await _dbService.markEvidenceAttachmentFailed(
        attachment,
        e,
        context: context,
      );
      LogService.to.error(
        'Sync',
        'Delete Evidence attachment failed localId=${attachment.id} '
            'syncId=${attachment.syncId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> _syncEvidenceAttachment(
    EvidenceAttachment attachment, {
    required SyncRunContext context,
  }) {
    context.checkCurrent();
    return attachment.uploadState == EvidenceAttachmentUploadState.deleted ||
            attachment.deletedAt != null
        ? _deleteEvidenceAttachment(attachment, context: context)
        : _uploadEvidenceAttachment(attachment, context: context);
  }

  Future<bool> _syncPendingEvidenceAttachments({
    String? evidenceSyncId,
    required SyncRunContext context,
  }) async {
    context.checkCurrent();
    final pending = await _dbService.getPendingEvidenceAttachmentsForSync(
      context: context,
    );
    context.checkCurrent();
    var success = true;
    for (final attachment in pending) {
      context.checkCurrent();
      if (evidenceSyncId != null &&
          attachment.evidenceSyncId != evidenceSyncId) {
        continue;
      }

      final key = ownerScopedSyncEntityKey(
        ownerId: context.ownerId,
        syncId: attachment.syncId,
        localId: attachment.id,
      );
      final queue = _syncQueue!;
      final canAttempt = await queue.canAttempt('evidence_attachment', key);
      context.checkCurrent();
      if (!canAttempt) {
        success = false;
        continue;
      }
      final pushed = await _syncEvidenceAttachment(
        attachment,
        context: context,
      );
      context.checkCurrent();
      if (pushed) {
        await queue.recordSuccess('evidence_attachment', key);
      } else {
        await queue.recordFailure('evidence_attachment', key);
      }
      context.checkCurrent();
      success = pushed && success;
    }
    return success;
  }

  Future<void> downloadEvidenceAttachment(
    EvidenceAttachment attachment, {
    SyncRunContext? context,
  }) async {
    context ??= captureRunContext();
    if (context == null || attachment.ownerUserId != context.ownerId) return;
    context.checkCurrent();
    final evidence = await _dbService.getEvidenceBySyncId(
      attachment.evidenceSyncId,
    );
    context.checkCurrent();
    if (evidence == null) return;
    await downloadEvidenceFile(evidence, context: context);
  }

  Future<void> downloadEvidenceFile(
    ExpenseEvidence evidence, {
    SyncRunContext? context,
  }) async {
    context ??= captureRunContext();
    if (context == null || evidence.ownerUserId != context.ownerId) return;
    context.checkCurrent();
    final remotePath = evidence.remoteStoragePath;
    if (remotePath == null || remotePath.isEmpty) return;
    if (!evidenceStoragePathBelongsToOwner(remotePath, context.ownerId)) {
      throw StateError('Evidence storage path belongs to another owner');
    }

    final currentPath = evidence.localFilePath;
    if (currentPath != null && await File(currentPath).exists()) return;

    final bytes = await _client.storage
        .from(_evidenceBucket)
        .download(remotePath);
    context.checkCurrent();
    final appDir = await getApplicationDocumentsDirectory();
    context.checkCurrent();
    final safeProject = evidence.projectName.trim().replaceAll(
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
      '_',
    );
    final folder = Directory(
      '${appDir.path}/Evidence/${safeProject.isEmpty ? "DefaultProject" : safeProject}',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    context.checkCurrent();
    final rawFileName = evidence.fileName ?? remotePath.split('/').last;
    final localPath = safeEvidenceDownloadPath(
      directory: folder.path,
      remoteFileName: rawFileName,
    );
    await File(localPath).writeAsBytes(bytes);
    context.checkCurrent();
    evidence.localFilePath = localPath;
    await _dbService.updateDownloadedEvidenceFile(evidence, context: context);
  }

  // --- Pull Everything ---

  // --- Sync All ---

  Future<bool> syncAll({
    String reason = 'manual',
    bool forceFullRefresh = false,
    bool forceNew = false,
  }) async {
    if (!_isLoggedIn || _databaseRestoreInProgress || _conflictGate.isBlocked) {
      return false;
    }
    final active = _activeSync;
    if (active != null) {
      if (!forceNew &&
          !forceFullRefresh &&
          _activeSyncContext?.isCurrent == true) {
        LogService.to.debug('Sync', 'Reuse active sync for $reason');
        return active;
      }
      // New sessions and explicit restarts must not overlap an older run.
      if (forceNew) cancelSync();
      await active;
      if (!_isLoggedIn ||
          _databaseRestoreInProgress ||
          _conflictGate.isBlocked) {
        return false;
      }
      // Another caller may already have started the replacement while waiting.
      if (_activeSync != null && _activeSync != active) {
        return syncAll(reason: reason, forceFullRefresh: forceFullRefresh);
      }
    }

    _syncCancelRequested = false;
    final context = captureRunContext();
    if (context == null) return false;
    _activeSyncContext = context;
    final future = _runSyncAll(
      reason,
      context: context,
      forceFullRefresh: forceFullRefresh,
    );
    _activeSync = future;
    _runningSyncs.add(future);
    try {
      return await future;
    } finally {
      _runningSyncs.remove(future);
      if (identical(_activeSync, future)) {
        _activeSync = null;
        _activeSyncContext = null;
      }
    }
  }

  Future<bool> _runSyncAll(
    String reason, {
    required SyncRunContext context,
    required bool forceFullRefresh,
  }) async {
    try {
      context.checkCurrent();
      final directory = _dbService.database.directory;
      if (directory == null) throw StateError('Database directory missing');
      final restoreGeneration =
          await DatabaseRestoreCoordinator.readRestoreGeneration(
            directory,
            storedGeneration: _storage.read<int>(_restoreGenerationKey) ?? 0,
          );
      context.checkCurrent();
      final completedKey = 'sync_restored_generation_${context.ownerId}';
      final needsRestoreRefresh =
          restoreGeneration > (_storage.read<int>(completedKey) ?? 0);
      final fullRefresh = forceFullRefresh || needsRestoreRefresh;
      LogService.to.info(
        'Sync',
        'Sync started: $reason${fullRefresh ? " (full refresh)" : ""}',
      );
      final success = await _syncWorkLogsWithEngine(
        context: context,
        forceFullRefresh: fullRefresh,
      );
      context.checkCurrent();
      if (success) {
        await _storage.write(
          'last_sync_time_${context.ownerId}',
          DateTime.now().toUtc().toIso8601String(),
        );
        context.checkCurrent();
        if (needsRestoreRefresh) {
          await _storage.write(completedKey, restoreGeneration);
        }
      }
      LogService.to.info('Sync', success ? 'Sync complete' : 'Sync incomplete');
      return success;
    } on SyncRunInvalidated {
      LogService.to.info('Sync', 'Discard stale sync continuation');
      return false;
    }
  }

  Future<bool> _syncWorkLogsWithEngine({
    required SyncRunContext context,
    required bool forceFullRefresh,
  }) async {
    context.checkCurrent();
    final userId = context.ownerId;
    _syncQueue = IsarSyncQueue(_dbService.database, context: context);

    try {
      final summary =
          await SyncEngine(
            adapters: [
              WorkLogSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: userId,
                context: context,
              ),
              SubscriptionSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: userId,
                context: context,
              ),
              ProjectSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: userId,
                context: context,
              ),
              ExpenseRecordSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: userId,
                context: context,
              ),
              EvidenceSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: userId,
                context: context,
                syncAttachmentsForEvidence: (evidence) {
                  return _syncPendingEvidenceAttachments(
                    evidenceSyncId: evidence.syncId,
                    context: context,
                  );
                },
                downloadEvidenceFile: (evidence) =>
                    downloadEvidenceFile(evidence, context: context),
              ),
              EvidenceAttachmentSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: userId,
                context: context,
                syncAttachment: (attachment) =>
                    _syncEvidenceAttachment(attachment, context: context),
                downloadAttachment: (attachment) =>
                    downloadEvidenceAttachment(attachment, context: context),
              ),
            ],
            cursorStore: GetStorageSyncCursorStore(
              storage: _storage,
              namespace: userId,
              context: context,
            ),
            conflictStore: IsarSyncConflictStore(
              _dbService.database,
              context: context,
            ),
            context: context,
            queue: _syncQueue!,
            runControl: SyncRunControl(
              isCancelled: () => _syncCancelRequested || !context.isCurrent,
              isPaused: () => _syncPaused,
              waitWhilePaused: () => _waitWhilePaused(context),
            ),
          ).syncAll(
            mode: forceFullRefresh
                ? SyncMode.fullRefresh
                : SyncMode.incremental,
          );
      final workLogSummary = summary.adapters['work_log'];
      final subscriptionSummary = summary.adapters['subscription'];
      final projectSummary = summary.adapters['project'];
      final expenseRecordSummary = summary.adapters['expense_record'];
      final evidenceSummary = summary.adapters['evidence'];
      LogService.to.info(
        'Sync',
        'WorkLog adapter sync ${summary.success ? "complete" : "incomplete"}: '
            '${workLogSummary?.pulledRows ?? 0} pulled, '
            '${workLogSummary?.pushedChanges ?? 0} pushed, '
            '${workLogSummary?.failedPushes ?? 0} failed; '
            'Subscription adapter: '
            '${subscriptionSummary?.pulledRows ?? 0} pulled, '
            '${subscriptionSummary?.pushedChanges ?? 0} pushed, '
            '${subscriptionSummary?.failedPushes ?? 0} failed; '
            'Project adapter: '
            '${projectSummary?.pulledRows ?? 0} pulled, '
            '${projectSummary?.pushedChanges ?? 0} pushed, '
            '${projectSummary?.failedPushes ?? 0} failed; '
            'ExpenseRecord adapter: '
            '${expenseRecordSummary?.pulledRows ?? 0} pulled, '
            '${expenseRecordSummary?.pushedChanges ?? 0} pushed, '
            '${expenseRecordSummary?.failedPushes ?? 0} failed; '
            'Evidence adapter: '
            '${evidenceSummary?.pulledRows ?? 0} pulled, '
            '${evidenceSummary?.pushedChanges ?? 0} pushed, '
            '${evidenceSummary?.failedPushes ?? 0} failed',
      );
      return summary.success;
    } on SyncRunInvalidated {
      return false;
    } catch (e, stackTrace) {
      if (!context.isCurrent) return false;
      _handlePossibleSessionExpired(e, 'WorkLog adapter sync');
      LogService.to.error(
        'Sync',
        'WorkLog adapter sync failed: $e',
        stackTrace,
      );
      return false;
    }
  }
}
