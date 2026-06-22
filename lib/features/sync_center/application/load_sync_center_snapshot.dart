import 'package:life_log/features/sync_center/domain/sync_center_repository_port.dart';
import 'package:life_log/features/sync_center/domain/sync_center_snapshot.dart';

final class LoadSyncCenterSnapshot {
  final SyncCenterRepositoryPort repository;

  const LoadSyncCenterSnapshot(this.repository);

  Future<SyncCenterSnapshot> call() {
    return repository.loadSnapshot();
  }
}
