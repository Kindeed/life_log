import 'package:isar/isar.dart';

part 'subscription_model.g.dart';

@collection
class Subscription {
  Id id = Isar.autoIncrement;

  // Sync fields
  int? remoteId;
  DateTime? syncedAt;
  bool isDirty = false;

  late String name;

  double? price; // 价格

  @enumerated
  // 【修改点 1】类型改为 SubscriptionCycle，默认值也对应修改
  SubscriptionCycle cycle = SubscriptionCycle.monthly;

  late DateTime nextPaymentDate;

  // --- 保留你原有的字段 ---
  int reminderDays = 1;
  String? note;
  int? sortIndex;
}

// 【修改点 2】枚举名称改为 SubscriptionCycle (配合统计页面的代码)
enum SubscriptionCycle {
  monthly,
  yearly,
  oneTime, // 保留了你原有的 oneTime
}

extension SubscriptionDomainLogic on Subscription {
  /// 计算单个订阅的年均花费
  double get yearlyCost {
    final p = price ?? 0.0;
    return cycle == SubscriptionCycle.monthly ? p * 12 : p;
  }

  /// 判断该订阅在指定月份是否需要扣费，并返回费用
  double costForMonth(int targetMonth) {
    final p = price ?? 0.0;
    if (cycle == SubscriptionCycle.monthly) return p;
    if (nextPaymentDate.month == targetMonth) return p;
    return 0.0;
  }
}

extension SubscriptionListDomainLogic on Iterable<Subscription> {
  /// 计算所有订阅的年均花费总计
  double get totalYearlyCost => fold(0.0, (sum, sub) => sum + sub.yearlyCost);

  /// 计算所有订阅在指定月份的花费总计
  double totalCostForMonth(int targetMonth) =>
      fold(0.0, (sum, sub) => sum + sub.costForMonth(targetMonth));
}
