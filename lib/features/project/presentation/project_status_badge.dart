import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';

/// Project lifecycle, independent of the selected record stage.
class ProjectStatusBadge extends StatelessWidget {
  final ProjectEntryStatus status;

  const ProjectStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPill(
      label: status.label,
      icon: status == ProjectEntryStatus.active
          ? Icons.radio_button_checked_rounded
          : Icons.archive_outlined,
      color: status == ProjectEntryStatus.active
          ? theme.semanticColors.project
          : theme.colorScheme.onSurfaceVariant,
    );
  }
}
