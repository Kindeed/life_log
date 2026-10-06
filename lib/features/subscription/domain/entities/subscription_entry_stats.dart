import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'subscription_billing_schedule.dart';
import 'subscription_currency.dart';
import 'subscription_exchange_rates.dart';

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
    return _billingSchedule.paymentDateInMonth(targetMonth) == null
        ? 0.0
        : price ?? 0.0;
  }

  double? yearlyCostInCny(SubscriptionExchangeRates rates) {
    return rates.convertToCny(yearlyCost, currency);
  }

  double? costForMonthInCny(
    DateTime targetMonth,
    SubscriptionExchangeRates rates,
  ) {
    return rates.convertToCny(costForMonth(targetMonth), currency);
  }

  DateTime nextOccurrenceAfter(DateTime referenceDay) =>
      _billingSchedule.nextOccurrenceAfter(referenceDay);

  /// The next valid charge for an active subscription, including today.
  /// Monthly/yearly records recur; one-time/custom records never auto-renew.
  DateTime? nextBillingDateOnOrAfter(DateTime referenceDay) {
    if (!status.isBillable) return null;
    return _billingSchedule.nextBillingDateOnOrAfter(referenceDay);
  }

  SubscriptionBillingSchedule get _billingSchedule =>
      SubscriptionBillingSchedule(
        cycle: cycle,
        nextPaymentDate: nextPaymentDate,
        anchorDate: anchorDate,
        endDate: endDate,
      );
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
    final end = DateTime(start.year, start.month, start.day + daysAhead);
    final dueSoon = where((entry) {
      final paymentDay = entry.nextBillingDateOnOrAfter(start);
      return paymentDay != null && !paymentDay.isAfter(end);
    }).toList();

    dueSoon.sort(
      (a, b) => a
          .nextBillingDateOnOrAfter(start)!
          .compareTo(b.nextBillingDateOnOrAfter(start)!),
    );
    return dueSoon;
  }

  /// Returns only entries whose own reminder window includes today.
  /// `reminderDays == 0` means notify on the payment day itself.
  List<SubscriptionEntry> dueForReminderFrom(DateTime referenceDay) {
    final start = dateOnlyLocal(referenceDay);
    final due = where((entry) {
      final paymentDay = entry.nextBillingDateOnOrAfter(start);
      final end = DateTime(
        start.year,
        start.month,
        start.day + entry.reminderDays,
      );
      return paymentDay != null && !paymentDay.isAfter(end);
    }).toList();
    due.sort(
      (a, b) => a
          .nextBillingDateOnOrAfter(start)!
          .compareTo(b.nextBillingDateOnOrAfter(start)!),
    );
    return due;
  }

  double totalYearlyCostInCny(SubscriptionExchangeRates rates) {
    return fold(0.0, (sum, entry) => sum + (entry.yearlyCostInCny(rates) ?? 0));
  }

  double totalCostForMonthInCny(
    DateTime targetMonth,
    SubscriptionExchangeRates rates,
  ) {
    return fold(
      0.0,
      (sum, entry) => sum + (entry.costForMonthInCny(targetMonth, rates) ?? 0),
    );
  }

  Set<SubscriptionCurrency> currenciesWithoutRates(
    SubscriptionExchangeRates rates,
  ) {
    return where(
      (entry) => (entry.price ?? 0) > 0 && !rates.hasRateFor(entry.currency),
    ).map((entry) => entry.currency).toSet();
  }
}

extension SubscriptionStatusLogic on SubscriptionStatus {
  bool get isBillable => this == SubscriptionStatus.active;
}
