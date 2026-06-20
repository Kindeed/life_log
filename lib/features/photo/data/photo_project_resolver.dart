import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/data/project_repository.dart';

abstract interface class PhotoProjectResolver {
  Future<PhotoLinkedProject> ensureProject(String name);
}

final class PhotoLinkedProject {
  final int id;
  final String name;

  const PhotoLinkedProject({required this.id, required this.name});
}

final class GetItPhotoProjectResolver implements PhotoProjectResolver {
  const GetItPhotoProjectResolver();

  @override
  Future<PhotoLinkedProject> ensureProject(String name) async {
    final project = await serviceLocator<ProjectRepository>().ensureProject(
      name,
    );
    return PhotoLinkedProject(id: project.id, name: project.name);
  }
}
