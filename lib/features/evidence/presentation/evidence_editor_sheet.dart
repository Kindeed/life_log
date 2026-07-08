import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_date_picker.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/data/evidence_file_utils.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/data/evidence_parse_service.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_cubit.dart';
import 'package:life_log/features/evidence/presentation/evidence_lost_data_recovery.dart';

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
  late final EvidenceEditorCubit _editorCubit;
  late final TextEditingController _projectController;
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late final EvidencePendingPickerStore _pendingPickerStore;
  bool _isParsingAttachment = false;

  @override
  void initState() {
    super.initState();
    _pendingPickerStore = EvidencePendingPickerStore();
    _editorCubit = EvidenceEditorCubit(
      saveEntry: serviceLocator<SaveEvidenceEntry>(),
      deleteEntry: serviceLocator<DeleteEvidenceEntry>(),
      selectedDate: DateTime.now(),
      existingEntry: _evidenceEntryFromLegacy(widget.existing),
      existingAlreadyDirty: widget.existing?.isDirty ?? false,
      initialProjectName: widget.initialProject,
      sourcePath: widget.sourcePath,
      sourceExtension: widget.sourceExtension,
    );

    final editorState = _editorCubit.state;
    _projectController = TextEditingController(text: editorState.projectName);
    _amountController = TextEditingController(text: editorState.amountText);
    _merchantController = TextEditingController(text: editorState.merchant);
    _noteController = TextEditingController(text: editorState.note);
  }

  @override
  void dispose() {
    _editorCubit.close();
    _projectController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _editorCubit,
      child: BlocListener<EvidenceEditorCubit, EvidenceEditorState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.failure != current.failure,
        listener: (context, editorState) {
          unawaited(_handleEditorState(context, editorState));
        },
        child: BlocBuilder<EvidenceEditorCubit, EvidenceEditorState>(
          builder: (context, editorState) {
            return _buildEditor(context, editorState);
          },
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context, EvidenceEditorState editorState) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final semantic = theme.semanticColors;
    final fillColor = semantic.mutedSurface;
    final previewPath = _previewPath(editorState);
    final isBusy =
        editorState.status == EvidenceEditorStatus.submitting ||
        editorState.status == EvidenceEditorStatus.deleting;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              editorState.existingEntry == null ? '添加凭证' : '编辑凭证',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: textSecondary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );

    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (previewPath != null) ...[
          SizedBox(height: 12.h),
          _buildAttachmentPreview(
            path: previewPath,
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
          if (isEvidenceParseablePath(previewPath)) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isParsingAttachment ? null : _parseAttachment,
                icon: const Icon(Icons.document_scanner_rounded),
                label: Text(_isParsingAttachment ? '正在解析' : '解析附件'),
              ),
            ),
          ],
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
                label: _formatDate(editorState.evidenceDate),
                icon: Icons.event_rounded,
                fillColor: fillColor,
                onTap: () => _pickDate(
                  initial: editorState.evidenceDate,
                  onPicked: _editorCubit.changeEvidenceDate,
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
              child: _buildDropdown<EvidenceEntryCategory>(
                value: editorState.category,
                values: EvidenceEntryCategory.values,
                labelBuilder: (value) => value.label,
                icon: Icons.category_rounded,
                fillColor: fillColor,
                onChanged: _editorCubit.changeCategory,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildDropdown<EvidenceEntryStatus>(
                value: editorState.evidenceStatus,
                values: EvidenceEntryStatus.values,
                labelBuilder: (value) => value.label,
                icon: Icons.verified_rounded,
                fillColor: fillColor,
                onChanged: _editorCubit.changeEvidenceStatus,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildPickerTile(
          label: editorState.tripDate == null
              ? '关联出差日期（可选）'
              : _formatDate(editorState.tripDate!),
          icon: Icons.luggage_rounded,
          fillColor: fillColor,
          trailing: editorState.tripDate == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => _editorCubit.changeTripDate(null),
                ),
          onTap: () => _pickDate(
            initial: editorState.tripDate ?? editorState.evidenceDate,
            onPicked: _editorCubit.changeTripDate,
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
        if (editorState.existingEntry == null)
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(isBusy ? '正在保存' : '保存凭证'),
              style: _primaryButtonStyle(context),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : _confirmDelete,
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
                  onPressed: isBusy ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(isBusy ? '正在保存' : '保存修改'),
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

  String? _previewPath(EvidenceEditorState editorState) {
    return editorState.pendingSourcePath ??
        editorState.existingEntry?.localFilePath;
  }

  Widget _buildAttachmentPreview({
    required String path,
    required Color fillColor,
    required Color textSecondary,
  }) {
    if (isEvidenceImagePath(path)) {
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

  String _fileName(String path) {
    return evidenceFileName(path);
  }

  String _attachmentTypeLabel(String path) => evidenceAttachmentTypeLabel(path);

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
    final picked = await showLifeLogDatePicker(
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
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed || _editorCubit.state.existingEntry == null) return;
    await _editorCubit.delete();
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除凭证'),
          content: const Text('确定删除这条凭证记录吗？删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _save() async {
    _syncTextControllersToEditor();
    await _editorCubit.submit();
  }

  Future<void> _handleEditorState(
    BuildContext context,
    EvidenceEditorState editorState,
  ) async {
    switch (editorState.status) {
      case EvidenceEditorStatus.saved:
      case EvidenceEditorStatus.deleted:
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (!context.mounted) return;
        await Navigator.of(context).maybePop();
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                editorState.status == EvidenceEditorStatus.saved
                    ? '凭证记录已保存'
                    : '凭证已删除',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        break;
      case EvidenceEditorStatus.failure:
        _showEditorFailure(context, editorState.failure);
        break;
      case EvidenceEditorStatus.editing:
      case EvidenceEditorStatus.submitting:
      case EvidenceEditorStatus.deleting:
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

  String _formatDate(DateTime date) => formatDateYmd(date);

  Future<void> _pickEvidenceFromCamera() async {
    await _pendingPickerStore.rememberLaunch(
      source: EvidencePendingPickerSource.camera,
      initialProject: _editorCubit.state.projectName,
    );
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (file == null || !mounted) return;
      _editorCubit.changeAttachment(file.path);
    } finally {
      await _pendingPickerStore.clear();
    }
  }

  Future<void> _pickEvidenceFromGallery() async {
    await _pendingPickerStore.rememberLaunch(
      source: EvidencePendingPickerSource.gallery,
      initialProject: _editorCubit.state.projectName,
    );
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (file == null || !mounted) return;
      _editorCubit.changeAttachment(file.path);
    } finally {
      await _pendingPickerStore.clear();
    }
  }

  Future<void> _pickEvidenceFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: evidenceImportExtensions,
    );
    final file = result?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty || !mounted) return;
    _editorCubit.changeAttachment(path, sourceExtension: file?.extension);
  }

  Future<void> _parseAttachment() async {
    final path = _previewPath(_editorCubit.state);
    if (path == null) return;
    if (!isEvidenceParseablePath(path)) {
      _showEditorMessage(context, '当前仅支持解析图片或 PDF 凭证');
      return;
    }

    setState(() => _isParsingAttachment = true);
    try {
      final result = await serviceLocator<EvidenceParseService>().parseFile(
        path,
      );
      if (!mounted) return;
      var changed = false;

      if (result.amount != null && _amountController.text.trim().isEmpty) {
        _amountController.text = result.amount!.toStringAsFixed(2);
        _editorCubit.changeAmountText(_amountController.text);
        changed = true;
      }
      if (result.merchant != null && _merchantController.text.trim().isEmpty) {
        _merchantController.text = result.merchant!;
        _editorCubit.changeMerchant(_merchantController.text);
        changed = true;
      }
      if (result.evidenceDate != null && _shouldApplyParsedDate()) {
        _editorCubit.changeEvidenceDate(result.evidenceDate!);
        changed = true;
      }
      final nextNote = _appendParsedNoteLines(
        _noteController.text,
        result.noteLines,
      );
      if (nextNote != _noteController.text.trim()) {
        _noteController.text = nextNote;
        _editorCubit.changeNote(_noteController.text);
        changed = true;
      }

      setState(() {});
      _showEditorMessage(context, changed ? '已填入识别到的空字段' : '没有识别到可自动填入的字段');
    } catch (e) {
      if (!mounted) return;
      _showEditorMessage(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isParsingAttachment = false);
      }
    }
  }

  void _showEditorMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  bool _shouldApplyParsedDate() {
    final editorState = _editorCubit.state;
    return editorState.existingEntry == null;
  }

  String _appendParsedNoteLines(String current, List<String> lines) {
    final nextLines = current
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !_isGeneratedParsedNoteLine(line))
        .toList();
    final existing = nextLines.join('\n');
    for (final line in lines) {
      if (line.trim().isEmpty || existing.contains(line)) continue;
      nextLines.add(line);
    }
    return nextLines.join('\n');
  }

  bool _isGeneratedParsedNoteLine(String line) {
    return line.startsWith('发票号：') ||
        line.startsWith('消费内容：') ||
        line.startsWith('购买方：') ||
        line.startsWith('纳税号：') ||
        line.startsWith('校验：');
  }
}

EvidenceEntry? _evidenceEntryFromLegacy(ExpenseEvidence? evidence) {
  if (evidence == null) return null;
  return EvidenceEntry(
    id: evidence.id,
    projectName: evidence.projectName,
    projectId: evidence.projectId,
    evidenceDate: evidence.evidenceDate,
    amount: evidence.amount,
    currency: evidence.currency,
    category: evidence.category.toEvidenceEntryCategory(),
    status: evidence.status.toEvidenceEntryStatus(),
    merchant: evidence.merchant,
    note: evidence.note,
    localFilePath: evidence.localFilePath,
    remoteStoragePath: evidence.remoteStoragePath,
    fileName: evidence.fileName,
    mimeType: evidence.mimeType,
    uploadedAt: evidence.uploadedAt,
    tripDate: evidence.tripDate,
  );
}

extension on EvidenceCategory {
  EvidenceEntryCategory toEvidenceEntryCategory() {
    return switch (this) {
      EvidenceCategory.invoice => EvidenceEntryCategory.invoice,
      EvidenceCategory.payment => EvidenceEntryCategory.payment,
      EvidenceCategory.purchase => EvidenceEntryCategory.purchase,
      EvidenceCategory.travel => EvidenceEntryCategory.travel,
      EvidenceCategory.meal => EvidenceEntryCategory.meal,
      EvidenceCategory.accommodation => EvidenceEntryCategory.accommodation,
      EvidenceCategory.other => EvidenceEntryCategory.other,
    };
  }
}

extension on EvidenceStatus {
  EvidenceEntryStatus toEvidenceEntryStatus() {
    return switch (this) {
      EvidenceStatus.pending => EvidenceEntryStatus.pending,
      EvidenceStatus.submitted => EvidenceEntryStatus.submitted,
      EvidenceStatus.reimbursed => EvidenceEntryStatus.reimbursed,
    };
  }
}
