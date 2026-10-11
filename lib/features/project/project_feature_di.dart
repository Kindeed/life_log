import 'package:get_it/get_it.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/application/create_project_entry.dart';
import 'package:life_log/features/project/application/delete_project_entry.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/application/delete_project_note_entry.dart';
import 'package:life_log/features/project/application/load_project_note_entries.dart';
import 'package:life_log/features/project/application/save_project_note_entry.dart';
import 'package:life_log/features/project/application/watch_project_note_entries.dart';
import 'package:life_log/features/project/data/legacy_project_repository_adapter.dart';
import 'package:life_log/features/project/data/project_repository.dart';
import 'package:life_log/features/project/data/project_note_dao.dart';
import 'package:life_log/features/project/data/project_note_repository.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

GetIt configureProjectFeatureDependencies({
  GetIt? locator,
  ProjectRepositoryPort? repository,
  ProjectNoteRepositoryPort? noteRepository,
}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<ProjectNoteRepositoryPort>()) {
    activeLocator.registerLazySingleton<ProjectNoteRepositoryPort>(() {
      if (noteRepository != null) return noteRepository;
      final db = activeLocator<DbService>();
      return ProjectNoteRepository(
        ProjectNoteDao(
          database: db.database,
          currentOwnerUserId: () => db.currentOwnerUserId,
          contextToken: () => (
            sessionEpoch: activeLocator.isRegistered<AuthService>()
                ? activeLocator<AuthService>().sessionEpoch
                : 0,
            databaseGeneration: db.databaseGeneration,
          ),
        ),
      );
    });
  }
  if (!activeLocator.isRegistered<LoadProjectNoteEntries>()) {
    activeLocator.registerLazySingleton<LoadProjectNoteEntries>(
      () => LoadProjectNoteEntries(activeLocator<ProjectNoteRepositoryPort>()),
    );
  }
  if (!activeLocator.isRegistered<WatchProjectNoteEntries>()) {
    activeLocator.registerLazySingleton<WatchProjectNoteEntries>(
      () => WatchProjectNoteEntries(
        activeLocator<ProjectNoteRepositoryPort>(),
        watchScope: () => _watchNoteOwnerScope(activeLocator),
      ),
    );
  }
  if (!activeLocator.isRegistered<SaveProjectNoteEntry>()) {
    activeLocator.registerLazySingleton<SaveProjectNoteEntry>(
      () => SaveProjectNoteEntry(activeLocator<ProjectNoteRepositoryPort>()),
    );
  }
  if (!activeLocator.isRegistered<DeleteProjectNoteEntry>()) {
    activeLocator.registerLazySingleton<DeleteProjectNoteEntry>(
      () => DeleteProjectNoteEntry(activeLocator<ProjectNoteRepositoryPort>()),
    );
  }

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

Stream<void> _watchNoteOwnerScope(GetIt locator) {
  if (!locator.isRegistered<ProfileAccountRepositoryPort>()) {
    return const Stream<void>.empty();
  }
  final account = locator<ProfileAccountRepositoryPort>();
  final initial = account.loadAccount();
  var first = true;
  return account
      .watchAccount()
      .where((snapshot) {
        if (first) {
          first = false;
          return snapshot != initial;
        }
        return true;
      })
      .map((_) {});
}
