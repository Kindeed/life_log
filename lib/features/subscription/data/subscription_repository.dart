import '../../../common/services/log_service.dart';
import '../../../common/utils/record_validators.dart';
import '../../../common/utils/sync_id_policy.dart';
import 'subscription_local_data_source.dart';
import 'subscription_model.dart';
import 'subscription_sync_gateway.dart';

class SubscriptionRepository {
  SubscriptionRepository({
    SubscriptionLocalDataSource? localDataSource,
    SubscriptionSyncGateway? syncGateway,
  }) : _localDataSource =
           localDataSource ?? const DbSubscriptionLocalDataSource(),
       _syncGateway =
           syncGateway ?? const ServiceLocatorSubscriptionSyncGateway();

  final SubscriptionLocalDataSource _localDataSource;
  final SubscriptionSyncGateway _syncGateway;

  // --- 查询业务 ---
  Future<List<Subscription>> getAllSubscriptions() async {
    return await _localDataSource.getAllSubscriptions();
  }

  Stream<void> watchSubscriptions() {
    return _localDataSource.watchSubscriptions();
  }

  // --- 修改业务 ---
  Future<void> saveSubscription(Subscription sub, int currentCount) async {
    validateSubscription(sub);
    sub.syncId = ensureSyncId(sub.syncId);

    // 如果是新增（没有 sortIndex），把它排到最后
    sub.sortIndex ??= currentCount;

    // 1. 本地存储
    await _localDataSource.addSubscription(sub);

    if (!_syncGateway.isAvailable) {
      LogService.to.info('SubscriptionRepository', '本地模式：跳过云端同步');
      return;
    }

    if (sub.remoteId != null && !sub.isDirty && !sub.pendingDelete) {
      return;
    }

    // 2. 云端同步
    try {
      final success = await _syncGateway.pushSubscription(sub);
      if (!success) {
        LogService.to.error('SubscriptionRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e, stackTrace) {
      LogService.to.error('SubscriptionRepository', '云端同步失败: $e', stackTrace);
    }
  }

  // 删除业务逻辑
  Future<void> deleteSubscription(int id) async {
    final sub = await _localDataSource.markSubscriptionDeleted(id);

    try {
      if (sub == null || sub.remoteId == null) {
        await _localDataSource.purgeDeletedSubscription(id);
      } else if (!_syncGateway.isAvailable) {
        LogService.to.info('SubscriptionRepository', '本地模式：跳过云端删除');
      } else {
        final success = await _syncGateway.deleteSubscription(sub);
        if (success) {
          await _localDataSource.purgeDeletedSubscription(id);
        }
      }
    } catch (e, stackTrace) {
      LogService.to.error('SubscriptionRepository', '云端删除失败: $e', stackTrace);
    }
  }

  // 排序更新持久化
  Future<void> reorderSubscriptions(List<Subscription> subs) async {
    final changed = await _localDataSource.reorderSubscriptions(subs);
    if (changed.isEmpty) return;

    if (!_syncGateway.isAvailable) {
      LogService.to.info('SubscriptionRepository', '本地模式：跳过排序云端同步');
      return;
    }

    for (final sub in changed) {
      try {
        final success = await _syncGateway.pushSubscription(sub);
        if (!success) {
          LogService.to.error(
            'SubscriptionRepository',
            '排序云端同步未完成，保留待同步状态: ${sub.name}',
          );
        }
      } catch (e, stackTrace) {
        LogService.to.error(
          'SubscriptionRepository',
          '排序云端同步失败: $e',
          stackTrace,
        );
      }
    }
  }
}
