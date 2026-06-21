import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/data/project_repository.dart';

abstract interface class EvidenceProjectLinker {
  Future<EvidenceLinkedProject> ensureSyncableProject(String name);
}

final class EvidenceLinkedProject {
  final int id;
  final String name;
  final String? syncId;

  const EvidenceLinkedProject({
    required this.id,
    required this.name,
    this.syncId,
  });
}

final class GetItEvidenceProjectLinker implements EvidenceProjectLinker {
  const GetItEvidenceProjectLinker();

  @override
  Future<EvidenceLinkedProject> ensureSyncableProject(String name) async {
    final project = await serviceLocator<ProjectRepository>()
        .ensureSyncableProject(name);
    return EvidenceLinkedProject(
      id: project.id,
      name: project.name,
      syncId: project.syncId,
    );
  }
}
