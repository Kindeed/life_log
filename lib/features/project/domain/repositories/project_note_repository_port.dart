import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';

abstract interface class ProjectNoteRepositoryPort {
  Future<List<ProjectNoteEntry>> getEntries(ProjectRecordScope scope);
  Stream<void> watchEntries();
  Object? captureContext();
  Future<ProjectNoteEntry> saveEntry(
    ProjectNoteEntry entry, {
    Object? expectedContext,
  });
  Future<void> deleteEntry(int id, {Object? expectedContext});
}

/// A read or command started in an account/database context that no longer
/// exists. Presentation must discard cached rows rather than keep them visible.
final class ProjectNoteContextChanged extends StateError {
  ProjectNoteContextChanged() : super('账号或数据库已变化，请重新打开项目');
}
