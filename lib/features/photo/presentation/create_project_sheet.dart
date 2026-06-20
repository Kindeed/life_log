import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/application/create_project_entry.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';

void showCreateProjectSheet(
  BuildContext context, {
  String? initialName,
  Future<void> Function(ProjectEntry project)? onCreated,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _CreateProjectSheet(initialName: initialName, onCreated: onCreated),
  );
}

class _CreateProjectSheet extends StatefulWidget {
  final String? initialName;
  final Future<void> Function(ProjectEntry project)? onCreated;

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
            hintText: '输入项目名称',
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (name.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('请输入项目名称')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await serviceLocator<CreateProjectEntry>().call(name);
      await result.when(
        success: (project) async {
          navigator.pop();
          if (widget.onCreated != null) {
            await widget.onCreated!(project);
          }
          messenger.showSnackBar(
            SnackBar(content: Text('项目「${project.name}」已建立')),
          );
        },
        failure: (failure) async {
          messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
