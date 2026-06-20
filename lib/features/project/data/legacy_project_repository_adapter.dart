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
  Future<void> deleteEntry(ProjectEntry entry) {
    final project = Project()
      ..id = entry.id
      ..name = entry.name
      ..status = entry.status.toProjectStatus();
    return _repository.deleteProject(project);
  }
}

extension ProjectEntryMapper on Project {
  ProjectEntry toProjectEntry() {
    return ProjectEntry(
      id: id,
      name: name,
      status: status.toProjectEntryStatus(),
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
