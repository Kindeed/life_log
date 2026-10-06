import 'package:life_log/common/utils/date_utils.dart';
import 'subscription_entry.dart';

/// Pure calendar calculation shared by feature and legacy statistics.
/// A projected occurrence never records a payment or changes the anchor.
final class SubscriptionBillingSchedule {
  final SubscriptionBillingCycle cycle;
  final DateTime nextPaymentDate;
  final DateTime? anchorDate;
  final DateTime? endDate;

  const SubscriptionBillingSchedule({
    required this.cycle,
    required this.nextPaymentDate,
    this.anchorDate,
    this.endDate,
  });

  DateTime get _anchor => dateOnlyLocal(anchorDate ?? nextPaymentDate);

  DateTime? paymentDateInMonth(DateTime month) {
    final localMonth = dateOnlyLocal(month);
    final anchor = _anchor;
    final storedDate = dateOnlyLocal(nextPaymentDate);
    final storedInMonth =
        storedDate.year == localMonth.year &&
        storedDate.month == localMonth.month;
    final payment = switch (cycle) {
      SubscriptionBillingCycle.monthly when storedInMonth => storedDate,
      SubscriptionBillingCycle.monthly => _dateInMonth(
        anchor,
        localMonth.year,
        localMonth.month,
      ),
      SubscriptionBillingCycle.yearly when storedDate.year == localMonth.year =>
        storedInMonth ? storedDate : null,
      SubscriptionBillingCycle.yearly when anchor.month == localMonth.month =>
        _dateInMonth(anchor, localMonth.year, localMonth.month),
      SubscriptionBillingCycle.oneTime ||
      SubscriptionBillingCycle.custom => storedDate,
      _ => null,
    };
    if (payment == null ||
        payment.year != localMonth.year ||
        payment.month != localMonth.month ||
        !_inRange(payment)) {
      return null;
    }
    return payment;
  }

  DateTime? nextBillingDateOnOrAfter(DateTime referenceDay) {
    final reference = dateOnlyLocal(referenceDay);
    final candidate = nextOccurrenceAfter(reference);
    if (candidate.isBefore(reference) || !_inRange(candidate)) return null;
    return candidate;
  }

  DateTime nextOccurrenceAfter(DateTime referenceDay) {
    final reference = dateOnlyLocal(referenceDay);
    final anchor = _anchor;
    final storedDate = dateOnlyLocal(nextPaymentDate);
    if (cycle == SubscriptionBillingCycle.oneTime ||
        cycle == SubscriptionBillingCycle.custom) {
      return storedDate;
    }
    // Respect a manually scheduled future charge as well as future starts.
    final firstDate = storedDate.isBefore(anchor) ? anchor : storedDate;
    if (!firstDate.isBefore(reference)) return firstDate;

    if (cycle == SubscriptionBillingCycle.monthly) {
      var candidate = _dateInMonth(anchor, reference.year, reference.month);
      // A manually advanced charge already occupies its billing period.
      if (candidate.isBefore(reference) ||
          (candidate.year == firstDate.year &&
              candidate.month == firstDate.month)) {
        candidate = _dateInMonth(anchor, reference.year, reference.month + 1);
      }
      return candidate;
    }
    var candidate = _dateInMonth(anchor, reference.year, anchor.month);
    if (candidate.isBefore(reference) || candidate.year == firstDate.year) {
      candidate = _dateInMonth(anchor, reference.year + 1, anchor.month);
    }
    return candidate;
  }

  bool _inRange(DateTime payment) {
    return !payment.isBefore(_anchor) &&
        (endDate == null || !payment.isAfter(dateOnlyLocal(endDate!)));
  }
}

DateTime _dateInMonth(DateTime anchor, int year, int month) {
  final monthStart = DateTime(year, month);
  final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
  final day = anchor.day > lastDay ? lastDay : anchor.day;
  return DateTime(monthStart.year, monthStart.month, day);
}
