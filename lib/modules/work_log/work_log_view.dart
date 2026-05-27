import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/modules/work_log/widgets/calendar_header.dart';
import 'package:life_log/modules/work_log/widgets/day_log_list.dart';
import 'package:life_log/modules/work_log/widgets/day_cell.dart';
import 'package:life_log/modules/work_log/views/log_edit_view.dart';
import 'work_log_controller.dart';
import 'work_log_model.dart';

class WorkLogView extends StatelessWidget {
  const WorkLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<WorkLogController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLogEdit(logic),
        icon: const Icon(Icons.edit_calendar_rounded),
        label: const Text('记工时'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // 1. 顶部栏
                  CalendarHeader(
                    logic: logic,
                    isDark: isDark,
                    textPrimary: textPrimary,
                  ),

                  // 2. 日历主体
                  ConstrainedPage(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: AppCard(
                      padding: EdgeInsets.fromLTRB(6.w, 8.h, 6.w, 8.h),
                      child: Obx(() {
                        logic.dataVersion.value;
                        return TableCalendar<WorkLog>(
                          locale: 'zh_CN',
                          firstDay: DateTime(2020, 1, 1),
                          lastDay: DateTime(2030, 12, 31),
                          focusedDay: logic.focusedDay.value,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          calendarFormat: logic.calendarFormat.value,
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
                              isSameDay(logic.selectedDay.value, day),
                          onDaySelected: logic.onDaySelected,
                          onPageChanged: logic.onPageChanged,
                          eventLoader: logic.getEventsForDay,
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) => null,
                            prioritizedBuilder: (context, day, focusedDay) {
                              return DayCell(
                                day: day,
                                focusedDay: focusedDay,
                                logic: logic,
                                isDark: isDark,
                                textPrimary: textPrimary,
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
            // 3. 详情区域
            SliverFillRemaining(
              hasScrollBody: false,
              child: ConstrainedPage(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Obx(() {
                  logic.dataVersion.value;
                  final isInitialLoading =
                      logic.isLoading.value && logic.logsMap.isEmpty;
                  final selectedDate = logic.selectedDay.value;
                  final events = logic.getEventsForDay(selectedDate);
                  if (isInitialLoading) {
                    return AppCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 26.h,
                      ),
                      child: const AppLoading(label: "正在加载工时"),
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
                        title: "这天还没有记录",
                        message: "使用右下角「记工时」添加工作、出差、请假或休息。",
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: DayLogList(
                      date: selectedDate,
                      logs: events,
                      logic: logic,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLogEdit(WorkLogController logic) {
    final selectedDate = logic.selectedDay.value;
    Get.to(
      () => LogEditView(
        selectedDate: selectedDate,
        existingLog: logic.getLogForDay(selectedDate),
        initialType: LogType.work,
      ),
    );
  }
}
