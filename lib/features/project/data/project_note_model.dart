import 'package:isar_community/isar.dart';

part 'project_note_model.g.dart';

/// A local project-channel record. This collection is backed up with Isar and
/// deliberately has no cloud identity, tombstone, or sync-dirty fields.
@collection
class ProjectNote {
  Id id = Isar.autoIncrement;

  String? ownerUserId;

  @Index()
  int? projectId;

  /// Identifies the parent project, never an identity for uploading this note.
  String? projectSyncId;

  late String projectName;
  String? projectStageName;
  late String content;

  @Index()
  late DateTime date;

  late DateTime createdAt;
  late DateTime updatedAt;
}
