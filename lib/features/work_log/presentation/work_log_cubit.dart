import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/work_log/application/load_work_log_month.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_month_snapshot.dart';
import 'package:life_log/features/work_log/presentation/work_log_day_metadata.dart';

enum WorkLogStatus { initial, loading, ready, failure }

enum WorkLogCalendarSpan { month, week }

final class WorkLogState extends Equatable {
  final WorkLogStatus status;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final WorkLogCalendarSpan calendarSpan;
  final Map<DateTime, List<WorkLogEntry>> entriesByDay;
  final Map<DateTime, WorkLogDayMetadata> dayMetadataByDay;
  final WorkLogMonthSummary summary;
  final AppFailure? failure;

  const WorkLogState({
    required this.status,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarSpan,
    required this.entriesByDay,
    required this.dayMetadataByDay,
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
      dayMetadataByDay: const {},
      summary: WorkLogMonthSummary.empty,
    );
  }

  List<WorkLogEntry> eventsForDay(DateTime day) {
    return entriesByDay[dateOnlyLocal(day)] ?? const [];
  }

  WorkLogDayMetadata? metadataForDay(DateTime day) {
    return dayMetadataByDay[dateOnlyLocal(day)];
  }

  WorkLogState copyWith({
    WorkLogStatus? status,
    DateTime? focusedDay,
    DateTime? selectedDay,
    WorkLogCalendarSpan? calendarSpan,
    Map<DateTime, List<WorkLogEntry>>? entriesByDay,
    Map<DateTime, WorkLogDayMetadata>? dayMetadataByDay,
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
      dayMetadataByDay: dayMetadataByDay ?? this.dayMetadataByDay,
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
    dayMetadataByDay,
    summary,
    failure,
  ];
}

final class WorkLogCubit extends Cubit<WorkLogState> {
  final LoadWorkLogMonth _loadMonth;
  final WatchWorkLogEntries _watchEntries;
  StreamSubscription<void>? _entriesSubscription;
  DateTime? _loadedMonth;
  int _monthLoadRequestId = 0;

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
    final requestId = ++_monthLoadRequestId;
    final focusedDay = state.focusedDay;
    emit(state.copyWith(status: WorkLogStatus.loading, clearFailure: true));

    final result = await _loadMonth(focusedDay);
    if (isClosed || requestId != _monthLoadRequestId) return;
    result.when(
      success: (snapshot) {
        _loadedMonth = DateTime(snapshot.month.year, snapshot.month.month);
        emit(
          state.copyWith(
            status: WorkLogStatus.ready,
            entriesByDay: snapshot.entriesByDay,
            summary: snapshot.summary,
            clearFailure: true,
          ),
        );
        _prefetchVisibleDayMetadata(state.focusedDay);
      },
      failure: (failure) {
        emit(state.copyWith(status: WorkLogStatus.failure, failure: failure));
      },
    );
  }

  void selectDay(DateTime selected, DateTime focused) {
    final nextFocused = dateOnlyLocal(focused);
    emit(
      state.copyWith(
        status: state.status == WorkLogStatus.initial
            ? WorkLogStatus.ready
            : state.status,
        selectedDay: dateOnlyLocal(selected),
        focusedDay: nextFocused,
      ),
    );
    _loadFocusedMonthIfNeeded(nextFocused);
  }

  void changeFocusedDay(DateTime focused) {
    final nextFocused = dateOnlyLocal(focused);
    emit(state.copyWith(focusedDay: nextFocused));
    _loadFocusedMonthIfNeeded(nextFocused);
  }

  void changeCalendarSpan(WorkLogCalendarSpan span) {
    emit(state.copyWith(calendarSpan: span));
    _prefetchVisibleDayMetadata(state.focusedDay);
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    return super.close();
  }

  void _loadFocusedMonthIfNeeded(DateTime focused) {
    final loadedMonth = _loadedMonth;
    if (loadedMonth != null &&
        loadedMonth.year == focused.year &&
        loadedMonth.month == focused.month) {
      return;
    }
    unawaited(loadFocusedMonth());
  }

  void _prefetchVisibleDayMetadata(DateTime focused) {
    final missingDays = _visibleDaysFor(focused, state.calendarSpan)
        .where((day) => !state.dayMetadataByDay.containsKey(day))
        .toList(growable: false);
    if (missingDays.isEmpty) return;
    unawaited(_loadDayMetadata(missingDays));
  }

  Future<void> _loadDayMetadata(List<DateTime> days) async {
    await Future<void>.delayed(Duration.zero);
    if (isClosed) return;

    final additions = <DateTime, WorkLogDayMetadata>{};
    for (final day in days) {
      additions[day] = buildWorkLogDayMetadata(day);
    }
    if (isClosed || additions.isEmpty) return;

    emit(
      state.copyWith(
        dayMetadataByDay: Map<DateTime, WorkLogDayMetadata>.unmodifiable({
          ...state.dayMetadataByDay,
          ...additions,
        }),
      ),
    );
  }

  List<DateTime> _visibleDaysFor(DateTime focused, WorkLogCalendarSpan span) {
    final localFocused = dateOnlyLocal(focused);
    final start = switch (span) {
      WorkLogCalendarSpan.week => localFocused.subtract(
        Duration(days: localFocused.weekday - DateTime.monday),
      ),
      WorkLogCalendarSpan.month =>
        DateTime(localFocused.year, localFocused.month).subtract(
          Duration(
            days:
                DateTime(localFocused.year, localFocused.month).weekday -
                DateTime.monday,
          ),
        ),
    };
    final count = span == WorkLogCalendarSpan.month ? 42 : 7;
    return List<DateTime>.generate(
      count,
      (index) => dateOnlyLocal(start.add(Duration(days: index))),
      growable: false,
    );
  }
}
