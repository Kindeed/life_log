import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/work_log_day_metadata.dart';
import 'package:table_calendar/table_calendar.dart';

class DayCell extends StatelessWidget {
  final DateTime day;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final WorkLogEntry? event;
  final int entryCount;
  final WorkLogDayMetadata? metadata;
  final bool isDark;
  final Color textPrimary;

  const DayCell({
    super.key,
    required this.day,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    this.event,
    this.entryCount = 0,
    this.metadata,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = isSameDay(day, selectedDay);
    final today = isSameDay(day, DateTime.now());
    final outside =
        calendarFormat == CalendarFormat.month &&
        day.month != focusedDay.month &&
        !selected;
    final status = event == null ? null : _eventStatus(context, event!);
    final foreground = selected ? scheme.onPrimary : textPrimary;
    final muted = selected
        ? scheme.onPrimary.withValues(alpha: 0.88)
        : scheme.onSurfaceVariant;
    final count = entryCount > 0
        ? entryCount
        : event == null
        ? 0
        : 1;
    final holiday = metadata?.holidayIsWork;
    final label = [
      '${day.year}年${day.month}月${day.day}日',
      if (metadata != null) metadata!.text,
      if (holiday != null) holiday ? '调休上班' : '法定休息',
      if (status != null) status.text,
      if (count > 0) '共$count条记录',
    ].join('，');

    return Semantics(
      label: label,
      selected: selected,
      child: Tooltip(
        message: label,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.fast),
              curve: AppMotion.standardDecelerate,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary
                    : today
                    ? scheme.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: today && !selected
                    ? Border.all(color: scheme.primary)
                    : null,
              ),
              child: Opacity(
                opacity: outside ? 0.48 : 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 58;
                    return Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              2,
                              holiday != null
                                  ? compact
                                        ? 4
                                        : 8
                                  : compact
                                  ? 1
                                  : 3,
                              2,
                              compact ? 1 : 3,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: compact ? 12 : 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.05,
                                  ),
                                ),
                                SizedBox(height: compact ? 1 : 3),
                                Text(
                                  metadata?.text ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: compact ? 8 : 10,
                                    height: 1.1,
                                  ),
                                ),
                                if (status != null) ...[
                                  SizedBox(height: compact ? 1 : 3),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: compact ? 1 : 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      color: selected
                                          ? scheme.onPrimary.withValues(
                                              alpha: 0.15,
                                            )
                                          : status.color.withValues(
                                              alpha: isDark ? 0.20 : 0.10,
                                            ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            status.text,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: selected
                                                  ? scheme.onPrimary
                                                  : status.color,
                                              fontSize: compact ? 8 : 10,
                                              fontWeight: FontWeight.w700,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                        if (count > 1) ...[
                                          const SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              '+${count - 1}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: selected
                                                    ? scheme.onPrimary
                                                    : muted,
                                                fontSize: compact ? 7 : 8,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (holiday != null)
                          Positioned(
                            top: 2,
                            right: 3,
                            child: Text(
                              holiday ? '班' : '休',
                              style: TextStyle(
                                fontSize: compact ? 7 : 8,
                                height: 1,
                                color: selected
                                    ? scheme.onPrimary
                                    : holiday
                                    ? muted
                                    : scheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _DayCellStatus _eventStatus(BuildContext context, WorkLogEntry entry) {
    final colors = Theme.of(context).logColors;
    return switch (entry.type) {
      WorkLogEntryType.work => _DayCellStatus(
        text: (entry.overtimeHours ?? 0) > 0
            ? '+${_formatHours(entry.overtimeHours!)}h'
            : '工',
        color: (entry.overtimeHours ?? 0) > 0 ? colors.overtime : colors.work,
      ),
      WorkLogEntryType.businessTrip => _DayCellStatus(
        text: '差',
        color: colors.businessTrip,
      ),
      WorkLogEntryType.leave => _DayCellStatus(
        text: entry.location?.trim().isNotEmpty == true
            ? entry.location!.trim()
            : '假',
        color: colors.leave,
      ),
      WorkLogEntryType.rest => _DayCellStatus(text: '休', color: colors.rest),
    };
  }

  String _formatHours(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

final class _DayCellStatus {
  final String text;
  final Color color;
  const _DayCellStatus({required this.text, required this.color});
}
