import 'package:equatable/equatable.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_month_snapshot.dart';

final class WorkLogTodaySnapshot extends Equatable {
  final DateTime today;
  final WorkLogEntry? todayEntry;
  final List<WorkLogEntry> recentEntries;
  final WorkLogMonthSummary currentMonthSummary;

  const WorkLogTodaySnapshot({
    required this.today,
    required this.todayEntry,
    required this.recentEntries,
    required this.currentMonthSummary,
  });

  static WorkLogTodaySnapshot empty(DateTime today) {
    return WorkLogTodaySnapshot(
      today: today,
      todayEntry: null,
      recentEntries: const [],
      currentMonthSummary: WorkLogMonthSummary.empty,
    );
  }

  @override
  List<Object?> get props => [
    today,
    todayEntry,
    recentEntries,
    currentMonthSummary,
  ];
}
