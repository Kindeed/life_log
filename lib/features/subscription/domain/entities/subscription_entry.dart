import 'package:equatable/equatable.dart';

enum SubscriptionBillingCycle { monthly, yearly, oneTime, custom }

enum SubscriptionStatus { active, paused, canceled, archived }

final class SubscriptionEntry extends Equatable {
  final int id;
  final String name;
  final double? price;
  final SubscriptionBillingCycle cycle;
  final DateTime nextPaymentDate;
  final DateTime? anchorDate;
  final DateTime? endDate;
  final SubscriptionStatus status;
  final int reminderDays;
  final String? note;
  final int? sortIndex;

  const SubscriptionEntry({
    required this.id,
    required this.name,
    required this.price,
    required this.cycle,
    required this.nextPaymentDate,
    this.anchorDate,
    this.endDate,
    this.status = SubscriptionStatus.active,
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
    anchorDate,
    endDate,
    status,
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
        anchorDate != other.anchorDate ||
        endDate != other.endDate ||
        status != other.status ||
        reminderDays != other.reminderDays ||
        note != other.note ||
        sortIndex != other.sortIndex;
  }
}
