import 'package:equatable/equatable.dart';

enum ProjectEntryStatus { active, archived }

final class ProjectEntry extends Equatable {
  final int id;
  final String? syncId;
  final String name;
  final ProjectEntryStatus status;
  final bool isLocalArchive;
  final List<String> stageNames;
  final String? localCoverPath;
  final String? coverImagePath;

  const ProjectEntry({
    required this.id,
    this.syncId,
    required this.name,
    required this.status,
    this.isLocalArchive = false,
    this.stageNames = const <String>[],
    this.localCoverPath,
    this.coverImagePath,
  });

  String get label => status.label;

  @override
  List<Object?> get props => [
    id,
    syncId,
    name,
    status,
    isLocalArchive,
    stageNames,
    localCoverPath,
    coverImagePath,
  ];
}

extension ProjectEntryStatusLabel on ProjectEntryStatus {
  String get label {
    return switch (this) {
      ProjectEntryStatus.active => '进行中',
      ProjectEntryStatus.archived => '已归档',
    };
  }
}
