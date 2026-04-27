import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/modules/work_log/widgets/calendar_header.dart';
import 'package:life_log/modules/work_log/widgets/day_log_list.dart';
import 'package:life_log/modules/work_log/widgets/day_cell.dart';
import 'work_log_controller.dart';
import 'work_log_model.dart';
import 'add_log_sheet.dart';

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
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Obx(() {
                        return TableCalendar<WorkLog>(
                          key: ValueKey(
                            "${logic.selectedDay.value}_${logic.dataVersion.value}",
                          ),
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
                          rowHeight: 60.h,
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
                  SizedBox(height: 18.h),
                ],
              ),
            ),
            // 3. 详情区域
            SliverFillRemaining(
              hasScrollBody: false,
              child: ConstrainedPage(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Obx(() {
                  final selectedDate = logic.selectedDay.value;
                  final events = logic.getEventsForDay(selectedDate);
                  if (events.isEmpty) {
                    return AppCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 26.h,
                      ),
                      child: AppEmptyState(
                        icon: Icons.edit_calendar_rounded,
                        title: "这天还没有记录",
                        message: "添加工作、出差、请假或休息记录。",
                        actionLabel: "记一笔",
                        onAction: () => _showAddSheet(logic),
                      ),
                    );
                  }

                  return DayLogList(
                    date: selectedDate,
                    logs: events,
                    logic: logic,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(WorkLogController logic, {WorkLog? log}) {
    Get.bottomSheet(
      AddLogSheet(selectedDate: logic.selectedDay.value, existingLog: log),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
