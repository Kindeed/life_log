import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/data/project_repository.dart';

abstract interface class PhotoProjectResolver {
  Future<PhotoLinkedProject> ensureProject(String name, {int? projectId});
}

final class PhotoLinkedProject {
  final int id;
  final String name;

  const PhotoLinkedProject({required this.id, required this.name});
}

final class GetItPhotoProjectResolver implements PhotoProjectResolver {
  const GetItPhotoProjectResolver();

  @override
  Future<PhotoLinkedProject> ensureProject(
    String name, {
    int? projectId,
  }) async {
    final repository = serviceLocator<ProjectRepository>();
    final project = projectId == null
        ? await repository.ensureProject(name)
        : await repository.findProject(projectId, name);
    if (project == null || (projectId != null && project.id != projectId)) {
      throw StateError('项目已不存在或不属于当前账号，请重新选择项目');
    }
    return PhotoLinkedProject(id: project.id, name: project.name);
  }
}
