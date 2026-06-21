import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/project/data/project_local_data_source.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/project/data/project_repository.dart';
import 'package:life_log/features/project/data/project_sync_gateway.dart';

void main() {
  group('Project data boundary', () {
    test('keeps Isar model and repository under the feature data boundary', () {
      final featureModel = File('lib/features/project/data/project_model.dart');
      final featureGenerated = File(
        'lib/features/project/data/project_model.g.dart',
      );
      final featureRepository = File(
        'lib/features/project/data/project_repository.dart',
      );
      final legacyPaths = [
        'lib/modules/project/project_model.dart',
        'lib/modules/project/project_model.g.dart',
        'lib/modules/project/project_repository.dart',
      ];

      expect(featureModel.existsSync(), isTrue);
      expect(featureGenerated.existsSync(), isTrue);
      expect(featureRepository.existsSync(), isTrue);
      for (final path in legacyPaths) {
        expect(File(path).existsSync(), isFalse);
      }

      expect(
        featureModel.readAsStringSync(),
        contains("part 'project_model.g.dart';"),
      );
      expect(
        featureGenerated.readAsStringSync(),
        contains("part of 'project_model.dart';"),
      );
      expect(
        featureRepository.readAsStringSync(),
        contains('class ProjectRepository'),
      );
    });

    test(
      'blocks production imports from returning to the legacy data path',
      () {
        final sources = [
          'lib/common/bindings/tabs_binding.dart',
          'lib/common/db/db_service.dart',
          'lib/common/services/sync_service.dart',
          'lib/features/evidence/data/evidence_project_linker.dart',
          'lib/features/expense/data/expense_record_project_linker.dart',
          'lib/features/photo/data/photo_repository.dart',
          'lib/features/photo/presentation/create_project_sheet.dart',
          'lib/features/photo/presentation/photo_view.dart',
          'lib/features/photo/presentation/project_gallery_view.dart',
          'lib/features/project/application/create_project_entry.dart',
          'lib/features/project/application/delete_project_entry.dart',
          'lib/features/project/data/legacy_project_repository_adapter.dart',
          'lib/features/project/project_feature_di.dart',
        ];

        for (final path in sources) {
          final source = File(path).readAsStringSync();
          expect(source, isNot(contains('modules/project/project_model.dart')));
          expect(
            source,
            isNot(contains('modules/project/project_repository.dart')),
          );
        }
      },
    );

    test('keeps DbService and SyncService behind project data seams', () {
      final repositorySource = File(
        'lib/features/project/data/project_repository.dart',
      ).readAsStringSync();
      final diSource = File(
        'lib/features/project/project_feature_di.dart',
      ).readAsStringSync();
      final bindingSource = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();

      expect(
        File(
          'lib/features/project/data/project_local_data_source.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/features/project/data/project_sync_gateway.dart',
        ).existsSync(),
        isTrue,
      );
      expect(repositorySource, contains('ProjectLocalDataSource'));
      expect(repositorySource, contains('ProjectSyncGateway'));
      expect(repositorySource, isNot(contains("package:get/get.dart")));
      expect(repositorySource, isNot(contains('GetxService')));
      expect(repositorySource, isNot(contains('Get.find')));
      expect(repositorySource, isNot(contains('Get.isRegistered')));
      expect(repositorySource, isNot(contains('DbService.to')));
      expect(repositorySource, isNot(contains('SyncService.to')));
      expect(diSource, isNot(contains('Get.find<ProjectRepository>')));
      expect(
        bindingSource,
        isNot(contains('Get.lazyPut(() => ProjectRepository')),
      );
    });

    test(
      'routes project reads and watches through injected local seam',
      () async {
        final local = _ProjectLocalDataSourceFake(
          projects: [_project(id: 1, name: 'A')],
        );
        final repository = ProjectRepository(
          localDataSource: local,
          syncGateway: _ProjectSyncGatewayFake(),
        );

        expect(await repository.getAllProjects(), local.projects);
        expect(repository.watchProjects(), isA<Stream<void>>());
        expect(local.watchCount, 1);
      },
    );

    test('routes project save through local seam and sync gateway', () async {
      final local = _ProjectLocalDataSourceFake();
      final sync = _ProjectSyncGatewayFake(isAvailable: true);
      final repository = ProjectRepository(
        localDataSource: local,
        syncGateway: sync,
      );
      final project = _project(id: 0, name: '  New Project  ');

      await repository.saveProject(project);

      expect(project.name, 'New Project');
      expect(project.syncId, isNotEmpty);
      expect(project.isDirty, isTrue);
      expect(local.addedProjects, [project]);
      expect(sync.pushedProjects, [project]);
    });

    test(
      'skips clean remote project push and purges local-only delete',
      () async {
        final cleanRemote = _project(id: 7, name: 'Remote')
          ..remoteId = 70
          ..isDirty = false
          ..pendingDelete = false;
        final localOnlyDeleted = _project(id: 8, name: 'Local deleted');
        final local = _ProjectLocalDataSourceFake(
          ensureResult: cleanRemote,
          deletedResult: localOnlyDeleted,
        );
        final sync = _ProjectSyncGatewayFake(isAvailable: true);
        final repository = ProjectRepository(
          localDataSource: local,
          syncGateway: sync,
        );

        final ensured = await repository.ensureSyncableProject('Remote');
        await repository.deleteProject(localOnlyDeleted);

        expect(ensured, same(cleanRemote));
        expect(sync.pushedProjects, isEmpty);
        expect(sync.deletedProjects, isEmpty);
        expect(local.purgedIds, [8]);
      },
    );
  });
}

Project _project({required int id, required String name}) {
  return Project()
    ..id = id
    ..name = name
    ..createdAt = DateTime(2026, 5)
    ..updatedAt = DateTime(2026, 5);
}

final class _ProjectLocalDataSourceFake implements ProjectLocalDataSource {
  final changes = StreamController<void>.broadcast();
  final List<Project> projects;
  final List<Project> addedProjects = [];
  final List<int> purgedIds = [];
  final Project? ensureResult;
  final Project? deletedResult;
  int watchCount = 0;

  _ProjectLocalDataSourceFake({
    List<Project>? projects,
    this.ensureResult,
    this.deletedResult,
  }) : projects = projects ?? [];

  @override
  Future<void> addProject(Project project) async {
    addedProjects.add(project);
  }

  @override
  Future<Project> ensureProject(String name, {bool syncable = false}) async {
    return ensureResult ?? _project(id: 1, name: name);
  }

  @override
  Future<List<Project>> getAllProjects() async => projects;

  @override
  Future<Project?> markProjectDeleted(int id) async => deletedResult;

  @override
  Future<void> purgeDeletedProject(int id) async {
    purgedIds.add(id);
  }

  @override
  Stream<void> watchProjects() {
    watchCount++;
    return changes.stream;
  }
}

final class _ProjectSyncGatewayFake implements ProjectSyncGateway {
  @override
  final bool isAvailable;
  final List<Project> pushedProjects = [];
  final List<Project> deletedProjects = [];

  _ProjectSyncGatewayFake({this.isAvailable = false});

  @override
  Future<bool> deleteProject(Project project) async {
    deletedProjects.add(project);
    return true;
  }

  @override
  Future<bool> pushProject(Project project) async {
    pushedProjects.add(project);
    return true;
  }
}
