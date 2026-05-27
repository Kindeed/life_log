import 'package:isar/isar.dart';

part 'project_model.g.dart';

@collection
class Project {
  Id id = Isar.autoIncrement;

  String? ownerUserId;
  int? remoteId;
  String? syncId;
  int remoteVersion = 0;
  DateTime? remoteUpdatedAt;
  DateTime? syncedAt;
  bool isDirty = false;
  @Index()
  DateTime? deletedAt;
  bool pendingDelete = false;

  @Index(caseSensitive: false)
  late String name;

  @enumerated
  ProjectStatus status = ProjectStatus.active;

  late DateTime createdAt;
  late DateTime updatedAt;
}

enum ProjectStatus { active, archived }

extension ProjectBusinessChanges on Project {
  bool hasBusinessChangesComparedTo(Project other) {
    return name != other.name ||
        status != other.status ||
        createdAt != other.createdAt ||
        updatedAt != other.updatedAt;
  }
}

extension ProjectStatusLabel on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.active:
        return '进行中';
      case ProjectStatus.archived:
        return '已归档';
    }
  }
}
