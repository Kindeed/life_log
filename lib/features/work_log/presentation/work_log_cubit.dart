import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/work_log/application/load_work_log_month.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_month_snapshot.dart';

enum WorkLogStatus { initial, loading, ready, failure }

enum WorkLogCalendarSpan { month, week }

final class WorkLogState extends Equatable {
  final WorkLogStatus status;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final WorkLogCalendarSpan calendarSpan;
  final Map<DateTime, List<WorkLogEntry>> entriesByDay;
  final WorkLogMonthSummary summary;
  final AppFailure? failure;

  const WorkLogState({
    required this.status,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarSpan,
    required this.entriesByDay,
    required this.summary,
    this.failure,
  });

  factory WorkLogState.initial(DateTime now) {
    final today = dateOnlyLocal(now);
    return WorkLogState(
      status: WorkLogStatus.initial,
      focusedDay: today,
      selectedDay: today,
      calendarSpan: WorkLogCalendarSpan.month,
      entriesByDay: const {},
      summary: WorkLogMonthSummary.empty,
    );
  }

  List<WorkLogEntry> eventsForDay(DateTime day) {
    return entriesByDay[dateOnlyLocal(day)] ?? const [];
  }

  WorkLogState copyWith({
    WorkLogStatus? status,
    DateTime? focusedDay,
    DateTime? selectedDay,
    WorkLogCalendarSpan? calendarSpan,
    Map<DateTime, List<WorkLogEntry>>? entriesByDay,
    WorkLogMonthSummary? summary,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return WorkLogState(
      status: status ?? this.status,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      calendarSpan: calendarSpan ?? this.calendarSpan,
      entriesByDay: entriesByDay ?? this.entriesByDay,
      summary: summary ?? this.summary,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    focusedDay,
    selectedDay,
    calendarSpan,
    entriesByDay,
    summary,
    failure,
  ];
}

final class WorkLogCubit extends Cubit<WorkLogState> {
  final LoadWorkLogMonth _loadMonth;
  final WatchWorkLogEntries _watchEntries;
  StreamSubscription<void>? _entriesSubscription;

  WorkLogCubit({
    required LoadWorkLogMonth loadMonth,
    required WatchWorkLogEntries watchEntries,
    DateTime Function()? initialNow,
  }) : _loadMonth = loadMonth,
       _watchEntries = watchEntries,
       super(WorkLogState.initial((initialNow ?? DateTime.now)()));

  void start() {
    if (_entriesSubscription != null) return;

    unawaited(loadFocusedMonth());
    _entriesSubscription = _watchEntries().listen((_) {
      unawaited(loadFocusedMonth());
    });
  }

  Future<void> loadFocusedMonth() async {
    if (isClosed) return;
    emit(state.copyWith(status: WorkLogStatus.loading, clearFailure: true));

    final result = await _loadMonth(state.focusedDay);
    if (isClosed) return;
    result.when(
      success: (snapshot) {
        emit(
          state.copyWith(
            status: WorkLogStatus.ready,
            entriesByDay: snapshot.entriesByDay,
            summary: snapshot.summary,
            clearFailure: true,
          ),
        );
      },
      failure: (failure) {
        emit(state.copyWith(status: WorkLogStatus.failure, failure: failure));
      },
    );
  }

  void selectDay(DateTime selected, DateTime focused) {
    emit(
      state.copyWith(
        status: state.status == WorkLogStatus.initial
            ? WorkLogStatus.ready
            : state.status,
        selectedDay: dateOnlyLocal(selected),
        focusedDay: dateOnlyLocal(focused),
      ),
    );
  }

  void changeFocusedDay(DateTime focused) {
    emit(state.copyWith(focusedDay: dateOnlyLocal(focused)));
  }

  void changeCalendarSpan(WorkLogCalendarSpan span) {
    emit(state.copyWith(calendarSpan: span));
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    return super.close();
  }
}
