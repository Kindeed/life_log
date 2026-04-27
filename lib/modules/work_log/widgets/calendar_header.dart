import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../work_log_controller.dart';

class CalendarHeader extends StatelessWidget {
  final WorkLogController logic;
  final bool isDark;
  final Color textPrimary;

  const CalendarHeader({
    super.key,
    required this.logic,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: logic.focusedDay.value,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                logic.onPageChanged(picked);
                logic.onDaySelected(picked, picked);
              }
            },
            child: Row(
              children: [
                Obx(
                  () => Text(
                    DateFormat("yyyy年M月").format(logic.focusedDay.value),
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Obx(() {
            final isMonth = logic.calendarFormat.value == CalendarFormat.month;
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildToggleItem(
                    context,
                    "月",
                    isMonth,
                    () => logic.onFormatChanged(CalendarFormat.month),
                  ),
                  _buildToggleItem(
                    context,
                    "周",
                    !isMonth,
                    () => logic.onFormatChanged(CalendarFormat.week),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    BuildContext context,
    String text,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }
}
