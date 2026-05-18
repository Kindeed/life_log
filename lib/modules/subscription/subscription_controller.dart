import 'dart:async';
import 'package:get/get.dart';
import '../../common/services/log_service.dart';
import 'subscription_model.dart';
import 'subscription_repository.dart';

enum SubscriptionFilter { all, monthly, yearly, oneTime }

enum SubscriptionSortMode { manual, date, price }

class SubscriptionController extends GetxController {
  static SubscriptionController get to => Get.find();

  final subs = <Subscription>[].obs;
  final filter = SubscriptionFilter.all.obs;
  final sortMode = SubscriptionSortMode.manual.obs;
  final _derivedVersion = 0.obs;
  List<Subscription> _visibleSubsCache = const [];
  double _currentMonthCostCache = 0;
  double _yearlyCostCache = 0;
  List<Subscription> _dueSoonSubsCache = const [];

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
      _rebuildDerivedState();
    } catch (e, stackTrace) {
      LogService.to.error('Subscription', '加载订阅失败: $e', stackTrace);
    }
  }

  // --- 添加/更新订阅 ---
  Future<void> addSub(Subscription sub) async {
    try {
      // 如果是新增（没有 sortIndex），把它排到最后
      final hadSortIndex = sub.sortIndex != null;
      sub.sortIndex ??= subs.length;
      if (!hadSortIndex && sub.remoteId != null) {
        sub.isDirty = true;
      }
      await SubscriptionRepository.to.saveSubscription(sub, subs.length);
      LogService.to.info('Subscription', '添加/更新订阅: ${sub.name}');
    } catch (e, stackTrace) {
      LogService.to.error('Subscription', '保存订阅失败: $e', stackTrace);
      Get.snackbar('保存失败', e.toString());
      rethrow;
    }
  }

  // --- 删除订阅 ---
  Future<void> deleteSub(int id) async {
    try {
      await SubscriptionRepository.to.deleteSubscription(id);
      LogService.to.info('Subscription', '删除订阅 ID: $id');
    } catch (e, stackTrace) {
      LogService.to.error('Subscription', '删除订阅失败: $e', stackTrace);
      Get.snackbar('删除失败', e.toString());
      rethrow;
    }
  }

  List<Subscription> get visibleSubs {
    _derivedVersion.value;
    return _visibleSubsCache;
  }

  double get currentMonthCost {
    _derivedVersion.value;
    return _currentMonthCostCache;
  }

  double get yearlyCost {
    _derivedVersion.value;
    return _yearlyCostCache;
  }

  List<Subscription> get dueSoonSubs {
    _derivedVersion.value;
    return _dueSoonSubsCache;
  }

  int get dueSoonCount {
    _derivedVersion.value;
    return _dueSoonSubsCache.length;
  }

  void _rebuildDerivedState() {
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

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));
    final dueSoon = subs.where((sub) {
      final date = DateTime(
        sub.nextPaymentDate.year,
        sub.nextPaymentDate.month,
        sub.nextPaymentDate.day,
      );
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList()..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));

    _visibleSubsCache = filtered;
    _currentMonthCostCache = subs.totalCostForMonth(
      DateTime(now.year, now.month),
    );
    _yearlyCostCache = subs.totalYearlyCost;
    _dueSoonSubsCache = dueSoon;
    _derivedVersion.value++;
  }

  void setFilter(SubscriptionFilter value) {
    filter.value = value;
    _rebuildDerivedState();
  }

  void setSortMode(SubscriptionSortMode value) {
    sortMode.value = value;
    _rebuildDerivedState();
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
    _rebuildDerivedState();

    // 重新写入数据库中的顺序
    try {
      await SubscriptionRepository.to.reorderSubscriptions(subs);
      LogService.to.info('Subscription', '重新排序订阅');
    } catch (e, stackTrace) {
      LogService.to.error('Subscription', '重新排序订阅失败: $e', stackTrace);
      Get.snackbar('排序失败', e.toString());
      rethrow;
    }
  }
}
