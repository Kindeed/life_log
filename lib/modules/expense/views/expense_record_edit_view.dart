import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_confirm_dialog.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/modules/expense/expense_record_controller.dart';

import '../expense_record_model.dart';

class ExpenseRecordEditView extends StatefulWidget {
  final ExpenseRecord? record;
  final DateTime? initialDate;
  final String? initialProjectName;

  const ExpenseRecordEditView({
    super.key,
    this.record,
    this.initialDate,
    this.initialProjectName,
  });

  @override
  State<ExpenseRecordEditView> createState() => _ExpenseRecordEditViewState();
}

class _ExpenseRecordEditViewState extends State<ExpenseRecordEditView> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _projectController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _date;
  ExpenseCategory _category = ExpenseCategory.other;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _date = record?.expenseDate ?? widget.initialDate ?? DateTime.now();
    if (record != null) {
      _amountController.text = record.amount.toString();
      _merchantController.text = record.merchant ?? '';
      _projectController.text = record.projectName ?? '';
      _noteController.text = record.note ?? '';
      _category = record.category;
    } else if (widget.initialProjectName?.trim().isNotEmpty == true) {
      _projectController.text = widget.initialProjectName!.trim();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _projectController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: Text(widget.record == null ? '添加项目支出' : '编辑项目支出')),
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
                      controller: _amountController,
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
                      children: ExpenseCategory.values.map((category) {
                        final selected = _category == category;
                        return GestureDetector(
                          onTap: () => setState(() => _category = category),
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
                      controller: _merchantController,
                      hintText: '商家/用途',
                      prefixIcon: const Icon(Icons.storefront_rounded),
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _projectController,
                      hintText: '项目名称（建议先填）',
                      prefixIcon: const Icon(Icons.folder_special_rounded),
                    ),
                    SizedBox(height: 12.h),
                    _DateTile(date: _date, onTap: _pickDate),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _noteController,
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
        child: widget.record == null
            ? AppButton.primary(label: '保存', onPressed: _save, height: 50.h)
            : Row(
                children: [
                  Expanded(
                    child: AppButton.destructive(
                      label: '删除',
                      onPressed: _delete,
                      height: 50.h,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton.primary(
                      label: '保存修改',
                      onPressed: _save,
                      height: 50.h,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _categoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.meal:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.travel:
        return Icons.luggage_rounded;
      case ExpenseCategory.office:
        return Icons.business_center_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color _categoryColor(ExpenseCategory category, AppSemanticColors semantic) {
    switch (category) {
      case ExpenseCategory.meal:
        return semantic.warning;
      case ExpenseCategory.transport:
        return semantic.stats;
      case ExpenseCategory.shopping:
        return semantic.expense;
      case ExpenseCategory.travel:
        return semantic.project;
      case ExpenseCategory.office:
        return semantic.work;
      case ExpenseCategory.other:
        return semantic.success;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 0) {
      Get.snackbar('错误', '请输入有效金额');
      return;
    }

    final existing = widget.record;
    final next = ExpenseRecord()
      ..expenseDate = _date
      ..amount = amount
      ..currency = existing?.currency ?? 'CNY'
      ..category = _category
      ..merchant = _merchantController.text.trim()
      ..projectName = _projectController.text.trim().isEmpty
          ? null
          : _projectController.text.trim()
      ..note = _noteController.text.trim();

    if (existing != null) {
      next.id = existing.id;
      next.ownerUserId = existing.ownerUserId;
      next.remoteId = existing.remoteId;
      next.syncId = existing.syncId;
      next.remoteVersion = existing.remoteVersion;
      next.remoteUpdatedAt = existing.remoteUpdatedAt;
      next.syncedAt = existing.syncedAt;
      next.deletedAt = existing.deletedAt;
      next.pendingDelete = existing.pendingDelete;
      next.projectId = existing.projectId;
    }

    next.isDirty =
        existing == null ||
        existing.isDirty ||
        next.hasBusinessChangesComparedTo(existing);

    try {
      await ExpenseRecordController.to.saveRecord(next);
      Get.back();
      Get.snackbar('已保存', '消费记录已更新');
    } catch (_) {
      // Controller already logs and shows the snackbar; stop the success flow.
      return;
    }
  }

  Future<void> _delete() async {
    final existing = widget.record;
    if (existing == null) return;
    final confirmed = await AppConfirmDialog.show(
      title: '删除消费',
      message: '确定删除这条消费记录吗？',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ExpenseRecordController.to.deleteRecord(existing.id);
      Get.back();
    } catch (_) {
      // Controller already logs and shows the snackbar; stop the success flow.
      return;
    }
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
