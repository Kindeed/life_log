import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/project/application/create_project_entry.dart';
import 'package:life_log/features/project/application/delete_project_entry.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

void main() {
  group('ProjectCubit', () {
    test('loads entries and exposes lookup by name', () async {
      final repository = _ProjectCubitRepository(
        entries: [
          _entry(id: 1, name: 'Alpha'),
          _entry(id: 2, name: 'Archive', status: ProjectEntryStatus.archived),
        ],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.loadEntries();

      expect(cubit.state.status, ProjectReadStatus.ready);
      expect(cubit.state.totalProjectCount, 2);
      expect(cubit.state.entryNamed('Alpha')?.id, 1);
      expect(cubit.state.entryNamed('Missing'), isNull);
      expect(
        cubit.state.entries.singleWhere((entry) => entry.id == 2).label,
        '已归档',
      );
    });

    test('reloads entries when repository emits changes', () async {
      final repository = _ProjectCubitRepository(
        entries: [_entry(id: 1, name: 'Alpha')],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      cubit.start();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.entries.single.name, 'Alpha');

      repository.entries = [_entry(id: 2, name: 'Beta')];
      repository.emitChange();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.entries.single.name, 'Beta');
    });

    test('emits failure state when loading entries fails', () async {
      final repository = _ProjectCubitRepository(
        entries: const [],
        loadError: StateError('projects down'),
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.loadEntries();

      expect(cubit.state.status, ProjectReadStatus.failure);
      expect(cubit.state.failure?.code, 'project/load-entries');
      expect(cubit.state.failure?.message, contains('projects down'));
    });

    test('saves normalized project stage names', () async {
      final repository = _ProjectCubitRepository(
        entries: [_entry(id: 1, name: 'Alpha')],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      final failure = await cubit.saveStageNames(repository.entries.single, [
        '合同',
        ' ',
        '执行',
        '合同',
      ]);

      expect(failure, isNull);
      expect(repository.entries.single.stageNames, ['合同', '执行']);
    });
  });

  group('CreateProjectEntry', () {
    test('creates a project through the repository port', () async {
      final repository = _ProjectCubitRepository(entries: const []);
      final createProject = CreateProjectEntry(repository);

      final result = await createProject('Alpha');

      expect(result.valueOrNull?.name, 'Alpha');
      expect(repository.createdNames, ['Alpha']);
    });

    test('returns failure when repository creation fails', () async {
      final repository = _ProjectCubitRepository(
        entries: const [],
        createError: ArgumentError('empty'),
      );
      final createProject = CreateProjectEntry(repository);

      final result = await createProject('');

      expect(result.failureOrNull?.code, 'project/create-entry');
      expect(result.failureOrNull?.message, contains('empty'));
    });
  });

  group('DeleteProjectEntry', () {
    test('delegates the atomic cascade to the project repository', () async {
      final projectRepository = _ProjectCubitRepository(
        entries: [_entry(id: 1, name: 'Alpha')],
      );
      final deleteProject = DeleteProjectEntry(projectRepository);

      final result = await deleteProject(_entry(id: 1, name: 'Alpha'));

      expect(result.failureOrNull, isNull);
      expect(projectRepository.deletedEntries.map((entry) => entry.name), [
        'Alpha',
      ]);
    });

    test('keeps cascade ownership in the project data boundary', () {
      final source = File(
        'lib/features/project/application/delete_project_entry.dart',
      ).readAsStringSync();
      final di = File(
        'lib/features/project/project_feature_di.dart',
      ).readAsStringSync();

      expect(source, contains('ProjectRepositoryPort'));
      expect(source, contains('_repository.deleteEntry(entry)'));
      expect(source, isNot(contains('DeletePhotoEntries')));
      expect(source, isNot(contains('LoadExpenseRecordEntries')));
      expect(source, isNot(contains('DeleteExpenseRecordEntry')));
      expect(source, isNot(contains('LoadProjectWorkLogTrips')));
      expect(source, isNot(contains('SaveWorkLogEntry')));
      expect(
        source,
        isNot(contains('features/photo/data/photo_repository.dart')),
      );
      expect(
        source,
        isNot(contains('features/expense/data/expense_record_repository.dart')),
      );
      expect(di, isNot(contains('Get.find<PhotoRepository>')));
      expect(di, isNot(contains('Get.find<ExpenseRecordRepository>')));
    });
  });

  group('LoadProjectWorkLogTrips', () {
    test(
      'loads linked trips and can include unlinked trips for relinking',
      () async {
        final repository = _ProjectWorkLogRepository([
          _trip(id: 1, projectName: 'Alpha'),
          _trip(id: 2, projectName: 'Beta'),
          WorkLogEntry(
            id: 3,
            date: DateTime(2026, 5, 3),
            type: WorkLogEntryType.businessTrip,
          ),
          WorkLogEntry(
            id: 4,
            date: DateTime(2026, 5, 4),
            type: WorkLogEntryType.work,
            projectName: 'Alpha',
          ),
        ]);
        final loadTrips = LoadProjectWorkLogTrips(repository);

        final linkedOnly = await loadTrips('Alpha');
        final withUnlinked = await loadTrips('Alpha', includeUnlinked: true);

        expect(linkedOnly.valueOrNull!.map((entry) => entry.id), [1]);
        expect(withUnlinked.valueOrNull!.map((entry) => entry.id), [3, 1]);
      },
    );
  });

  group('Project read UI ownership', () {
    test('routes project overview read state through ProjectCubit', () {
      final photoView = File(
        'lib/features/photo/presentation/photo_view.dart',
      ).readAsStringSync();
      final tabsBinding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();

      expect(photoView, contains('ProjectCubit'));
      expect(photoView, contains('ProjectEntry'));
      expect(photoView, isNot(contains('ProjectController')));
      expect(photoView, isNot(contains('projectController.projects')));
      expect(photoView, isNot(contains('project_model.dart')));

      expect(appEntry, contains('configureProjectFeatureDependencies'));
      expect(
        tabsBinding,
        isNot(contains('configureProjectFeatureDependencies')),
      );
    });

    test('routes project creation through the feature command', () {
      final createSheet = File(
        'lib/features/photo/presentation/create_project_sheet.dart',
      ).readAsStringSync();

      expect(createSheet, contains('CreateProjectEntry'));
      expect(createSheet, contains('ProjectEntry'));
      expect(createSheet, contains('ScaffoldMessenger'));
      expect(createSheet, isNot(contains('ProjectController')));
      expect(createSheet, isNot(contains('Get.snackbar')));
      expect(createSheet, isNot(contains('project_model.dart')));
    });

    test('routes project gallery lookup through ProjectCubit', () {
      final projectGallery = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();

      expect(projectGallery, contains('ProjectCubit'));
      expect(projectGallery, contains('ProjectEntry'));
      expect(projectGallery, contains('DeleteProjectEntry'));
      expect(projectGallery, isNot(contains('projectController.projects')));
      expect(projectGallery, isNot(contains('ProjectController')));
      expect(projectGallery, isNot(contains('Project? _currentProject')));
      expect(projectGallery, isNot(contains('project_model.dart')));
    });

    test('retires the legacy ProjectController runtime path', () {
      final controller = File('lib/modules/project/project_controller.dart');
      final tabsBinding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      final backupService = File(
        'lib/common/db/backup_service.dart',
      ).readAsStringSync();

      expect(controller.existsSync(), isFalse);
      expect(tabsBinding, isNot(contains('ProjectController')));
      expect(tabsBinding, isNot(contains('project_controller.dart')));
      expect(backupService, isNot(contains('ProjectController')));
      expect(backupService, isNot(contains('project_controller.dart')));
    });
  });
}

ProjectCubit _cubit(_ProjectCubitRepository repository) {
  return ProjectCubit(
    loadEntries: LoadProjectEntries(repository),
    watchEntries: WatchProjectEntries(repository),
    saveEntry: SaveProjectEntry(repository),
  );
}

ProjectEntry _entry({
  required int id,
  required String name,
  ProjectEntryStatus status = ProjectEntryStatus.active,
  List<String> stageNames = const <String>[],
}) {
  return ProjectEntry(
    id: id,
    name: name,
    status: status,
    stageNames: stageNames,
  );
}

final class _ProjectCubitRepository implements ProjectRepositoryPort {
  final _controller = StreamController<void>.broadcast();
  Object? loadError;
  Object? createError;
  List<ProjectEntry> entries;
  final createdNames = <String>[];
  final deletedEntries = <ProjectEntry>[];

  _ProjectCubitRepository({
    required this.entries,
    this.loadError,
    this.createError,
  });

  @override
  Future<List<ProjectEntry>> getAllEntries() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return entries;
  }

  @override
  Stream<void> watchEntries() => _controller.stream;

  @override
  Future<ProjectEntry> ensureEntry(String name) async {
    final error = createError;
    if (error != null) {
      throw error;
    }
    createdNames.add(name);
    final entry = ProjectEntry(
      id: entries.length + 1,
      name: name,
      status: ProjectEntryStatus.active,
    );
    entries = [...entries, entry];
    return entry;
  }

  @override
  Future<ProjectEntry> saveEntry(ProjectEntry entry) async {
    entries = [
      for (final item in entries)
        if (item.id == entry.id) entry else item,
    ];
    return entry;
  }

  @override
  Future<ProjectEntry> saveCoverPath(
    ProjectEntry entry, {
    required String? localCoverPath,
    required String? coverImagePath,
  }) async {
    final updated = ProjectEntry(
      id: entry.id,
      syncId: entry.syncId,
      name: entry.name,
      status: entry.status,
      stageNames: entry.stageNames,
      localCoverPath: localCoverPath,
      coverImagePath: coverImagePath,
    );
    entries = [
      for (final item in entries) item.id == entry.id ? updated : item,
    ];
    return updated;
  }

  @override
  Future<void> deleteEntry(ProjectEntry entry) async {
    deletedEntries.add(entry);
  }

  void emitChange() {
    _controller.add(null);
  }
}

WorkLogEntry _trip({required int id, required String projectName}) {
  return WorkLogEntry(
    id: id,
    syncId: 'trip-sync-$id',
    date: DateTime(2026, 5, 1),
    type: WorkLogEntryType.businessTrip,
    projectId: id,
    projectName: projectName,
  );
}

final class _ProjectWorkLogRepository implements WorkLogRepositoryPort {
  final List<WorkLogEntry> entries;
  final savedEntries = <WorkLogEntry>[];

  _ProjectWorkLogRepository(this.entries);

  @override
  Future<List<WorkLogEntry>> getAllEntries() async => entries;

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async => entries;

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {
    savedEntries.add(entry);
  }

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
