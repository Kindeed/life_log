import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:life_log/modules/work_log/widgets/calendar_header.dart';
import 'package:life_log/modules/work_log/widgets/day_cell.dart';
import 'package:life_log/modules/work_log/widgets/log_detail_card.dart';
import 'work_log_controller.dart';
import 'work_log_model.dart';
import 'add_log_sheet.dart';
import '../../common/theme/app_colors.dart';

const double kRadius = 24.0;

class WorkLogView extends StatelessWidget {
  const WorkLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<WorkLogController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(kRadius),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(
                            alpha: isDark ? 0.3 : 0.03,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
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
                        calendarStyle: const CalendarStyle(markersMaxCount: 0),
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
                  SizedBox(height: 24.h),
                ],
              ),
            ),
            // 3. 详情区域
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.topCenter,
                child: Obx(() {
                  final selectedDate = logic.selectedDay.value;
                  final events = logic.getEventsForDay(selectedDate);
                  if (events.isEmpty) {
                    return _buildEmptyState(context, logic, isDark, cardColor);
                  } else {
                    return LogDetailCard(
                      log: events.first,
                      logic: logic,
                      date: selectedDate,
                      isDark: isDark,
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WorkLogController logic,
    bool isDark,
    Color cardColor,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 40.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).shadowColor.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_calendar_rounded,
            size: 48.sp,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          SizedBox(height: 8.h),
          Text(
            "今天还没有记录哦",
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: () => _showAddSheet(logic),
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20.sp,
              ),
              label: Text(
                "记一笔",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
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
