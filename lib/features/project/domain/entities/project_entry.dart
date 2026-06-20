import 'package:equatable/equatable.dart';

enum ProjectEntryStatus { active, archived }

final class ProjectEntry extends Equatable {
  final int id;
  final String name;
  final ProjectEntryStatus status;

  const ProjectEntry({
    required this.id,
    required this.name,
    required this.status,
  });

  String get label => status.label;

  @override
  List<Object?> get props => [id, name, status];
}

extension ProjectEntryStatusLabel on ProjectEntryStatus {
  String get label {
    return switch (this) {
      ProjectEntryStatus.active => '进行中',
      ProjectEntryStatus.archived => '已归档',
    };
  }
}
