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
    final label = month
        ? '${date.year}年${date.month}月'
        : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final titleStyle =
        (month ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)
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
          Text(
            days,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: countStyle,
          ),
          Text('·', style: countStyle),
        ],
        Text(
          records,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: countStyle,
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(left: month ? 0 : AppSpacing.sm),
      child: Semantics(
        label: [label, if (days != null) days, records].join('，'),
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
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                foregroundColor: theme.colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final titleWidth = _measure(context, label, titleStyle);
                  final summaryWidth =
                      _measure(context, records, countStyle) +
                      (days == null
                          ? 0
                          : _measure(context, days, countStyle) +
                                _measure(context, '·', countStyle) +
                                AppSpacing.xs * 2);
                  final singleRow =
                      titleWidth +
                          AppSpacing.lg +
                          summaryWidth +
                          AppSpacing.xs +
                          18 <=
                      constraints.maxWidth;
                  final title = Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  );
                  if (singleRow) {
                    return Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: AppSpacing.lg),
                        summary,
                        const SizedBox(width: AppSpacing.xs),
                        arrow,
                      ],
                    );
                  }
                  final arrowWithTitle =
                      titleWidth + AppSpacing.xs + 18 <= constraints.maxWidth;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: title),
                          if (arrowWithTitle) ...[
                            const SizedBox(width: AppSpacing.xs),
                            arrow,
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(child: summary),
                          if (!arrowWithTitle) ...[
                            const SizedBox(width: AppSpacing.xs),
                            arrow,
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _measure(BuildContext context, String text, TextStyle? style) {
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
  final width = painter.width;
  painter.dispose();
  return width;
}
