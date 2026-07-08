import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/work_log_cubit.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_launcher.dart';
import 'package:life_log/features/work_log/presentation/widgets/calendar_header.dart';
import 'package:life_log/features/work_log/presentation/widgets/day_cell.dart';
import 'package:life_log/features/work_log/presentation/widgets/day_log_list.dart';
import 'package:table_calendar/table_calendar.dart';

class WorkLogView extends StatelessWidget {
  const WorkLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkLogCubit>(
      create: (_) => serviceLocator<WorkLogCubit>()..start(),
      child: const _WorkLogContent(),
    );
  }
}

class _WorkLogContent extends StatelessWidget {
  const _WorkLogContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'work_log_add_fab',
        onPressed: () {
          final cubitState = context.read<WorkLogCubit>().state;
          _openLogEdit(
            context,
            selectedDate: cubitState.selectedDay,
            existingEntry: _existingWorkEntryForDay(
              cubitState,
              cubitState.selectedDay,
            ),
          );
        },
        icon: const Icon(Icons.edit_calendar_rounded),
        label: const Text('记工时'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  BlocBuilder<WorkLogCubit, WorkLogState>(
                    buildWhen: (previous, current) =>
                        previous.focusedDay != current.focusedDay ||
                        previous.calendarSpan != current.calendarSpan,
                    builder: (context, cubitState) {
                      return CalendarHeader(
                        focusedDay: cubitState.focusedDay,
                        isMonth:
                            cubitState.calendarSpan ==
                            WorkLogCalendarSpan.month,
                        onDatePicked: (picked) =>
                            _selectCalendarDay(context, picked, picked),
                        onMonthSelected: () => _changeCalendarSpan(
                          context,
                          WorkLogCalendarSpan.month,
                        ),
                        onWeekSelected: () => _changeCalendarSpan(
                          context,
                          WorkLogCalendarSpan.week,
                        ),
                        isDark: isDark,
                        textPrimary: textPrimary,
                      );
                    },
                  ),
                  ConstrainedPage(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: AppCard(
                      padding: EdgeInsets.fromLTRB(6.w, 8.h, 6.w, 8.h),
                      child: BlocBuilder<WorkLogCubit, WorkLogState>(
                        buildWhen: (previous, current) =>
                            previous.focusedDay != current.focusedDay ||
                            previous.selectedDay != current.selectedDay ||
                            previous.calendarSpan != current.calendarSpan ||
                            previous.entriesByDay != current.entriesByDay,
                        builder: (context, cubitState) {
                          final calendarFormat = _calendarFormatFor(
                            cubitState.calendarSpan,
                          );
                          return TableCalendar<WorkLogEntry>(
                            locale: 'zh_CN',
                            firstDay: DateTime(2020, 1, 1),
                            lastDay: DateTime(2030, 12, 31),
                            focusedDay: cubitState.focusedDay,
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            calendarFormat: calendarFormat,
                            headerVisible: false,
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekendStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 12.sp,
                              ),
                              weekdayStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                            rowHeight: 58.h,
                            calendarStyle: const CalendarStyle(
                              markersMaxCount: 0,
                            ),
                            selectedDayPredicate: (day) =>
                                isSameDay(cubitState.selectedDay, day),
                            onDaySelected: (selected, focused) =>
                                _selectCalendarDay(context, selected, focused),
                            onPageChanged: (focused) {
                              context.read<WorkLogCubit>().changeFocusedDay(
                                focused,
                              );
                            },
                            eventLoader: (day) =>
                                _entriesForDay(cubitState, day),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, day, events) => null,
                              prioritizedBuilder: (context, day, focusedDay) {
                                return DayCell(
                                  day: day,
                                  focusedDay: focusedDay,
                                  selectedDay: cubitState.selectedDay,
                                  calendarFormat: calendarFormat,
                                  event: _firstEntryForDay(cubitState, day),
                                  metadata: cubitState.metadataForDay(day),
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: ConstrainedPage(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: BlocBuilder<WorkLogCubit, WorkLogState>(
                  builder: (context, cubitState) {
                    final isInitialLoading =
                        cubitState.status == WorkLogStatus.loading &&
                        cubitState.entriesByDay.isEmpty;
                    final selectedDate = cubitState.selectedDay;
                    final events = _entriesForDay(cubitState, selectedDate);

                    if (isInitialLoading) {
                      return AppCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 26.h,
                        ),
                        child: const AppLoading(label: '正在加载工时'),
                      );
                    }

                    if (events.isEmpty) {
                      return AppCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 26.h,
                        ),
                        child: const AppEmptyState(
                          icon: Icons.edit_calendar_rounded,
                          title: '这天还没有记录',
                          message: '使用右下角「记工时」添加工作、出差、请假或休息。',
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: DayLogList(
                        date: selectedDate,
                        logs: events,
                        onEditLog: (log) => _openLogSheet(
                          context,
                          selectedDate: selectedDate,
                          existingEntry: log,
                        ),
                        onDeleteLog: (log) => _deleteLog(context, log),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WorkLogEntry> _entriesForDay(WorkLogState cubitState, DateTime day) {
    return cubitState.eventsForDay(day);
  }

  WorkLogEntry? _firstEntryForDay(WorkLogState cubitState, DateTime day) {
    final events = _entriesForDay(cubitState, day);
    return events.isEmpty ? null : events.first;
  }

  WorkLogEntry? _existingWorkEntryForDay(
    WorkLogState cubitState,
    DateTime day,
  ) {
    WorkLogEntry? existingWork;
    for (final entry in _entriesForDay(cubitState, day)) {
      if (entry.type != WorkLogEntryType.work) continue;
      if (existingWork == null || entry.isNewerThan(existingWork)) {
        existingWork = entry;
      }
    }
    return existingWork;
  }

  void _openLogEdit(
    BuildContext context, {
    required DateTime selectedDate,
    WorkLogEntry? existingEntry,
  }) {
    openWorkLogEditorPage(
      context,
      selectedDate: selectedDate,
      existingEntry: existingEntry,
      initialType: WorkLogEntryType.work,
      onSavedOrDeleted: () => _refreshWorkLogState(context),
    );
  }

  void _openLogSheet(
    BuildContext context, {
    required DateTime selectedDate,
    required WorkLogEntry existingEntry,
  }) {
    openWorkLogEditorSheet(
      context,
      selectedDate: selectedDate,
      existingEntry: existingEntry,
      onSavedOrDeleted: () => _refreshWorkLogState(context),
    );
  }

  Future<void> _deleteLog(BuildContext context, WorkLogEntry entry) async {
    final result = await serviceLocator<DeleteWorkLogEntry>().call(entry.id);
    final failure = result.failureOrNull;
    if (failure != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：${failure.message}')));
      return;
    }

    if (!context.mounted) return;
    await _refreshWorkLogState(context);
  }

  Future<void> _refreshWorkLogState(BuildContext context) async {
    await context.read<WorkLogCubit>().loadFocusedMonth();
  }

  void _selectCalendarDay(
    BuildContext context,
    DateTime selected,
    DateTime focused,
  ) {
    context.read<WorkLogCubit>().selectDay(selected, focused);
  }

  void _changeCalendarSpan(BuildContext context, WorkLogCalendarSpan span) {
    context.read<WorkLogCubit>().changeCalendarSpan(span);
  }

  CalendarFormat _calendarFormatFor(WorkLogCalendarSpan span) {
    return switch (span) {
      WorkLogCalendarSpan.month => CalendarFormat.month,
      WorkLogCalendarSpan.week => CalendarFormat.week,
    };
  }
}
