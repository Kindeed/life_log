import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/evidence_file_utils.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';
import 'package:life_log/modules/evidence/evidence_parse_service.dart';
import 'package:life_log/modules/evidence/evidence_summary_utils.dart';
import 'package:pdfx/pdfx.dart';

void showEvidenceDetailSheet(ExpenseEvidence item) {
  Get.bottomSheet(
    EvidenceDetailSheet(item: item),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class EvidenceDetailSheet extends StatefulWidget {
  final ExpenseEvidence item;

  const EvidenceDetailSheet({super.key, required this.item});

  @override
  State<EvidenceDetailSheet> createState() => _EvidenceDetailSheetState();
}

class _EvidenceDetailSheetState extends State<EvidenceDetailSheet> {
  late ExpenseEvidence _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    final controller = EvidenceController.to;
    final theme = Theme.of(context);
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final title = evidenceDisplayTitle(_item);
    final path = _item.localFilePath;
    final hasLocalFile = path != null && File(path).existsSync();
    final canTryRestore = !hasLocalFile && _item.remoteStoragePath != null;
    final canParse = hasLocalFile && isEvidenceParseablePath(path);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.9.sh),
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: Get.back,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              EvidenceAttachmentPreview(item: _item, height: 260.h),
              if (!hasLocalFile) ...[
                SizedBox(height: 10.h),
                _MissingFileNotice(
                  canTryRestore: canTryRestore,
                  onRestore: () async {
                    final restored = await controller.ensureLocalEvidenceFile(
                      _item,
                      notify: true,
                    );
                    if (restored && mounted) setState(() {});
                  },
                ),
              ],
              SizedBox(height: 16.h),
              _InfoRow(label: '项目', value: _item.projectName),
              _InfoRow(label: '日期', value: formatDateYmd(_item.evidenceDate)),
              _InfoRow(label: '金额', value: formatMoney(_item.amount ?? 0)),
              _InfoRow(label: '类型', value: _item.category.label),
              _InfoRow(label: '状态', value: _item.status.label),
              if (evidenceContentSummary(_item) case final summary?)
                _InfoRow(label: '摘要', value: summary),
              if (_item.fileName?.trim().isNotEmpty == true)
                _InfoRow(label: '文件', value: _item.fileName!.trim()),
              if (_item.tripDate != null)
                _InfoRow(label: '出差日期', value: formatDateYmd(_item.tripDate!)),
              if (_item.note?.trim().isNotEmpty == true)
                _InfoRow(label: '备注', value: _item.note!.trim()),
              SizedBox(height: 18.h),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.open_in_new_rounded,
                          label: '打开',
                          onPressed: () => controller.openEvidenceFile(_item),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.ios_share_rounded,
                          label: '导出',
                          onPressed: () => controller.exportEvidenceFile(_item),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _ActionButton(
                            icon: Icons.document_scanner_rounded,
                            label: controller.isParsing.value ? '解析中' : '解析',
                            onPressed: canParse && !controller.isParsing.value
                                ? () => _parseAndApply(controller)
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.edit_rounded,
                          label: '编辑',
                          filled: true,
                          onPressed: () {
                            Get.back();
                            controller.editEvidence(_item);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _parseAndApply(EvidenceController controller) async {
    final result = await controller.parseEvidenceFile(_item);
    if (result == null) return;

    final next = _copyEvidence(_item);
    final changed = _applyParsedFields(next, result);
    if (!changed) {
      Get.snackbar('解析完成', '识别结果没有可自动填入的空字段');
      return;
    }

    next.isDirty = true;
    await controller.saveEvidence(next);
    _item = next;
  }

  bool _applyParsedFields(ExpenseEvidence target, EvidenceParseResult result) {
    var changed = false;
    if (target.amount == null && result.amount != null) {
      target.amount = result.amount;
      changed = true;
    }
    if ((target.merchant == null || target.merchant!.trim().isEmpty) &&
        result.merchant != null) {
      target.merchant = result.merchant;
      changed = true;
    }
    if (target.currency.trim().isEmpty && result.currency != null) {
      target.currency = result.currency!;
      changed = true;
    }
    if (result.evidenceDate != null && _isToday(target.evidenceDate)) {
      target.evidenceDate = result.evidenceDate!;
      changed = true;
    }
    final nextNote = _appendParsedNoteLines(target.note, result.noteLines);
    if (nextNote != (target.note?.trim() ?? '')) {
      target.note = nextNote;
      changed = true;
    }
    return changed;
  }

  String _appendParsedNoteLines(String? current, List<String> lines) {
    final nextLines = (current ?? '')
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
        line.startsWith('纳税号：');
  }

  bool _isToday(DateTime date) {
    final normalized = dateOnlyLocal(date);
    final today = dateOnlyLocal(DateTime.now());
    return normalized.year == today.year &&
        normalized.month == today.month &&
        normalized.day == today.day;
  }

  ExpenseEvidence _copyEvidence(ExpenseEvidence source) {
    return ExpenseEvidence()
      ..id = source.id
      ..ownerUserId = source.ownerUserId
      ..remoteId = source.remoteId
      ..syncId = source.syncId
      ..remoteVersion = source.remoteVersion
      ..remoteUpdatedAt = source.remoteUpdatedAt
      ..syncedAt = source.syncedAt
      ..isDirty = source.isDirty
      ..deletedAt = source.deletedAt
      ..pendingDelete = source.pendingDelete
      ..createdAt = source.createdAt
      ..updatedAt = source.updatedAt
      ..projectName = source.projectName
      ..projectId = source.projectId
      ..evidenceDate = source.evidenceDate
      ..amount = source.amount
      ..currency = source.currency
      ..category = source.category
      ..status = source.status
      ..merchant = source.merchant
      ..note = source.note
      ..localFilePath = source.localFilePath
      ..remoteStoragePath = source.remoteStoragePath
      ..fileName = source.fileName
      ..mimeType = source.mimeType
      ..uploadedAt = source.uploadedAt
      ..tripDate = source.tripDate;
  }
}

class EvidenceAttachmentPreview extends StatelessWidget {
  final ExpenseEvidence item;
  final double? width;
  final double height;

  const EvidenceAttachmentPreview({
    super.key,
    required this.item,
    this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final path = item.localFilePath;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        color: theme.colorScheme.surfaceContainerHighest,
        child: path == null || !File(path).existsSync()
            ? _placeholder(theme, Icons.receipt_long_rounded, '未找到本机文件')
            : isEvidenceImagePath(path)
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _placeholder(theme, Icons.broken_image_rounded, '无法显示图片'),
              )
            : isEvidencePdfPath(path) && width == null
            ? _PdfAttachmentPreview(path: path)
            : _FileAttachmentPreview(path: path),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 28.sp),
        SizedBox(height: 8.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}

class _PdfAttachmentPreview extends StatefulWidget {
  final String path;

  const _PdfAttachmentPreview({required this.path});

  @override
  State<_PdfAttachmentPreview> createState() => _PdfAttachmentPreviewState();
}

class _PdfAttachmentPreviewState extends State<_PdfAttachmentPreview> {
  late final PdfController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(document: PdfDocument.openFile(widget.path));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfView(
      controller: _controller,
      scrollDirection: Axis.vertical,
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) => _FileAttachmentPreview(path: widget.path),
      ),
    );
  }
}

class _FileAttachmentPreview extends StatelessWidget {
  final String path;

  const _FileAttachmentPreview({required this.path});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isEvidencePdfPath(path)
                ? Icons.picture_as_pdf_rounded
                : Icons.insert_drive_file_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 34.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            evidenceFileName(path),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            evidenceAttachmentTypeLabel(path),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingFileNotice extends StatelessWidget {
  final bool canTryRestore;
  final VoidCallback onRestore;

  const _MissingFileNotice({
    required this.canTryRestore,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.semanticColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.semanticColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.semanticColors.warning),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              canTryRestore ? '本机文件缺失，可尝试从云端恢复。' : '本机文件缺失，只保留了凭证记录。',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13.sp,
              ),
            ),
          ),
          if (canTryRestore)
            TextButton(onPressed: onRestore, child: const Text('恢复')),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18.sp),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    if (filled) {
      return SizedBox(
        height: 46.h,
        child: FilledButton(onPressed: onPressed, child: child),
      );
    }
    return SizedBox(
      height: 46.h,
      child: OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78.w,
            child: Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 13.sp),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
