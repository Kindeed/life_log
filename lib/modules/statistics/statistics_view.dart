import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/layout/constrained_page.dart';
import '../../common/theme/app_motion.dart';
import '../../common/theme/app_semantic_colors.dart';
import '../../common/utils/formatters.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_metric_tile.dart';
import '../../common/widgets/app_section_header.dart';
import 'statistics_controller.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<StatisticsController>();
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

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
                _MetricGrid(logic: logic, semantic: semantic),
                SizedBox(height: 20.h),
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
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: logic.isCurrentMonth
                        ? _StatusPill(
                            key: const ValueKey("current-month-badge"),
                            label: "本月",
                            icon: Icons.today_rounded,
                            color: semantic.success,
                          )
                        : InkWell(
                            key: const ValueKey("back-to-current-month"),
                            onTap: logic.resetToCurrentMonth,
                            borderRadius: BorderRadius.circular(999),
                            child: _StatusPill(
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42.w,
          height: 42.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 24.sp, color: color),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final StatisticsController logic;
  final AppSemanticColors semantic;

  const _MetricGrid({required this.logic, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: "加班小时",
                  value: logic.workHours.value.toStringAsFixed(1),
                  icon: Icons.timelapse_rounded,
                  color: semantic.work,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppMetricTile(
                  label: "工作天数",
                  value: "${logic.workDays.value}",
                  icon: Icons.work_history_rounded,
                  color: semantic.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: "待报销",
                  value: formatMoney(logic.unreimbursedAmount.value),
                  icon: Icons.receipt_long_rounded,
                  color: semantic.warning,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppMetricTile(
                  label: "本月订阅",
                  value: formatMoney(logic.selectedMonthSubCost.value),
                  icon: Icons.subscriptions_rounded,
                  color: semantic.expense,
                ),
              ),
            ],
          ),
        ],
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
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppCard(
      child: Obx(() {
        final totalDays =
            logic.workDays.value + logic.tripDays.value + logic.restDays.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: "工时概览"),
            SizedBox(height: 16.h),
            _ProgressRow(
              label: "工作",
              value: logic.workDays.value,
              total: totalDays,
              color: semantic.work,
            ),
            SizedBox(height: 12.h),
            _ProgressRow(
              label: "出差",
              value: logic.tripDays.value,
              total: totalDays,
              color: semantic.warning,
            ),
            SizedBox(height: 12.h),
            _ProgressRow(
              label: "休息/请假",
              value: logic.restDays.value,
              total: totalDays,
              color: semantic.success,
            ),
            if (totalDays == 0) ...[
              SizedBox(height: 12.h),
              Text(
                "本月暂无工时记录",
                style: TextStyle(color: textSecondary, fontSize: 13.sp),
              ),
            ],
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
        final reimburseTotal =
            logic.reimbursedAmount.value + logic.unreimbursedAmount.value;
        final fixedTotal = logic.yearSubCost.value <= 0
            ? logic.selectedMonthSubCost.value
            : logic.yearSubCost.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: "财务概览"),
            SizedBox(height: 16.h),
            _ProgressRow(
              label: "待报销",
              valueLabel: formatMoney(logic.unreimbursedAmount.value),
              progressValue: logic.unreimbursedAmount.value,
              progressTotal: reimburseTotal,
              color: semantic.warning,
            ),
            SizedBox(height: 12.h),
            _ProgressRow(
              label: "已报销",
              valueLabel: formatMoney(logic.reimbursedAmount.value),
              progressValue: logic.reimbursedAmount.value,
              progressTotal: reimburseTotal,
              color: semantic.success,
            ),
            SizedBox(height: 18.h),
            _ProgressRow(
              label: "本月订阅",
              valueLabel: formatMoney(logic.selectedMonthSubCost.value),
              progressValue: logic.selectedMonthSubCost.value,
              progressTotal: fixedTotal,
              color: semantic.expense,
            ),
            SizedBox(height: 12.h),
            _ProgressRow(
              label: "固定年支",
              valueLabel: formatMoney(logic.yearSubCost.value),
              progressValue: logic.yearSubCost.value,
              progressTotal: fixedTotal,
              color: semantic.stats,
            ),
          ],
        );
      }),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int? value;
  final int? total;
  final String? valueLabel;
  final double? progressValue;
  final double? progressTotal;
  final Color color;

  const _ProgressRow({
    required this.label,
    this.value,
    this.total,
    this.valueLabel,
    this.progressValue,
    this.progressTotal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final progress = _progress();
    final displayValue = valueLabel ?? "${value ?? 0}天";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13.sp, color: textSecondary),
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8.h,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  double _progress() {
    final numericValue = progressValue ?? (value ?? 0).toDouble();
    final numericTotal = progressTotal ?? (total ?? 0).toDouble();
    if (numericTotal <= 0) return 0;
    return (numericValue / numericTotal).clamp(0, 1).toDouble();
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
