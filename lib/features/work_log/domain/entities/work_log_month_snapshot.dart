import 'package:equatable/equatable.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

final class WorkLogMonthSummary extends Equatable {
  final double workHours;
  final int workDays;
  final int tripDays;
  final int restDays;

  const WorkLogMonthSummary({
    required this.workHours,
    required this.workDays,
    required this.tripDays,
    required this.restDays,
  });

  static const empty = WorkLogMonthSummary(
    workHours: 0,
    workDays: 0,
    tripDays: 0,
    restDays: 0,
  );

  @override
  List<Object?> get props => [workHours, workDays, tripDays, restDays];
}

final class WorkLogMonthSnapshot extends Equatable {
  final DateTime month;
  final Map<DateTime, List<WorkLogEntry>> entriesByDay;
  final WorkLogMonthSummary summary;

  const WorkLogMonthSnapshot({
    required this.month,
    required this.entriesByDay,
    required this.summary,
  });

  static WorkLogMonthSnapshot empty(DateTime month) {
    return WorkLogMonthSnapshot(
      month: month,
      entriesByDay: const {},
      summary: WorkLogMonthSummary.empty,
    );
  }

  @override
  List<Object?> get props => [month, entriesByDay, summary];
}
