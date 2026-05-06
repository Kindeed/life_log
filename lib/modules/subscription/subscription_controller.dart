import 'dart:async';
import 'package:get/get.dart';
import '../../common/services/log_service.dart';
import 'subscription_model.dart';
import 'subscription_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum SubscriptionFilter { all, monthly, yearly, oneTime }

enum SubscriptionSortMode { manual, date, price }

class SubscriptionController extends GetxController {
  static SubscriptionController get to => Get.find();

  final subs = <Subscription>[].obs;
  // 控制 FAB 显示/隐藏
  final isFabVisible = true.obs;
  final filter = SubscriptionFilter.all.obs;
  final sortMode = SubscriptionSortMode.manual.obs;

  StreamSubscription? _dbSub;

  @override
  void onInit() {
    super.onInit();
    loadData();
    _dbSub = SubscriptionRepository.to.watchSubscriptions().listen((_) {
      loadData();
    });
  }

  @override
  void onClose() {
    _dbSub?.cancel();
    super.onClose();
  }

  // --- 加载数据 (按 sortIndex 排序) ---
  Future<void> loadData() async {
    try {
      final list = await SubscriptionRepository.to.getAllSubscriptions();
      // 排序逻辑：如果 sortIndex 为 null，默认为 0
      list.sort((a, b) => (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0));
      subs.value = list;
    } catch (e, stackTrace) {
      LogService.to.error('Subscription', '加载订阅失败: $e', stackTrace);
    }
  }

  // --- 添加/更新订阅 ---
  Future<void> addSub(Subscription sub) async {
    // 如果是新增（没有 sortIndex），把它排到最后
    final hadSortIndex = sub.sortIndex != null;
    sub.sortIndex ??= subs.length;
    if (!hadSortIndex && sub.remoteId != null) {
      sub.isDirty = true;
    }
    await SubscriptionRepository.to.saveSubscription(sub, subs.length);
    LogService.to.info('Subscription', '添加/更新订阅: ${sub.name}');
  }

  // --- 删除订阅 ---
  Future<void> deleteSub(int id) async {
    await SubscriptionRepository.to.deleteSubscription(id);
    LogService.to.info('Subscription', '删除订阅 ID: $id');
  }

  List<Subscription> get visibleSubs {
    final filtered = subs.where((sub) {
      switch (filter.value) {
        case SubscriptionFilter.all:
          return true;
        case SubscriptionFilter.monthly:
          return sub.cycle == SubscriptionCycle.monthly;
        case SubscriptionFilter.yearly:
          return sub.cycle == SubscriptionCycle.yearly;
        case SubscriptionFilter.oneTime:
          return sub.cycle == SubscriptionCycle.oneTime;
      }
    }).toList();

    switch (sortMode.value) {
      case SubscriptionSortMode.manual:
        filtered.sort((a, b) => (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0));
        break;
      case SubscriptionSortMode.date:
        filtered.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
        break;
      case SubscriptionSortMode.price:
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
    }

    return filtered;
  }

  double get currentMonthCost {
    final now = DateTime.now();
    return subs.totalCostForMonth(DateTime(now.year, now.month));
  }

  double get yearlyCost => subs.totalYearlyCost;

  List<Subscription> get dueSoonSubs {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 7));
    return subs.where((sub) {
      final date = DateTime(
        sub.nextPaymentDate.year,
        sub.nextPaymentDate.month,
        sub.nextPaymentDate.day,
      );
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList()..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
  }

  int get dueSoonCount => dueSoonSubs.length;

  void setFilter(SubscriptionFilter value) {
    filter.value = value;
  }

  void setSortMode(SubscriptionSortMode value) {
    sortMode.value = value;
  }

  // --- 核心：拖拽排序逻辑 ---
  Future<void> reorderSub(int oldIndex, int newIndex) async {
    if (filter.value != SubscriptionFilter.all ||
        sortMode.value != SubscriptionSortMode.manual) {
      return;
    }
    if (oldIndex < 0 || oldIndex >= subs.length) return;
    if (newIndex < 0) newIndex = 0;
    if (newIndex > subs.length) newIndex = subs.length;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = subs.removeAt(oldIndex);
    subs.insert(newIndex, item);

    // 重新写入数据库中的顺序
    await SubscriptionRepository.to.reorderSubscriptions(subs);
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
