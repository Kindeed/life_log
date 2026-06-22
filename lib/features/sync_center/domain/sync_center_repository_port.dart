import 'package:life_log/features/sync_center/domain/sync_center_snapshot.dart';

abstract interface class SyncCenterRepositoryPort {
  Future<SyncCenterSnapshot> loadSnapshot();

  Future<void> resolveConflict(int id, {required String resolution});
}
