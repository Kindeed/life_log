import 'package:equatable/equatable.dart';

enum ProjectEntryStatus { active, archived }

final class ProjectEntry extends Equatable {
  final int id;
  final String? syncId;
  final String name;
  final ProjectEntryStatus status;
  final List<String> stageNames;

  const ProjectEntry({
    required this.id,
    this.syncId,
    required this.name,
    required this.status,
    this.stageNames = const <String>[],
  });

  String get label => status.label;

  @override
  List<Object?> get props => [id, syncId, name, status, stageNames];
}

extension ProjectEntryStatusLabel on ProjectEntryStatus {
  String get label {
    return switch (this) {
      ProjectEntryStatus.active => '进行中',
      ProjectEntryStatus.archived => '已归档',
    };
  }
}
