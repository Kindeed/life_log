import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_press_feedback.dart';

/// Opens the protected editor or additional record types at the bottom edge.
/// Place in Scaffold.bottomNavigationBar; keyboard and safe insets are included.
class ProjectChannelComposer extends StatelessWidget {
  final VoidCallback? onWrite;
  final VoidCallback? onAdd;

  const ProjectChannelComposer({
    super.key,
    required this.onWrite,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: AnimatedPadding(
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.standardDecelerate,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Material(
            key: const ValueKey('project-channel-composer-surface'),
            color: theme.semanticColors.mutedSurface,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: '写文字记录',
                    child: AppPressFeedback(
                      enabled: onWrite != null,
                      child: TextButton(
                        key: const ValueKey('project-channel-write'),
                        onPressed: onWrite,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          shape: shape,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '写记录…',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: onWrite == null
                                      ? theme.disabledColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                AppPressFeedback(
                  enabled: onAdd != null,
                  child: IconButton(
                    key: const ValueKey('project-channel-add'),
                    tooltip: '添加记录',
                    onPressed: onAdd,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      shape: shape,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
