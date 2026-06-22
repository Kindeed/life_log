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
import 'package:life_log/core/di/service_locator.dart';
import '../db/db_service.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../utils/sync_id_generator.dart';

class SyncService {
  final _client = Supabase.instance.client;
  final _storage = GetStorage();
  late final _syncQueue = IsarSyncQueue(_dbService.database);
  static const _evidenceBucket = 'evidence-files';
  Future<bool>? _activeSync;
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

  User? get _currentUser => _authService?.currentUser.value;

  bool get _isLoggedIn => _authService?.isLoggedIn ?? false;

  String get _lastSyncKey {
    final user = _currentUser;
    return user != null ? 'last_sync_time_${user.id}' : 'last_sync_time';
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
    _syncCancelRequested = true;
    _syncPaused = false;
    LogService.to.info('Sync', 'Sync cancellation requested');
  }

  Future<void> _waitWhilePaused() async {
    while (_syncPaused && !_syncCancelRequested) {
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

    void handleAuthChange() {
      final user = authService.currentUser.value;
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
    _bootstrapSyncFuture = _runBootstrapSync(userId, reason: reason);
    try {
      await _bootstrapSyncFuture;
      _lastBootstrapSyncAt = DateTime.now();
    } finally {
      _bootstrapSyncFuture = null;
    }
  }

  Future<void> _runBootstrapSync(
    String userId, {
    required String reason,
  }) async {
    try {
      await syncAll(reason: reason);
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, '$reason sync bootstrap');
      LogService.to.error(
        'Sync',
        '$reason sync bootstrap failed: $e',
        stackTrace,
      );
    }
  }

  // --- Evidence Sync ---

  String _attachmentStoragePath(User user, EvidenceAttachment attachment) {
    final existing = attachment.remoteStoragePath;
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final fileName = attachment.originalFileName;
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex <= 0 ? '' : fileName.substring(dotIndex);
    return '${user.id}/${attachment.evidenceSyncId}/${attachment.syncId}$extension';
  }

  Future<bool> _uploadEvidenceAttachment(EvidenceAttachment attachment) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      await _dbService.markEvidenceAttachmentUploading(attachment);

      final localPath = attachment.localPath;
      if (localPath == null || localPath.trim().isEmpty) {
        throw StateError('Evidence attachment local path is missing');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        throw StateError('Evidence attachment file does not exist: $localPath');
      }

      final storagePath = _attachmentStoragePath(user, attachment);
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

      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from(_evidenceAttachmentsTable)
          .upsert({
            'user_id': user.id,
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

      await _dbService.markEvidenceAttachmentUploaded(
        attachment,
        remoteStoragePath: storagePath,
      );
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'upload Evidence attachment');
      await _dbService.markEvidenceAttachmentFailed(attachment, e);
      LogService.to.error(
        'Sync',
        'Upload Evidence attachment failed localId=${attachment.id} '
            'syncId=${attachment.syncId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> _deleteEvidenceAttachment(EvidenceAttachment attachment) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from(_evidenceAttachmentsTable)
          .upsert({
            'user_id': user.id,
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

      final remotePath = attachment.remoteStoragePath;
      if (remotePath != null && remotePath.trim().isNotEmpty) {
        await _client.storage.from(_evidenceBucket).remove([remotePath]);
      }
      await _dbService.purgeEvidenceAttachment(attachment.id);
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'delete Evidence attachment');
      await _dbService.markEvidenceAttachmentFailed(attachment, e);
      LogService.to.error(
        'Sync',
        'Delete Evidence attachment failed localId=${attachment.id} '
            'syncId=${attachment.syncId}: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> _syncEvidenceAttachment(EvidenceAttachment attachment) {
    return attachment.uploadState == EvidenceAttachmentUploadState.deleted ||
            attachment.deletedAt != null
        ? _deleteEvidenceAttachment(attachment)
        : _uploadEvidenceAttachment(attachment);
  }

  Future<bool> _syncPendingEvidenceAttachments({String? evidenceSyncId}) async {
    final pending = await _dbService.getPendingEvidenceAttachmentsForSync();
    var success = true;
    for (final attachment in pending) {
      if (evidenceSyncId != null &&
          attachment.evidenceSyncId != evidenceSyncId) {
        continue;
      }

      final pushed = await _syncEvidenceAttachment(attachment);
      success = pushed && success;
    }
    return success;
  }

  Future<void> downloadEvidenceAttachment(EvidenceAttachment attachment) async {
    final evidence = await _dbService.getEvidenceBySyncId(
      attachment.evidenceSyncId,
    );
    if (evidence == null) return;
    await downloadEvidenceFile(evidence);
  }

  Future<void> downloadEvidenceFile(ExpenseEvidence evidence) async {
    final remotePath = evidence.remoteStoragePath;
    if (remotePath == null || remotePath.isEmpty) return;

    final currentPath = evidence.localFilePath;
    if (currentPath != null && await File(currentPath).exists()) return;

    final bytes = await _client.storage
        .from(_evidenceBucket)
        .download(remotePath);
    final appDir = await getApplicationDocumentsDirectory();
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

    final fileName = evidence.fileName ?? remotePath.split('/').last;
    final localPath = '${folder.path}${Platform.pathSeparator}$fileName';
    await File(localPath).writeAsBytes(bytes);
    evidence.localFilePath = localPath;
    await _dbService.updateEvidenceRemoteId(evidence);
  }

  // --- Pull Everything ---

  // --- Sync All ---

  Future<bool> syncAll({
    String reason = 'manual',
    bool forceFullRefresh = false,
    bool forceNew = false,
  }) async {
    if (!_isLoggedIn) return false;

    if (_activeSync != null && !forceNew) {
      LogService.to.debug('Sync', 'Reuse active sync for $reason');
      return _activeSync!;
    }

    if (forceNew) {
      LogService.to.info('Sync', 'Start independent sync for $reason');
      return _runSyncAll(reason, forceFullRefresh: forceFullRefresh);
    }

    _activeSync = _runSyncAll(reason, forceFullRefresh: forceFullRefresh);

    try {
      return await _activeSync!;
    } finally {
      _activeSync = null;
    }
  }

  Future<bool> _runSyncAll(
    String reason, {
    required bool forceFullRefresh,
  }) async {
    _syncCancelRequested = false;
    LogService.to.info(
      'Sync',
      'Sync started: $reason${forceFullRefresh ? " (full refresh)" : ""}',
    );

    final workLogSuccess = await _syncWorkLogsWithEngine(
      forceFullRefresh: forceFullRefresh,
    );
    final pullSuccess = await _pullAll();
    if (!pullSuccess) return false;

    final pushSuccess = await _pushUnsyncedData();
    final success = workLogSuccess && pushSuccess;
    if (pushSuccess) {
      // Kept for compatibility with older builds and existing debug displays.
      _storage.write(_lastSyncKey, DateTime.now().toUtc().toIso8601String());
    }

    LogService.to.info('Sync', success ? 'Sync complete' : 'Sync incomplete');
    return success;
  }

  Future<bool> _syncWorkLogsWithEngine({required bool forceFullRefresh}) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      final summary =
          await SyncEngine(
            adapters: [
              WorkLogSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
              ),
              SubscriptionSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
              ),
              ProjectSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
              ),
              ExpenseRecordSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
              ),
              EvidenceSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
                syncAttachmentsForEvidence: (evidence) {
                  return _syncPendingEvidenceAttachments(
                    evidenceSyncId: evidence.syncId,
                  );
                },
                downloadEvidenceFile: downloadEvidenceFile,
              ),
              EvidenceAttachmentSyncAdapter(
                client: _client,
                dbService: _dbService,
                userId: user.id,
                syncAttachment: _syncEvidenceAttachment,
                downloadAttachment: downloadEvidenceAttachment,
              ),
            ],
            cursorStore: GetStorageSyncCursorStore(
              storage: _storage,
              namespace: user.id,
            ),
            conflictStore: IsarSyncConflictStore(_dbService.database),
            queue: _syncQueue,
            runControl: SyncRunControl(
              isCancelled: () => _syncCancelRequested,
              isPaused: () => _syncPaused,
              waitWhilePaused: _waitWhilePaused,
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
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'WorkLog adapter sync');
      LogService.to.error(
        'Sync',
        'WorkLog adapter sync failed: $e',
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> _pullAll() async {
    try {
      final user = _currentUser;
      if (user == null) return false;

      LogService.to.info('Sync', 'Legacy pull skipped; adapters own pull');
      return true;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'pull');
      LogService.to.error('Sync', 'Pull failed: $e', stackTrace);
      return false;
    }
  }

  Future<bool> _pushUnsyncedData() async {
    try {
      var success = true;

      final attachmentsPushed = await _syncPendingEvidenceAttachments();
      if (!attachmentsPushed) {
        success = false;
      }

      LogService.to.info(
        'Sync',
        'Push ${success ? "complete" : "incomplete"}: '
            'evidenceAttachments ${attachmentsPushed ? "complete" : "incomplete"}',
      );
      return success;
    } catch (e, stackTrace) {
      _handlePossibleSessionExpired(e, 'push pending data');
      LogService.to.error('Sync', 'Push failed: $e', stackTrace);
      return false;
    }
  }
}
