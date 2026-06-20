import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';

extension SubscriptionEntryStats on SubscriptionEntry {
  double get yearlyCost {
    final amount = price ?? 0.0;
    return cycle == SubscriptionBillingCycle.monthly ? amount * 12 : amount;
  }

  double costForMonth(DateTime targetMonth) {
    final amount = price ?? 0.0;
    final localTargetMonth = dateOnlyLocal(targetMonth);
    final localPaymentDate = dateOnlyLocal(nextPaymentDate);

    return switch (cycle) {
      SubscriptionBillingCycle.monthly => amount,
      SubscriptionBillingCycle.yearly
          when localPaymentDate.month == localTargetMonth.month =>
        amount,
      SubscriptionBillingCycle.oneTime
          when localPaymentDate.year == localTargetMonth.year &&
              localPaymentDate.month == localTargetMonth.month =>
        amount,
      _ => 0.0,
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
      final paymentDay = dateOnlyLocal(entry.nextPaymentDate);
      return !paymentDay.isBefore(start) && !paymentDay.isAfter(end);
    }).toList();

    dueSoon.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return dueSoon;
  }
}
