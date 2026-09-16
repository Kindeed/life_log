import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/application/create_project_entry.dart';
import 'package:life_log/features/project/application/delete_project_entry.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/data/legacy_project_repository_adapter.dart';
import 'package:life_log/features/project/data/project_repository.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';

GetIt configureProjectFeatureDependencies({
  GetIt? locator,
  ProjectRepositoryPort? repository,
}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<ProjectRepository>()) {
    activeLocator.registerLazySingleton<ProjectRepository>(
      ProjectRepository.new,
    );
  }

  if (!activeLocator.isRegistered<ProjectRepositoryPort>()) {
    activeLocator.registerLazySingleton<ProjectRepositoryPort>(
      () =>
          repository ??
          LegacyProjectRepositoryAdapter(activeLocator<ProjectRepository>()),
    );
  }

  if (!activeLocator.isRegistered<WatchProjectEntries>()) {
    activeLocator.registerLazySingleton<WatchProjectEntries>(
      () => WatchProjectEntries(activeLocator<ProjectRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<LoadProjectEntries>()) {
    activeLocator.registerLazySingleton<LoadProjectEntries>(
      () => LoadProjectEntries(activeLocator<ProjectRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<CreateProjectEntry>()) {
    activeLocator.registerLazySingleton<CreateProjectEntry>(
      () => CreateProjectEntry(activeLocator<ProjectRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<SaveProjectEntry>()) {
    activeLocator.registerLazySingleton<SaveProjectEntry>(
      () => SaveProjectEntry(activeLocator<ProjectRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<DeleteProjectEntry>()) {
    activeLocator.registerLazySingleton<DeleteProjectEntry>(
      () => DeleteProjectEntry(activeLocator<ProjectRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<ProjectCubit>()) {
    activeLocator.registerFactory<ProjectCubit>(
      () => ProjectCubit(
        loadEntries: activeLocator<LoadProjectEntries>(),
        watchEntries: activeLocator<WatchProjectEntries>(),
        saveEntry: activeLocator<SaveProjectEntry>(),
      ),
    );
  }

  return activeLocator;
}
