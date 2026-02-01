import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lunar/lunar.dart';
import 'package:intl/intl.dart';
import 'work_log_controller.dart';
import 'log_model.dart';
import 'add_log_sheet.dart';

// --- 风格常量 ---
const Color kPrimaryColor = Color(0xFF1A73E8);
const Color kBgColor = Color(0xFFF7F9FC);
const Color kCardColor = Colors.white;
const double kRadius = 24.0;

class WorkLogView extends StatelessWidget {
  const WorkLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(WorkLogController());

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // 1. 顶部栏
                  _buildCustomHeader(context, logic),

                  // 2. 日历主体
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(kRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Obx(
                      () => TableCalendar<WorkLog>(
                        key: ValueKey(logic.selectedDay.value),
                        locale: 'zh_CN',
                        firstDay: DateTime(2020, 1, 1),
                        lastDay: DateTime(2030, 12, 31),
                        focusedDay: logic.focusedDay.value,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        calendarFormat: logic.calendarFormat.value,
                        headerVisible: false,
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekendStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                          weekdayStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.sp,
                          ),
                        ),
                        rowHeight: 60.h,
                        calendarStyle: const CalendarStyle(markersMaxCount: 0),
                        selectedDayPredicate: (day) =>
                            isSameDay(logic.selectedDay.value, day),
                        onDaySelected: logic.onDaySelected,
                        onPageChanged: logic.onPageChanged,
                        eventLoader: logic.getEventsForDay,
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) => null,
                          prioritizedBuilder: (context, day, focusedDay) {
                            final events = logic.getEventsForDay(day);
                            final isSelected = isSameDay(
                              day,
                              logic.selectedDay.value,
                            );
                            final isToday = isSameDay(day, DateTime.now());

                            final lunar = Lunar.fromDate(day);
                            final festivals = lunar.getFestivals();
                            final jieQi = lunar.getJieQi();
                            String dateStr =
                                "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                            final holiday = HolidayUtil.getHoliday(dateStr);

                            String bottomText = lunar.getDayInChinese();
                            Color bottomColor = Colors.grey[400]!;
                            FontWeight bottomWeight = FontWeight.normal;
                            bool isSpecial = false;

                            if (jieQi.isNotEmpty) {
                              bottomText = jieQi;
                              bottomColor = kPrimaryColor.withValues(
                                alpha: 0.7,
                              );
                            }
                            if (festivals.isNotEmpty) {
                              bottomText = festivals[0];
                              bottomColor = Colors.green;
                            }

                            if (events.isNotEmpty) {
                              final log = events.first;
                              isSpecial = true;
                              bottomWeight = FontWeight.w900;

                              if (log.type == LogType.work) {
                                bottomText =
                                    (log.overtimeHours != null &&
                                        log.overtimeHours! > 0)
                                    ? "+${log.overtimeHours}"
                                    : "正常";
                                bottomColor = kPrimaryColor;
                              } else if (log.type == LogType.businessTrip) {
                                bottomText = "出差";
                                bottomColor = Colors.orange;
                              } else if (log.type == LogType.leave) {
                                bottomText = log.location ?? "假";
                                bottomColor = Colors.purple;
                              } else if (log.type == LogType.rest) {
                                bottomText = "休";
                                bottomColor = Colors.green;
                              }
                            }

                            BoxDecoration? decoration;
                            Color dayColor = Colors.black87;
                            if (isSelected) {
                              decoration = BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              );
                              dayColor = Colors.white;
                              bottomColor = Colors.white.withValues(alpha: 0.9);
                            } else if (isToday) {
                              decoration = BoxDecoration(
                                border: Border.all(
                                  color: kPrimaryColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              );
                              dayColor = kPrimaryColor;
                            }

                            if (logic.calendarFormat.value ==
                                    CalendarFormat.month &&
                                day.month != focusedDay.month &&
                                !isSelected) {
                              dayColor = Colors.grey.shade200;
                              bottomColor = Colors.grey.shade200;
                              if (isSpecial) {
                                bottomColor = bottomColor.withValues(
                                  alpha: 0.5,
                                );
                              }
                            }

                            return Container(
                              margin: const EdgeInsets.all(4),
                              decoration: decoration,
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            fontWeight:
                                                (isSelected || isSpecial)
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: holiday.isWork()
                                              ? Colors.grey[200]
                                              : Colors.red[50],
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
                                                ? Colors.black45
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h), // Increased spacing form Calendar
                ],
              ),
            ),
            // 3. 详情区域 - 使用 SliverFillRemaining 填满剩余空间并允许滚动
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.topCenter,
                child: Obx(() {
                  final selectedDate = logic.selectedDay.value;
                  final events = logic.getEventsForDay(selectedDate);
                  if (events.isEmpty) {
                    return _buildEmptyState(logic);
                  } else {
                    return _buildModernDetailCard(
                      context,
                      events.first,
                      logic,
                      selectedDate,
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),

      // 【核心修改】移除了 floatingActionButton
      // 现在的逻辑是：没数据点中间的大按钮，有数据点卡片上的操作区
    );
  }

  // --- 【核心修改】美化后的空状态按钮 ---
  Widget _buildEmptyState(WorkLogController logic) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 40.h),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. 更大、更淡的图标
          Icon(
            Icons.edit_calendar_rounded,
            size: 48.sp,
            color: Colors.grey[200],
          ),
          SizedBox(height: 8.h),

          Text(
            "今天还没有记录哦",
            style: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
          ),
          SizedBox(height: 24.h),

          // 2. 居中的核心操作按钮
          SizedBox(
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: () => _showAddSheet(logic),
              icon: Icon(Icons.add, color: Colors.white, size: 20.sp),
              label: Text(
                "记一笔",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 详情卡片 ---
  Widget _buildModernDetailCard(
    BuildContext context,
    WorkLog log,
    WorkLogController logic,
    DateTime date,
  ) {
    IconData icon;
    Color themeColor;
    String title;
    List<Widget> tags = [];

    if (log.type == LogType.work) {
      icon = Icons.work;
      themeColor = kPrimaryColor;
      title = "工作日";
      if (log.overtimeHours != null && log.overtimeHours! > 0) {
        tags.add(
          _buildTag(
            "加班 ${log.overtimeHours} 小时",
            Icons.access_time_rounded,
            Colors.orange,
          ),
        );
      } else {
        tags.add(_buildTag("正常出勤", Icons.check_circle_outline, Colors.green));
      }
    } else if (log.type == LogType.businessTrip) {
      icon = Icons.flight;
      themeColor = Colors.orange;
      title = "出差";
      tags.add(
        _buildTag(
          log.location ?? "未填写地点",
          Icons.location_on_outlined,
          Colors.blue,
        ),
      );
      if (log.transport != null && log.transport!.isNotEmpty) {
        tags.add(
          _buildTag(
            log.transport!,
            Icons.directions_transit_filled_outlined,
            Colors.teal,
          ),
        );
      }
      if (log.expenses != null && log.expenses! > 0) {
        tags.add(
          _buildTag(
            "¥${log.expenses}",
            Icons.account_balance_wallet_outlined,
            Colors.deepOrange,
          ),
        );
      }
    } else if (log.type == LogType.leave) {
      icon = Icons.spa;
      themeColor = Colors.purple;
      title = "请假";
      tags.add(
        _buildTag(log.location ?? "假期", Icons.bookmark_outline, Colors.purple),
      );
    } else {
      icon = Icons.hotel;
      themeColor = Colors.green;
      title = "休息";
      tags.add(_buildTag("享受生活", Icons.coffee, Colors.green));
    }

    final lunar = Lunar.fromDate(date);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                  color: themeColor.withValues(alpha: 0.1),
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
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${date.month}月${date.day}日 · 农历${lunar.getMonthInChinese()}${lunar.getDayInChinese()}",
                      style: TextStyle(
                        color: Colors.grey[400],
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
                    bgColor: Colors.red.withValues(alpha: 0.05),
                    onTap: () => _confirmDelete(context, logic, log.id),
                  ),
                  SizedBox(width: 12.w),
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    color: themeColor,
                    bgColor: themeColor.withValues(alpha: 0.1),
                    onTap: () => _showAddSheet(logic, log: log),
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
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Text(
                log.note!,
                style: TextStyle(
                  color: Colors.grey[600],
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

  Widget _buildCustomHeader(BuildContext context, WorkLogController logic) {
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
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.black54),
              ],
            ),
          ),
          Obx(() {
            final isMonth = logic.calendarFormat.value == CalendarFormat.month;
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildToggleItem(
                    "月",
                    isMonth,
                    () => logic.onFormatChanged(CalendarFormat.month),
                  ),
                  _buildToggleItem(
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

  Widget _buildToggleItem(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
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

  void _showAddSheet(WorkLogController logic, {WorkLog? log}) {
    Get.bottomSheet(
      AddLogSheet(selectedDate: logic.selectedDay.value, existingLog: log),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
