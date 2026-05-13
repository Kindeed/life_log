import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lunar/lunar.dart';
import 'package:life_log/common/theme/app_colors.dart';
import '../work_log_controller.dart';
import '../work_log_model.dart';

class DayCell extends StatelessWidget {
  final DateTime day;
  final DateTime focusedDay;
  final WorkLogController logic;
  final bool isDark;
  final Color textPrimary;

  const DayCell({
    super.key,
    required this.day,
    required this.focusedDay,
    required this.logic,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final events = logic.getEventsForDay(day);
    final event = events.isEmpty ? null : events.first;
    final isSelected = isSameDay(day, logic.selectedDay.value);
    final isToday = isSameDay(day, DateTime.now());

    final lunar = Lunar.fromDate(day);
    final festivals = lunar.getFestivals();
    final jieQi = lunar.getJieQi();
    String dateStr =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final holiday = HolidayUtil.getHoliday(dateStr);

    String bottomText = lunar.getDayInChinese();
    Color bottomColor = Theme.of(context).colorScheme.onSurfaceVariant;
    FontWeight bottomWeight = FontWeight.normal;
    bool isSpecial = false;

    if (jieQi.isNotEmpty) {
      bottomText = jieQi;
      bottomColor = AppColors.primaryBlue.withValues(alpha: 0.7);
    }
    if (festivals.isNotEmpty) {
      bottomText = festivals[0];
      bottomColor = AppColors.green;
    }

    // 获取自定义颜色扩展
    final logColors = Theme.of(context).logColors;

    if (event != null) {
      isSpecial = true;
      bottomWeight = FontWeight.w900;

      if (event.type == LogType.work) {
        bottomText = (event.overtimeHours ?? 0) > 0
            ? "+${_formatHours(event.overtimeHours ?? 0)}h"
            : "工";
        bottomColor = (event.overtimeHours ?? 0) > 0
            ? logColors.overtime
            : logColors.work;
      } else if (event.type == LogType.businessTrip) {
        bottomText = "差";
        bottomColor = logColors.businessTrip;
      } else if (event.type == LogType.leave) {
        bottomText = event.location?.trim().isNotEmpty == true
            ? event.location!.trim()
            : "假";
        bottomColor = logColors.leave;
      } else if (event.type == LogType.rest) {
        bottomText = "休";
        bottomColor = logColors.rest;
      }
    }

    BoxDecoration? decoration;
    Color dayColor = textPrimary;
    if (isSelected) {
      decoration = BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
      dayColor = Theme.of(context).colorScheme.onPrimary;
      bottomColor = Theme.of(
        context,
      ).colorScheme.onPrimary.withValues(alpha: 0.9);
    } else if (isToday) {
      decoration = BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primaryBlue, width: 1),
        borderRadius: BorderRadius.circular(12),
      );
      dayColor = AppColors.primaryBlue;
    }

    if (logic.calendarFormat.value == CalendarFormat.month &&
        day.month != focusedDay.month &&
        !isSelected) {
      dayColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
      bottomColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
      if (isSpecial) {
        bottomColor = bottomColor.withValues(alpha: 0.5);
      }
    }

    return Center(
      child: Container(
        width: 44.w,
        height: 50.h,
        margin: EdgeInsets.all(2.h),
        decoration:
            decoration ??
            BoxDecoration(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  3.w,
                  holiday != null ? 7.h : 3.h,
                  3.w,
                  3.h,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${day.day}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dayColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      bottomText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: bottomColor,
                        fontSize: 9.sp,
                        height: 1.05,
                        fontWeight: (isSelected || isSpecial)
                            ? FontWeight.bold
                            : bottomWeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (holiday != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: holiday.isWork()
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    holiday.isWork() ? "班" : "休",
                    style: TextStyle(
                      fontSize: 7.5.sp,
                      color: holiday.isWork()
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatHours(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}
