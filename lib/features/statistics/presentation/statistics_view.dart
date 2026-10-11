import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_section_header.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'statistics_controller.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = serviceLocator<StatisticsController>();
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("统计面板"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "刷新",
            onPressed: () => logic.refreshStats(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: logic,
        builder: (context, _) {
          return SafeArea(
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
          );
        },
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
            child: Column(
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
      child: Builder(
        builder: (context) {
          final totalDays = logic.workDays + logic.tripDays + logic.restDays;
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
                      value: logic.workHours.toStringAsFixed(1),
                      icon: Icons.timelapse_rounded,
                      color: semantic.work,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _CompactStat(
                      label: "工作天数",
                      value: "${logic.workDays}",
                      icon: Icons.work_history_rounded,
                      color: semantic.success,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _CompactStat(
                      label: "出差天数",
                      value: "${logic.tripDays}",
                      icon: Icons.business_center_rounded,
                      color: semantic.warning,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              totalDays == 0
                  ? const _EmptyPanel(message: "本月暂无工时记录")
                  : _WorkCalendar(
                      days: logic.dailyWorkStats,
                      semantic: semantic,
                    ),
            ],
          );
        },
      ),
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
      child: Builder(
        builder: (context) {
          final totalCost = logic.selectedMonthTotalCost;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(title: "财务概览"),
              SizedBox(height: 16.h),
              _TotalCostHeader(
                totalCost: totalCost,
                yearlyCost: logic.yearSubCost,
                semantic: semantic,
              ),
              SizedBox(height: 14.h),
              _CostComposition(
                subscriptionCost: logic.selectedMonthSubCost,
                expenseAmounts: logic.selectedMonthExpensesByCurrency,
                estimateNote: logic.subscriptionEstimateNote,
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
              for (final group
                  in logic.evidenceReimbursementsByCurrency.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ReimbursementGroup(
                    title: '凭证报销 · ${group.key}',
                    currency: group.key,
                    stats: group.value,
                    pendingColor: semantic.warning,
                    reimbursedColor: semantic.success,
                  ),
                ),
              if (logic.evidenceReimbursementsByCurrency.isEmpty)
                const _EmptyPanel(message: '本月暂无凭证报销金额'),
            ],
          );
        },
      ),
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
                    "人民币支出估算",
                    style: TextStyle(color: textSecondary, fontSize: 13.sp),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatCnyEstimate(totalCost),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '订阅年度人民币估算 ${formatCnyEstimate(yearlyCost)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
      ],
    );
  }
}

class _CostComposition extends StatelessWidget {
  final double subscriptionCost;
  final Map<String, double> expenseAmounts;
  final String estimateNote;
  final AppSemanticColors semantic;

  const _CostComposition({
    required this.subscriptionCost,
    required this.expenseAmounts,
    required this.estimateNote,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AmountTile(
          label: '订阅 · 人民币估算',
          value: formatCnyEstimate(subscriptionCost),
          color: semantic.expense,
        ),
        const SizedBox(height: 8),
        Text(
          estimateNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final code in (expenseAmounts.keys.toList()..sort()))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AmountTile(
              label: '一次性消费 · $code 原币种',
              value: formatMoney(expenseAmounts[code]!, currency: code),
              color: semantic.stats,
            ),
          ),
        if (expenseAmounts.isEmpty) const _EmptyPanel(message: '本月暂无一次性消费'),
        if (expenseAmounts.keys.any((code) => code != 'CNY'))
          Text(
            '外币消费按原币种列示，未计入人民币支出估算',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            style: TextStyle(color: textSecondary, fontSize: 12.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
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
  final String currency;

  const _ReimbursementGroup({
    required this.title,
    required this.stats,
    required this.pendingColor,
    required this.reimbursedColor,
    this.currency = 'CNY',
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          formatMoney(stats.total, currency: currency),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
        SizedBox(height: 10.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final pending = _AmountTile(
              label: '待报销',
              value: formatMoney(stats.pending, currency: currency),
              color: pendingColor,
            );
            final reimbursed = _AmountTile(
              label: '已报销',
              value: formatMoney(stats.reimbursed, currency: currency),
              color: reimbursedColor,
            );
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 19) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [pending, const SizedBox(height: 8), reimbursed],
              );
            }
            return Row(
              children: [
                Expanded(child: pending),
                const SizedBox(width: 10),
                Expanded(child: reimbursed),
              ],
            );
          },
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
    if (!total.isFinite || total <= 0) return const SizedBox.shrink();

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
