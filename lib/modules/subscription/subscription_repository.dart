import 'package:get/get.dart';
import '../../../common/db/db_service.dart';
import '../../../common/services/sync_service.dart';
import '../../../common/services/log_service.dart';
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
    // 如果是新增（没有 sortIndex），把它排到最后
    sub.sortIndex ??= currentCount;

    // 1. 本地存储
    await DbService.to.addSubscription(sub);

    // 2. 云端同步
    try {
      await SyncService.to.pushSubscription(sub);
    } catch (e) {
      LogService.to.error('SubscriptionRepository', '云端同步失败: $e');
    }
  }

  // 删除业务逻辑
  Future<void> deleteSubscription(int id) async {
    // 1. 尝试获取 remoteId
    final sub = await DbService.to.getSubscription(id);
    final remoteId = sub?.remoteId;

    // 2. 本地删除
    await DbService.to.deleteSubscription(id);

    // 3. 云端删除
    if (remoteId != null) {
      try {
        await SyncService.to.deleteSubscription(remoteId);
      } catch (e) {
        LogService.to.error('SubscriptionRepository', '云端删除失败: $e');
      }
    }
  }

  // 排序更新持久化
  Future<void> reorderSubscriptions(List<Subscription> subs) async {
    await DbService.to.reorderSubscriptions(subs);
  }
}
