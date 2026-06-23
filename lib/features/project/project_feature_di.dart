import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/load_evidence_entries.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/application/load_expense_record_entries.dart';
import 'package:life_log/features/photo/application/delete_photo_entries.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/project/application/create_project_entry.dart';
import 'package:life_log/features/project/application/delete_project_entry.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/data/legacy_project_repository_adapter.dart';
import 'package:life_log/features/project/data/project_repository.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';

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

  if (!activeLocator.isRegistered<DeleteProjectEntry>()) {
    activeLocator.registerLazySingleton<DeleteProjectEntry>(
      () => DeleteProjectEntry(
        repository: activeLocator<ProjectRepositoryPort>(),
        loadPhotoEntries: activeLocator<LoadPhotoEntries>(),
        deletePhotoEntries: activeLocator<DeletePhotoEntries>(),
        loadEvidenceEntries: activeLocator<LoadEvidenceEntries>(),
        deleteEvidenceEntry: activeLocator<DeleteEvidenceEntry>(),
        loadExpenseRecordEntries: activeLocator<LoadExpenseRecordEntries>(),
        deleteExpenseRecordEntry: activeLocator<DeleteExpenseRecordEntry>(),
        loadProjectWorkLogTrips: activeLocator<LoadProjectWorkLogTrips>(),
        saveWorkLogEntry: activeLocator<SaveWorkLogEntry>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<ProjectCubit>()) {
    activeLocator.registerFactory<ProjectCubit>(
      () => ProjectCubit(
        loadEntries: activeLocator<LoadProjectEntries>(),
        watchEntries: activeLocator<WatchProjectEntries>(),
      ),
    );
  }

  return activeLocator;
}
