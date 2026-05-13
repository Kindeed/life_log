import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_confirm_dialog.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';

void showEvidenceEditorSheet({
  ExpenseEvidence? existing,
  String? initialProject,
  String? sourcePath,
  String? sourceExtension,
}) {
  Get.to(
    () => EvidenceEditorSheet(
      existing: existing,
      initialProject: initialProject,
      sourcePath: sourcePath,
      sourceExtension: sourceExtension,
      asPage: true,
    ),
  );
}

void showEvidenceEditorBottomSheet({
  ExpenseEvidence? existing,
  String? initialProject,
  String? sourcePath,
  String? sourceExtension,
}) {
  Get.bottomSheet(
    EvidenceEditorSheet(
      existing: existing,
      initialProject: initialProject,
      sourcePath: sourcePath,
      sourceExtension: sourceExtension,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class EvidenceEditorSheet extends StatefulWidget {
  final ExpenseEvidence? existing;
  final String? initialProject;
  final String? sourcePath;
  final String? sourceExtension;
  final bool asPage;

  const EvidenceEditorSheet({
    super.key,
    this.existing,
    this.initialProject,
    this.sourcePath,
    this.sourceExtension,
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
  String? _pendingSourcePath;
  String? _pendingSourceExtension;
  EvidenceCategory _category = EvidenceCategory.invoice;
  EvidenceStatus _status = EvidenceStatus.pending;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _projectController = TextEditingController(
      text: existing?.projectName ?? widget.initialProject ?? '',
    );
    _amountController = TextEditingController(
      text: existing?.amount == null ? '' : existing!.amount!.toString(),
    );
    _merchantController = TextEditingController(text: existing?.merchant ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _evidenceDate = dateOnlyLocal(existing?.evidenceDate ?? DateTime.now());
    _tripDate = existing?.tripDate == null
        ? null
        : dateOnlyLocal(existing!.tripDate!);
    _pendingSourcePath = widget.sourcePath;
    _pendingSourceExtension = widget.sourceExtension;
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
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final semantic = theme.semanticColors;
    final fillColor = semantic.mutedSurface;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 10.h),
      child: Row(
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
    );

    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_previewPath != null) ...[
          SizedBox(height: 12.h),
          _buildAttachmentPreview(
            fillColor: fillColor,
            textSecondary: textSecondary,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEvidenceFromCamera,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('重拍'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEvidenceFromGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('更换'),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickEvidenceFromFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('导入文件'),
            ),
          ),
        ] else ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEvidenceFromCamera,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('拍摄凭证'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEvidenceFromGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('导入截图'),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickEvidenceFromFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('导入文件'),
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
                  onPicked: (date) => setState(() => _evidenceDate = date),
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
          label: _tripDate == null ? '关联出差日期（可选）' : _formatDate(_tripDate!),
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
    );

    if (widget.asPage) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 28.h),
                  child: formContent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final view = View.of(context);
    final bottomInset = view.viewInsets.bottom / view.devicePixelRatio;
    final rootHeight = view.physicalSize.height / view.devicePixelRatio;
    final resizedByKeyboard = rootHeight - MediaQuery.sizeOf(context).height;
    final keyboardInset = bottomInset > 0 ? bottomInset : resizedByKeyboard;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.92.sh),
        padding: EdgeInsets.only(bottom: 24.h),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: semantic.border, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, keyboardInset),
                child: formContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _previewPath =>
      _pendingSourcePath ?? widget.existing?.localFilePath;

  Widget _buildAttachmentPreview({
    required Color fillColor,
    required Color textSecondary,
  }) {
    final path = _previewPath;
    if (path == null) return const SizedBox.shrink();

    if (_isImagePath(path)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          height: 160.h,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildAttachmentFallback(
            fillColor: fillColor,
            textSecondary: textSecondary,
            path: path,
          ),
        ),
      );
    }

    return _buildAttachmentFallback(
      fillColor: fillColor,
      textSecondary: textSecondary,
      path: path,
    );
  }

  Widget _buildAttachmentFallback({
    required Color fillColor,
    required Color textSecondary,
    required String path,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 160.h,
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.semanticColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            color: textSecondary,
            size: 30.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            _fileName(path),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _attachmentTypeLabel(path),
            style: TextStyle(color: textSecondary, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.heic');
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String _attachmentTypeLabel(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF 发票';
    if (_isImagePath(path)) return '图片附件';
    return '文件附件';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color fillColor,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: semantic.border, width: 1),
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      scrollPadding: EdgeInsets.only(
        bottom:
            View.of(context).viewInsets.bottom /
                View.of(context).devicePixelRatio +
            96.h,
      ),
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: fillColor,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
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
    final semantic = theme.semanticColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(minHeight: 56.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: semantic.border, width: 1),
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
    final semantic = theme.semanticColors;
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: semantic.border, width: 1),
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
      onPicked(dateOnlyLocal(picked));
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
      Get.snackbar('错误', '请输入项目名称');
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

    EvidenceController.to.saveEvidence(
      next,
      sourcePath: _pendingSourcePath,
      sourceExtension: _pendingSourceExtension,
    );
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
        _pendingSourcePath != null;
  }

  String _formatDate(DateTime date) => formatDateYmd(date);

  Future<void> _pickEvidenceFromCamera() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (file == null) return;
    setState(() {
      _pendingSourcePath = file.path;
      _pendingSourceExtension = null;
    });
  }

  Future<void> _pickEvidenceFromGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (file == null) return;
    setState(() {
      _pendingSourcePath = file.path;
      _pendingSourceExtension = null;
    });
  }

  Future<void> _pickEvidenceFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final file = result?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty) return;
    setState(() {
      _pendingSourcePath = path;
      _pendingSourceExtension = file?.extension;
    });
  }
}
