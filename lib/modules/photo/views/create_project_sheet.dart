import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/modules/project/project_controller.dart';
import 'package:life_log/modules/project/project_model.dart';

void showCreateProjectSheet({
  String? initialName,
  Future<void> Function(Project project)? onCreated,
}) {
  Get.bottomSheet(
    _CreateProjectSheet(initialName: initialName, onCreated: onCreated),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _CreateProjectSheet extends StatefulWidget {
  final String? initialName;
  final Future<void> Function(Project project)? onCreated;

  const _CreateProjectSheet({this.initialName, this.onCreated});

  @override
  State<_CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<_CreateProjectSheet> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: '创建项目',
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _nameController,
            autofocus: true,
            labelText: '项目名称',
            hintText: '输入第一个项目名称',
            prefixIcon: Icon(
              Icons.folder_special_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: '创建项目',
              onPressed: _isSaving ? null : _create,
              isLoading: _isSaving,
              height: 52.h,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('错误', '请输入项目名称');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final project = await ProjectController.to.createProject(name);
      Get.back();
      if (widget.onCreated != null) {
        await widget.onCreated!(project);
      }
      Get.snackbar('已创建', '项目「${project.name}」已建立');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
