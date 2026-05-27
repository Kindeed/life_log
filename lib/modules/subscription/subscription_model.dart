import 'package:isar/isar.dart';

import '../../common/utils/date_utils.dart';

part 'subscription_model.g.dart';

@collection
class Subscription {
  Id id = Isar.autoIncrement;

  // Sync fields
  String? ownerUserId;
  int? remoteId;
  String? syncId;
  int remoteVersion = 0;
  DateTime? remoteUpdatedAt;
  DateTime? syncedAt;
  bool isDirty = false;
  @Index()
  DateTime? deletedAt;
  bool pendingDelete = false;

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
  double costForMonth(DateTime targetMonth) {
    final p = price ?? 0.0;
    final localTargetMonth = dateOnlyLocal(targetMonth);
    final localPaymentDate = dateOnlyLocal(nextPaymentDate);
    if (cycle == SubscriptionCycle.monthly) return p;
    if (cycle == SubscriptionCycle.yearly &&
        localPaymentDate.month == localTargetMonth.month) {
      return p;
    }
    if (cycle == SubscriptionCycle.oneTime &&
        localPaymentDate.year == localTargetMonth.year &&
        localPaymentDate.month == localTargetMonth.month) {
      return p;
    }
    return 0.0;
  }
}

extension SubscriptionListDomainLogic on Iterable<Subscription> {
  /// 计算所有订阅的年均花费总计
  double get totalYearlyCost => fold(0.0, (sum, sub) => sum + sub.yearlyCost);

  /// 计算所有订阅在指定月份的花费总计
  double totalCostForMonth(DateTime targetMonth) =>
      fold(0.0, (sum, sub) => sum + sub.costForMonth(targetMonth));
}

extension SubscriptionBusinessChanges on Subscription {
  bool hasBusinessChangesComparedTo(Subscription other) {
    return name != other.name ||
        price != other.price ||
        cycle != other.cycle ||
        nextPaymentDate != other.nextPaymentDate ||
        reminderDays != other.reminderDays ||
        note != other.note ||
        sortIndex != other.sortIndex;
  }
}
