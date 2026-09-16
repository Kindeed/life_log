import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:life_log/common/theme/app_spacing.dart';
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        AppSpacing.sm.h,
        16.w,
        AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
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
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: 0,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 22.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('月'), tooltip: '月视图'),
              ButtonSegment(value: false, label: Text('周'), tooltip: '周视图'),
            ],
            selected: {isMonth},
            onSelectionChanged: (value) =>
                value.first ? onMonthSelected() : onWeekSelected(),
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(48, 48),
              visualDensity: VisualDensity.standard,
            ),
          ),
        ],
      ),
    );
  }
}
