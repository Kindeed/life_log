import 'package:isar/isar.dart';

import '../../../common/utils/date_utils.dart';

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
    final p = price ?? 0.0;
    final localTargetMonth = dateOnlyLocal(targetMonth);
    final localPaymentDate = dateOnlyLocal(nextPaymentDate);
    final localAnchorDate = dateOnlyLocal(anchorDate ?? nextPaymentDate);
    final localEndDate = endDate == null ? null : dateOnlyLocal(endDate!);
    if (!_subscriptionMonthInRange(
      localTargetMonth,
      localAnchorDate,
      localEndDate,
    )) {
      return 0.0;
    }
    return switch (cycle) {
      SubscriptionCycle.monthly => p,
      SubscriptionCycle.yearly
          when localAnchorDate.month == localTargetMonth.month =>
        p,
      SubscriptionCycle.oneTime
          when localPaymentDate.year == localTargetMonth.year &&
              localPaymentDate.month == localTargetMonth.month =>
        p,
      SubscriptionCycle.custom
          when localPaymentDate.year == localTargetMonth.year &&
              localPaymentDate.month == localTargetMonth.month =>
        p,
      _ => 0.0,
    };
  }

  DateTime nextOccurrenceAfter(DateTime referenceDay) {
    final reference = dateOnlyLocal(referenceDay);
    final anchor = dateOnlyLocal(anchorDate ?? nextPaymentDate);
    var candidate = dateOnlyLocal(nextPaymentDate);
    if (candidate.isAfter(reference) || candidate.isAtSameMomentAs(reference)) {
      return candidate;
    }

    return switch (cycle) {
      SubscriptionCycle.monthly => _subscriptionMonthlyOccurrenceAfter(
        anchor,
        reference,
      ),
      SubscriptionCycle.yearly => _subscriptionYearlyOccurrenceAfter(
        anchor,
        reference,
      ),
      SubscriptionCycle.oneTime || SubscriptionCycle.custom => candidate,
    };
  }

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

bool _subscriptionMonthInRange(
  DateTime targetMonth,
  DateTime anchorDate,
  DateTime? endDate,
) {
  final targetStart = DateTime(targetMonth.year, targetMonth.month);
  final anchorStart = DateTime(anchorDate.year, anchorDate.month);
  if (targetStart.isBefore(anchorStart)) return false;
  if (endDate == null) return true;
  final endStart = DateTime(endDate.year, endDate.month);
  return !targetStart.isAfter(endStart);
}

DateTime _subscriptionMonthlyOccurrenceAfter(
  DateTime anchor,
  DateTime reference,
) {
  final monthOffset =
      (reference.year - anchor.year) * 12 + reference.month - anchor.month;
  var candidate = _subscriptionDateInMonth(
    anchor,
    anchor.year,
    anchor.month + monthOffset,
  );
  if (candidate.isBefore(reference)) {
    candidate = _subscriptionDateInMonth(
      anchor,
      candidate.year,
      candidate.month + 1,
    );
  }
  return candidate;
}

DateTime _subscriptionYearlyOccurrenceAfter(
  DateTime anchor,
  DateTime reference,
) {
  var candidate = _subscriptionDateInMonth(
    anchor,
    reference.year,
    anchor.month,
  );
  if (candidate.isBefore(reference)) {
    candidate = _subscriptionDateInMonth(
      anchor,
      reference.year + 1,
      anchor.month,
    );
  }
  return candidate;
}

DateTime _subscriptionDateInMonth(DateTime anchor, int year, int month) {
  final monthStart = DateTime(year, month);
  final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
  final day = anchor.day > lastDay ? lastDay : anchor.day;
  return DateTime(monthStart.year, monthStart.month, day);
}
