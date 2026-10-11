import 'package:life_log/features/project/data/project_note_dao.dart';
import 'package:life_log/features/project/data/project_note_model.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';

final class ProjectNoteRepository implements ProjectNoteRepositoryPort {
  final ProjectNoteDao _dao;

  const ProjectNoteRepository(this._dao);

  @override
  Future<List<ProjectNoteEntry>> getEntries(ProjectRecordScope scope) async =>
      (await _dao.getEntries(scope)).map(_toEntry).toList(growable: false);

  @override
  Stream<void> watchEntries() => _dao.watch();

  @override
  Object captureContext() => _dao.captureContext();

  @override
  Future<ProjectNoteEntry> saveEntry(
    ProjectNoteEntry entry, {
    Object? expectedContext,
  }) async => _toEntry(
    await _dao.save(
      ProjectNote()
        ..id = entry.id
        ..projectId = entry.projectId
        ..projectSyncId = entry.projectSyncId
        ..projectName = entry.projectName
        ..projectStageName = entry.projectStageName
        ..content = entry.content
        ..date = entry.date
        ..createdAt = entry.createdAt
        ..updatedAt = entry.updatedAt,
      expectedContext: expectedContext,
    ),
  );

  @override
  Future<void> deleteEntry(int id, {Object? expectedContext}) =>
      _dao.delete(id, expectedContext: expectedContext);
}

ProjectNoteEntry _toEntry(ProjectNote note) => ProjectNoteEntry(
  id: note.id,
  projectId: note.projectId,
  projectSyncId: note.projectSyncId,
  projectName: note.projectName,
  projectStageName: note.projectStageName,
  content: note.content,
  date: note.date,
  createdAt: note.createdAt,
  updatedAt: note.updatedAt,
);
