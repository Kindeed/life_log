import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';

/// 项目选择器底部弹窗。
///
/// 显示已有项目列表并支持搜索和创建新项目。
void showProjectPicker(
  BuildContext context, {
  required TextEditingController controller,
  required List<String> existingProjects,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ProjectPickerSheet(
      controller: controller,
      existingProjects: existingProjects,
    ),
  );
}

class _ProjectPickerSheet extends StatefulWidget {
  final TextEditingController controller;
  final List<String> existingProjects;

  const _ProjectPickerSheet({
    required this.controller,
    required this.existingProjects,
  });

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final hintColor = theme.colorScheme.onSurfaceVariant;
    final query = _searchCtrl.text.trim();
    final filteredProjects = query.isEmpty
        ? widget.existingProjects
        : widget.existingProjects
              .where(
                (project) =>
                    project.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    final showCreate =
        query.isNotEmpty && !widget.existingProjects.contains(query);

    return AppSheetScaffold(
      title: "选择项目",
      height: MediaQuery.sizeOf(context).height * 0.7,
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
      child: Column(
        children: [
          AppTextField(
            controller: _searchCtrl,
            autofocus: true,
            hintText: "搜索或创建新项目...",
            prefixIcon: Icon(Icons.search, color: hintColor),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: filteredProjects.isEmpty && !showCreate
                ? Center(
                    child: Text("暂无项目历史", style: TextStyle(color: hintColor)),
                  )
                : ListView.builder(
                    itemCount: filteredProjects.length + (showCreate ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (showCreate && index == 0) {
                        return _ProjectPickerTile(
                          icon: Icons.add,
                          title: '创建新项目: "$query"',
                          textColor: textColor,
                          iconColor: AppColors.primaryBlue,
                          onTap: () => _selectProject(query),
                        );
                      }

                      final dataIndex = showCreate ? index - 1 : index;
                      final projectName = filteredProjects[dataIndex];
                      return ListTile(
                        leading: Icon(Icons.folder, color: hintColor),
                        title: Text(
                          projectName,
                          style: TextStyle(color: textColor),
                        ),
                        trailing: widget.controller.text == projectName
                            ? const Icon(
                                Icons.check,
                                color: AppColors.primaryBlue,
                              )
                            : null,
                        onTap: () => _selectProject(projectName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _selectProject(String projectName) {
    widget.controller.text = projectName;
    Navigator.of(context).pop();
  }
}

class _ProjectPickerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ProjectPickerTile({
    required this.icon,
    required this.title,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.2),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }
}
