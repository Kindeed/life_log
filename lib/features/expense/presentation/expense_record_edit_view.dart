import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_date_picker.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/application/save_expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/presentation/expense_record_editor_cubit.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

class ExpenseRecordEditView extends StatefulWidget {
  final ExpenseRecordEntry? existingEntry;
  final bool existingAlreadyDirty;
  final DateTime? initialDate;
  final String? initialProjectName;
  final Future<void> Function()? onSavedOrDeleted;

  const ExpenseRecordEditView({
    super.key,
    this.existingEntry,
    this.existingAlreadyDirty = false,
    this.initialDate,
    this.initialProjectName,
    this.onSavedOrDeleted,
  });

  @override
  State<ExpenseRecordEditView> createState() => _ExpenseRecordEditViewState();
}

class _ExpenseRecordEditViewState extends State<ExpenseRecordEditView> {
  late final ExpenseRecordEditorCubit _editorCubit;
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _projectController = TextEditingController();
  final _noteController = TextEditingController();
  late Future<List<WorkLogEntry>> _tripEntriesFuture;

  @override
  void initState() {
    super.initState();
    _editorCubit = ExpenseRecordEditorCubit(
      saveEntry: serviceLocator<SaveExpenseRecordEntry>(),
      deleteEntry: serviceLocator<DeleteExpenseRecordEntry>(),
      selectedDate: widget.initialDate ?? DateTime.now(),
      existingEntry: widget.existingEntry,
      existingAlreadyDirty: widget.existingAlreadyDirty,
      initialProjectName: widget.initialProjectName,
    );

    final editorState = _editorCubit.state;
    _amountController.text = editorState.amountText;
    _merchantController.text = editorState.merchant;
    _projectController.text = editorState.projectName;
    _noteController.text = editorState.note;
    _tripEntriesFuture = _loadTripsForProject(editorState.projectName);
  }

  @override
  void dispose() {
    _editorCubit.close();
    _amountController.dispose();
    _merchantController.dispose();
    _projectController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _editorCubit,
      child: BlocListener<ExpenseRecordEditorCubit, ExpenseRecordEditorState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.failure != current.failure,
        listener: (context, editorState) {
          unawaited(_handleEditorState(context, editorState));
        },
        child: BlocBuilder<ExpenseRecordEditorCubit, ExpenseRecordEditorState>(
          builder: (context, editorState) {
            return _ExpenseRecordEditorScaffold(
              editorState: editorState,
              amountController: _amountController,
              merchantController: _merchantController,
              projectController: _projectController,
              noteController: _noteController,
              tripEntriesFuture: _tripEntriesFuture,
              onProjectChanged: _handleProjectChanged,
              onPickDate: _pickDate,
              onSave: _save,
              onDelete: _delete,
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showLifeLogDatePicker(
      context: context,
      initialDate: _editorCubit.state.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _editorCubit.changeDate(picked);
    }
  }

  Future<List<WorkLogEntry>> _loadTripsForProject(String projectName) async {
    final result = await serviceLocator<LoadProjectWorkLogTrips>().call(
      projectName,
    );
    return result.valueOrNull ?? const <WorkLogEntry>[];
  }

  void _handleProjectChanged(String value) {
    _editorCubit.changeProjectName(value);
    setState(() {
      _tripEntriesFuture = _loadTripsForProject(value);
    });
  }

  Future<void> _save() async {
    _syncTextControllersToEditor();
    await _editorCubit.submit();
  }

  Future<void> _delete() async {
    final confirmed = await _confirmDelete();
    if (!confirmed || !mounted) return;
    await _editorCubit.delete();
  }

  Future<void> _handleEditorState(
    BuildContext context,
    ExpenseRecordEditorState editorState,
  ) async {
    switch (editorState.status) {
      case ExpenseRecordEditorStatus.saved:
      case ExpenseRecordEditorStatus.deleted:
        final messenger = ScaffoldMessenger.maybeOf(context);
        await widget.onSavedOrDeleted?.call();
        if (!context.mounted) return;
        await Navigator.of(context).maybePop();
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                editorState.status == ExpenseRecordEditorStatus.saved
                    ? '消费记录已保存'
                    : '消费记录已删除',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        break;
      case ExpenseRecordEditorStatus.failure:
        _showEditorFailure(context, editorState.failure);
        break;
      case ExpenseRecordEditorStatus.editing:
      case ExpenseRecordEditorStatus.submitting:
      case ExpenseRecordEditorStatus.deleting:
        break;
    }
  }

  void _syncTextControllersToEditor() {
    _editorCubit
      ..changeAmountText(_amountController.text)
      ..changeMerchant(_merchantController.text)
      ..changeProjectName(_projectController.text)
      ..changeNote(_noteController.text);
  }

  void _showEditorFailure(BuildContext context, AppFailure? failure) {
    final message = failure?.message ?? '保存失败';
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除消费'),
          content: const Text('确定删除这条消费记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _ExpenseRecordEditorScaffold extends StatelessWidget {
  final ExpenseRecordEditorState editorState;
  final TextEditingController amountController;
  final TextEditingController merchantController;
  final TextEditingController projectController;
  final TextEditingController noteController;
  final Future<List<WorkLogEntry>> tripEntriesFuture;
  final ValueChanged<String> onProjectChanged;
  final Future<void> Function() onPickDate;
  final Future<void> Function() onSave;
  final Future<void> Function() onDelete;

  const _ExpenseRecordEditorScaffold({
    required this.editorState,
    required this.amountController,
    required this.merchantController,
    required this.projectController,
    required this.noteController,
    required this.tripEntriesFuture,
    required this.onProjectChanged,
    required this.onPickDate,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(editorState.existingEntry == null ? '添加项目支出' : '编辑项目支出'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 96.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('金额', style: TextStyle(color: textSecondary)),
                    SizedBox(height: 10.h),
                    AppTextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: '0.00',
                      prefixIcon: Icon(
                        Icons.currency_yen_rounded,
                        color: semantic.expense,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              AppCard(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('分类', style: TextStyle(color: textSecondary)),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: ExpenseRecordEntryCategory.values.map((
                        category,
                      ) {
                        final selected = editorState.category == category;
                        return GestureDetector(
                          onTap: () => context
                              .read<ExpenseRecordEditorCubit>()
                              .changeCategory(category),
                          child: AppPill(
                            icon: _categoryIcon(category),
                            label: category.label,
                            color: _categoryColor(category, semantic),
                            selected: selected,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              AppCard(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    AppTextField(
                      controller: merchantController,
                      hintText: '商家/用途',
                      prefixIcon: const Icon(Icons.storefront_rounded),
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: projectController,
                      hintText: '项目名称（建议先填）',
                      prefixIcon: const Icon(Icons.folder_special_rounded),
                      onChanged: onProjectChanged,
                    ),
                    SizedBox(height: 12.h),
                    _TripWorkLogTile(
                      editorState: editorState,
                      tripEntriesFuture: tripEntriesFuture,
                    ),
                    SizedBox(height: 12.h),
                    _DateTile(
                      date: editorState.selectedDate,
                      onTap: onPickDate,
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: noteController,
                      hintText: '备注',
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppSafeBottomBar(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
        child: _buildBottomActions(editorState),
      ),
    );
  }

  Widget _buildBottomActions(ExpenseRecordEditorState editorState) {
    final isBusy =
        editorState.status == ExpenseRecordEditorStatus.submitting ||
        editorState.status == ExpenseRecordEditorStatus.deleting;
    if (editorState.existingEntry == null) {
      return AppButton.primary(
        label: '保存',
        onPressed: isBusy ? null : onSave,
        isLoading: editorState.status == ExpenseRecordEditorStatus.submitting,
        height: 50.h,
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton.destructive(
            label: '删除',
            onPressed: isBusy ? null : onDelete,
            isLoading: editorState.status == ExpenseRecordEditorStatus.deleting,
            height: 50.h,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButton.primary(
            label: '保存修改',
            onPressed: isBusy ? null : onSave,
            isLoading:
                editorState.status == ExpenseRecordEditorStatus.submitting,
            height: 50.h,
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(ExpenseRecordEntryCategory category) {
    return switch (category) {
      ExpenseRecordEntryCategory.meal => Icons.restaurant_rounded,
      ExpenseRecordEntryCategory.transport => Icons.directions_car_rounded,
      ExpenseRecordEntryCategory.shopping => Icons.shopping_bag_rounded,
      ExpenseRecordEntryCategory.travel => Icons.luggage_rounded,
      ExpenseRecordEntryCategory.office => Icons.business_center_rounded,
      ExpenseRecordEntryCategory.other => Icons.more_horiz_rounded,
    };
  }

  Color _categoryColor(
    ExpenseRecordEntryCategory category,
    AppSemanticColors semantic,
  ) {
    return switch (category) {
      ExpenseRecordEntryCategory.meal => semantic.warning,
      ExpenseRecordEntryCategory.transport => semantic.stats,
      ExpenseRecordEntryCategory.shopping => semantic.expense,
      ExpenseRecordEntryCategory.travel => semantic.project,
      ExpenseRecordEntryCategory.office => semantic.work,
      ExpenseRecordEntryCategory.other => semantic.success,
    };
  }
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateTile({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: semantic.mutedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: semantic.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(formatDateYmd(date))),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripWorkLogTile extends StatelessWidget {
  final ExpenseRecordEditorState editorState;
  final Future<List<WorkLogEntry>> tripEntriesFuture;

  const _TripWorkLogTile({
    required this.editorState,
    required this.tripEntriesFuture,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    return FutureBuilder<List<WorkLogEntry>>(
      future: tripEntriesFuture,
      builder: (context, snapshot) {
        final trips = snapshot.data ?? const <WorkLogEntry>[];
        final selectedId = editorState.tripWorkLogId ?? 0;
        final values = <int>{
          0,
          if (selectedId != 0) selectedId,
          ...trips.map((trip) => trip.id),
        }.toList();

        return Container(
          height: 56.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: semantic.mutedSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: semantic.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: values.contains(selectedId) ? selectedId : 0,
              isExpanded: true,
              icon: Icon(
                Icons.expand_more_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              items: values.map((value) {
                final trip = _firstTripById(trips, value);
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    value == 0
                        ? (trips.isEmpty ? '暂无可关联出差' : '不关联出差')
                        : _tripLabel(trip, value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                final trip = _firstTripById(trips, value ?? 0);
                context.read<ExpenseRecordEditorCubit>().changeTripWorkLog(
                  id: trip?.id,
                  syncId: trip?.syncId,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

WorkLogEntry? _firstTripById(List<WorkLogEntry> trips, int id) {
  for (final trip in trips) {
    if (trip.id == id) return trip;
  }
  return null;
}

String _tripLabel(WorkLogEntry? trip, int id) {
  if (trip == null) return '出差 #$id';
  final location = trip.location?.trim();
  final parts = <String>[
    formatDateYmd(trip.date),
    if (location != null && location.isNotEmpty) location,
    if (trip.transport?.trim().isNotEmpty == true) trip.transport!.trim(),
  ];
  return parts.join(' · ');
}
