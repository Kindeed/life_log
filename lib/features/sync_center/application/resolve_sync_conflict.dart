import 'package:life_log/features/sync_center/domain/sync_center_repository_port.dart';

final class ResolveSyncConflict {
  final SyncCenterRepositoryPort repository;

  const ResolveSyncConflict(this.repository);

  Future<void> call(int id, {required String resolution}) {
    if (!const {'keep-local', 'use-remote', 'copy'}.contains(resolution)) {
      throw ArgumentError.value(resolution, 'resolution', 'Unknown action');
    }
    return repository.resolveConflict(id, resolution: resolution);
  }
}
