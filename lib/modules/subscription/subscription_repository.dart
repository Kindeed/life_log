import 'package:get/get.dart';
import '../../../common/db/db_service.dart';
import '../../../common/services/sync_service.dart';
import '../../../common/services/log_service.dart';
import '../../../common/utils/record_validators.dart';
import '../../../common/utils/sync_id_generator.dart';
import 'subscription_model.dart';

class SubscriptionRepository extends GetxService {
  static SubscriptionRepository get to => Get.find();

  // --- 查询业务 ---
  Future<List<Subscription>> getAllSubscriptions() async {
    return await DbService.to.getAllSubscriptions();
  }

  Stream<void> watchSubscriptions() {
    return DbService.to.watchSubscriptions();
  }

  // --- 修改业务 ---
  Future<void> saveSubscription(Subscription sub, int currentCount) async {
    validateSubscription(sub);
    sub.syncId ??= SyncIdGenerator.newSyncId();

    // 如果是新增（没有 sortIndex），把它排到最后
    sub.sortIndex ??= currentCount;

    // 1. 本地存储
    await DbService.to.addSubscription(sub);

    if (!Get.isRegistered<SyncService>()) {
      LogService.to.info('SubscriptionRepository', '本地模式：跳过云端同步');
      return;
    }

    if (sub.remoteId != null && !sub.isDirty && !sub.pendingDelete) {
      return;
    }

    // 2. 云端同步
    try {
      final success = await SyncService.to.pushSubscription(sub);
      if (!success) {
        LogService.to.error('SubscriptionRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e) {
      LogService.to.error('SubscriptionRepository', '云端同步失败: $e');
    }
  }

  // 删除业务逻辑
  Future<void> deleteSubscription(int id) async {
    final sub = await DbService.to.markSubscriptionDeleted(id);

    try {
      if (sub == null || sub.remoteId == null) {
        await DbService.to.purgeDeletedSubscription(id);
      } else if (!Get.isRegistered<SyncService>()) {
        LogService.to.info('SubscriptionRepository', '本地模式：跳过云端删除');
      } else {
        final success = await SyncService.to.deleteSubscription(sub);
        if (success) {
          await DbService.to.purgeDeletedSubscription(id);
        }
      }
    } catch (e) {
      LogService.to.error('SubscriptionRepository', '云端删除失败: $e');
    }
  }

  // 排序更新持久化
  Future<void> reorderSubscriptions(List<Subscription> subs) async {
    final changed = await DbService.to.reorderSubscriptions(subs);
    if (changed.isEmpty) return;

    if (!Get.isRegistered<SyncService>()) {
      LogService.to.info('SubscriptionRepository', '本地模式：跳过排序云端同步');
      return;
    }

    for (final sub in changed) {
      try {
        final success = await SyncService.to.pushSubscription(sub);
        if (!success) {
          LogService.to.error(
            'SubscriptionRepository',
            '排序云端同步未完成，保留待同步状态: ${sub.name}',
          );
        }
      } catch (e) {
        LogService.to.error('SubscriptionRepository', '排序云端同步失败: $e');
      }
    }
  }
}
