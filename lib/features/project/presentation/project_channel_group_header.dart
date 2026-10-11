import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/widgets/app_press_feedback.dart';

enum ProjectChannelDateLevel { month, day }

/// A controlled date outline heading; the channel owns expansion and records.
class ProjectChannelGroupHeader extends StatelessWidget {
  final DateTime date;
  final ProjectChannelDateLevel level;
  final int recordCount;
  final int? dayCount;
  final bool expanded;
  final VoidCallback onToggle;

  const ProjectChannelGroupHeader({
    super.key,
    required this.date,
    required this.level,
    required this.recordCount,
    this.dayCount,
    required this.expanded,
    required this.onToggle,
  }) : assert(recordCount >= 0),
       assert(dayCount == null || dayCount >= 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = level == ProjectChannelDateLevel.month;
    final fullDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final label = month
        ? '${date.year}年${date.month}月'
        : '${date.month}月${date.day}日';
    final weekday = '周${weekdays[date.weekday - 1]}';
    final titleStyle =
        (month ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
            ?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: month ? FontWeight.w600 : FontWeight.w500,
            );
    final countStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final records = '$recordCount 条记录';
    final days = month && dayCount != null ? '$dayCount 天' : null;
    final arrow = AnimatedRotation(
      turns: expanded ? 0.25 : 0,
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.standardDecelerate,
      child: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final summary = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (days != null) ...[
          Text(days, style: countStyle),
          Text('·', style: countStyle),
        ],
        Text(records, style: countStyle),
      ],
    );
    return Semantics(
      label: [
        month ? label : fullDate,
        if (days != null) days,
        records,
      ].join('，'),
      hint: '${expanded ? '收起' : '展开'}${month ? '本月' : '当天'}记录',
      button: true,
      expanded: expanded,
      onTap: onToggle,
      child: ExcludeSemantics(
        child: AppPressFeedback(
          child: TextButton(
            onPressed: onToggle,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              foregroundColor: theme.colorScheme.onSurface,
              backgroundColor: month
                  ? theme.colorScheme.surfaceContainerLow
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(AppRadius.sm),
                  bottom: Radius.circular(month && expanded ? 0 : AppRadius.sm),
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titleSize = _measureSize(context, label, titleStyle);
                final titleWidth =
                    titleSize.width +
                    (month
                        ? 0
                        : AppSpacing.sm +
                              _measure(context, weekday, countStyle));
                final summaryWidth =
                    _measure(context, records, countStyle) +
                    (days == null
                        ? 0
                        : _measure(context, days, countStyle) +
                              _measure(context, '·', countStyle) +
                              AppSpacing.xs * 2);
                final singleRow =
                    18 +
                        AppSpacing.xs +
                        titleWidth +
                        AppSpacing.lg +
                        summaryWidth <=
                    constraints.maxWidth;
                final title = month
                    ? Text(label, style: titleStyle)
                    : Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(label, style: titleStyle, softWrap: false),
                          Text(weekday, style: countStyle, softWrap: false),
                        ],
                      );
                if (singleRow) {
                  return Row(
                    children: [
                      arrow,
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: title),
                      const SizedBox(width: AppSpacing.lg),
                      summary,
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 18,
                          height: titleSize.height,
                          child: Center(child: arrow),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(child: title),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(left: 18 + AppSpacing.xs),
                      child: summary,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

double _measure(BuildContext context, String text, TextStyle? style) =>
    _measureSize(context, text, style).width;

Size _measureSize(BuildContext context, String text, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}
