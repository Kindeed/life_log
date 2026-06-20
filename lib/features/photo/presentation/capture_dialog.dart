import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/photo/presentation/project_picker.dart';

/// 归档照片对话框。
///
/// 在拍照后弹出，让用户选择项目并添加描述。
void showCaptureDialog(
  BuildContext context, {
  String? initialProject,
  required FutureOr<void> Function(String projectName, String description)
  onConfirm,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CaptureDialogSheet(
      initialProject: initialProject ?? '',
      onConfirm: onConfirm,
    ),
  );
}

class _CaptureDialogSheet extends StatefulWidget {
  final String initialProject;
  final FutureOr<void> Function(String projectName, String description)
  onConfirm;

  const _CaptureDialogSheet({
    required this.initialProject,
    required this.onConfirm,
  });

  @override
  State<_CaptureDialogSheet> createState() => _CaptureDialogSheetState();
}

class _CaptureDialogSheetState extends State<_CaptureDialogSheet> {
  late final TextEditingController _projectCtrl;
  late final TextEditingController _descCtrl;
  late final PhotoCubit photoCubit;

  @override
  void initState() {
    super.initState();
    _projectCtrl = TextEditingController(text: widget.initialProject);
    _descCtrl = TextEditingController();
    photoCubit = serviceLocator<PhotoCubit>()..start();
  }

  @override
  void dispose() {
    _projectCtrl.dispose();
    _descCtrl.dispose();
    photoCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final hintColor = theme.colorScheme.onSurfaceVariant;

    return BlocBuilder<PhotoCubit, PhotoState>(
      bloc: photoCubit,
      builder: (context, photoState) {
        final existingProjects = photoState.projectSummaries
            .map((summary) => summary.name)
            .toList();

        return AppSheetScaffold(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_fix_high_rounded,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    "归档照片",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: () => showProjectPicker(
                  context,
                  controller: _projectCtrl,
                  existingProjects: existingProjects,
                ),
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: _projectCtrl,
                    labelText: "选择或创建项目",
                    prefixIcon: Icon(
                      Icons.folder_special_rounded,
                      color: hintColor,
                    ),
                    suffixIcon: Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      color: hintColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _descCtrl,
                labelText: "添加备注 (可选)",
                prefixIcon: Icon(Icons.edit_note_rounded, color: hintColor),
              ),
              SizedBox(height: 32.h),
              AppButton.primary(
                label: "确认录入",
                height: 56.h,
                onPressed: () {
                  final projectName = _projectCtrl.text.trim();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  if (projectName.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text("请输入项目名称，或在选择器里创建新项目")),
                    );
                    return;
                  }
                  navigator.pop();
                  unawaited(
                    Future<void>.sync(
                      () =>
                          widget.onConfirm(projectName, _descCtrl.text.trim()),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
