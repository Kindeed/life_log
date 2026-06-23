import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/application/load_work_log_edit_draft.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/data/legacy_work_log_repository_adapter.dart';
import 'package:life_log/features/work_log/data/work_log_repository.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

void main() {
  group('SaveWorkLogEntry', () {
    test('delegates entry save with the dirty decision', () async {
      final repository = _WritePathRepository();
      final result = await SaveWorkLogEntry(
        repository,
      ).call(_entry(id: 7, note: '保存路径'), markDirty: true);

      expect(result.isSuccess, isTrue);
      expect(repository.savedEntries.single.entry.id, 7);
      expect(repository.savedEntries.single.entry.note, '保存路径');
      expect(repository.savedEntries.single.markDirty, isTrue);
    });

    test('returns app failure when saving throws', () async {
      final result = await SaveWorkLogEntry(
        _WritePathRepository(saveError: StateError('save down')),
      ).call(_entry(id: 8), markDirty: true);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'work-log/save-entry');
      expect(result.failureOrNull?.message, contains('save down'));
    });
  });

  group('DeleteWorkLogEntry', () {
    test('delegates delete by id', () async {
      final repository = _WritePathRepository();
      final result = await DeleteWorkLogEntry(repository).call(12);

      expect(result.isSuccess, isTrue);
      expect(repository.deletedIds, [12]);
    });

    test('returns app failure when deleting throws', () async {
      final result = await DeleteWorkLogEntry(
        _WritePathRepository(deleteError: StateError('delete down')),
      ).call(13);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'work-log/delete-entry');
      expect(result.failureOrNull?.message, contains('delete down'));
    });
  });

  group('LoadWorkLogEditDraft', () {
    test(
      'returns edit draft with dirty metadata from repository port',
      () async {
        final repository = _WritePathRepository(
          editDraft: WorkLogEditDraft(
            entry: _entry(id: 31),
            alreadyDirty: true,
          ),
        );
        final result = await LoadWorkLogEditDraft(repository).call(31);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull?.entry.id, 31);
        expect(result.valueOrNull?.alreadyDirty, isTrue);
      },
    );
  });

  group('LegacyWorkLogRepositoryAdapter', () {
    test('uses the feature data WorkLogRepository boundary', () {
      final repositoryFile = File(
        'lib/features/work_log/data/work_log_repository.dart',
      );
      final legacyRepositoryFile = File(
        'lib/modules/work_log/work_log_repository.dart',
      );

      expect(repositoryFile.existsSync(), isTrue);
      expect(legacyRepositoryFile.existsSync(), isFalse);
      expect(
        _libDartSources(),
        isNot(contains('modules/work_log/work_log_repository.dart')),
      );
    });

    test('uses the feature data WorkLog Isar model boundary', () {
      final modelFile = File('lib/features/work_log/data/work_log_model.dart');
      final generatedModelFile = File(
        'lib/features/work_log/data/work_log_model.g.dart',
      );
      final legacyModelFile = File('lib/modules/work_log/work_log_model.dart');
      final legacyGeneratedModelFile = File(
        'lib/modules/work_log/work_log_model.g.dart',
      );

      expect(modelFile.existsSync(), isTrue);
      expect(generatedModelFile.existsSync(), isTrue);
      expect(legacyModelFile.existsSync(), isFalse);
      expect(legacyGeneratedModelFile.existsSync(), isFalse);
      expect(
        _libDartSources(),
        isNot(contains('modules/work_log/work_log_model.dart')),
      );
    });

    test('keeps DbService and SyncService behind feature data seams', () {
      final repositorySource = File(
        'lib/features/work_log/data/work_log_repository.dart',
      ).readAsStringSync();
      final localDataSourceFile = File(
        'lib/features/work_log/data/work_log_local_data_source.dart',
      );
      final syncGatewayFile = File(
        'lib/features/work_log/data/work_log_sync_gateway.dart',
      );

      expect(localDataSourceFile.existsSync(), isTrue);
      expect(syncGatewayFile.existsSync(), isTrue);
      expect(repositorySource, contains('WorkLogLocalDataSource'));
      expect(repositorySource, contains('WorkLogSyncGateway'));
      expect(repositorySource, isNot(contains('DbService.to')));
      expect(repositorySource, isNot(contains('SyncService.to')));
    });

    test('keeps WorkLogRepository owned by GetIt feature DI', () {
      final repositorySource = File(
        'lib/features/work_log/data/work_log_repository.dart',
      ).readAsStringSync();
      final diSource = File(
        'lib/features/work_log/work_log_feature_di.dart',
      ).readAsStringSync();
      final bindingSource = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();

      expect(repositorySource, isNot(contains("package:get/get.dart")));
      expect(repositorySource, isNot(contains('GetxService')));
      expect(repositorySource, isNot(contains('WorkLogRepository.to')));
      expect(repositorySource, isNot(contains('Get.find')));
      expect(repositorySource, isNot(contains('Get.isRegistered')));
      expect(diSource, contains('registerLazySingleton<WorkLogRepository>'));
      expect(diSource, contains('activeLocator<WorkLogRepository>()'));
      expect(diSource, isNot(contains('WorkLogRepository.to')));
      expect(
        bindingSource,
        isNot(contains('Get.lazyPut(() => WorkLogRepository')),
      );
    });

    test('maps feature save entries back to legacy WorkLog records', () async {
      final repository = _LegacyRepositorySpy();
      final adapter = LegacyWorkLogRepositoryAdapter(repository);

      await adapter.saveEntry(
        WorkLogEntry(
          id: 21,
          date: DateTime(2026, 5, 9, 18),
          type: WorkLogEntryType.businessTrip,
          location: '上海',
          transport: '高铁',
          expenses: 32,
          isReimbursed: true,
          projectId: 4,
          projectSyncId: 'project-sync-4',
          projectName: '上海项目',
          note: '应用层写路径',
        ),
        markDirty: true,
      );

      final saved = repository.savedLogs.single;
      expect(saved.id, 21);
      expect(saved.date, DateTime(2026, 5, 9, 18));
      expect(saved.type, LogType.businessTrip);
      expect(saved.location, '上海');
      expect(saved.transport, '高铁');
      expect(saved.expenses, 32);
      expect(saved.isReimbursed, isTrue);
      expect(saved.projectId, 4);
      expect(saved.projectSyncId, 'project-sync-4');
      expect(saved.projectName, '上海项目');
      expect(saved.note, '应用层写路径');
      expect(saved.isDirty, isTrue);
    });

    test('maps legacy project association into work-log entries', () async {
      final repository = _LegacyRepositorySpy()
        ..storedLogs.add(
          WorkLog()
            ..id = 24
            ..date = DateTime(2026, 5, 9)
            ..type = LogType.businessTrip
            ..projectId = 8
            ..projectSyncId = 'project-sync-8'
            ..projectName = 'Y9',
        );
      final adapter = LegacyWorkLogRepositoryAdapter(repository);

      final entries = await adapter.getAllEntries();

      expect(entries.single.projectId, 8);
      expect(entries.single.projectSyncId, 'project-sync-8');
      expect(entries.single.projectName, 'Y9');
    });

    test('delegates feature delete entries to the legacy repository', () async {
      final repository = _LegacyRepositorySpy();
      final adapter = LegacyWorkLogRepositoryAdapter(repository);

      await adapter.deleteEntry(22);

      expect(repository.deletedIds, [22]);
    });

    test('maps legacy dirty state into an edit draft', () async {
      final repository = _LegacyRepositorySpy()
        ..storedLogs.add(
          WorkLog()
            ..id = 23
            ..date = DateTime(2026, 5, 9)
            ..type = LogType.work
            ..overtimeHours = 1
            ..note = '编辑草稿'
            ..isDirty = true,
        );
      final adapter = LegacyWorkLogRepositoryAdapter(repository);

      final draft = await adapter.getEditDraft(23);

      expect(draft?.entry.id, 23);
      expect(draft?.entry.note, '编辑草稿');
      expect(draft?.alreadyDirty, isTrue);
    });
  });
}

WorkLogEntry _entry({required int id, String? note}) {
  return WorkLogEntry(
    id: id,
    date: DateTime(2026, 5, 9),
    type: WorkLogEntryType.work,
    overtimeHours: 1,
    note: note,
  );
}

final class _SavedEntryCall {
  final WorkLogEntry entry;
  final bool markDirty;

  const _SavedEntryCall({required this.entry, required this.markDirty});
}

final class _WritePathRepository implements WorkLogRepositoryPort {
  final Object? saveError;
  final Object? deleteError;
  final WorkLogEditDraft? editDraft;
  final savedEntries = <_SavedEntryCall>[];
  final deletedIds = <int>[];

  _WritePathRepository({this.saveError, this.deleteError, this.editDraft});

  @override
  Future<List<WorkLogEntry>> getAllEntries() async => const [];

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async =>
      const [];

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => editDraft;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {
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

final class _LegacyRepositorySpy extends WorkLogRepository {
  final storedLogs = <WorkLog>[];
  final savedLogs = <WorkLog>[];
  final deletedIds = <int>[];

  @override
  Future<List<WorkLog>> getAllLogs() async => storedLogs;

  @override
  Future<List<WorkLog>> getLogsByMonth(DateTime month) async {
    return storedLogs
        .where(
          (log) => log.date.year == month.year && log.date.month == month.month,
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveLog(WorkLog log) async {
    savedLogs.add(log);
  }

  @override
  Future<void> deleteLog(int id) async {
    deletedIds.add(id);
  }
}

String _libDartSources() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}
