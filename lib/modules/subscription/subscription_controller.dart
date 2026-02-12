import 'package:get/get.dart';
import '../../common/db/db_service.dart';
import '../../common/services/log_service.dart';
import 'subscription_model.dart';
import '../../common/services/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SubscriptionController extends GetxController {
  static SubscriptionController get to => Get.find();

  final subs = <Subscription>[].obs;
  // 控制 FAB 显示/隐藏
  final isFabVisible = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // --- 加载数据 (按 sortIndex 排序) ---
  Future<void> loadData() async {
    final list = await DbService.to.getAllSubscriptions();
    // 排序逻辑：如果 sortIndex 为 null，默认为 0
    list.sort((a, b) => (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0));
    subs.value = list;
  }

  // --- 添加/更新订阅 ---
  Future<void> addSub(Subscription sub) async {
    // 如果是新增（没有 sortIndex），把它排到最后
    sub.sortIndex ??= subs.length;
    await DbService.to.addSubscription(sub);
    await loadData();
    EventBus.instance.fire(const SubscriptionChangedEvent());
    LogService.to.info('Subscription', '添加/更新订阅: ${sub.name}');
    //Get.snackbar("成功", "已保存订阅");
  }

  // --- 删除订阅 ---
  Future<void> deleteSub(int id) async {
    await DbService.to.deleteSubscription(id);
    await loadData();
    EventBus.instance.fire(const SubscriptionChangedEvent());
    LogService.to.info('Subscription', '删除订阅 ID: $id');
  }

  // --- 排序逻辑 (按价格) ---
  void sortByPrice() {
    subs.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
  }

  // --- 排序逻辑 (按时间) ---
  void sortByDate() {
    subs.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
  }

  // --- 核心：拖拽排序逻辑 ---
  Future<void> reorderSub(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = subs.removeAt(oldIndex);
    subs.insert(newIndex, item);

    // 重新写入数据库中的顺序
    await DbService.to.reorderSubscriptions(subs);
    EventBus.instance.fire(const SubscriptionChangedEvent());
    LogService.to.info('Subscription', '重新排序订阅');
  }

  // --- 滚动监听 ---
  void onScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      if (!isFabVisible.value) isFabVisible.value = true;
    } else if (notification.direction == ScrollDirection.reverse) {
      if (isFabVisible.value) isFabVisible.value = false;
    }
  }
}
