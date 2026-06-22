import 'package:life_log/features/sync_center/domain/sync_center_repository_port.dart';

final class ResolveSyncConflict {
  final SyncCenterRepositoryPort repository;

  const ResolveSyncConflict(this.repository);

  Future<void> call(int id, {required String resolution}) {
    return repository.resolveConflict(id, resolution: resolution);
  }
}
