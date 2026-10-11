import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/widgets/app_local_thumbnail.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';

/// A single lazily built project message. The parent owns ordering and dates.
class ProjectChannelRecord extends StatelessWidget {
  final String title;
  final String subtitle;
  final String typeLabel;
  final DateTime eventTime;
  final String? content;
  final IconData icon;
  final Color color;
  final PhotoEntry? photo;
  final VoidCallback onTap;

  const ProjectChannelRecord({
    super.key,
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.eventTime,
    this.content,
    required this.icon,
    required this.color,
    this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = (content ?? photo?.description ?? '').trim();
    final heading = title.trim();
    final kind = typeLabel.trim();
    final metadata = _metadata(kind);
    final showHeading =
        heading.isNotEmpty &&
        heading != body &&
        !{kind, '$kind记录', '文字记录', '项目照片'}.contains(heading) &&
        (photo == null || !subtitle.split(' · ').contains(heading));
    final radius = BorderRadius.circular(AppRadius.sm);

    return Semantics(
      button: true,
      label: '查看${kind.isEmpty ? '记录' : kind}详情',
      hint: '点按查看完整内容',
      child: Material(
        color: scheme.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photo != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AppLocalThumbnail(
                      filePath: photo!.filePath,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: scheme.surfaceContainerLow,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 24,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '照片文件不可用',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (photo == null)
                        _header(theme, metadata, showHeading ? heading : null),
                      if (photo != null && showHeading) ...[
                        _heading(theme, heading),
                        if (body.isNotEmpty)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                      if (body.isNotEmpty) ...[
                        if (photo == null)
                          const SizedBox(height: AppSpacing.sm),
                        Text(
                          body,
                          maxLines: 12,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (photo != null) ...[
                        if (showHeading || body.isNotEmpty)
                          const SizedBox(height: AppSpacing.sm),
                        _header(theme, metadata, null),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(ThemeData theme, String heading) => Text(
    heading,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _header(ThemeData theme, String metadata, String? heading) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (heading != null) ...[
              _heading(theme, heading),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              metadata,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  String _metadata(String kind) {
    final parts = <String>{
      if (kind.isNotEmpty) kind,
      ...subtitle
          .split(' · ')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty && value != kind),
    };
    final localTime = eventTime.isUtc ? eventTime.toLocal() : eventTime;
    // A business date is not a recorded clock time. Do not invent midnight.
    if (eventTime.hour != 0 || eventTime.minute != 0) {
      parts.add(
        '${localTime.hour.toString().padLeft(2, '0')}:'
        '${localTime.minute.toString().padLeft(2, '0')}',
      );
    }
    return parts.join(' · ');
  }
}
