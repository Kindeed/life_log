import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/application/save_photo_from_path.dart';
import 'package:life_log/features/photo/data/legacy_photo_repository_adapter.dart';
import 'package:life_log/features/photo/data/photo_file_store.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/photo/data/photo_repository.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/project/data/project_repository.dart';

import '../../../tool/isar_test_runtime.dart' show initializeTestIsar;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestIsar);
  late Directory directory;
  late IsarDatabase database;
  late DbService db;
  late SavePhotoFromPath save;
  late Project archive;
  late Project current;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('photo_identity_');
    database = await IsarDatabase.open(
      schemas: DbService.schemas,
      directory: directory.path,
      name: 'photos_${DateTime.now().microsecondsSinceEpoch}',
      inspector: false,
    );
    db = await _OwnerDb().initWithDatabaseForTest(database);
    serviceLocator.registerSingleton<DbService>(db);
    serviceLocator.registerSingleton<ProjectRepository>(ProjectRepository());
    save = SavePhotoFromPath(
      LegacyPhotoRepositoryAdapter(
        PhotoRepository(fileStore: _Files('${directory.path}/archive')),
      ),
    );
    archive = _project('同名项目')
      ..updatedAt = DateTime(2026, 10, 12)
      ..status = ProjectStatus.archived
      ..isLocalArchive = true;
    current = _project(archive.name)..updatedAt = DateTime(2026, 10, 11);
    await database.writeTxn(() async {
      archive.id = await database.isar.projects.put(archive);
      current.id = await database.isar.projects.put(current);
    });
  });

  tearDown(() async {
    await serviceLocator.reset();
    await database.close();
    final resolved = await directory.resolveSymbolicLinks();
    expect(resolved, directory.absolute.path);
    await directory.delete(recursive: true);
  });

  test(
    'keeps selected current and local archive identities among namesakes',
    () async {
      for (final project in [current, archive]) {
        final source = File('${directory.path}/source_${project.id}.jpg');
        await source.writeAsString('photo ${project.id}');
        final result = await save(
          tempPath: source.path,
          projectName: project.name,
          projectId: project.id,
          projectStageName: '勘查',
          description: '现场记录',
          deviceName: 'Phone',
          deleteSource: true,
        );
        expect(result.failureOrNull, isNull);
        final photo = result.valueOrNull!;
        expect(photo.projectId, project.id);
        expect(photo.projectStageName, '勘查');
        expect(
          await File(photo.filePath).readAsString(),
          'photo ${project.id}',
        );
        expect(await source.exists(), isFalse);
      }
      final retained = (await db.getProject(archive.id))!;
      expect(retained.isLocalArchive, isTrue);
      expect(retained.isDirty, isFalse);
      expect(retained.syncId, isNull);
      expect(await db.getPendingProjectsForSync(), isEmpty);
      expect(
        (await db.getAllPhotos()).map((photo) => photo.projectId),
        containsAll([current.id, archive.id]),
      );
    },
  );

  test(
    'uses the latest exact project name after a concurrent rename',
    () async {
      await database.writeTxn(() async {
        current.name = '项目改名';
        await database.isar.projects.put(current);
      });
      final source = File('${directory.path}/rename.jpg');
      await source.writeAsString('photo');
      final result = await save(
        tempPath: source.path,
        projectName: archive.name,
        projectId: current.id,
        description: '',
        deviceName: 'Phone',
        deleteSource: false,
      );
      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull!.projectId, current.id);
      expect(result.valueOrNull!.projectName, '项目改名');
      expect(result.valueOrNull!.filePath, contains('项目改名'));
      expect(await source.exists(), isTrue);
    },
  );

  test(
    'missing, foreign and invalid explicit ids preserve the source without fallback',
    () async {
      final foreign = _project(archive.name)..ownerUserId = 'owner-b';
      await database.writeTxn(() async {
        foreign.id = await database.isar.projects.put(foreign);
      });
      final source = File('${directory.path}/keep.jpg');
      await source.writeAsString('original');
      for (final id in [99999, foreign.id, 0]) {
        final result = await save(
          tempPath: source.path,
          projectName: archive.name,
          projectId: id,
          description: '',
          deviceName: 'Phone',
          deleteSource: true,
        );
        expect(result.failureOrNull, isNotNull);
        expect(await source.readAsString(), 'original');
        expect(await Directory('${directory.path}/archive').exists(), isFalse);
        expect(await database.isar.photoItems.count(), 0);
      }
    },
  );
}

Project _project(String name) => Project()
  ..name = name
  ..ownerUserId = 'owner-a'
  ..createdAt = DateTime(2026, 10, 11)
  ..updatedAt = DateTime(2026, 10, 11);

final class _OwnerDb extends DbService {
  @override
  String? get currentOwnerUserId => 'owner-a';
}

final class _Files implements PhotoFileStore {
  final String root;
  final _io = const IoPhotoFileStore();
  _Files(this.root);
  @override
  Future<String> appDocumentsPath() async => root;
  @override
  Future<String> availablePath(String directoryPath, String fileName) =>
      _io.availablePath(directoryPath, fileName);
  @override
  String basename(String path) => _io.basename(path);
  @override
  Future<void> copyFile(String sourcePath, String targetPath) =>
      _io.copyFile(sourcePath, targetPath);
  @override
  Future<void> deleteFileIfExists(String path) => _io.deleteFileIfExists(path);
  @override
  Future<void> deleteSourceFile(String path) => _io.deleteSourceFile(path);
  @override
  String dirname(String path) => _io.dirname(path);
  @override
  Future<void> ensureDirectory(String path) => _io.ensureDirectory(path);
  @override
  Future<bool> fileExists(String path) => _io.fileExists(path);
  @override
  Future<String> renameFile(String sourcePath, String targetPath) =>
      _io.renameFile(sourcePath, targetPath);
}
