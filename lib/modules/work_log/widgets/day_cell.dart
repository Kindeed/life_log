import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lunar/lunar.dart';
import 'package:life_log/common/theme/app_colors.dart';
import '../work_log_controller.dart';
import '../work_log_model.dart';
// If HolidayUtil is not in lunar package, this might fail, but existing code uses it.
// Assuming it's available via imports or same package structure.
// Since strict mode is on, I'll assume it's imported via lunar or other.
// However, I can't add an import I don't know.
// I'll try to add imports I saw in work_log_view.dart

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

    if (events.isNotEmpty) {
      final log = events.first;
      isSpecial = true;
      bottomWeight = FontWeight.w900;

      if (log.type == LogType.work) {
        bottomText = (log.overtimeHours != null && log.overtimeHours! > 0)
            ? "+${log.overtimeHours}"
            : "正常";
        bottomColor = logColors.work;
      } else if (log.type == LogType.businessTrip) {
        bottomText = "出差";
        bottomColor = logColors.businessTrip;
      } else if (log.type == LogType.leave) {
        bottomText = log.location ?? "假";
        bottomColor = logColors.leave;
      } else if (log.type == LogType.rest) {
        bottomText = "休";
        bottomColor = logColors.rest;
      }
    }

    BoxDecoration? decoration;
    Color dayColor = textPrimary;
    if (isSelected) {
      decoration = BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
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

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: decoration,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: dayColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  bottomText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: bottomColor,
                    fontSize: 10.sp,
                    fontWeight: (isSelected || isSpecial)
                        ? FontWeight.bold
                        : bottomWeight,
                  ),
                ),
              ],
            ),
          ),
          if (holiday != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: holiday.isWork()
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  holiday.isWork() ? "班" : "休",
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: holiday.isWork()
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
