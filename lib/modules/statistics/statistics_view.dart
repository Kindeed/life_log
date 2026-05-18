import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/layout/constrained_page.dart';
import '../../common/theme/app_motion.dart';
import '../../common/utils/formatters.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_pill.dart';
import '../../common/widgets/app_section_header.dart';
import 'statistics_controller.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<StatisticsController>();
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("数据面板"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "刷新",
            onPressed: () => logic.refreshStats(),
          ),
        ],
      ),
      body: SafeArea(
        child: ConstrainedPage(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 30.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthSelector(logic: logic, semantic: semantic),
                SizedBox(height: 16.h),
                _WorkDistribution(logic: logic, semantic: semantic),
                SizedBox(height: 20.h),
                _FinanceOverview(logic: logic, semantic: semantic),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final StatisticsController logic;
  final AppSemanticColors semantic;

  const _MonthSelector({required this.logic, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          _MonthNavButton(
            icon: Icons.chevron_left_rounded,
            tooltip: "上个月",
            onPressed: logic.previousMonth,
            color: semantic.stats,
          ),
          Expanded(
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    logic.selectedMonthLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: logic.isCurrentMonth
                        ? AppPill(
                            key: const ValueKey("current-month-badge"),
                            label: "本月",
                            icon: Icons.today_rounded,
                            color: semantic.success,
                          )
                        : InkWell(
                            key: const ValueKey("back-to-current-month"),
                            onTap: logic.resetToCurrentMonth,
                            borderRadius: BorderRadius.circular(999),
                            child: AppPill(
                              label: "回到本月",
                              icon: Icons.keyboard_return_rounded,
                              color: semantic.work,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          _MonthNavButton(
            icon: Icons.chevron_right_rounded,
            tooltip: "下个月",
            onPressed: logic.nextMonth,
            color: semantic.stats,
          ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  const _MonthNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42.w,
          height: 42.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 24.sp, color: color),
        ),
      ),
    );
  }
}

class _WorkDistribution extends StatelessWidget {
  final StatisticsController logic;
  final AppSemanticColors semantic;

  const _WorkDistribution({required this.logic, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Obx(() {
        final totalDays =
            logic.workDays.value + logic.tripDays.value + logic.restDays.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: "工时概览"),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _CompactStat(
                    label: "加班小时",
                    value: logic.workHours.value.toStringAsFixed(1),
                    icon: Icons.timelapse_rounded,
                    color: semantic.work,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _CompactStat(
                    label: "工作天数",
                    value: "${logic.workDays.value}",
                    icon: Icons.work_history_rounded,
                    color: semantic.success,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _CompactStat(
                    label: "出差天数",
                    value: "${logic.tripDays.value}",
                    icon: Icons.business_center_rounded,
                    color: semantic.warning,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            totalDays == 0
                ? const _EmptyPanel(message: "本月暂无工时记录")
                : _WorkCalendar(days: logic.dailyWorkStats, semantic: semantic),
          ],
        );
      }),
    );
  }
}

class _FinanceOverview extends StatelessWidget {
  final StatisticsController logic;
  final AppSemanticColors semantic;

  const _FinanceOverview({required this.logic, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Obx(() {
        final totalCost = logic.selectedMonthTotalCost.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: "财务概览"),
            SizedBox(height: 16.h),
            _TotalCostHeader(
              totalCost: totalCost,
              yearlyCost: logic.yearSubCost.value,
              semantic: semantic,
            ),
            SizedBox(height: 14.h),
            _CostComposition(
              subscriptionCost: logic.selectedMonthSubCost.value,
              expenseRecordCost: logic.selectedMonthExpenseRecordCost.value,
              totalCost: totalCost,
              semantic: semantic,
            ),
            SizedBox(height: 18.h),
            _ReimbursementGroup(
              title: "出差垫付",
              stats: logic.tripReimbursement,
              pendingColor: semantic.warning,
              reimbursedColor: semantic.success,
            ),
            SizedBox(height: 14.h),
            _ReimbursementGroup(
              title: "凭证报销",
              stats: logic.evidenceReimbursement,
              pendingColor: semantic.warning,
              reimbursedColor: semantic.success,
            ),
          ],
        );
      }),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textSecondary, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

class _WorkCalendar extends StatelessWidget {
  final List<DailyWorkStat> days;
  final AppSemanticColors semantic;

  const _WorkCalendar({required this.days, required this.semantic});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const _EmptyPanel(message: "本月暂无工时记录");
    }
    const weekdayLabels = ["一", "二", "三", "四", "五", "六", "日"];
    final firstWeekdayOffset = days.first.date.weekday - 1;
    final cells = <Widget>[
      for (var i = 0; i < firstWeekdayOffset; i++) const SizedBox.shrink(),
      for (final day in days) _CalendarDayCell(day: day, semantic: semantic),
    ];

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6.h,
          crossAxisSpacing: 6.w,
          children: cells,
        ),
        SizedBox(height: 12.h),
        _WorkLegend(semantic: semantic),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DailyWorkStat day;
  final AppSemanticColors semantic;

  const _CalendarDayCell({required this.day, required this.semantic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _primaryColor(theme);
    final textColor = day.hasAnyStatus
        ? color
        : theme.colorScheme.onSurfaceVariant;
    final label = _buildStatusLabel(day);

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: day.hasAnyStatus ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.24), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${day.date.day}",
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: textColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            if (label.isNotEmpty) ...[
              SizedBox(height: 3.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildStatusLabel(DailyWorkStat day) {
    if (day.hasWork) {
      return day.overtimeHours > 0
          ? '+${_formatHours(day.overtimeHours)}h'
          : '工';
    }
    if (day.hasTrip) return '差';
    if (day.hasLeave) return '假';
    if (day.hasRest) return '休';
    return '';
  }

  Color _primaryColor(ThemeData theme) {
    if (day.hasWork) return semantic.work;
    if (day.hasTrip) return semantic.warning;
    if (day.hasLeave) return semantic.expense;
    if (day.hasRest) return semantic.success;
    return theme.colorScheme.outlineVariant;
  }

  String _formatHours(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _WorkLegend extends StatelessWidget {
  final AppSemanticColors semantic;

  const _WorkLegend({required this.semantic});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 8.h,
      children: [
        _LegendItem(label: "工作", color: semantic.work),
        _LegendItem(label: "出差", color: semantic.warning),
        _LegendItem(label: "请假", color: semantic.expense),
        _LegendItem(label: "休息", color: semantic.success),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 12.sp),
        ),
      ],
    );
  }
}

class _TotalCostHeader extends StatelessWidget {
  final double totalCost;
  final double yearlyCost;
  final AppSemanticColors semantic;

  const _TotalCostHeader({
    required this.totalCost,
    required this.yearlyCost,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: semantic.expense.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.payments_rounded,
                color: semantic.expense,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "本月总支出",
                    style: TextStyle(color: textSecondary, fontSize: 13.sp),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMoney(totalCost),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                "固定年支 ${formatMoney(yearlyCost)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(color: textSecondary, fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CostComposition extends StatelessWidget {
  final double subscriptionCost;
  final double expenseRecordCost;
  final double totalCost;
  final AppSemanticColors semantic;

  const _CostComposition({
    required this.subscriptionCost,
    required this.expenseRecordCost,
    required this.totalCost,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCost <= 0) return const _EmptyPanel(message: "本月暂无支出记录");

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AmountTile(
                label: "订阅/固定支出",
                value: formatMoney(subscriptionCost),
                color: semantic.expense,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _AmountTile(
                label: "一次性消费",
                value: formatMoney(expenseRecordCost),
                color: semantic.stats,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _StackedBar(
          firstValue: subscriptionCost,
          firstColor: semantic.expense,
          secondValue: expenseRecordCost,
          secondColor: semantic.stats,
          total: totalCost,
        ),
      ],
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textSecondary, fontSize: 12.sp),
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReimbursementGroup extends StatelessWidget {
  final String title;
  final ReimbursementStats stats;
  final Color pendingColor;
  final Color reimbursedColor;

  const _ReimbursementGroup({
    required this.title,
    required this.stats,
    required this.pendingColor,
    required this.reimbursedColor,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              formatMoney(stats.total),
              style: TextStyle(color: textSecondary, fontSize: 12.sp),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _AmountTile(
                label: "待报销",
                value: formatMoney(stats.pending),
                color: pendingColor,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _AmountTile(
                label: "已报销",
                value: formatMoney(stats.reimbursed),
                color: reimbursedColor,
              ),
            ),
          ],
        ),
        if (stats.total > 0) ...[
          SizedBox(height: 10.h),
          _StackedBar(
            firstValue: stats.pending,
            firstColor: pendingColor,
            secondValue: stats.reimbursed,
            secondColor: reimbursedColor,
            total: stats.total,
          ),
        ],
      ],
    );
  }
}

class _StackedBar extends StatelessWidget {
  final double firstValue;
  final Color firstColor;
  final double secondValue;
  final Color secondColor;
  final double total;

  const _StackedBar({
    required this.firstValue,
    required this.firstColor,
    required this.secondValue,
    required this.secondColor,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 9.h,
        child: Row(
          children: [
            if (firstValue > 0)
              Expanded(
                flex: _barFlex(firstValue),
                child: ColoredBox(color: firstColor),
              ),
            if (secondValue > 0)
              Expanded(
                flex: _barFlex(secondValue),
                child: ColoredBox(color: secondColor),
              ),
          ],
        ),
      ),
    );
  }

  int _barFlex(double value) => (value / total * 1000).round().clamp(1, 1000);
}

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}
