import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/application/load_expense_record_edit_draft.dart';
import 'package:life_log/features/expense/application/save_expense_record_entry.dart';
import 'package:life_log/features/expense/application/watch_expense_record_entries.dart';
import 'package:life_log/features/expense/data/expense_record_local_data_source.dart';
import 'package:life_log/features/expense/data/expense_record_project_linker.dart';
import 'package:life_log/features/expense/data/legacy_expense_record_repository_adapter.dart';
import 'package:life_log/features/expense/data/expense_record_sync_gateway.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_edit_draft.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry_stats.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/expense/data/expense_record_repository.dart';

void main() {
  group('ExpenseRecordEntryStats', () {
    test('groups local month records and sums total amount', () {
      final entries = [
        ExpenseRecordEntry(
          id: 1,
          expenseDate: DateTime(2026, 5, 1),
          amount: 12,
        ),
        ExpenseRecordEntry(
          id: 2,
          expenseDate: DateTime(2026, 5, 20),
          amount: 8,
        ),
        ExpenseRecordEntry(
          id: 3,
          expenseDate: DateTime(2026, 6, 1),
          amount: 99,
        ),
      ];

      final mayEntries = entries.inMonth(DateTime(2026, 5)).toList();

      expect(mayEntries.map((entry) => entry.id), [1, 2]);
      expect(mayEntries.totalAmount, 20);
    });
  });

  group('SaveExpenseRecordEntry', () {
    test('delegates entry save with the dirty decision', () async {
      final repository = _WritePathRepository();

      final result = await SaveExpenseRecordEntry(
        repository,
      ).call(_entry(id: 7, amount: 18), markDirty: true);

      expect(result.isSuccess, isTrue);
      expect(repository.savedEntries.single.entry.id, 7);
      expect(repository.savedEntries.single.entry.amount, 18);
      expect(repository.savedEntries.single.markDirty, isTrue);
    });

    test('returns app failure when saving throws', () async {
      final result = await SaveExpenseRecordEntry(
        _WritePathRepository(saveError: StateError('save down')),
      ).call(_entry(id: 8), markDirty: true);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'expense-record/save-entry');
      expect(result.failureOrNull?.message, contains('save down'));
    });
  });

  group('DeleteExpenseRecordEntry', () {
    test('delegates delete by id', () async {
      final repository = _WritePathRepository();

      final result = await DeleteExpenseRecordEntry(repository).call(12);

      expect(result.isSuccess, isTrue);
      expect(repository.deletedIds, [12]);
    });

    test('returns app failure when deleting throws', () async {
      final result = await DeleteExpenseRecordEntry(
        _WritePathRepository(deleteError: StateError('delete down')),
      ).call(13);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'expense-record/delete-entry');
      expect(result.failureOrNull?.message, contains('delete down'));
    });
  });

  group('LoadExpenseRecordEditDraft', () {
    test(
      'returns edit draft with dirty metadata from repository port',
      () async {
        final repository = _WritePathRepository(
          editDraft: ExpenseRecordEditDraft(
            entry: _entry(id: 31, amount: 44),
            alreadyDirty: true,
          ),
        );

        final result = await LoadExpenseRecordEditDraft(repository).call(31);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull?.entry.id, 31);
        expect(result.valueOrNull?.entry.amount, 44);
        expect(result.valueOrNull?.alreadyDirty, isTrue);
      },
    );
  });

  group('LegacyExpenseRecordRepositoryAdapter', () {
    test('keeps DbService and SyncService behind feature data seams', () {
      final repositorySource = File(
        'lib/features/expense/data/expense_record_repository.dart',
      ).readAsStringSync();
      final localDataSourceFile = File(
        'lib/features/expense/data/expense_record_local_data_source.dart',
      );
      final syncGatewayFile = File(
        'lib/features/expense/data/expense_record_sync_gateway.dart',
      );

      expect(localDataSourceFile.existsSync(), isTrue);
      expect(syncGatewayFile.existsSync(), isTrue);
      expect(repositorySource, contains('ExpenseRecordLocalDataSource'));
      expect(repositorySource, contains('ExpenseRecordSyncGateway'));
      expect(repositorySource, isNot(contains('DbService.to')));
      expect(repositorySource, isNot(contains('SyncService.to')));
    });

    test('keeps project linking behind a feature data seam', () {
      final repositorySource = File(
        'lib/features/expense/data/expense_record_repository.dart',
      ).readAsStringSync();
      final projectLinkerFile = File(
        'lib/features/expense/data/expense_record_project_linker.dart',
      );

      expect(projectLinkerFile.existsSync(), isTrue);
      expect(repositorySource, contains('ExpenseRecordProjectLinker'));
      expect(repositorySource, isNot(contains('ProjectRepository.to')));
      expect(
        repositorySource,
        isNot(contains('modules/project/project_repository.dart')),
      );
    });

    test('keeps ExpenseRecordRepository owned by GetIt feature DI', () {
      final repositorySource = File(
        'lib/features/expense/data/expense_record_repository.dart',
      ).readAsStringSync();
      final diSource = File(
        'lib/features/expense/expense_feature_di.dart',
      ).readAsStringSync();
      final bindingSource = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();

      expect(repositorySource, isNot(contains("package:get/get.dart")));
      expect(repositorySource, isNot(contains('GetxService')));
      expect(repositorySource, isNot(contains('ExpenseRecordRepository.to')));
      expect(repositorySource, isNot(contains('Get.find')));
      expect(repositorySource, isNot(contains('Get.isRegistered')));
      expect(
        diSource,
        contains('registerLazySingleton<ExpenseRecordRepository>'),
      );
      expect(diSource, contains('activeLocator<ExpenseRecordRepository>()'));
      expect(diSource, isNot(contains('Get.find<ExpenseRecordRepository>')));
      expect(
        bindingSource,
        isNot(contains('Get.lazyPut(() => ExpenseRecordRepository')),
      );
    });

    test('routes reads and watches through the injected local seam', () async {
      final controller = StreamController<void>();
      final stored = _expenseRecord(id: 9, amount: 42);
      final localDataSource = _ExpenseRecordLocalDataSourceSpy(
        storedRecords: [stored],
        watchStream: controller.stream,
      );
      final repository = ExpenseRecordRepository(
        localDataSource: localDataSource,
        syncGateway: _ExpenseRecordSyncGatewaySpy(isAvailable: false),
      );

      expect(await repository.getAllExpenseRecords(), [same(stored)]);

      final values = <void>[];
      final sub = repository.watchExpenseRecords().listen(values.add);
      controller.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(values, hasLength(1));
      await sub.cancel();
      await controller.close();
    });

    test('routes saves through injected local and sync seams', () async {
      final localDataSource = _ExpenseRecordLocalDataSourceSpy();
      final syncGateway = _ExpenseRecordSyncGatewaySpy(isAvailable: true);
      final repository = ExpenseRecordRepository(
        localDataSource: localDataSource,
        syncGateway: syncGateway,
      );
      final record = _expenseRecord(amount: 18);

      final saved = await repository.saveExpenseRecord(record);

      expect(saved, same(record));
      expect(record.syncId, isNotEmpty);
      expect(localDataSource.addedRecords, [same(record)]);
      expect(syncGateway.pushedRecords, [same(record)]);
    });

    test('routes project names through the injected project linker', () async {
      final localDataSource = _ExpenseRecordLocalDataSourceSpy();
      final projectLinker = _ExpenseRecordProjectLinkerSpy(
        linkedProject: const ExpenseRecordLinkedProject(
          id: 42,
          name: 'Canonical Project',
          syncId: 'project-sync-42',
        ),
      );
      final repository = ExpenseRecordRepository(
        localDataSource: localDataSource,
        syncGateway: _ExpenseRecordSyncGatewaySpy(isAvailable: true),
        projectLinker: projectLinker,
      );
      final record = _expenseRecord()..projectName = '  canonical project  ';

      await repository.saveExpenseRecord(record);

      expect(projectLinker.linkedNames, ['canonical project']);
      expect(record.projectId, 42);
      expect(record.projectName, 'Canonical Project');
      expect(record.projectSyncId, 'project-sync-42');
      expect(localDataSource.addedRecords, [same(record)]);
    });

    test('skips project linking for blank project names', () async {
      final localDataSource = _ExpenseRecordLocalDataSourceSpy();
      final projectLinker = _ExpenseRecordProjectLinkerSpy(
        linkedProject: const ExpenseRecordLinkedProject(
          id: 42,
          name: 'Canonical Project',
        ),
      );
      final repository = ExpenseRecordRepository(
        localDataSource: localDataSource,
        syncGateway: _ExpenseRecordSyncGatewaySpy(isAvailable: true),
        projectLinker: projectLinker,
      );
      final record = _expenseRecord()..projectName = '   ';

      await repository.saveExpenseRecord(record);

      expect(projectLinker.linkedNames, isEmpty);
      expect(record.projectId, isNull);
      expect(record.projectName, isNull);
      expect(localDataSource.addedRecords, [same(record)]);
    });

    test(
      'does not push already clean remote records after local save',
      () async {
        final localDataSource = _ExpenseRecordLocalDataSourceSpy();
        final syncGateway = _ExpenseRecordSyncGatewaySpy(isAvailable: true);
        final repository = ExpenseRecordRepository(
          localDataSource: localDataSource,
          syncGateway: syncGateway,
        );
        final record = _expenseRecord(remoteId: 99, isDirty: false);

        await repository.saveExpenseRecord(record);

        expect(localDataSource.addedRecords, [same(record)]);
        expect(syncGateway.pushedRecords, isEmpty);
      },
    );

    test('purges local-only deletes through the injected local seam', () async {
      final deleted = _expenseRecord(id: 17);
      final localDataSource = _ExpenseRecordLocalDataSourceSpy(
        markedDeleted: deleted,
      );
      final syncGateway = _ExpenseRecordSyncGatewaySpy(isAvailable: true);
      final repository = ExpenseRecordRepository(
        localDataSource: localDataSource,
        syncGateway: syncGateway,
      );

      await repository.deleteExpenseRecord(17);

      expect(localDataSource.markDeletedIds, [17]);
      expect(localDataSource.purgedIds, [17]);
      expect(syncGateway.deletedRecords, isEmpty);
    });

    test(
      'routes remote deletes through injected local and sync seams',
      () async {
        final deleted = _expenseRecord(id: 18, remoteId: 77);
        final localDataSource = _ExpenseRecordLocalDataSourceSpy(
          markedDeleted: deleted,
        );
        final syncGateway = _ExpenseRecordSyncGatewaySpy(isAvailable: true);
        final repository = ExpenseRecordRepository(
          localDataSource: localDataSource,
          syncGateway: syncGateway,
        );

        await repository.deleteExpenseRecord(18);

        expect(localDataSource.markDeletedIds, [18]);
        expect(syncGateway.deletedRecords, [same(deleted)]);
        expect(localDataSource.purgedIds, [18]);
      },
    );

    test('maps legacy expense records to domain entries', () async {
      final repository = _LegacyExpenseRecordRepositorySpy()
        ..storedRecords.add(
          ExpenseRecord()
            ..id = 7
            ..expenseDate = DateTime(2026, 5, 2)
            ..amount = 18
            ..currency = 'USD'
            ..category = ExpenseCategory.travel
            ..merchant = 'Rail'
            ..note = 'ticket'
            ..projectId = 3
            ..projectName = 'Alpha',
        );
      final adapter = LegacyExpenseRecordRepositoryAdapter(repository);

      final entries = await adapter.getAllEntries();

      expect(entries.single.id, 7);
      expect(entries.single.expenseDate, DateTime(2026, 5, 2));
      expect(entries.single.amount, 18);
      expect(entries.single.currency, 'USD');
      expect(entries.single.category, ExpenseRecordEntryCategory.travel);
      expect(entries.single.merchant, 'Rail');
      expect(entries.single.note, 'ticket');
      expect(entries.single.projectId, 3);
      expect(entries.single.projectName, 'Alpha');
    });

    test('watches through the repository port', () async {
      final controller = StreamController<void>();
      final repository = _LegacyExpenseRecordRepositorySpy(
        watchStream: controller.stream,
      );
      final adapter = LegacyExpenseRecordRepositoryAdapter(repository);

      final values = <void>[];
      final sub = WatchExpenseRecordEntries(adapter)().listen(values.add);
      controller.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(values, hasLength(1));
      await sub.cancel();
      await controller.close();
    });

    test('maps feature save entries back to legacy records', () async {
      final repository = _LegacyExpenseRecordRepositorySpy();
      final adapter = LegacyExpenseRecordRepositoryAdapter(repository);

      await adapter.saveEntry(
        _entry(
          id: 21,
          amount: 33,
          category: ExpenseRecordEntryCategory.office,
          merchant: 'Desk',
          note: 'keyboard',
          projectId: 4,
          projectName: 'Office',
        ),
        markDirty: true,
      );

      final saved = repository.savedRecords.single;
      expect(saved.id, 21);
      expect(saved.amount, 33);
      expect(saved.category, ExpenseCategory.office);
      expect(saved.merchant, 'Desk');
      expect(saved.note, 'keyboard');
      expect(saved.projectId, 4);
      expect(saved.projectName, 'Office');
      expect(saved.isDirty, isTrue);
    });

    test('preserves legacy sync metadata behind the adapter', () async {
      final repository = _LegacyExpenseRecordRepositorySpy()
        ..storedRecords.add(
          ExpenseRecord()
            ..id = 23
            ..ownerUserId = 'owner-1'
            ..remoteId = 99
            ..syncId = 'sync-23'
            ..remoteVersion = 5
            ..remoteUpdatedAt = DateTime(2026, 5, 1)
            ..syncedAt = DateTime(2026, 5, 2)
            ..deletedAt = DateTime(2026, 5, 3)
            ..pendingDelete = true
            ..expenseDate = DateTime(2026, 5, 10)
            ..amount = 10
            ..currency = 'CNY'
            ..category = ExpenseCategory.meal
            ..merchant = 'Old'
            ..projectId = 7
            ..projectName = 'Old Project',
        );
      final adapter = LegacyExpenseRecordRepositoryAdapter(repository);

      await adapter.saveEntry(
        _entry(
          id: 23,
          amount: 16,
          merchant: 'Updated',
          projectName: 'New Project',
        ),
        markDirty: true,
      );

      final saved = repository.savedRecords.single;
      expect(saved.id, 23);
      expect(saved.amount, 16);
      expect(saved.merchant, 'Updated');
      expect(saved.ownerUserId, 'owner-1');
      expect(saved.remoteId, 99);
      expect(saved.syncId, 'sync-23');
      expect(saved.remoteVersion, 5);
      expect(saved.remoteUpdatedAt, DateTime(2026, 5, 1));
      expect(saved.syncedAt, DateTime(2026, 5, 2));
      expect(saved.deletedAt, DateTime(2026, 5, 3));
      expect(saved.pendingDelete, isTrue);
      expect(saved.isDirty, isTrue);
    });

    test('maps legacy dirty state into an edit draft', () async {
      final repository = _LegacyExpenseRecordRepositorySpy()
        ..storedRecords.add(
          ExpenseRecord()
            ..id = 33
            ..expenseDate = DateTime(2026, 5, 10)
            ..amount = 10
            ..isDirty = true,
        );
      final adapter = LegacyExpenseRecordRepositoryAdapter(repository);

      final draft = await adapter.getEditDraft(33);

      expect(draft?.entry.id, 33);
      expect(draft?.entry.amount, 10);
      expect(draft?.alreadyDirty, isTrue);
    });

    test('delegates feature delete entries to the legacy repository', () async {
      final repository = _LegacyExpenseRecordRepositorySpy();
      final adapter = LegacyExpenseRecordRepositoryAdapter(repository);

      await adapter.deleteEntry(42);

      expect(repository.deletedIds, [42]);
    });
  });
}

ExpenseRecordEntry _entry({
  required int id,
  double amount = 10,
  ExpenseRecordEntryCategory category = ExpenseRecordEntryCategory.meal,
  String? merchant,
  String? note,
  int? projectId,
  String? projectName,
}) {
  return ExpenseRecordEntry(
    id: id,
    expenseDate: DateTime(2026, 5, 10),
    amount: amount,
    category: category,
    merchant: merchant,
    note: note,
    projectId: projectId,
    projectName: projectName,
  );
}

ExpenseRecord _expenseRecord({
  int id = 0,
  double amount = 10,
  int? remoteId,
  bool isDirty = false,
}) {
  return ExpenseRecord()
    ..id = id
    ..expenseDate = DateTime(2026, 5, 10)
    ..amount = amount
    ..remoteId = remoteId
    ..isDirty = isDirty;
}

final class _SavedEntryCall {
  final ExpenseRecordEntry entry;
  final bool markDirty;

  const _SavedEntryCall({required this.entry, required this.markDirty});
}

final class _WritePathRepository implements ExpenseRecordRepositoryPort {
  final Object? saveError;
  final Object? deleteError;
  final ExpenseRecordEditDraft? editDraft;
  final savedEntries = <_SavedEntryCall>[];
  final deletedIds = <int>[];

  _WritePathRepository({this.saveError, this.deleteError, this.editDraft});

  @override
  Future<List<ExpenseRecordEntry>> getAllEntries() async => const [];

  @override
  Future<ExpenseRecordEditDraft?> getEditDraft(int id) async => editDraft;

  @override
  Future<void> saveEntry(
    ExpenseRecordEntry entry, {
    required bool markDirty,
  }) async {
    final error = saveError;
    if (error != null) {
      throw error;
    }
    savedEntries.add(_SavedEntryCall(entry: entry, markDirty: markDirty));
  }

  @override
  Future<void> deleteEntry(int id) async {
    final error = deleteError;
    if (error != null) {
      throw error;
    }
    deletedIds.add(id);
  }

  @override
  Stream<void> watchEntries() => const Stream.empty();
}

final class _LegacyExpenseRecordRepositorySpy extends ExpenseRecordRepository {
  final List<ExpenseRecord> storedRecords = [];
  final List<ExpenseRecord> savedRecords = [];
  final List<int> deletedIds = [];
  final Stream<void> watchStream;

  _LegacyExpenseRecordRepositorySpy({Stream<void>? watchStream})
    : watchStream = watchStream ?? const Stream.empty();

  @override
  Future<List<ExpenseRecord>> getAllExpenseRecords() async => storedRecords;

  @override
  Future<ExpenseRecord> saveExpenseRecord(ExpenseRecord record) async {
    savedRecords.add(record);
    return record;
  }

  @override
  Future<void> deleteExpenseRecord(int id) async {
    deletedIds.add(id);
  }

  @override
  Stream<void> watchExpenseRecords() => watchStream;
}

final class _ExpenseRecordLocalDataSourceSpy
    implements ExpenseRecordLocalDataSource {
  final List<ExpenseRecord> storedRecords;
  final List<ExpenseRecord> addedRecords = [];
  final List<int> markDeletedIds = [];
  final List<int> purgedIds = [];
  final ExpenseRecord? markedDeleted;
  final Stream<void> watchStream;

  _ExpenseRecordLocalDataSourceSpy({
    this.storedRecords = const [],
    this.markedDeleted,
    this.watchStream = const Stream.empty(),
  });

  @override
  Future<int> addExpenseRecord(ExpenseRecord record) async {
    addedRecords.add(record);
    return record.id;
  }

  @override
  Future<List<ExpenseRecord>> getAllExpenseRecords() async => storedRecords;

  @override
  Future<ExpenseRecord?> markExpenseRecordDeleted(int id) async {
    markDeletedIds.add(id);
    return markedDeleted;
  }

  @override
  Future<void> purgeDeletedExpenseRecord(int id) async {
    purgedIds.add(id);
  }

  @override
  Stream<void> watchExpenseRecords() => watchStream;
}

final class _ExpenseRecordSyncGatewaySpy implements ExpenseRecordSyncGateway {
  @override
  final bool isAvailable;
  final List<ExpenseRecord> pushedRecords = [];
  final List<ExpenseRecord> deletedRecords = [];

  _ExpenseRecordSyncGatewaySpy({required this.isAvailable});

  @override
  Future<bool> deleteExpenseRecord(ExpenseRecord record) async {
    deletedRecords.add(record);
    return true;
  }

  @override
  Future<bool> pushExpenseRecord(ExpenseRecord record) async {
    pushedRecords.add(record);
    return true;
  }
}

final class _ExpenseRecordProjectLinkerSpy
    implements ExpenseRecordProjectLinker {
  final ExpenseRecordLinkedProject linkedProject;
  final linkedNames = <String>[];

  _ExpenseRecordProjectLinkerSpy({required this.linkedProject});

  @override
  Future<ExpenseRecordLinkedProject> ensureSyncableProject(String name) async {
    linkedNames.add(name);
    return linkedProject;
  }
}
