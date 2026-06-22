import 'package:isar/isar.dart';

part 'sync_queue_record.g.dart';

@collection
class SyncQueueRecord {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String entityName;

  @Index()
  late String entityKey;

  late int attemptCount;

  late DateTime nextAttemptAt;

  DateTime? lastAttemptAt;

  String? lastError;
}
