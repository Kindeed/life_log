import 'package:isar/isar.dart';

class IsarDatabase {
  final Isar isar;

  IsarDatabase(this.isar);

  static Future<IsarDatabase> open({
    required List<CollectionSchema<dynamic>> schemas,
    required String directory,
    String name = Isar.defaultName,
    int maxSizeMiB = Isar.defaultMaxSizeMiB,
    bool relaxedDurability = true,
    CompactCondition? compactOnLaunch,
    bool inspector = true,
  }) async {
    final isar = await Isar.open(
      schemas,
      directory: directory,
      name: name,
      maxSizeMiB: maxSizeMiB,
      relaxedDurability: relaxedDurability,
      compactOnLaunch: compactOnLaunch,
      inspector: inspector,
    );
    return IsarDatabase(isar);
  }

  Future<T> readTxn<T>(Future<T> Function() callback) {
    return isar.txn(callback);
  }

  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    return isar.writeTxn(callback, silent: silent);
  }

  Future<void> close({bool deleteFromDisk = false}) async {
    await isar.close(deleteFromDisk: deleteFromDisk);
  }
}
