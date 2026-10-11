import 'package:equatable/equatable.dart';

final class ProjectNoteEntry extends Equatable {
  final int id;
  final int? projectId;
  final String? projectSyncId;
  final String projectName;
  final String? projectStageName;
  final String content;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectNoteEntry({
    this.id = 0,
    this.projectId,
    this.projectSyncId,
    required this.projectName,
    this.projectStageName,
    required this.content,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    projectId,
    projectSyncId,
    projectName,
    projectStageName,
    content,
    date,
    createdAt,
    updatedAt,
  ];
}
