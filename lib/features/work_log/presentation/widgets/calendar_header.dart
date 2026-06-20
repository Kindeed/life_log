import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_date_picker.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final bool isMonth;
  final ValueChanged<DateTime> onDatePicked;
  final VoidCallback onMonthSelected;
  final VoidCallback onWeekSelected;
  final bool isDark;
  final Color textPrimary;

  const CalendarHeader({
    super.key,
    required this.focusedDay,
    required this.isMonth,
    required this.onDatePicked,
    required this.onMonthSelected,
    required this.onWeekSelected,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 14.h),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showLifeLogDatePicker(
                  context: context,
                  initialDate: focusedDay,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  onDatePicked(picked);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      DateFormat("yyyy年M月").format(focusedDay),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 27.sp,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: 0,
                        height: 1.08,
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
          ),
          SizedBox(width: 10.w),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: semantic.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleItem(context, "月", isMonth, onMonthSelected),
                _buildToggleItem(context, "周", !isMonth, onWeekSelected),
              ],
            ),
          ),
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
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: isDark ? 0.18 : 0.08),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }
}
