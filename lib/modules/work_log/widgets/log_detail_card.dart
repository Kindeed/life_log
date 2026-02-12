import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lunar/lunar.dart';
import 'package:life_log/common/theme/app_colors.dart';
import '../work_log_controller.dart';
import '../work_log_model.dart';
import '../add_log_sheet.dart';

const double kRadius = 24.0;

class LogDetailCard extends StatelessWidget {
  final WorkLog log;
  final WorkLogController logic;
  final DateTime date;
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;

  const LogDetailCard({
    super.key,
    required this.log,
    required this.logic,
    required this.date,
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color themeColor;
    String title;
    List<Widget> tags = [];

    if (log.type == LogType.work) {
      icon = Icons.work;
      themeColor = AppColors.primaryBlue;
      title = "工作日";
      if (log.overtimeHours != null && log.overtimeHours! > 0) {
        tags.add(
          _buildTag(
            "加班 ${log.overtimeHours} 小时",
            Icons.access_time_rounded,
            AppColors.orange,
            isDark,
          ),
        );
      } else {
        tags.add(
          _buildTag(
            "正常出勤",
            Icons.check_circle_outline,
            AppColors.green,
            isDark,
          ),
        );
      }
    } else if (log.type == LogType.businessTrip) {
      icon = Icons.flight;
      themeColor = AppColors.orange;
      title = "出差";
      tags.add(
        _buildTag(
          log.location ?? "未填写地点",
          Icons.location_on_outlined,
          Colors.blue,
          isDark,
        ),
      );
      if (log.transport != null && log.transport!.isNotEmpty) {
        tags.add(
          _buildTag(
            log.transport!,
            Icons.directions_transit_filled_outlined,
            Colors.teal,
            isDark,
          ),
        );
      }
      if (log.expenses != null && log.expenses! > 0) {
        tags.add(
          _buildTag(
            "¥${log.expenses}",
            Icons.account_balance_wallet_outlined,
            Colors.deepOrange,
            isDark,
          ),
        );
      }
    } else if (log.type == LogType.leave) {
      icon = Icons.spa;
      themeColor = AppColors.purple;
      title = "请假";
      tags.add(
        _buildTag(
          log.location ?? "假期",
          Icons.bookmark_outline,
          AppColors.purple,
          isDark,
        ),
      );
    } else {
      icon = Icons.hotel;
      themeColor = AppColors.green;
      title = "休息";
      tags.add(_buildTag("享受生活", Icons.coffee, AppColors.green, isDark));
    }

    final lunar = Lunar.fromDate(date);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: themeColor, size: 28.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${date.month}月${date.day}日 · 农历${lunar.getMonthInChinese()}${lunar.getDayInChinese()}",
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red.withValues(alpha: 0.8),
                    bgColor: Colors.red.withValues(alpha: isDark ? 0.15 : 0.05),
                    onTap: () => _confirmDelete(context, logic, log.id),
                  ),
                  SizedBox(width: 12.w),
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    color: themeColor,
                    bgColor: themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    onTap: () => _showAddSheet(context, logic, log: log),
                  ),
                ],
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Wrap(spacing: 8.w, runSpacing: 8.h, children: tags),
          ],
          if (log.note != null && log.note!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                ),
              ),
              child: Text(
                log.note!,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WorkLogController logic, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text("确定要清空这一天的记录吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              logic.deleteLog(id);
            },
            child: const Text(
              "删除",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(
    BuildContext context,
    WorkLogController logic, {
    WorkLog? log,
  }) {
    Get.bottomSheet(
      AddLogSheet(selectedDate: logic.selectedDay.value, existingLog: log),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
