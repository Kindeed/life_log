import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_confirm_dialog.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';

void showEvidenceEditorSheet({
  ExpenseEvidence? existing,
  String? initialProject,
  String? sourcePath,
}) {
  Get.to(
    () => EvidenceEditorSheet(
      existing: existing,
      initialProject: initialProject,
      sourcePath: sourcePath,
      asPage: true,
    ),
  );
}

void showEvidenceEditorBottomSheet({
  ExpenseEvidence? existing,
  String? initialProject,
  String? sourcePath,
}) {
  Get.bottomSheet(
    EvidenceEditorSheet(
      existing: existing,
      initialProject: initialProject,
      sourcePath: sourcePath,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class EvidenceEditorSheet extends StatefulWidget {
  final ExpenseEvidence? existing;
  final String? initialProject;
  final String? sourcePath;
  final bool asPage;

  const EvidenceEditorSheet({
    super.key,
    this.existing,
    this.initialProject,
    this.sourcePath,
    this.asPage = false,
  });

  @override
  State<EvidenceEditorSheet> createState() => _EvidenceEditorSheetState();
}

class _EvidenceEditorSheetState extends State<EvidenceEditorSheet> {
  late final TextEditingController _projectController;
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late DateTime _evidenceDate;
  DateTime? _tripDate;
  EvidenceCategory _category = EvidenceCategory.invoice;
  EvidenceStatus _status = EvidenceStatus.pending;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _projectController = TextEditingController(
      text: existing?.projectName ?? widget.initialProject ?? 'DefaultProject',
    );
    _amountController = TextEditingController(
      text: existing?.amount == null ? '' : existing!.amount!.toString(),
    );
    _merchantController = TextEditingController(text: existing?.merchant ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _evidenceDate = existing?.evidenceDate ?? DateTime.now();
    _tripDate = existing?.tripDate;
    _category = existing?.category ?? EvidenceCategory.invoice;
    _status = existing?.status ?? EvidenceStatus.pending;
  }

  @override
  void dispose() {
    _projectController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final fillColor = isDark ? theme.cardColor : const Color(0xFFF7F9FC);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final content = SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.92.sh),
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h + bottomInset),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? '添加凭证' : '编辑凭证',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: Get.back,
                  ),
                ],
              ),
              if (_previewPath != null) ...[
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_previewPath!),
                    height: 160.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 120.h,
                      alignment: Alignment.center,
                      color: fillColor,
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _projectController,
                label: '项目',
                icon: Icons.folder_special_rounded,
                fillColor: fillColor,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _amountController,
                      label: '金额',
                      icon: Icons.payments_rounded,
                      fillColor: fillColor,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildPickerTile(
                      label: _formatDate(_evidenceDate),
                      icon: Icons.event_rounded,
                      fillColor: fillColor,
                      onTap: () => _pickDate(
                        initial: _evidenceDate,
                        onPicked: (date) =>
                            setState(() => _evidenceDate = date),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _merchantController,
                label: '商家/用途',
                icon: Icons.storefront_rounded,
                fillColor: fillColor,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown<EvidenceCategory>(
                      value: _category,
                      values: EvidenceCategory.values,
                      labelBuilder: (value) => value.label,
                      icon: Icons.category_rounded,
                      fillColor: fillColor,
                      onChanged: (value) => setState(() => _category = value),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDropdown<EvidenceStatus>(
                      value: _status,
                      values: EvidenceStatus.values,
                      labelBuilder: (value) => value.label,
                      icon: Icons.verified_rounded,
                      fillColor: fillColor,
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildPickerTile(
                label: _tripDate == null
                    ? '关联出差日期（可选）'
                    : _formatDate(_tripDate!),
                icon: Icons.luggage_rounded,
                fillColor: fillColor,
                trailing: _tripDate == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _tripDate = null),
                      ),
                onTap: () => _pickDate(
                  initial: _tripDate ?? _evidenceDate,
                  onPicked: (date) => setState(() => _tripDate = date),
                ),
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _noteController,
                label: '备注',
                icon: Icons.edit_note_rounded,
                fillColor: fillColor,
                maxLines: 3,
              ),
              SizedBox(height: 20.h),
              if (widget.existing == null)
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('保存凭证'),
                    style: _primaryButtonStyle(context),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _confirmDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          '删除',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error),
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('保存修改'),
                        style: _primaryButtonStyle(context),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    if (!widget.asPage) return content;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(top: true, child: content),
    );
  }

  String? get _previewPath =>
      widget.sourcePath ?? widget.existing?.localFilePath;

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color fillColor,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required IconData icon,
    required Color fillColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(minHeight: 56.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> values,
    required String Function(T value) labelBuilder,
    required IconData icon,
    required Color fillColor,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 8.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: values
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(labelBuilder(item)),
                      ),
                    )
                    .toList(),
                onChanged: (item) {
                  if (item != null) onChanged(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      padding: EdgeInsets.symmetric(vertical: 13.h),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await AppConfirmDialog.show(
      title: '删除凭证',
      message: '确定删除这条凭证记录吗？删除后无法恢复。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed || widget.existing == null) return;
    await EvidenceController.to.deleteEvidence(widget.existing!);
  }

  void _save() {
    final projectName = _projectController.text.trim();
    if (projectName.isEmpty) {
      Get.snackbar('错误', '项目名称不能为空');
      return;
    }

    final existing = widget.existing;
    final next = ExpenseEvidence()
      ..projectName = projectName
      ..evidenceDate = _evidenceDate
      ..amount = double.tryParse(_amountController.text.trim())
      ..currency = existing?.currency ?? 'CNY'
      ..category = _category
      ..status = _status
      ..merchant = _merchantController.text.trim()
      ..note = _noteController.text.trim()
      ..localFilePath = existing?.localFilePath
      ..remoteStoragePath = existing?.remoteStoragePath
      ..fileName = existing?.fileName
      ..mimeType = existing?.mimeType
      ..uploadedAt = existing?.uploadedAt
      ..tripDate = _tripDate;

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
    }

    next.isDirty =
        existing == null ||
        existing.isDirty ||
        _hasBusinessChanges(existing, next);

    EvidenceController.to.saveEvidence(next, sourcePath: widget.sourcePath);
  }

  bool _hasBusinessChanges(ExpenseEvidence original, ExpenseEvidence next) {
    return original.projectName != next.projectName ||
        original.evidenceDate != next.evidenceDate ||
        original.amount != next.amount ||
        original.currency != next.currency ||
        original.category != next.category ||
        original.status != next.status ||
        original.merchant != next.merchant ||
        original.note != next.note ||
        original.tripDate != next.tripDate ||
        widget.sourcePath != null;
  }

  String _formatDate(DateTime date) => formatDateYmd(date);
}
