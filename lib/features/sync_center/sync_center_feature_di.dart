import 'package:get_it/get_it.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/sync_center/application/load_sync_center_snapshot.dart';
import 'package:life_log/features/sync_center/application/resolve_sync_conflict.dart';
import 'package:life_log/features/sync_center/data/isar_sync_center_repository.dart';
import 'package:life_log/features/sync_center/domain/sync_center_repository_port.dart';

GetIt configureSyncCenterFeatureDependencies({GetIt? locator}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<SyncCenterRepositoryPort>()) {
    activeLocator.registerLazySingleton<SyncCenterRepositoryPort>(
      () => IsarSyncCenterRepository(activeLocator<IsarDatabase>()),
    );
  }
  if (!activeLocator.isRegistered<LoadSyncCenterSnapshot>()) {
    activeLocator.registerLazySingleton<LoadSyncCenterSnapshot>(
      () => LoadSyncCenterSnapshot(activeLocator<SyncCenterRepositoryPort>()),
    );
  }
  if (!activeLocator.isRegistered<ResolveSyncConflict>()) {
    activeLocator.registerLazySingleton<ResolveSyncConflict>(
      () => ResolveSyncConflict(activeLocator<SyncCenterRepositoryPort>()),
    );
  }

  return activeLocator;
}
