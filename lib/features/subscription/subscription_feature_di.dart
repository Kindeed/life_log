import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/application/delete_subscription_entry.dart';
import 'package:life_log/features/subscription/application/load_subscription_edit_draft.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/load_subscription_today.dart';
import 'package:life_log/features/subscription/application/reorder_subscription_entries.dart';
import 'package:life_log/features/subscription/application/save_subscription_entry.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/data/legacy_subscription_repository_adapter.dart';
import 'package:life_log/features/subscription/data/subscription_repository.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/presentation/subscription_cubit.dart';
import 'package:life_log/features/subscription/presentation/subscription_today_cubit.dart';

GetIt configureSubscriptionFeatureDependencies({
  GetIt? locator,
  SubscriptionRepositoryPort? repository,
  DateTime Function()? initialNow,
}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<SubscriptionRepository>()) {
    activeLocator.registerLazySingleton<SubscriptionRepository>(
      SubscriptionRepository.new,
    );
  }

  if (!activeLocator.isRegistered<SubscriptionRepositoryPort>()) {
    activeLocator.registerLazySingleton<SubscriptionRepositoryPort>(
      () =>
          repository ??
          LegacySubscriptionRepositoryAdapter(
            activeLocator<SubscriptionRepository>(),
          ),
    );
  }

  if (!activeLocator.isRegistered<WatchSubscriptionEntries>()) {
    activeLocator.registerLazySingleton<WatchSubscriptionEntries>(
      () =>
          WatchSubscriptionEntries(activeLocator<SubscriptionRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<LoadSubscriptionEntries>()) {
    activeLocator.registerLazySingleton<LoadSubscriptionEntries>(
      () =>
          LoadSubscriptionEntries(activeLocator<SubscriptionRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<LoadSubscriptionToday>()) {
    activeLocator.registerLazySingleton<LoadSubscriptionToday>(
      () => LoadSubscriptionToday(activeLocator<SubscriptionRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<LoadSubscriptionEditDraft>()) {
    activeLocator.registerLazySingleton<LoadSubscriptionEditDraft>(
      () => LoadSubscriptionEditDraft(
        activeLocator<SubscriptionRepositoryPort>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<SaveSubscriptionEntry>()) {
    activeLocator.registerLazySingleton<SaveSubscriptionEntry>(
      () => SaveSubscriptionEntry(activeLocator<SubscriptionRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<DeleteSubscriptionEntry>()) {
    activeLocator.registerLazySingleton<DeleteSubscriptionEntry>(
      () =>
          DeleteSubscriptionEntry(activeLocator<SubscriptionRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<ReorderSubscriptionEntries>()) {
    activeLocator.registerLazySingleton<ReorderSubscriptionEntries>(
      () => ReorderSubscriptionEntries(
        activeLocator<SubscriptionRepositoryPort>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<SubscriptionCubit>()) {
    activeLocator.registerFactory<SubscriptionCubit>(
      () => SubscriptionCubit(
        loadEntries: activeLocator<LoadSubscriptionEntries>(),
        watchEntries: activeLocator<WatchSubscriptionEntries>(),
        initialNow: initialNow,
      ),
    );
  }

  if (!activeLocator.isRegistered<SubscriptionTodayCubit>()) {
    activeLocator.registerFactory<SubscriptionTodayCubit>(
      () => SubscriptionTodayCubit(
        loadToday: activeLocator<LoadSubscriptionToday>(),
        watchEntries: activeLocator<WatchSubscriptionEntries>(),
        todayProvider: initialNow,
      ),
    );
  }

  return activeLocator;
}
