import 'package:get_storage/get_storage.dart';
import 'package:life_log/core/sync/sync_cursor_store.dart';
import 'package:life_log/core/sync/sync_run_context.dart';

final class GetStorageSyncCursorStore implements SyncCursorStore {
  final GetStorage storage;
  final String namespace;
  final SyncRunContext? context;

  const GetStorageSyncCursorStore({
    required this.storage,
    required this.namespace,
    this.context,
  });

  String _key(String entityName) => 'sync_cursor_${namespace}_$entityName';

  @override
  Future<SyncCursor?> read(String entityName) async {
    context?.checkCurrent();
    final raw = storage.read(_key(entityName));
    if (raw == null) return null;

    final parts = raw.toString().split('|');
    if (parts.length != 2) return null;

    final updatedAt = DateTime.tryParse(parts[0])?.toUtc();
    if (updatedAt == null) return null;

    return SyncCursor(updatedAt: updatedAt, rowId: parts[1]);
  }

  @override
  Future<void> write(String entityName, SyncCursor cursor) async {
    context?.checkCurrent();
    await storage.write(
      _key(entityName),
      '${cursor.updatedAt.toIso8601String()}|${cursor.rowId}',
    );
  }

  Future<void> clear(Iterable<String> entityNames) async {
    for (final name in entityNames) {
      await storage.remove(_key(name));
    }
  }
}
