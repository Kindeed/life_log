import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/expense/data/expense_record_local_data_source.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/expense/data/expense_record_project_linker.dart';
import 'package:life_log/features/expense/data/expense_record_repository.dart';
import 'package:life_log/features/expense/data/expense_record_sync_gateway.dart';

void main() {
  group('U289: ExpenseRecord project unbinding and range query', () {
    test(
      'saveExpenseRecord thoroughly clears projectId, projectSyncId, and projectName when projectName is empty or null',
      () async {
        final localDataSource = _FakeLocalDataSource();
        final repository = ExpenseRecordRepository(
          localDataSource: localDataSource,
          syncGateway: const _FakeSyncGateway(),
          projectLinker: _FakeProjectLinker(),
        );

        // Case 1: projectName is empty whitespace
        final recordA = ExpenseRecord()
          ..id = 1
          ..expenseDate = DateTime(2026, 5, 1)
          ..amount = 100
          ..projectId = 42
          ..projectSyncId = 'proj-sync-42'
          ..projectName = '   ';

        await repository.saveExpenseRecord(recordA);

        expect(recordA.projectId, isNull);
        expect(recordA.projectSyncId, isNull);
        expect(recordA.projectName, isNull);
        expect(localDataSource.addedRecords, contains(recordA));

        // Case 2: projectName is null
        final recordB = ExpenseRecord()
          ..id = 2
          ..expenseDate = DateTime(2026, 5, 2)
          ..amount = 200
          ..projectId = 88
          ..projectSyncId = 'proj-sync-88'
          ..projectName = null;

        await repository.saveExpenseRecord(recordB);

        expect(recordB.projectId, isNull);
        expect(recordB.projectSyncId, isNull);
        expect(recordB.projectName, isNull);
        expect(localDataSource.addedRecords, contains(recordB));
      },
    );

    test(
      'getExpenseRecordsByProject queries local data source efficiently by project name',
      () async {
        final recordA = ExpenseRecord()
          ..id = 1
          ..expenseDate = DateTime(2026, 5, 1)
          ..amount = 50
          ..projectName = 'Project Alpha';
        final recordB = ExpenseRecord()
          ..id = 2
          ..expenseDate = DateTime(2026, 5, 2)
          ..amount = 75
          ..projectName = 'Project Beta';
        final recordC = ExpenseRecord()
          ..id = 3
          ..expenseDate = DateTime(2026, 5, 3)
          ..amount = 120
          ..projectName = 'Project Alpha';

        final localDataSource = _FakeLocalDataSource(
          storedRecords: [recordA, recordB, recordC],
        );
        final repository = ExpenseRecordRepository(
          localDataSource: localDataSource,
          syncGateway: const _FakeSyncGateway(),
        );

        final results = await repository.getExpenseRecordsByProject(
          'Project Alpha',
        );
        expect(results.length, 2);
        expect(results.map((r) => r.id), containsAll([1, 3]));
        expect(localDataSource.lastQueriedProjectName, 'Project Alpha');
      },
    );

    test(
      'getExpenseRecordsByProjectId queries local data source efficiently by project local id',
      () async {
        final recordA = ExpenseRecord()
          ..id = 1
          ..expenseDate = DateTime(2026, 5, 1)
          ..amount = 50
          ..projectId = 10;
        final recordB = ExpenseRecord()
          ..id = 2
          ..expenseDate = DateTime(2026, 5, 2)
          ..amount = 75
          ..projectId = 20;

        final localDataSource = _FakeLocalDataSource(
          storedRecords: [recordA, recordB],
        );
        final repository = ExpenseRecordRepository(
          localDataSource: localDataSource,
          syncGateway: const _FakeSyncGateway(),
        );

        final results = await repository.getExpenseRecordsByProjectId(10);
        expect(results.length, 1);
        expect(results.single.id, 1);
        expect(localDataSource.lastQueriedProjectId, 10);
      },
    );
  });
}

final class _FakeLocalDataSource implements ExpenseRecordLocalDataSource {
  final List<ExpenseRecord> storedRecords;
  final List<ExpenseRecord> addedRecords = [];
  String? lastQueriedProjectName;
  int? lastQueriedProjectId;

  _FakeLocalDataSource({this.storedRecords = const []});

  @override
  Future<int> addExpenseRecord(ExpenseRecord record) async {
    addedRecords.add(record);
    return record.id;
  }

  @override
  Future<List<ExpenseRecord>> getAllExpenseRecords() async => storedRecords;

  @override
  Future<List<ExpenseRecord>> getExpenseRecordsByProject(
    String projectName,
  ) async {
    lastQueriedProjectName = projectName;
    final trimmed = projectName.trim();
    if (trimmed.isEmpty) return const [];
    return storedRecords
        .where(
          (r) => r.projectName?.trim().toLowerCase() == trimmed.toLowerCase(),
        )
        .toList();
  }

  @override
  Future<List<ExpenseRecord>> getExpenseRecordsByProjectId(
    int projectId,
  ) async {
    lastQueriedProjectId = projectId;
    if (projectId <= 0) return const [];
    return storedRecords.where((r) => r.projectId == projectId).toList();
  }

  @override
  Future<ExpenseRecord?> markExpenseRecordDeleted(int id) async => null;

  @override
  Future<void> purgeDeletedExpenseRecord(int id) async {}

  @override
  Stream<void> watchExpenseRecords() => const Stream.empty();
}

final class _FakeSyncGateway implements ExpenseRecordSyncGateway {
  const _FakeSyncGateway();

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestSync(
    ExpenseRecord record, {
    required String reason,
  }) async => true;
}

final class _FakeProjectLinker implements ExpenseRecordProjectLinker {
  @override
  Future<ExpenseRecordLinkedProject> ensureSyncableProject(
    String projectName,
  ) async {
    return const ExpenseRecordLinkedProject(
      id: 42,
      name: 'Linked Project',
      syncId: 'sync-42',
    );
  }
}
