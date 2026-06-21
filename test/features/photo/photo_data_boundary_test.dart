import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/photo/data/photo_file_store.dart';
import 'package:life_log/features/photo/data/photo_local_data_source.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/photo/data/photo_project_resolver.dart';
import 'package:life_log/features/photo/data/photo_repository.dart';

void main() {
  group('Photo data boundary', () {
    test('keeps Isar model and repository under the feature data boundary', () {
      final featureModel = File('lib/features/photo/data/photo_model.dart');
      final featureGenerated = File(
        'lib/features/photo/data/photo_model.g.dart',
      );
      final featureRepository = File(
        'lib/features/photo/data/photo_repository.dart',
      );
      final legacyPaths = [
        'lib/modules/photo/photo_model.dart',
        'lib/modules/photo/photo_model.g.dart',
        'lib/modules/photo/photo_repository.dart',
      ];

      expect(featureModel.existsSync(), isTrue);
      expect(featureGenerated.existsSync(), isTrue);
      expect(featureRepository.existsSync(), isTrue);
      for (final path in legacyPaths) {
        expect(File(path).existsSync(), isFalse);
      }

      expect(
        featureModel.readAsStringSync(),
        contains("part 'photo_model.g.dart';"),
      );
      expect(
        featureGenerated.readAsStringSync(),
        contains("part of 'photo_model.dart';"),
      );
      expect(
        featureRepository.readAsStringSync(),
        contains('class PhotoRepository'),
      );
    });

    test('keeps PhotoItem local-only after moving the data layer', () {
      final source = File(
        'lib/features/photo/data/photo_model.dart',
      ).readAsStringSync();
      const forbiddenFields = {
        'syncId',
        'remoteId',
        'isDirty',
        'remoteVersion',
        'deletedAt',
        'pendingDelete',
      };

      for (final field in forbiddenFields) {
        expect(
          RegExp('\\b$field\\b').hasMatch(source),
          isFalse,
          reason: 'PhotoItem must stay local-only and not define $field.',
        );
      }
    });

    test(
      'blocks production imports from returning to the legacy data path',
      () {
        final sources = [
          'lib/common/bindings/tabs_binding.dart',
          'lib/common/db/db_service.dart',
          'lib/features/project/application/delete_project_entry.dart',
          'lib/features/project/project_feature_di.dart',
          'lib/features/photo/presentation/photo_add_action_launcher.dart',
          'lib/features/photo/presentation/photo_preview_view.dart',
          'lib/features/photo/presentation/photo_view.dart',
          'lib/features/photo/presentation/project_gallery_view.dart',
        ];

        for (final path in sources) {
          final source = File(path).readAsStringSync();
          expect(source, isNot(contains('modules/photo/photo_model.dart')));
          expect(
            source,
            isNot(contains('modules/photo/photo_repository.dart')),
          );
        }
      },
    );

    test('keeps local storage, project lookup, and file IO behind seams', () {
      final repositorySource = File(
        'lib/features/photo/data/photo_repository.dart',
      ).readAsStringSync();
      final diSource = File(
        'lib/features/photo/photo_feature_di.dart',
      ).readAsStringSync();
      final bindingSource = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();

      expect(
        File(
          'lib/features/photo/data/photo_local_data_source.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/features/photo/data/photo_project_resolver.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('lib/features/photo/data/photo_file_store.dart').existsSync(),
        isTrue,
      );
      expect(repositorySource, contains('PhotoLocalDataSource'));
      expect(repositorySource, contains('PhotoProjectResolver'));
      expect(repositorySource, contains('PhotoFileStore'));
      expect(repositorySource, isNot(contains("package:get/get.dart")));
      expect(repositorySource, isNot(contains('GetxService')));
      expect(repositorySource, isNot(contains('DbService.to')));
      expect(repositorySource, isNot(contains('ProjectRepository.to')));
      expect(repositorySource, isNot(contains('SyncService')));
      expect(RegExp(r'\bFile\(').hasMatch(repositorySource), isFalse);
      expect(RegExp(r'\bDirectory\(').hasMatch(repositorySource), isFalse);
      expect(
        repositorySource,
        isNot(contains('getApplicationDocumentsDirectory')),
      );
      expect(diSource, isNot(contains('Get.find<PhotoRepository>')));
      expect(
        bindingSource,
        isNot(contains('Get.lazyPut(() => PhotoRepository')),
      );
    });

    test('does not persist photo metadata when archive copy fails', () async {
      final local = _PhotoLocalDataSourceFake();
      final fileStore = _PhotoFileStoreFake(copyError: StateError('copy down'));
      final repository = PhotoRepository(
        localDataSource: local,
        projectResolver: _PhotoProjectResolverFake(),
        fileStore: fileStore,
      );

      await expectLater(
        repository.processAndSavePhoto(
          tempPath: 'C:/tmp/source.jpg',
          projectName: 'Project',
          description: 'Desc',
          deviceName: 'Phone',
        ),
        throwsStateError,
      );

      expect(local.addedPhotos, isEmpty);
    });

    test('does not delete photo row when file deletion fails', () async {
      final photo = _photo(id: 7, path: 'C:/app/photo.jpg');
      final local = _PhotoLocalDataSourceFake(photosById: {7: photo});
      final fileStore = _PhotoFileStoreFake(
        deleteIfExistsError: StateError('delete down'),
      );
      final repository = PhotoRepository(
        localDataSource: local,
        projectResolver: _PhotoProjectResolverFake(),
        fileStore: fileStore,
      );

      await expectLater(repository.deletePhotos([photo]), throwsStateError);

      expect(local.deletedIds, isEmpty);
    });
  });
}

PhotoItem _photo({required int id, required String path}) {
  return PhotoItem()
    ..id = id
    ..createdAt = DateTime(2026, 5)
    ..fileName = path.split('/').last
    ..filePath = path
    ..projectName = 'Project'
    ..dateIndexed = DateTime(2026, 5);
}

final class _PhotoLocalDataSourceFake implements PhotoLocalDataSource {
  final changes = StreamController<void>.broadcast();
  final Map<int, PhotoItem> photosById;
  final List<PhotoItem> addedPhotos = [];
  final List<int> deletedIds = [];

  _PhotoLocalDataSourceFake({Map<int, PhotoItem>? photosById})
    : photosById = photosById ?? {};

  @override
  Future<void> addPhoto(PhotoItem photo) async {
    addedPhotos.add(photo);
  }

  @override
  Future<void> deletePhoto(int id) async {
    deletedIds.add(id);
  }

  @override
  Future<List<PhotoItem>> getAllPhotos() async => photosById.values.toList();

  @override
  Future<PhotoItem?> getPhoto(int id) async => photosById[id];

  @override
  Stream<void> watchPhotos() => changes.stream;
}

final class _PhotoProjectResolverFake implements PhotoProjectResolver {
  @override
  Future<PhotoLinkedProject> ensureProject(String name) async {
    return PhotoLinkedProject(id: 1, name: name);
  }
}

final class _PhotoFileStoreFake implements PhotoFileStore {
  final Object? copyError;
  final Object? deleteIfExistsError;

  _PhotoFileStoreFake({this.copyError, this.deleteIfExistsError});

  @override
  Future<String> appDocumentsPath() async => 'C:/app';

  @override
  Future<String> availablePath(String directoryPath, String fileName) async {
    return '$directoryPath/$fileName';
  }

  @override
  String basename(String path) => path.split('/').last;

  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {
    final error = copyError;
    if (error != null) throw error;
  }

  @override
  Future<void> deleteFileIfExists(String path) async {
    final error = deleteIfExistsError;
    if (error != null) throw error;
  }

  @override
  Future<void> deleteSourceFile(String path) async {}

  @override
  String dirname(String path) {
    final index = path.lastIndexOf('/');
    return index == -1 ? '.' : path.substring(0, index);
  }

  @override
  Future<void> ensureDirectory(String path) async {}

  @override
  Future<bool> fileExists(String path) async => true;

  @override
  Future<String> renameFile(String sourcePath, String targetPath) async {
    return targetPath;
  }
}
