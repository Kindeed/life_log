import 'package:isar_community/isar.dart';

import '../domain/entities/subscription_billing_schedule.dart';
import '../domain/entities/subscription_entry.dart';

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

  /// Original billing currency. Conversion to CNY is display-only data.
  String currency = 'CNY';

  @enumerated
  SubscriptionCycle cycle = SubscriptionCycle.monthly;

  late DateTime nextPaymentDate;

  DateTime? anchorDate;
  DateTime? endDate;

  @enumerated
  SubscriptionRecordStatus status = SubscriptionRecordStatus.active;

  int reminderDays = 1;
  String? note;
  int? sortIndex;
}

enum SubscriptionCycle { monthly, yearly, oneTime, custom }

enum SubscriptionRecordStatus { active, paused, canceled, archived }

extension SubscriptionDomainLogic on Subscription {
  /// 计算单个订阅的年均花费
  double get yearlyCost {
    if (!status.isBillable) return 0.0;
    final p = price ?? 0.0;
    return switch (cycle) {
      SubscriptionCycle.monthly => p * 12,
      SubscriptionCycle.yearly ||
      SubscriptionCycle.oneTime ||
      SubscriptionCycle.custom => p,
    };
  }

  /// 判断该订阅在指定月份是否需要扣费，并返回费用
  double costForMonth(DateTime targetMonth) {
    if (!status.isBillable) return 0.0;
    return _billingSchedule.paymentDateInMonth(targetMonth) == null
        ? 0.0
        : price ?? 0.0;
  }

  DateTime nextOccurrenceAfter(DateTime referenceDay) =>
      _billingSchedule.nextOccurrenceAfter(referenceDay);

  SubscriptionBillingSchedule get _billingSchedule =>
      SubscriptionBillingSchedule(
        cycle: switch (cycle) {
          SubscriptionCycle.monthly => SubscriptionBillingCycle.monthly,
          SubscriptionCycle.yearly => SubscriptionBillingCycle.yearly,
          SubscriptionCycle.oneTime => SubscriptionBillingCycle.oneTime,
          SubscriptionCycle.custom => SubscriptionBillingCycle.custom,
        },
        nextPaymentDate: nextPaymentDate,
        anchorDate: anchorDate,
        endDate: endDate,
      );

  void markPaidAndAdvance({DateTime? paidAt}) {
    nextPaymentDate = nextOccurrenceAfter(
      paidAt ?? nextPaymentDate.add(const Duration(days: 1)),
    );
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
        currency != other.currency ||
        cycle != other.cycle ||
        nextPaymentDate != other.nextPaymentDate ||
        anchorDate != other.anchorDate ||
        endDate != other.endDate ||
        status != other.status ||
        reminderDays != other.reminderDays ||
        note != other.note ||
        sortIndex != other.sortIndex;
  }
}

extension SubscriptionRecordStatusLogic on SubscriptionRecordStatus {
  bool get isBillable => this == SubscriptionRecordStatus.active;
}
