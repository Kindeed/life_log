import 'package:get_it/get_it.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';
import 'package:life_log/features/sync_center/application/load_sync_center_snapshot.dart';
import 'package:life_log/features/sync_center/application/resolve_sync_conflict.dart';
import 'package:life_log/features/sync_center/data/isar_sync_center_repository.dart';
import 'package:life_log/features/sync_center/data/sync_conflict_remote_gateway.dart';
import 'package:life_log/features/sync_center/domain/sync_center_repository_port.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

GetIt configureSyncCenterFeatureDependencies({GetIt? locator}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<SyncCenterRepositoryPort>()) {
    activeLocator.registerLazySingleton<SyncCenterRepositoryPort>(
      () => IsarSyncCenterRepository(
        activeLocator<IsarDatabase>(),
        currentOwnerId: () => activeLocator<DbService>().currentOwnerUserId,
        currentMutationRevision:
            activeLocator<DbService>().mutationRevisionForSyncEntity,
        captureContext: () => activeLocator.isRegistered<SyncService>()
            ? activeLocator<SyncService>().captureRunContext()
            : null,
        remoteGateway: activeLocator.isRegistered<SyncService>()
            ? SupabaseSyncConflictRemoteGateway(Supabase.instance.client)
            : null,
        runWithSyncSuspended: activeLocator.isRegistered<SyncService>()
            ? activeLocator<SyncService>().withSyncSuspended
            : null,
        requestSync: (entityName, entityKey) async {
          if (!activeLocator.isRegistered<SyncScheduler>()) return;
          await activeLocator<SyncScheduler>().requestSync(
            reason: 'conflict-resolved',
            entityName: entityName,
            entityKey: entityKey,
          );
        },
      ),
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
