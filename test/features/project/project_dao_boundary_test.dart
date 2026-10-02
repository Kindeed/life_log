import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectDao boundary', () {
    test(
      'DbService uses feature DAO reads and owner-fenced Project mutations',
      () {
        final daoFile = File('lib/features/project/data/project_dao.dart');
        final dbService = File(
          'lib/common/db/db_service.dart',
        ).readAsStringSync();

        expect(daoFile.existsSync(), isTrue);

        final daoSource = daoFile.readAsStringSync();
        expect(daoSource, contains('class ProjectDao'));
        expect(daoSource, contains('Future<Project?> getById'));
        expect(daoSource, contains('Future<List<Project>> getAllSorted'));
        expect(
          daoSource,
          contains('Future<List<Project>> getActiveSortedForOwner'),
        );
        expect(daoSource, contains('Future<List<Project>> getPendingForSync'));
        expect(
          daoSource,
          contains('Future<List<Project>> getPendingForSyncForOwner'),
        );
        expect(daoSource, contains('Stream<void> watch'));
        expect(daoSource, contains('Future<void> delete'));

        expect(dbService, contains('late ProjectDao _projectDao'));
        expect(dbService, contains('_projectDao = ProjectDao(database)'));
        expect(dbService, contains('_projectDao.getActiveSortedForOwner('));
        expect(
          dbService,
          contains('_projectDao.getPendingForSyncForOwner(owner)'),
        );
        expect(dbService, contains('_preparePendingSyncRows('));
        expect(dbService, contains('_projectDao.getById('));
        expect(dbService, contains('_projectDao.watch()'));
        expect(dbService, contains('Future<void> purgeDeletedProject('));
        expect(dbService, contains('_syncWrite(context, (owner) async'));
        expect(dbService, contains('live.ownerUserId != owner'));
        expect(dbService, contains('await isar.projects.delete(id)'));
      },
    );
  });
}
