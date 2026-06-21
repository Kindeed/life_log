import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';

void main() {
  group('PhotoCubit', () {
    test('loads entries and derives project summaries', () async {
      final repository = _FakePhotoRepository([
        _photo(
          id: 1,
          projectName: 'Y9',
          createdAt: DateTime(2026, 6, 17, 9),
          deviceName: 'Pixel',
          description: '',
        ),
        _photo(
          id: 2,
          projectName: 'Life',
          createdAt: DateTime(2026, 6, 18, 10),
          deviceName: 'iPhone',
          description: 'desk',
        ),
        _photo(
          id: 3,
          projectName: 'Y9',
          createdAt: DateTime(2026, 6, 18, 11),
          deviceName: 'Pixel',
          description: 'board',
        ),
      ]);
      final cubit = PhotoCubit(
        loadEntries: LoadPhotoEntries(repository),
        watchEntries: WatchPhotoEntries(repository),
      );

      await cubit.loadEntries();

      expect(cubit.state.status, PhotoStatus.ready);
      expect(cubit.state.totalPhotoCount, 3);
      expect(cubit.state.projectSummaries.map((summary) => summary.name), [
        'Y9',
        'Life',
      ]);
      final y9 = cubit.state.projectSummaryNamed('Y9')!;
      expect(y9.photoCount, 2);
      expect(y9.latestPhoto!.id, 3);
      expect(y9.deviceCount, 1);
      expect(y9.untitledCount, 1);

      await cubit.close();
    });

    test('filters and sorts project summaries', () async {
      final repository = _FakePhotoRepository([
        _photo(id: 1, projectName: 'Alpha', createdAt: DateTime(2026, 1, 1)),
        _photo(id: 2, projectName: 'Beta', createdAt: DateTime(2026, 1, 2)),
        _photo(id: 3, projectName: 'Beta', createdAt: DateTime(2026, 1, 3)),
      ]);
      final cubit = PhotoCubit(
        loadEntries: LoadPhotoEntries(repository),
        watchEntries: WatchPhotoEntries(repository),
      );

      await cubit.loadEntries();
      cubit.setSortMode(PhotoProjectSortMode.count);
      expect(cubit.state.projectSummaries.map((summary) => summary.name), [
        'Beta',
        'Alpha',
      ]);

      cubit.updateSearch('alp');
      expect(cubit.state.filteredProjectSummaries.single.name, 'Alpha');

      await cubit.close();
    });

    test('reloads entries when repository emits changes', () async {
      final repository = _FakePhotoRepository([
        _photo(id: 1, projectName: 'First', createdAt: DateTime(2026, 1, 1)),
      ]);
      final cubit = PhotoCubit(
        loadEntries: LoadPhotoEntries(repository),
        watchEntries: WatchPhotoEntries(repository),
      );

      cubit.start();
      await Future<void>.delayed(Duration.zero);
      repository.entries = [
        _photo(id: 2, projectName: 'Second', createdAt: DateTime(2026, 1, 2)),
      ];
      repository.emitChange();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.entries.single.projectName, 'Second');

      await cubit.close();
      await repository.close();
    });
  });

  group('Photo read UI ownership', () {
    test('routes Photo overview read state through PhotoCubit', () {
      final source = File(
        'lib/features/photo/presentation/photo_view.dart',
      ).readAsStringSync();

      expect(source, contains('PhotoCubit'));
      expect(source, contains('BlocBuilder<PhotoCubit, PhotoState>'));
      expect(source, isNot(contains('controller.photos')));
      expect(source, isNot(contains('controller.groupedPhotos')));
      expect(source, isNot(contains('controller.totalPhotoCount')));
      expect(source, isNot(contains('controller.projectSearchQuery')));
      expect(source, isNot(contains('controller.projectSortMode')));
    });

    test('routes project gallery photo reads through PhotoCubit', () {
      final source = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();

      expect(source, contains('PhotoCubit'));
      expect(source, contains('BlocBuilder<PhotoCubit, PhotoState>'));
      expect(source, isNot(contains('controller.groupedPhotos')));
    });

    test(
      'registers Photo feature dependencies after the legacy repository',
      () {
        final binding = File(
          'lib/common/bindings/tabs_binding.dart',
        ).readAsStringSync();
        final appEntry = File(
          'lib/app/lifelog_mobile_entry.dart',
        ).readAsStringSync();
        final di = File('lib/features/photo/photo_feature_di.dart');

        expect(di.existsSync(), isTrue);
        expect(appEntry, contains('configurePhotoFeatureDependencies();'));
        expect(binding, isNot(contains('configurePhotoFeatureDependencies')));
      },
    );

    test('routes existing photo actions through feature commands', () {
      final preview = File(
        'lib/features/photo/presentation/photo_preview_view.dart',
      ).readAsStringSync();
      final gallery = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();
      final captureDialog = File(
        'lib/features/photo/presentation/capture_dialog.dart',
      ).readAsStringSync();
      final di = File(
        'lib/features/photo/photo_feature_di.dart',
      ).readAsStringSync();

      expect(preview, contains('DeletePhotoEntries'));
      expect(preview, contains('UpdatePhotoDescription'));
      expect(preview, isNot(contains('PhotoController.to.deletePhoto')));
      expect(
        preview,
        isNot(contains('PhotoController.to.updatePhotoDescription')),
      );

      expect(gallery, contains('DeletePhotoEntries'));
      expect(gallery, contains('ExportPhotoEntries'));
      expect(gallery, isNot(contains('controller.deletePhotos')));
      expect(gallery, isNot(contains('controller.exportPhotos')));

      expect(captureDialog, contains('PhotoCubit'));
      expect(
        captureDialog,
        isNot(contains('PhotoController.to.groupedPhotos')),
      );

      expect(di, contains('DeletePhotoEntries'));
      expect(di, contains('UpdatePhotoDescription'));
      expect(di, contains('ExportPhotoEntries'));
    });

    test('retires PhotoController in favor of feature launcher commands', () {
      final retiredPaths = [
        'lib/features/photo/presentation/photo_controller.dart',
        'lib/modules/photo/photo_controller.dart',
      ];
      final runtimeSources = [
        'lib/common/bindings/tabs_binding.dart',
        'lib/common/db/backup_service.dart',
        'lib/features/photo/presentation/photo_view.dart',
        'lib/features/photo/presentation/project_gallery_view.dart',
      ];
      final launcher = File(
        'lib/features/photo/presentation/photo_add_action_launcher.dart',
      );
      final gallery = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();
      final di = File(
        'lib/features/photo/photo_feature_di.dart',
      ).readAsStringSync();

      for (final path in retiredPaths) {
        expect(File(path).existsSync(), isFalse, reason: '$path is retired');
      }
      for (final path in runtimeSources) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('PhotoController')), reason: path);
        expect(source, isNot(contains('photo_controller.dart')), reason: path);
      }

      expect(launcher.existsSync(), isTrue);
      expect(gallery, contains('capturePhotoWithSystemCamera'));
      expect(gallery, contains('importPhotoFromGallery'));
      expect(gallery, isNot(contains('controller.captureWithSystemCamera')));
      expect(gallery, isNot(contains('controller.importFromGallery')));
      expect(di, contains('SavePhotoFromPath'));
    });
  });
}

PhotoEntry _photo({
  required int id,
  required String projectName,
  required DateTime createdAt,
  String? description,
  String? deviceName,
}) {
  return PhotoEntry(
    id: id,
    ownerUserId: 'local',
    createdAt: createdAt,
    fileName: '$id.jpg',
    filePath: 'photo-$id.jpg',
    description: description,
    deviceName: deviceName,
    projectName: projectName,
    projectId: id,
    dateIndexed: DateTime(createdAt.year, createdAt.month, createdAt.day),
  );
}

final class _FakePhotoRepository implements PhotoRepositoryPort {
  final _controller = StreamController<void>.broadcast();
  List<PhotoEntry> entries;

  _FakePhotoRepository(this.entries);

  @override
  Future<List<PhotoEntry>> getAllEntries() async => entries;

  @override
  Stream<void> watchEntries() => _controller.stream;

  @override
  Future<PhotoEntry> saveEntryFromPath({
    required String tempPath,
    required String projectName,
    required String description,
    required String deviceName,
    required bool deleteSource,
  }) async {
    final entry = _photo(
      id: entries.length + 1,
      projectName: projectName,
      createdAt: DateTime(2026, 6, 18, entries.length),
      description: description,
      deviceName: deviceName,
    );
    entries = [...entries, entry];
    return entry;
  }

  @override
  Future<void> deleteEntries(List<PhotoEntry> entriesToDelete) async {
    final ids = entriesToDelete.map((entry) => entry.id).toSet();
    entries = entries.where((entry) => !ids.contains(entry.id)).toList();
  }

  @override
  Future<String?> updateEntryDescription(
    PhotoEntry entry,
    String description,
  ) async {
    return null;
  }

  @override
  Future<int> exportEntries(
    List<PhotoEntry> entriesToExport,
    String targetDirectory,
  ) async {
    return entriesToExport.length;
  }

  void emitChange() => _controller.add(null);

  Future<void> close() => _controller.close();
}
