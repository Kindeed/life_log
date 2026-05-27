import 'sync_id_generator.dart';

typedef SyncIdFactory = String Function();

String ensureSyncId(
  String? current, {
  SyncIdFactory generator = SyncIdGenerator.newSyncId,
}) {
  final value = current?.trim();
  if (value != null && value.isNotEmpty) return value;
  return generator();
}
