import 'package:flutter/material.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';

/// The selected legacy stage remains available even if another client removed
/// its definition. Editing other fields must never discard that relationship.
class ProjectStageField extends StatelessWidget {
  final String projectName;
  final String selected;
  final Future<List<ProjectEntry>> projects;
  final ValueChanged<String> onChanged;
  final bool enabled;
  const ProjectStageField({
    super.key,
    required this.projectName,
    required this.selected,
    required this.projects,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (projectName.trim().isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<ProjectEntry>>(
      future: projects,
      builder: (context, snapshot) {
        final project = (snapshot.data ?? const <ProjectEntry>[])
            .where(
              (p) =>
                  p.name.trim().toLowerCase() ==
                  projectName.trim().toLowerCase(),
            )
            .firstOrNull;
        final values = <String>{
          '',
          ...?project?.stageNames,
          if (selected.isNotEmpty) selected,
        };
        return DropdownButtonFormField<String>(
          initialValue: selected,
          key: ValueKey('$projectName:$selected:${values.join('|')}'),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: '项目阶段',
            helperText: '选择这条记录所属的阶段',
            helperMaxLines: 2,
          ),
          items: values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value.isEmpty ? '未分阶段' : value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? (value) => onChanged(value ?? '') : null,
        );
      },
    );
  }
}
