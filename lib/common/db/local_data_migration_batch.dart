import 'package:isar/isar.dart';

part 'local_data_migration_batch.g.dart';

@collection
class LocalDataMigrationBatch {
  Id id = Isar.autoIncrement;

  String? fromOwner;

  late String toUserId;

  late int recordCount;

  late DateTime startedAt;

  DateTime? completedAt;

  late String status;
}
