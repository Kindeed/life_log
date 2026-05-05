import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lunar/lunar.dart';

import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../../common/widgets/app_section_header.dart';
import '../add_log_sheet.dart';
import '../work_log_controller.dart';
import '../work_log_model.dart';

class DayLogList extends StatelessWidget {
  final DateTime date;
  final List<WorkLog> logs;
  final WorkLogController logic;

  const DayLogList({
    super.key,
    required this.date,
    required this.logs,
    required this.logic,
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
          trailing: Text(
            "农历${lunar.getMonthInChinese()}${lunar.getDayInChinese()}",
            style: TextStyle(color: textSecondary, fontSize: 12.sp),
          ),
        ),
        SizedBox(height: 10.h),
        ...logs.map(
          (log) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _DayLogCard(log: log, logic: logic),
          ),
        ),
      ],
    );
  }
}

class _DayLogCard extends StatelessWidget {
  final WorkLog log;
  final WorkLogController logic;

  const _DayLogCard({required this.log, required this.logic});

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).semanticColors;
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final meta = _metaFor(log, semantic);

    return AppCard(
      padding: EdgeInsets.all(14.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, color: meta.color, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meta.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _IconAction(
                      icon: Icons.edit_rounded,
                      color: meta.color,
                      onTap: () => _showEditSheet(log),
                    ),
                    SizedBox(width: 4.w),
                    _IconAction(
                      icon: Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                      onTap: () => _deleteLog(log),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: meta.tags
                      .map((tag) => _LogTag(label: tag, color: meta.color))
                      .toList(),
                ),
                if (log.note?.trim().isNotEmpty == true) ...[
                  SizedBox(height: 10.h),
                  Text(
                    log.note!.trim(),
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13.sp,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _LogMeta _metaFor(WorkLog log, AppSemanticColors semantic) {
    switch (log.type) {
      case LogType.work:
        return _LogMeta(
          title: "工作",
          icon: Icons.work_rounded,
          color: semantic.work,
          tags: [
            if ((log.overtimeHours ?? 0) > 0)
              "加班 ${log.overtimeHours} 小时"
            else
              "正常出勤",
          ],
        );
      case LogType.businessTrip:
        return _LogMeta(
          title: "出差",
          icon: Icons.flight_takeoff_rounded,
          color: semantic.warning,
          tags: [
            log.location?.trim().isNotEmpty == true
                ? log.location!.trim()
                : "未填写地点",
            if (log.transport?.trim().isNotEmpty == true) log.transport!.trim(),
            if ((log.expenses ?? 0) > 0) "垫付 ¥${log.expenses}",
            log.isReimbursed ? "已报销" : "待报销",
          ],
        );
      case LogType.leave:
        return _LogMeta(
          title: "请假",
          icon: Icons.spa_rounded,
          color: semantic.expense,
          tags: [
            log.location?.trim().isNotEmpty == true
                ? log.location!.trim()
                : "请假",
          ],
        );
      case LogType.rest:
        return _LogMeta(
          title: "休息",
          icon: Icons.hotel_rounded,
          color: semantic.success,
          tags: const ["休息日"],
        );
    }
  }

  void _showEditSheet(WorkLog log) {
    Get.bottomSheet(
      AddLogSheet(selectedDate: logic.selectedDay.value, existingLog: log),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _deleteLog(WorkLog log) async {
    final confirmed = await AppConfirmDialog.show(
      title: "删除记录",
      message: "确定删除这条「${_typeLabel(log.type)}」记录吗？删除后无法恢复。",
      confirmLabel: "删除",
      destructive: true,
    );
    if (confirmed) {
      await logic.deleteLog(log.id);
    }
  }

  String _typeLabel(LogType type) {
    switch (type) {
      case LogType.work:
        return "工作";
      case LogType.businessTrip:
        return "出差";
      case LogType.leave:
        return "请假";
      case LogType.rest:
        return "休息";
    }
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18.sp),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
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
  final List<String> tags;

  const _LogMeta({
    required this.title,
    required this.icon,
    required this.color,
    required this.tags,
  });
}
