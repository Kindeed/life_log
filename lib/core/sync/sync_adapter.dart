import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_conflict.dart';

enum SyncMode { incremental, fullRefresh }

class SyncPullRequest {
  final SyncMode mode;
  final SyncCursor? cursor;

  const SyncPullRequest({required this.mode, required this.cursor});
}

class PushResult {
  final bool success;
  final bool purgeLocalDeleted;
  final SyncConflictDraft? conflict;

  const PushResult({
    required this.success,
    this.purgeLocalDeleted = false,
    this.conflict,
  });
}

abstract interface class SyncAdapter<T> {
  String get entityName;
  String get tableName;

  Future<List<T>> pendingLocalChanges();
  Future<List<Map<String, dynamic>>> pullRemoteRows(SyncPullRequest request);
  Future<PushResult> pushLocalChange(T entity);
  Future<void> mergeRemoteRow(Map<String, dynamic> row);
  Future<void> purgeLocalDeleted(T entity);
}
