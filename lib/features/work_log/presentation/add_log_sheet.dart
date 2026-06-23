import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/work_log_dialogs.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_cubit.dart';

class AddLogSheet extends StatefulWidget {
  final DateTime selectedDate;
  final WorkLogEntry? existingEntry;
  final bool existingAlreadyDirty;
  final WorkLogEntryType? initialType;
  final bool asPage;
  final Future<void> Function()? onSavedOrDeleted;

  const AddLogSheet({
    super.key,
    required this.selectedDate,
    this.existingEntry,
    this.existingAlreadyDirty = false,
    this.initialType,
    this.asPage = false,
    this.onSavedOrDeleted,
  });

  @override
  State<AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<AddLogSheet> {
  late final WorkLogEditorCubit _editorCubit;
  late final Future<List<ProjectEntry>> _projectEntriesFuture;
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final FocusNode _overtimeFocusNode = FocusNode();

  final TextEditingController _tripCityController = TextEditingController();
  final FocusNode _tripCityFocusNode = FocusNode();
  final TextEditingController _expenseController = TextEditingController();
  final FocusNode _expenseFocusNode = FocusNode();

  final TextEditingController _customLeaveController = TextEditingController();
  final FocusNode _customLeaveFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editorCubit = WorkLogEditorCubit(
      saveEntry: serviceLocator<SaveWorkLogEntry>(),
      deleteEntry: serviceLocator<DeleteWorkLogEntry>(),
      selectedDate: widget.selectedDate,
      existingEntry: widget.existingEntry,
      existingAlreadyDirty: widget.existingAlreadyDirty,
      initialType: widget.initialType,
    );
    _projectEntriesFuture = _loadProjectEntries();

    final editorState = _editorCubit.state;
    _noteController.text = editorState.note;
    _tripCityController.text = editorState.tripLocation;
    _expenseController.text = editorState.expenseText;
    _customLeaveController.text = editorState.customLeave;
  }

  @override
  void dispose() {
    _editorCubit.close();
    for (final node in _textFocusNodes) {
      node.dispose();
    }
    _noteController.dispose();
    _tripCityController.dispose();
    _customLeaveController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  List<FocusNode> get _textFocusNodes => [
    _noteFocusNode,
    _overtimeFocusNode,
    _tripCityFocusNode,
    _expenseFocusNode,
    _customLeaveFocusNode,
  ];

  Future<List<ProjectEntry>> _loadProjectEntries() async {
    final result = await serviceLocator<LoadProjectEntries>().call();
    return result.valueOrNull ?? const <ProjectEntry>[];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semantic = theme.semanticColors;
    final bgColor = semantic.mutedSurface;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return BlocProvider.value(
      value: _editorCubit,
      child: BlocListener<WorkLogEditorCubit, WorkLogEditorState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.failure != current.failure,
        listener: (context, editorState) {
          unawaited(_handleEditorState(context, editorState));
        },
        child: BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
          builder: (context, editorState) {
            return AppSheetScaffold(
              presentation: widget.asPage
                  ? AppSheetPresentation.page
                  : AppSheetPresentation.sheet,
              height: widget.asPage ? null : sheetHeight,
              title: widget.existingEntry != null ? "修改记录" : "记录一下",
              padding: EdgeInsets.zero,
              hideBottomBarWhenKeyboardVisible: false,
              bottomBar: AppSafeBottomBar(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                child: _buildBottomActions(editorState),
              ),
              child: Column(
                children: [
                  _buildTypeSelector(
                    editorState,
                    isDark,
                    bgColor,
                    textPrimary,
                    textSecondary,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (editorState.type == WorkLogEntryType.work)
                            _buildWorkForm(
                              editorState,
                              isDark,
                              bgColor,
                              textPrimary,
                            ),
                          if (editorState.type == WorkLogEntryType.businessTrip)
                            _buildTripForm(
                              editorState,
                              isDark,
                              bgColor,
                              textPrimary,
                            ),
                          if (editorState.type == WorkLogEntryType.leave)
                            _buildLeaveForm(
                              editorState,
                              isDark,
                              bgColor,
                              textPrimary,
                              textSecondary,
                            ),
                          if (editorState.type == WorkLogEntryType.rest)
                            _buildRestForm(isDark, textSecondary),

                          SizedBox(height: 20.h),
                          AppTextField(
                            controller: _noteController,
                            focusNode: _noteFocusNode,
                            hintText: "备注 (可选)...",
                            maxLines: 3,
                            onChanged: _editorCubit.changeNote,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeSelector(
    WorkLogEditorState editorState,
    bool isDark,
    Color bgColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _buildTypeItem(
            editorState,
            "工作",
            WorkLogEntryType.work,
            isDark,
            textPrimary,
          ),
          _buildTypeItem(
            editorState,
            "出差",
            WorkLogEntryType.businessTrip,
            isDark,
            textPrimary,
          ),
          _buildTypeItem(
            editorState,
            "请假",
            WorkLogEntryType.leave,
            isDark,
            textPrimary,
          ),
          _buildTypeItem(
            editorState,
            "休息",
            WorkLogEntryType.rest,
            isDark,
            textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeItem(
    WorkLogEditorState editorState,
    String label,
    WorkLogEntryType type,
    bool isDark,
    Color textPrimary,
  ) {
    final isSelected = editorState.type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _editorCubit.changeType(type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkDivider : Theme.of(context).cardColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? textPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(WorkLogEditorState editorState) {
    final isSubmitting =
        editorState.status == WorkLogEditorStatus.submitting ||
        editorState.status == WorkLogEditorStatus.deleting;
    if (widget.existingEntry == null) {
      return SizedBox(
        width: double.infinity,
        child: AppButton.primary(
          label: "保存",
          onPressed: isSubmitting ? null : _saveLog,
          isLoading: editorState.status == WorkLogEditorStatus.submitting,
          height: 50.h,
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: AppButton.destructive(
              label: "删除",
              onPressed: isSubmitting ? null : _deleteLog,
              height: 50.h,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: AppButton.primary(
              label: "保存修改",
              onPressed: isSubmitting ? null : _saveLog,
              isLoading: editorState.status == WorkLogEditorStatus.submitting,
              height: 50.h,
            ),
          ),
        ],
      );
    }
  }

  Future<void> _deleteLog() async {
    final confirmed = await confirmWorkLogDelete(
      context,
      title: "确认删除",
      message: "确定要删除这条记录吗？删除后无法恢复。",
    );
    if (!confirmed || !mounted) return;
    await _editorCubit.delete();
  }

  Future<void> _saveLog() async {
    _syncTextControllersToEditor();
    await _editorCubit.submit();
  }

  Future<void> _handleEditorState(
    BuildContext context,
    WorkLogEditorState editorState,
  ) async {
    switch (editorState.status) {
      case WorkLogEditorStatus.saved:
      case WorkLogEditorStatus.deleted:
        await widget.onSavedOrDeleted?.call();
        if (!context.mounted) return;
        await Navigator.of(context).maybePop();
        break;
      case WorkLogEditorStatus.failure:
        _showEditorFailure(
          context,
          editorState.failure,
          fallbackTitle: _failureTitle(editorState.failure),
        );
        break;
      case WorkLogEditorStatus.editing:
      case WorkLogEditorStatus.submitting:
      case WorkLogEditorStatus.deleting:
        break;
    }
  }

  void _syncTextControllersToEditor() {
    _editorCubit
      ..changeNote(_noteController.text)
      ..changeTripLocation(_tripCityController.text)
      ..changeExpenseText(_expenseController.text)
      ..changeCustomLeave(_customLeaveController.text);
  }

  void _showEditorFailure(
    BuildContext context,
    AppFailure? failure, {
    required String fallbackTitle,
  }) {
    final message = failure?.message ?? fallbackTitle;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          margin: EdgeInsets.all(20.w),
        ),
      );
  }

  String _failureTitle(AppFailure? failure) {
    final code = failure?.code ?? '';
    if (code == 'work-log/editor/invalid-expense') return "错误";
    if (code.contains('delete')) return "删除失败";
    return "保存失败";
  }

  Widget _buildWorkForm(
    WorkLogEditorState editorState,
    bool isDark,
    Color bgColor,
    Color textPrimary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "加班时长",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildOvertimeOption(editorState, 0.0, isDark, bgColor),
            _buildOvertimeOption(editorState, 1.0, isDark, bgColor),
            _buildOvertimeOption(editorState, 2.0, isDark, bgColor),
            _buildOvertimeOption(editorState, 4.0, isDark, bgColor),
          ],
        ),
        SizedBox(height: 12.h),
        _buildProjectSelector(editorState, bgColor, textPrimary),
        SizedBox(height: 12.h),
        AppTextField(
          focusNode: _overtimeFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icon(
            Icons.access_time,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          hintText: "自定义时长 (小时)",
          onChanged: (val) =>
              _editorCubit.changeOvertime(double.tryParse(val) ?? 0.0),
        ),
      ],
    );
  }

  Widget _buildProjectSelector(
    WorkLogEditorState editorState,
    Color bgColor,
    Color textPrimary,
  ) {
    return FutureBuilder<List<ProjectEntry>>(
      future: _projectEntriesFuture,
      builder: (context, snapshot) {
        final projects = snapshot.data ?? const <ProjectEntry>[];
        final currentValue = editorState.projectName.trim().isEmpty
            ? ''
            : editorState.projectName.trim();
        final values = <String>{
          '',
          currentValue,
          ...projects.map((project) => project.name.trim()),
        }.where((value) => value.isNotEmpty || value == '').toList();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: values.contains(currentValue) ? currentValue : '',
              isExpanded: true,
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(color: textPrimary),
              icon: const Icon(Icons.expand_more_rounded),
              items: values.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.isEmpty ? '无关联项目' : value),
                );
              }).toList(),
              onChanged: (value) {
                final selectedName = value?.trim() ?? '';
                if (selectedName.isEmpty) {
                  _editorCubit.changeProject();
                  return;
                }
                ProjectEntry? matched;
                for (final project in projects) {
                  if (project.name.trim() == selectedName) {
                    matched = project;
                    break;
                  }
                }
                _editorCubit.changeProject(id: matched?.id, name: selectedName);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOvertimeOption(
    WorkLogEditorState editorState,
    double value,
    bool isDark,
    Color bgColor,
  ) {
    final isSelected = editorState.overtimeHours == value;
    return GestureDetector(
      onTap: () => _editorCubit.changeOvertime(value),
      child: Container(
        width: 70.w,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1)
              : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value == 0 ? "无" : "$value h",
          style: TextStyle(
            color: isSelected
                ? AppColors.primaryBlue
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTripForm(
    WorkLogEditorState editorState,
    bool isDark,
    Color bgColor,
    Color textPrimary,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _tripCityController,
                focusNode: _tripCityFocusNode,
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                hintText: "城市/地点",
                onChanged: _editorCubit.changeTripLocation,
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: editorState.transport,
                  dropdownColor: isDark
                      ? AppColors.darkCard
                      : Theme.of(context).cardColor,
                  style: TextStyle(color: textPrimary),
                  items: ["飞机", "高铁", "火车", "打车", "自驾"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _editorCubit.changeTransport(val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        AppTextField(
          controller: _expenseController,
          focusNode: _expenseFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icon(
            Icons.attach_money,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          hintText: "垫付金额 (¥)",
          onChanged: _editorCubit.changeExpenseText,
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    editorState.isReimbursed
                        ? Icons.check_circle
                        : Icons.pending_outlined,
                    color: editorState.isReimbursed
                        ? AppColors.green
                        : AppColors.orange,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "是否已报销",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: editorState.isReimbursed,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: _editorCubit.changeReimbursed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveForm(
    WorkLogEditorState editorState,
    bool isDark,
    Color bgColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final types = ["年假", "事假", "病假", "调休", "其他"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "请假类型",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: types.map((type) {
            final isSelected = editorState.leaveType == type;
            return GestureDetector(
              onTap: () => _editorCubit.changeLeaveType(type),
              child: AppPill(
                label: type,
                color: AppColors.purple,
                selected: isSelected,
              ),
            );
          }).toList(),
        ),
        if (editorState.leaveType == "其他") ...[
          SizedBox(height: 16.h),
          AppTextField(
            controller: _customLeaveController,
            focusNode: _customLeaveFocusNode,
            prefixIcon: Icon(
              Icons.edit_note,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            hintText: "请输入请假原因...",
            onChanged: _editorCubit.changeCustomLeave,
          ),
        ],
      ],
    );
  }

  Widget _buildRestForm(bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.snooze, size: 40.sp, color: AppColors.orange),
          SizedBox(height: 8.h),
          Text(
            "好好休息，补充能量",
            style: TextStyle(color: textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
