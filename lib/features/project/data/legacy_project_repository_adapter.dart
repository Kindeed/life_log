import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/project/data/project_repository.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';

final class LegacyProjectRepositoryAdapter implements ProjectRepositoryPort {
  final ProjectRepository _repository;

  const LegacyProjectRepositoryAdapter(this._repository);

  @override
  Future<List<ProjectEntry>> getAllEntries() async {
    final projects = await _repository.getAllProjects();
    return projects.map((project) => project.toProjectEntry()).toList();
  }

  @override
  Stream<void> watchEntries() => _repository.watchProjects();

  @override
  Future<ProjectEntry> ensureEntry(String name) async {
    final project = await _repository.ensureProject(name);
    return project.toProjectEntry();
  }

  @override
  Future<ProjectEntry> saveEntry(ProjectEntry entry) async {
    final project = await _repository.findProject(entry.id, entry.name);
    if (project == null) {
      throw StateError('Project not found: ${entry.name}');
    }
    project
      ..name = entry.name
      ..status = entry.status.toProjectStatus()
      ..stageNames = normalizedProjectStageNames(entry.stageNames);
    final saved = await _repository.saveProject(project);
    return saved.toProjectEntry();
  }

  @override
  Future<void> deleteEntry(ProjectEntry entry) {
    final project = Project()
      ..id = entry.id
      ..name = entry.name
      ..status = entry.status.toProjectStatus()
      ..stageNames = normalizedProjectStageNames(entry.stageNames);
    return _repository.deleteProject(project);
  }
}

List<String> normalizedProjectStageNames(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) continue;
    final key = trimmed.toLowerCase();
    if (seen.add(key)) result.add(trimmed);
  }
  return List<String>.unmodifiable(result);
}

extension ProjectEntryMapper on Project {
  ProjectEntry toProjectEntry() {
    return ProjectEntry(
      id: id,
      syncId: syncId,
      name: name,
      status: status.toProjectEntryStatus(),
      stageNames: List<String>.unmodifiable(stageNames),
    );
  }
}

extension on ProjectStatus {
  ProjectEntryStatus toProjectEntryStatus() {
    return switch (this) {
      ProjectStatus.active => ProjectEntryStatus.active,
      ProjectStatus.archived => ProjectEntryStatus.archived,
    };
  }
}

extension on ProjectEntryStatus {
  ProjectStatus toProjectStatus() {
    return switch (this) {
      ProjectEntryStatus.active => ProjectStatus.active,
      ProjectEntryStatus.archived => ProjectStatus.archived,
    };
  }
}
