import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_tab_header.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_load_failure.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            ConstrainedPage(
              child: AppTabHeader(
                title: '工时',
                eyebrow: '每天的投入，清晰记录',
                action: AppTabAction(
                  label: '记工时',
                  icon: Icons.edit_calendar_rounded,
                  onPressed: () {
                    final state = context.read<WorkLogCubit>().state;
                    _openLogEdit(
                      context,
                      selectedDate: state.selectedDay,
                      existingEntry: _existingWorkEntryForDay(
                        state,
                        state.selectedDay,
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                key: const PageStorageKey('work-log-scroll'),
                slivers: [
                  SliverToBoxAdapter(
                    child: ConstrainedPage(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: BlocBuilder<WorkLogCubit, WorkLogState>(
                        builder: (context, state) =>
                            _MonthSummary(state: state),
                      ),
                    ),
                  ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: AppCard(
                            padding: EdgeInsets.fromLTRB(
                              6.w,
                              AppSpacing.xs.h,
                              6.w,
                              AppSpacing.xs.h,
                            ),
                            child: BlocBuilder<WorkLogCubit, WorkLogState>(
                              buildWhen: (previous, current) =>
                                  previous.focusedDay != current.focusedDay ||
                                  previous.selectedDay != current.selectedDay ||
                                  previous.calendarSpan !=
                                      current.calendarSpan ||
                                  previous.dayMetadataByDay !=
                                      current.dayMetadataByDay ||
                                  previous.entriesByDay != current.entriesByDay,
                              builder: (context, cubitState) {
                                final calendarFormat = _calendarFormatFor(
                                  cubitState.calendarSpan,
                                );
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final scale =
                                        MediaQuery.textScalerOf(
                                          context,
                                        ).scale(14) /
                                        14;
                                    final cellWidth = constraints.maxWidth / 7;
                                    final rowHeight =
                                        (cellWidth * 1.15).clamp(54.0, 64.0) +
                                        50 *
                                            (scale - 1).clamp(
                                              0.0,
                                              double.infinity,
                                            );
                                    return TableCalendar<WorkLogEntry>(
                                      locale: 'zh_CN',
                                      firstDay: DateTime(2020, 1, 1),
                                      lastDay: DateTime(2030, 12, 31),
                                      focusedDay: cubitState.focusedDay,
                                      startingDayOfWeek:
                                          StartingDayOfWeek.monday,
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
                                      rowHeight: rowHeight,
                                      daysOfWeekHeight:
                                          24 *
                                          (MediaQuery.textScalerOf(
                                                    context,
                                                  ).scale(12) /
                                                  12)
                                              .clamp(1, double.infinity),
                                      calendarStyle: const CalendarStyle(
                                        markersMaxCount: 0,
                                      ),
                                      selectedDayPredicate: (day) => isSameDay(
                                        cubitState.selectedDay,
                                        day,
                                      ),
                                      onDaySelected: (selected, focused) =>
                                          _selectCalendarDay(
                                            context,
                                            selected,
                                            focused,
                                          ),
                                      onPageChanged: (focused) {
                                        context
                                            .read<WorkLogCubit>()
                                            .changeFocusedDay(focused);
                                      },
                                      eventLoader: (day) =>
                                          _entriesForDay(cubitState, day),
                                      calendarBuilders: CalendarBuilders(
                                        markerBuilder: (context, day, events) =>
                                            null,
                                        prioritizedBuilder:
                                            (context, day, focusedDay) {
                                              return DayCell(
                                                day: day,
                                                focusedDay: focusedDay,
                                                selectedDay:
                                                    cubitState.selectedDay,
                                                calendarFormat: calendarFormat,
                                                event: _firstEntryForDay(
                                                  cubitState,
                                                  day,
                                                ),
                                                entryCount: _entriesForDay(
                                                  cubitState,
                                                  day,
                                                ).length,
                                                metadata: cubitState
                                                    .metadataForDay(day),
                                                isDark: isDark,
                                                textPrimary: textPrimary,
                                              );
                                            },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm.h),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ConstrainedPage(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: BlocBuilder<WorkLogCubit, WorkLogState>(
                        builder: (context, cubitState) {
                          final isInitialLoading =
                              cubitState.status == WorkLogStatus.loading &&
                              cubitState.entriesByDay.isEmpty;
                          final selectedDate = cubitState.selectedDay;
                          final events = _entriesForDay(
                            cubitState,
                            selectedDate,
                          );

                          if (isInitialLoading) {
                            return AppCard(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg.w,
                                vertical: AppSpacing.xl.h,
                              ),
                              child: const AppLoading(label: '正在加载工时'),
                            );
                          }

                          if (cubitState.status == WorkLogStatus.failure &&
                              events.isEmpty) {
                            return AppLoadFailure(
                              message: '暂时无法读取工时记录，已有数据不会被删除。',
                              onRetry: context
                                  .read<WorkLogCubit>()
                                  .loadFocusedMonth,
                            );
                          }
                          if (events.isEmpty) {
                            return AppCard(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg.w,
                                vertical: AppSpacing.lg.h,
                              ),
                              child: const AppEmptyState(
                                icon: Icons.edit_calendar_rounded,
                                title: '这天还没有记录',
                                message: '使用上方「记工时」添加工作、出差、请假或休息。',
                              ),
                            );
                          }

                          final list = DayLogList(
                            date: selectedDate,
                            logs: events,
                            onEditLog: (log) => _openLogSheet(
                              context,
                              selectedDate: selectedDate,
                              existingEntry: log,
                            ),
                            onDeleteLog: (log) => _deleteLog(context, log),
                          );
                          return Column(
                            children: [
                              if (cubitState.status == WorkLogStatus.failure)
                                AppLoadFailure(
                                  compact: true,
                                  message: '刷新失败，当前显示上次读取的记录。',
                                  onRetry: context
                                      .read<WorkLogCubit>()
                                      .loadFocusedMonth,
                                ),
                              list,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
                ],
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
    if (events.isEmpty) return null;
    WorkLogEntry? latest;
    for (final entry in events) {
      if (latest == null || entry.isNewerThan(latest)) {
        latest = entry;
      }
    }
    return latest;
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
    if (!context.mounted) return;
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

class _MonthSummary extends StatelessWidget {
  final WorkLogState state;
  const _MonthSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = state.summary;
    final hours = summary.workHours;
    final value = hours == hours.roundToDouble()
        ? hours.toStringAsFixed(0)
        : hours.toStringAsFixed(1);
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.focusedDay.month}月加班',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '$value 小时',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Text(
              '${summary.workDays} 天出勤 · ${summary.tripDays} 天出差\n${summary.restDays} 天休息',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
