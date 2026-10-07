import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'fixtures/photo_schema_v1437.dart';
import '../tool/isar_test_runtime.dart' show initializeTestIsar;

void main() {
  test(
    'v1.4.37 photo database upgrades without changing records or image files',
    () async {
      await initializeTestIsar();
      final directory = await Directory.systemTemp.createTemp(
        'lifelog-photo-stage-upgrade-',
      );
      Isar? database;
      try {
        final image = File('${directory.path}/original.jpg');
        await image.writeAsBytes([1, 2, 3, 4]);
        database = await Isar.open(
          [LegacyPhotoItemSchema],
          directory: directory.path,
          name: 'stage-upgrade',
        );
        final photo = PhotoItem()
          ..createdAt = DateTime(2026, 9, 7)
          ..capturedAt = DateTime(2026, 9, 6)
          ..dateIndexed = DateTime(2026, 9, 6)
          ..fileName = 'original.jpg'
          ..filePath = image.path
          ..projectId = 17
          ..projectName = '历史项目'
          ..description = '勘查现场'
          ..deviceName = 'Pixel';
        final id = await database.writeTxn(
          () => database!.collection<PhotoItem>().put(photo),
        );
        await database.close();
        database = await Isar.open(
          [PhotoItemSchema],
          directory: directory.path,
          name: 'stage-upgrade',
        );
        final legacy = (await database.collection<PhotoItem>().get(id))!;
        expect(legacy.projectStageName, isNull);
        expect(legacy.projectName, '历史项目');
        expect(legacy.projectId, 17);
        expect(legacy.description, '勘查现场');
        expect(legacy.capturedAt, DateTime(2026, 9, 6));
        legacy.projectStageName = '勘查';
        await database.writeTxn(
          () => database!.collection<PhotoItem>().put(legacy),
        );
        await database.close();
        database = await Isar.open(
          [PhotoItemSchema],
          directory: directory.path,
          name: 'stage-upgrade',
        );
        expect(
          (await database.collection<PhotoItem>().get(id))!.projectStageName,
          '勘查',
        );
        expect(await image.readAsBytes(), [1, 2, 3, 4]);
      } finally {
        await database?.close(deleteFromDisk: true);
        await directory.delete(recursive: true);
      }
    },
  );
}
