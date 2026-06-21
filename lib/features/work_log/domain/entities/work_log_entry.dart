import 'package:equatable/equatable.dart';

enum WorkLogEntryType { work, rest, leave, businessTrip }

final class WorkLogEntry extends Equatable {
  final int id;
  final DateTime date;
  final WorkLogEntryType type;
  final double? overtimeHours;
  final String? location;
  final String? transport;
  final double? expenses;
  final bool isReimbursed;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkLogEntry({
    required this.id,
    required this.date,
    required this.type,
    this.overtimeHours,
    this.location,
    this.transport,
    this.expenses,
    this.isReimbursed = false,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  WorkLogEntry copyWith({
    int? id,
    DateTime? date,
    WorkLogEntryType? type,
    double? overtimeHours,
    String? location,
    String? transport,
    double? expenses,
    bool? isReimbursed,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkLogEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      location: location ?? this.location,
      transport: transport ?? this.transport,
      expenses: expenses ?? this.expenses,
      isReimbursed: isReimbursed ?? this.isReimbursed,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  DateTime get recencyTime => updatedAt ?? createdAt ?? date;

  bool isNewerThan(WorkLogEntry other) {
    final timeCompare = recencyTime.compareTo(other.recencyTime);
    if (timeCompare != 0) return timeCompare > 0;
    return id > other.id;
  }

  @override
  List<Object?> get props => [
    id,
    date,
    type,
    overtimeHours,
    location,
    transport,
    expenses,
    isReimbursed,
    note,
    createdAt,
    updatedAt,
  ];
}
