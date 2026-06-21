import 'package:isar/isar.dart';

part 'sync_conflict_model.g.dart';

@collection
class SyncConflictRecord {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String entityName;

  @Index()
  String? entitySyncId;

  String? localId;

  String? remoteId;

  late String conflictType;

  int? localVersion;

  int? remoteVersion;

  DateTime? localUpdatedAt;

  DateTime? remoteUpdatedAt;

  late String message;

  late DateTime detectedAt;

  DateTime? resolvedAt;

  String? resolution;
}
