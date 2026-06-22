import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/photo/data/photo_model.dart';

void main() {
  final isarLibraryPath = _isarLibraryPath();
  final isarSkip = isarLibraryPath != null
      ? false
      : 'isar.dll is not available in this test environment. '
            'Set ISAR_DLL_PATH or place it at D:\\Tool\\Isar\\isar.dll.';
  setUpAll(() async {
    if (isarLibraryPath == null) return;
    await Isar.initializeIsarCore(libraries: {Abi.current(): isarLibraryPath});
  });

  Future<({DbService db, Directory tempDir})> openDb() async {
    final tempDir = await Directory.systemTemp.createTemp('life_log_db_test_');
    final service = DbService();
    final database = await IsarDatabase.open(
      schemas: DbService.schemas,
      directory: tempDir.path,
      name: 'life_log_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    return (
      db: await service.initWithDatabaseForTest(database),
      tempDir: tempDir,
    );
  }

  group('real Isar database behavior', () {
    late Directory tempDir;
    late DbService db;

    setUp(() async {
      final opened = await openDb();
      db = opened.db;
      tempDir = opened.tempDir;
    });

    tearDown(() async {
      await db.isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
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

    test('new local evidence can be deleted from visible records', () async {
      final id = await db.addEvidence(
        ExpenseEvidence()
          ..projectName = 'Build'
          ..evidenceDate = DateTime(2026, 6, 15)
          ..amount = 42,
      );

      expect(await db.getAllEvidence(), hasLength(1));

      final deleted = await db.markEvidenceDeleted(id);
      await db.purgeDeletedEvidence(id);

      expect(deleted, isNotNull);
      expect(await db.getAllEvidence(), isEmpty);
      expect(await db.isar.expenseEvidences.get(id), isNull);
    }, skip: isarSkip);
  });

  test('database startup maintenance is explicit instead of init-blocking', () {
    final source = File('lib/common/db/db_service.dart').readAsStringSync();

    expect(source, contains('Future<DbService> init({'));
    expect(source, contains('bool runStartupMaintenance = false'));
    expect(source, contains('Future<void> runStartupMaintenance'));
    expect(
      source,
      isNot(
        contains(
          'Future<DbService> init() async {\n'
          '    // 获取手机里专门存文档的路径',
        ),
      ),
    );
  });
}

String? _isarLibraryPath() {
  final explicitPath = Platform.environment['ISAR_DLL_PATH'];
  if (explicitPath != null && explicitPath.trim().isNotEmpty) {
    final file = File(explicitPath.trim());
    if (file.existsSync()) return file.path;
  }

  final defaultDDrivePath = File(r'D:\Tool\Isar\isar.dll');
  if (defaultDDrivePath.existsSync()) {
    return defaultDDrivePath.path;
  }

  return null;
}
