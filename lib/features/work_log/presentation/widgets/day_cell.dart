import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:lunar/lunar.dart';
import 'package:table_calendar/table_calendar.dart';

class DayCell extends StatelessWidget {
  final DateTime day;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final WorkLogEntry? event;
  final bool isDark;
  final Color textPrimary;

  const DayCell({
    super.key,
    required this.day,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    this.event,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = isSameDay(day, selectedDay);
    final isToday = isSameDay(day, DateTime.now());
    final lunar = Lunar.fromDate(day);
    final festivals = lunar.getFestivals();
    final jieQi = lunar.getJieQi();
    final holiday = HolidayUtil.getHoliday(
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
    );

    final status = _dayStatus(context, lunar, festivals, jieQi);
    var bottomText = status.text;
    var bottomColor = status.color;
    var bottomWeight = FontWeight.normal;
    var isSpecial = false;
    Color? statusColor;

    if (event != null) {
      final eventStatus = _eventStatus(context, event!);
      bottomText = eventStatus.text;
      bottomColor = eventStatus.color;
      bottomWeight = FontWeight.w900;
      isSpecial = true;
      statusColor = eventStatus.color;
    }

    final colorScheme = Theme.of(context).colorScheme;
    BoxDecoration? decoration;
    var dayColor = textPrimary;
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
      dayColor = colorScheme.onPrimary;
      bottomColor = colorScheme.onPrimary.withValues(alpha: 0.95);
    } else if (isToday) {
      decoration = BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primaryBlue, width: 1),
        borderRadius: BorderRadius.circular(12),
      );
      dayColor = AppColors.primaryBlue;
    }

    if (calendarFormat == CalendarFormat.month &&
        day.month != focusedDay.month &&
        !isSelected) {
      dayColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
      bottomColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
      if (isSpecial) {
        bottomColor = (statusColor ?? bottomColor).withValues(
          alpha: isDark ? 0.72 : 0.58,
        );
      }
    }

    final statusFillColor = statusColor == null
        ? Colors.transparent
        : isSelected
        ? colorScheme.onPrimary.withValues(alpha: 0.18)
        : statusColor.withValues(alpha: isDark ? 0.24 : 0.12);
    final statusBorderColor = statusColor == null
        ? Colors.transparent
        : isSelected
        ? colorScheme.onPrimary.withValues(alpha: 0.34)
        : statusColor.withValues(alpha: isDark ? 0.62 : 0.38);

    return Center(
      child: Container(
        width: 44.w,
        height: 50.h,
        margin: EdgeInsets.all(2.h),
        decoration:
            decoration ??
            BoxDecoration(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 42;
            final topPadding = holiday != null
                ? (compact ? 4.0 : 7.h)
                : (compact ? 2.0 : 3.h);
            final bottomPadding = compact ? 2.0 : 3.h;
            final contentHeight = math.max(
              20.0,
              constraints.maxHeight - topPadding - bottomPadding,
            );
            final dayFontSize = math.min(
              14.sp,
              math.max(9.0, contentHeight * 0.38),
            );
            final statusFontSize = math.min(
              9.sp,
              math.max(6.5, contentHeight * 0.26),
            );
            final verticalGap = math.min(
              2.h,
              math.max(0.5, contentHeight * 0.04),
            );
            final statusVerticalPadding = isSpecial
                ? math.min(1.h, compact ? 0.0 : 1.h)
                : 0.0;

            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      3.w,
                      topPadding,
                      3.w,
                      bottomPadding,
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
                            fontSize: dayFontSize,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: verticalGap),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSpecial ? 3.w : 0,
                              vertical: statusVerticalPadding,
                            ),
                            decoration: isSpecial
                                ? BoxDecoration(
                                    color: statusFillColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: statusBorderColor,
                                      width: 0.8,
                                    ),
                                  )
                                : null,
                            child: Text(
                              bottomText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: bottomColor,
                                fontSize: statusFontSize,
                                height: 1.05,
                                fontWeight: (isSelected || isSpecial)
                                    ? FontWeight.bold
                                    : bottomWeight,
                              ),
                            ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: compact ? 0 : 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: holiday.isWork()
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.errorContainer,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                        ),
                      ),
                      child: Text(
                        holiday.isWork() ? "班" : "休",
                        style: TextStyle(
                          fontSize: math.min(7.5.sp, compact ? 6.5 : 7.5.sp),
                          color: holiday.isWork()
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  _DayCellStatus _dayStatus(
    BuildContext context,
    Lunar lunar,
    List<String> festivals,
    String jieQi,
  ) {
    if (jieQi.isNotEmpty) {
      return _DayCellStatus(
        text: jieQi,
        color: AppColors.primaryBlue.withValues(alpha: 0.7),
      );
    }
    if (festivals.isNotEmpty) {
      return _DayCellStatus(text: festivals[0], color: AppColors.green);
    }
    return _DayCellStatus(
      text: lunar.getDayInChinese(),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  _DayCellStatus _eventStatus(BuildContext context, WorkLogEntry event) {
    final logColors = Theme.of(context).logColors;
    return switch (event.type) {
      WorkLogEntryType.work => _DayCellStatus(
        text: (event.overtimeHours ?? 0) > 0
            ? '+${_formatHours(event.overtimeHours ?? 0)}h'
            : '工',
        color: (event.overtimeHours ?? 0) > 0
            ? logColors.overtime
            : logColors.work,
      ),
      WorkLogEntryType.businessTrip => _DayCellStatus(
        text: '差',
        color: logColors.businessTrip,
      ),
      WorkLogEntryType.leave => _DayCellStatus(
        text: event.location?.trim().isNotEmpty == true
            ? event.location!.trim()
            : '假',
        color: logColors.leave,
      ),
      WorkLogEntryType.rest => _DayCellStatus(text: '休', color: logColors.rest),
    };
  }

  String _formatHours(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

final class _DayCellStatus {
  final String text;
  final Color color;

  const _DayCellStatus({required this.text, required this.color});
}
