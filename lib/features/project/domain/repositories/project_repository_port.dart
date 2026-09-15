import 'package:life_log/features/project/domain/entities/project_entry.dart';

abstract interface class ProjectRepositoryPort {
  Future<List<ProjectEntry>> getAllEntries();

  Stream<void> watchEntries();

  Future<ProjectEntry> ensureEntry(String name);

  Future<ProjectEntry> saveEntry(ProjectEntry entry);

  Future<ProjectEntry> saveCoverPath(
    ProjectEntry entry, {
    required String? localCoverPath,
    required String? coverImagePath,
  });

  Future<void> deleteEntry(ProjectEntry entry);
}
