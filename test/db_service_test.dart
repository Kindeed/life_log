import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';
import 'package:life_log/modules/expense/expense_record_model.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:life_log/modules/project/project_model.dart';
import 'package:life_log/modules/subscription/subscription_model.dart';
import 'package:life_log/modules/work_log/work_log_model.dart';

void main() {
  final canOpenIsar = File('isar.dll').existsSync();
  final isarSkip = canOpenIsar
      ? false
      : 'isar.dll is not available in this test environment';
  late Directory tempDir;
  late DbService db;

  Future<DbService> openDb() async {
    tempDir = await Directory.systemTemp.createTemp('life_log_db_test_');
    final service = DbService();
    service.isar = await Isar.open(
      [
        WorkLogSchema,
        SubscriptionSchema,
        PhotoItemSchema,
        ExpenseEvidenceSchema,
        ExpenseRecordSchema,
        ProjectSchema,
      ],
      directory: tempDir.path,
      name: 'life_log_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    Get.put<DbService>(service);
    return service;
  }

  setUp(() async {
    Get.testMode = true;
    db = await openDb();
  });

  tearDown(() async {
    await db.isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    Get.reset();
  });

  test(
    'claiming local records assigns PhotoItem owner without sync fields',
    () async {
      final createdAt = DateTime(2026, 5, 1);
      await db.isar.writeTxn(() async {
        await db.isar.photoItems.put(
          PhotoItem()
            ..createdAt = createdAt
            ..dateIndexed = createdAt
            ..fileName = 'local.jpg'
            ..filePath = '/tmp/local.jpg',
        );
        await db.isar.expenseEvidences.put(
          ExpenseEvidence()
            ..projectName = 'Build'
            ..evidenceDate = createdAt,
        );
        await db.isar.projects.put(
          Project()
            ..name = 'Build'
            ..createdAt = createdAt
            ..updatedAt = createdAt,
        );
      });

      await db.claimUnownedRecordsForOwnerForTest('user-1');

      final photo = await db.isar.photoItems.where().findFirst();
      final project = await db.isar.projects.where().findFirst();

      expect(photo!.ownerUserId, 'user-1');
      expect(project!.ownerUserId, 'user-1');
      expect(project.syncId, isNotNull);
      expect(project.isDirty, isTrue);
    },
    skip: isarSkip,
  );

  test('remote expense pull auto-creates syncable dirty project', () async {
    await db.syncRemoteExpenseRecordToLocal({
      'id': 11,
      'sync_id': 'expense-11',
      'version': 1,
      'updated_at': '2026-05-01T00:00:00Z',
      'expense_date': '2026-05-01',
      'project_name': 'Remote Build',
      'amount': 12.5,
      'currency': 'CNY',
    });

    final project = await db.isar.projects.where().findFirst();
    final record = await db.isar.expenseRecords.where().findFirst();

    expect(project!.name, 'Remote Build');
    expect(project.syncId, isNotNull);
    expect(project.isDirty, isTrue);
    expect(record!.projectId, project.id);
  }, skip: isarSkip);
}
