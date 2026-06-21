import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/application/initialize_work_log_feature.dart';
import 'package:life_log/features/work_log/application/load_work_log_edit_draft.dart';
import 'package:life_log/features/work_log/application/load_work_log_month.dart';
import 'package:life_log/features/work_log/application/load_work_log_today.dart';
import 'package:life_log/features/work_log/application/normalize_work_log_entries.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/data/legacy_work_log_repository_adapter.dart';
import 'package:life_log/features/work_log/data/work_log_repository.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_cubit.dart';
import 'package:life_log/features/work_log/presentation/work_log_today_cubit.dart';

GetIt configureWorkLogFeatureDependencies({
  GetIt? locator,
  WorkLogRepositoryPort? repository,
  DateTime Function()? initialNow,
}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<WorkLogRepository>()) {
    activeLocator.registerLazySingleton<WorkLogRepository>(
      WorkLogRepository.new,
    );
  }

  if (!activeLocator.isRegistered<WorkLogRepositoryPort>()) {
    activeLocator.registerLazySingleton<WorkLogRepositoryPort>(
      () =>
          repository ??
          LegacyWorkLogRepositoryAdapter(activeLocator<WorkLogRepository>()),
    );
  }

  if (!activeLocator.isRegistered<LoadWorkLogMonth>()) {
    activeLocator.registerLazySingleton<LoadWorkLogMonth>(
      () => LoadWorkLogMonth(activeLocator<WorkLogRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<LoadWorkLogEditDraft>()) {
    activeLocator.registerLazySingleton<LoadWorkLogEditDraft>(
      () => LoadWorkLogEditDraft(activeLocator<WorkLogRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<NormalizeWorkLogEntries>()) {
    activeLocator.registerLazySingleton<NormalizeWorkLogEntries>(
      () => NormalizeWorkLogEntries(activeLocator<WorkLogRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<InitializeWorkLogFeature>()) {
    activeLocator.registerLazySingleton<InitializeWorkLogFeature>(
      () => InitializeWorkLogFeature(
        normalizeEntries: activeLocator<NormalizeWorkLogEntries>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<LoadWorkLogToday>()) {
    activeLocator.registerLazySingleton<LoadWorkLogToday>(
      () => LoadWorkLogToday(activeLocator<WorkLogRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<SaveWorkLogEntry>()) {
    activeLocator.registerLazySingleton<SaveWorkLogEntry>(
      () => SaveWorkLogEntry(activeLocator<WorkLogRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<DeleteWorkLogEntry>()) {
    activeLocator.registerLazySingleton<DeleteWorkLogEntry>(
      () => DeleteWorkLogEntry(activeLocator<WorkLogRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<WatchWorkLogEntries>()) {
    activeLocator.registerLazySingleton<WatchWorkLogEntries>(
      () => WatchWorkLogEntries(activeLocator<WorkLogRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<WorkLogCubit>()) {
    activeLocator.registerFactory<WorkLogCubit>(
      () => WorkLogCubit(
        loadMonth: activeLocator<LoadWorkLogMonth>(),
        watchEntries: activeLocator<WatchWorkLogEntries>(),
        initialNow: initialNow,
      ),
    );
  }

  if (!activeLocator.isRegistered<WorkLogTodayCubit>()) {
    activeLocator.registerFactory<WorkLogTodayCubit>(
      () => WorkLogTodayCubit(
        loadToday: activeLocator<LoadWorkLogToday>(),
        watchEntries: activeLocator<WatchWorkLogEntries>(),
        todayProvider: initialNow,
      ),
    );
  }

  return activeLocator;
}
