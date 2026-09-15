import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_section_header.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/work_log_dialogs.dart';
import 'package:lunar/lunar.dart';

class DayLogList extends StatelessWidget {
  final DateTime date;
  final List<WorkLogEntry> logs;
  final void Function(WorkLogEntry log) onEditLog;
  final Future<void> Function(WorkLogEntry log) onDeleteLog;

  const DayLogList({
    super.key,
    required this.date,
    required this.logs,
    required this.onEditLog,
    required this.onDeleteLog,
  });

  @override
  Widget build(BuildContext context) {
    final lunar = Lunar.fromDate(date);
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: "${date.month}月${date.day}日",
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logs.length > 1) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    "共 ${logs.length} 条记录",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.xs.w + 2.w),
              ],
              Text(
                "农历${lunar.getMonthInChinese()}${lunar.getDayInChinese()}",
                style: TextStyle(color: textSecondary, fontSize: 12.sp),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        ...logs.map(
          (log) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
            child: _DayLogCard(
              log: log,
              onEditLog: onEditLog,
              onDeleteLog: onDeleteLog,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayLogCard extends StatelessWidget {
  final WorkLogEntry log;
  final void Function(WorkLogEntry log) onEditLog;
  final Future<void> Function(WorkLogEntry log) onDeleteLog;

  const _DayLogCard({
    required this.log,
    required this.onEditLog,
    required this.onDeleteLog,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).semanticColors;
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = _metaFor(log, semantic);

    return AppCard(
      padding: EdgeInsets.all(AppSpacing.md.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(meta.icon, color: meta.color, size: 20.sp),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      meta.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    _DurationBadge(label: meta.duration, color: meta.color),
                    const Spacer(),
                    _IconAction(
                      icon: Icons.edit_rounded,
                      color: meta.color,
                      onTap: () => onEditLog(log),
                    ),
                    SizedBox(width: AppSpacing.xs.w),
                    _IconAction(
                      icon: Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                      onTap: () => _deleteLog(context, log),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm.h),
                Wrap(
                  spacing: AppSpacing.xs.w + 2.w,
                  runSpacing: AppSpacing.xs.h + 2.h,
                  children: meta.tags
                      .map((tag) => _LogTag(label: tag, color: meta.color))
                      .toList(),
                ),
                if (log.projectName?.trim().isNotEmpty == true) ...[
                  SizedBox(height: AppSpacing.sm.h),
                  _ProjectBadge(
                    projectName: log.projectName!.trim(),
                    stageName: log.projectStageName?.trim(),
                    color: semantic.work,
                  ),
                ],
                if (log.note?.trim().isNotEmpty == true) ...[
                  SizedBox(height: AppSpacing.sm.h),
                  _NoteBox(
                    note: log.note!.trim(),
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _LogMeta _metaFor(WorkLogEntry log, AppSemanticColors semantic) {
    switch (log.type) {
      case WorkLogEntryType.work:
        final overtime = log.overtimeHours ?? 0;
        final durationText = overtime > 0
            ? "${(8 + overtime).toStringAsFixed(1).replaceAll('.0', '')}小时"
            : "8小时";
        return _LogMeta(
          title: "工作",
          icon: overtime > 0 ? Icons.more_time_rounded : Icons.work_rounded,
          color: semantic.work,
          duration: durationText,
          tags: [if (overtime > 0) "加班 ${log.overtimeHours} 小时" else "正常出勤"],
        );
      case WorkLogEntryType.businessTrip:
        return _LogMeta(
          title: "出差",
          icon: Icons.flight_takeoff_rounded,
          color: semantic.warning,
          duration: "8小时",
          tags: [
            log.location?.trim().isNotEmpty == true
                ? log.location!.trim()
                : "未填写地点",
            if (log.transport?.trim().isNotEmpty == true) log.transport!.trim(),
            if ((log.expenses ?? 0) > 0) "垫付 ¥${log.expenses}",
            log.isReimbursed ? "已报销" : "待报销",
          ],
        );
      case WorkLogEntryType.leave:
        return _LogMeta(
          title: "请假",
          icon: Icons.spa_rounded,
          color: semantic.expense,
          duration: "8小时",
          tags: [
            log.location?.trim().isNotEmpty == true
                ? log.location!.trim()
                : "请假",
          ],
        );
      case WorkLogEntryType.rest:
        return _LogMeta(
          title: "休息",
          icon: Icons.hotel_rounded,
          color: semantic.success,
          duration: "0小时",
          tags: const ["休息日"],
        );
    }
  }

  Future<void> _deleteLog(BuildContext context, WorkLogEntry log) async {
    final confirmed = await confirmWorkLogDelete(context);
    if (!confirmed || !context.mounted) return;
    await onDeleteLog(log);
  }
}

class _DurationBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DurationBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 11.sp, color: color),
          SizedBox(width: 3.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectBadge extends StatelessWidget {
  final String projectName;
  final String? stageName;
  final Color color;

  const _ProjectBadge({
    required this.projectName,
    this.stageName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = stageName != null && stageName!.isNotEmpty
        ? '$projectName · $stageName'
        : projectName;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String note;
  final Color textSecondary;
  final bool isDark;

  const _NoteBox({
    required this.note,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.35 : 0.45,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Icon(Icons.notes_rounded, size: 13.sp, color: textSecondary),
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12.5.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Icon(icon, color: color, size: 16.sp),
      ),
    );
  }
}

class _LogTag extends StatelessWidget {
  final String label;
  final Color color;

  const _LogTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LogMeta {
  final String title;
  final IconData icon;
  final Color color;
  final String duration;
  final List<String> tags;

  const _LogMeta({
    required this.title,
    required this.icon,
    required this.color,
    required this.duration,
    required this.tags,
  });
}
