import 'package:equatable/equatable.dart';

enum SubscriptionBillingCycle { monthly, yearly, oneTime }

final class SubscriptionEntry extends Equatable {
  final int id;
  final String name;
  final double? price;
  final SubscriptionBillingCycle cycle;
  final DateTime nextPaymentDate;
  final int reminderDays;
  final String? note;
  final int? sortIndex;

  const SubscriptionEntry({
    required this.id,
    required this.name,
    required this.price,
    required this.cycle,
    required this.nextPaymentDate,
    this.reminderDays = 1,
    this.note,
    this.sortIndex,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    cycle,
    nextPaymentDate,
    reminderDays,
    note,
    sortIndex,
  ];
}

extension SubscriptionEntryBusinessChanges on SubscriptionEntry {
  bool hasBusinessChangesComparedTo(SubscriptionEntry other) {
    return name != other.name ||
        price != other.price ||
        cycle != other.cycle ||
        nextPaymentDate != other.nextPaymentDate ||
        reminderDays != other.reminderDays ||
        note != other.note ||
        sortIndex != other.sortIndex;
  }
}
