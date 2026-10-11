import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/widgets/app_press_feedback.dart';

/// A compact scope control above the channel, independent of project lifecycle.
class ProjectChannelStageBar extends StatelessWidget {
  final String? selectedStage;
  final int stageCount;
  final int recordCount;
  final VoidCallback? onSelect;

  const ProjectChannelStageBar({
    super.key,
    required this.selectedStage,
    required this.stageCount,
    required this.recordCount,
    required this.onSelect,
  }) : assert(stageCount >= 0),
       assert(recordCount >= 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedStage?.trim();
    final label = selected == null
        ? '全部阶段'
        : selected.isEmpty
        ? '未分阶段'
        : selected;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: onSelect == null
          ? theme.disabledColor
          : theme.colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    );
    final countLabel = '$recordCount 条记录';
    final countStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final selector = Semantics(
      label: '选择项目阶段，$label，共 $stageCount 个阶段',
      button: true,
      enabled: onSelect != null,
      onTap: onSelect,
      child: ExcludeSemantics(
        child: Tooltip(
          message: '选择阶段（$stageCount 个阶段）',
          child: AppPressFeedback(
            enabled: onSelect != null,
            child: TextButton(
              key: const ValueKey('project-stage-selector'),
              onPressed: onSelect,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                alignment: Alignment.centerLeft,
                foregroundColor: theme.colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.expand_more_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stageWidth =
              (_textWidth(context, label, labelStyle) +
                      AppSpacing.sm * 2 +
                      AppSpacing.xs +
                      18)
                  .clamp(48.0, double.infinity);
          final countWidth = _textWidth(context, countLabel, countStyle);
          final stacked =
              stageWidth + AppSpacing.sm + countWidth > constraints.maxWidth;
          final count = Text(
            countLabel,
            semanticsLabel: '当前范围共 $recordCount 条记录',
            textAlign: stacked ? TextAlign.left : TextAlign.right,
            maxLines: stacked ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: countStyle,
          );
          if (stacked) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                selector,
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    0,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: count,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: selector),
              ),
              const SizedBox(width: AppSpacing.sm),
              count,
            ],
          );
        },
      ),
    );
  }
}

double _textWidth(BuildContext context, String text, TextStyle? style) {
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
