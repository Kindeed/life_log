import 'package:isar_community/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/project/data/project_note_model.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';

final class ProjectNoteDao {
  final IsarDatabase database;
  final String? Function() currentOwnerUserId;
  final Object? Function()? contextToken;

  const ProjectNoteDao({
    required this.database,
    required this.currentOwnerUserId,
    this.contextToken,
  });

  bool _visible(String? recordOwner, String? owner) =>
      recordOwner == null || (owner != null && recordOwner == owner);

  void _checkContext(Isar source, String? owner, Object? token) {
    if (!identical(database.isar, source) ||
        currentOwnerUserId() != owner ||
        contextToken?.call() != token) {
      throw ProjectNoteContextChanged();
    }
  }

  Future<Project?> _resolveProject(
    Isar source,
    ProjectRecordScope scope,
    String? owner,
  ) async {
    Project? project;
    if (scope.id != null) {
      project = await source.projects.get(scope.id!);
      // A stale local id must not silently attach to a namesake project.
      if (project == null) return null;
    } else if (scope.syncId?.trim().isNotEmpty == true) {
      final candidates = await source.projects
          .filter()
          .syncIdEqualTo(scope.syncId!.trim())
          .findAll();
      for (final candidate in candidates) {
        if (_visible(candidate.ownerUserId, owner) &&
            candidate.deletedAt == null) {
          project = candidate;
          break;
        }
      }
    }
    if (project == null ||
        project.deletedAt != null ||
        !_visible(project.ownerUserId, owner)) {
      return null;
    }
    final expectedSyncId = scope.syncId?.trim();
    if (expectedSyncId?.isNotEmpty == true &&
        project.syncId != expectedSyncId) {
      return null;
    }
    return project;
  }

  bool _belongsToProject(ProjectNote note, Project project) {
    final parentSyncId = project.syncId?.trim();
    final noteSyncId = note.projectSyncId?.trim();
    if (note.projectId != null && note.projectId != project.id) return false;
    if (noteSyncId?.isNotEmpty == true && parentSyncId?.isNotEmpty == true) {
      return noteSyncId == parentSyncId;
    }
    return note.projectId == project.id;
  }

  Future<List<ProjectNote>> getEntries(ProjectRecordScope scope) async {
    final source = database.isar;
    final owner = currentOwnerUserId();
    final token = contextToken?.call();
    final result = await database.readTxn(() async {
      final project = await _resolveProject(source, scope, owner);
      if (project == null) return <ProjectNote>[];
      final candidates = await source.projectNotes
          .filter()
          .projectIdEqualTo(project.id)
          .sortByDateDesc()
          .thenByCreatedAtDesc()
          .findAll();
      final notes = candidates
          .where(
            (note) =>
                _visible(note.ownerUserId, owner) &&
                _belongsToProject(note, project),
          )
          .toList();
      // Isar ids are not schema properties and cannot be added to native
      // property sort clauses. Use ids only to break timestamp ties here.
      notes.sort((a, b) {
        final eventOrder = b.date.compareTo(a.date);
        if (eventOrder != 0) return eventOrder;
        final createdOrder = b.createdAt.compareTo(a.createdAt);
        return createdOrder != 0 ? createdOrder : b.id.compareTo(a.id);
      });
      return notes;
    });
    _checkContext(source, owner, token);
    return result;
  }

  Stream<void> watch() =>
      database.watch((isar) => isar.projectNotes.watchLazy());

  Object captureContext() => (
    database: database.isar,
    owner: currentOwnerUserId(),
    token: contextToken?.call(),
  );

  void _checkExpectedContext(Object? expectedContext) {
    if (expectedContext != null && expectedContext != captureContext()) {
      throw ProjectNoteContextChanged();
    }
  }

  Future<ProjectNote> save(ProjectNote draft, {Object? expectedContext}) async {
    _checkExpectedContext(expectedContext);
    final content = draft.content.trim();
    if (content.isEmpty) throw ArgumentError('记录内容不能为空');
    final source = database.isar;
    final owner = currentOwnerUserId();
    final token = contextToken?.call();
    return database.writeTxn(() async {
      _checkContext(source, owner, token);
      _checkExpectedContext(expectedContext);
      final project = await _resolveProject(
        source,
        ProjectRecordScope(
          id: draft.projectId,
          syncId: draft.projectSyncId,
          name: draft.projectName,
        ),
        owner,
      );
      if (project == null) throw StateError('项目已不存在或不属于当前账号');

      final isNew = draft.id == 0 || draft.id == Isar.autoIncrement;
      final existing = isNew ? null : await source.projectNotes.get(draft.id);
      if (!isNew &&
          (existing == null ||
              !_visible(existing.ownerUserId, owner) ||
              !_belongsToProject(existing, project))) {
        throw StateError('记录已不存在或不属于当前项目');
      }
      _checkContext(source, owner, token);
      _checkExpectedContext(expectedContext);
      final now = DateTime.now();
      final note = ProjectNote()
        ..id = existing?.id ?? Isar.autoIncrement
        ..ownerUserId = existing?.ownerUserId ?? owner
        ..projectId = project.id
        ..projectSyncId = project.syncId
        ..projectName = project.name
        ..projectStageName = _nonEmpty(draft.projectStageName)
        ..content = content
        ..date = draft.date
        ..createdAt = existing?.createdAt ?? now
        ..updatedAt = now;
      note.id = await source.projectNotes.put(note);
      _checkContext(source, owner, token);
      _checkExpectedContext(expectedContext);
      return note;
    });
  }

  Future<void> delete(int id, {Object? expectedContext}) async {
    _checkExpectedContext(expectedContext);
    final source = database.isar;
    final owner = currentOwnerUserId();
    final token = contextToken?.call();
    await database.writeTxn(() async {
      _checkContext(source, owner, token);
      _checkExpectedContext(expectedContext);
      final existing = await source.projectNotes.get(id);
      if (existing == null) return;
      if (!_visible(existing.ownerUserId, owner)) {
        throw StateError('记录不属于当前账号');
      }
      final project = await _resolveProject(
        source,
        ProjectRecordScope(
          id: existing.projectId,
          syncId: existing.projectSyncId,
          name: existing.projectName,
        ),
        owner,
      );
      if (project == null) throw StateError('项目已不存在或不属于当前账号');
      _checkContext(source, owner, token);
      _checkExpectedContext(expectedContext);
      await source.projectNotes.delete(id);
      _checkContext(source, owner, token);
      _checkExpectedContext(expectedContext);
    });
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed?.isNotEmpty == true ? trimmed : null;
}
