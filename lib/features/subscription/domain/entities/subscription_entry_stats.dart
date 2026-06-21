import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';

extension SubscriptionEntryStats on SubscriptionEntry {
  double get yearlyCost {
    if (!status.isBillable) return 0.0;
    final amount = price ?? 0.0;
    return switch (cycle) {
      SubscriptionBillingCycle.monthly => amount * 12,
      SubscriptionBillingCycle.yearly ||
      SubscriptionBillingCycle.oneTime ||
      SubscriptionBillingCycle.custom => amount,
    };
  }

  double costForMonth(DateTime targetMonth) {
    if (!status.isBillable) return 0.0;
    final amount = price ?? 0.0;
    final localTargetMonth = dateOnlyLocal(targetMonth);
    final localPaymentDate = dateOnlyLocal(nextPaymentDate);
    final localAnchorDate = dateOnlyLocal(anchorDate ?? nextPaymentDate);
    final localEndDate = endDate == null ? null : dateOnlyLocal(endDate!);
    if (!_monthInRange(localTargetMonth, localAnchorDate, localEndDate)) {
      return 0.0;
    }

    return switch (cycle) {
      SubscriptionBillingCycle.monthly => amount,
      SubscriptionBillingCycle.yearly
          when localAnchorDate.month == localTargetMonth.month =>
        amount,
      SubscriptionBillingCycle.oneTime
          when localPaymentDate.year == localTargetMonth.year &&
              localPaymentDate.month == localTargetMonth.month =>
        amount,
      SubscriptionBillingCycle.custom
          when localPaymentDate.year == localTargetMonth.year &&
              localPaymentDate.month == localTargetMonth.month =>
        amount,
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
      SubscriptionBillingCycle.monthly => _monthlyOccurrenceAfter(
        anchor,
        reference,
      ),
      SubscriptionBillingCycle.yearly => _yearlyOccurrenceAfter(
        anchor,
        reference,
      ),
      SubscriptionBillingCycle.oneTime ||
      SubscriptionBillingCycle.custom => candidate,
    };
  }
}

extension SubscriptionEntryListStats on Iterable<SubscriptionEntry> {
  double get totalYearlyCost {
    return fold(0.0, (sum, entry) => sum + entry.yearlyCost);
  }

  double totalCostForMonth(DateTime targetMonth) {
    return fold(0.0, (sum, entry) => sum + entry.costForMonth(targetMonth));
  }

  List<SubscriptionEntry> dueSoonFrom(
    DateTime referenceDay, {
    int daysAhead = 7,
  }) {
    final start = dateOnlyLocal(referenceDay);
    final end = start.add(Duration(days: daysAhead));
    final dueSoon = where((entry) {
      if (!entry.status.isBillable) return false;
      final paymentDay = dateOnlyLocal(entry.nextPaymentDate);
      return !paymentDay.isBefore(start) && !paymentDay.isAfter(end);
    }).toList();

    dueSoon.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return dueSoon;
  }
}

extension SubscriptionStatusLogic on SubscriptionStatus {
  bool get isBillable => this == SubscriptionStatus.active;
}

bool _monthInRange(
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

DateTime _monthlyOccurrenceAfter(DateTime anchor, DateTime reference) {
  final monthOffset =
      (reference.year - anchor.year) * 12 + reference.month - anchor.month;
  var candidate = _dateInMonth(anchor, anchor.year, anchor.month + monthOffset);
  if (candidate.isBefore(reference)) {
    candidate = _dateInMonth(anchor, candidate.year, candidate.month + 1);
  }
  return candidate;
}

DateTime _yearlyOccurrenceAfter(DateTime anchor, DateTime reference) {
  var candidate = _dateInMonth(anchor, reference.year, anchor.month);
  if (candidate.isBefore(reference)) {
    candidate = _dateInMonth(anchor, reference.year + 1, anchor.month);
  }
  return candidate;
}

DateTime _dateInMonth(DateTime anchor, int year, int month) {
  final monthStart = DateTime(year, month);
  final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
  final day = anchor.day > lastDay ? lastDay : anchor.day;
  return DateTime(monthStart.year, monthStart.month, day);
}
