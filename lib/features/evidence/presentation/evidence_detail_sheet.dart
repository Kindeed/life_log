import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/data/evidence_file_utils.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/data/evidence_parse_service.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/presentation/evidence_attachment_preview.dart';
import 'package:life_log/features/evidence/presentation/evidence_detail_file_actions.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_summary_utils.dart';

class EvidenceDetailSheet extends StatefulWidget {
  final ExpenseEvidence item;

  const EvidenceDetailSheet({super.key, required this.item});

  @override
  State<EvidenceDetailSheet> createState() => _EvidenceDetailSheetState();
}

class _EvidenceDetailSheetState extends State<EvidenceDetailSheet> {
  late ExpenseEvidence _item;
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
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
                    tooltip: '删除',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: _confirmDelete,
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.of(context).maybePop(),
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
                    final restored =
                        await EvidenceDetailFileActions.restoreLocalFile(
                          context,
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
                          onPressed: () =>
                              EvidenceDetailFileActions.open(context, _item),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.ios_share_rounded,
                          label: '导出',
                          onPressed: () =>
                              EvidenceDetailFileActions.export(context, _item),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.document_scanner_rounded,
                          label: _isParsing ? '解析中' : '解析',
                          onPressed: canParse && !_isParsing
                              ? _parseAndApply
                              : null,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.edit_rounded,
                          label: '编辑',
                          filled: true,
                          onPressed: () =>
                              showEvidenceEditorSheet(context, existing: _item),
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

  Future<void> _confirmDelete() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;
    final result = await serviceLocator<DeleteEvidenceEntry>().call(_item.id);
    final failure = result.failureOrNull;
    if (!mounted) return;
    if (failure != null) {
      _showActionFailure('删除失败', failure.message);
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    await Navigator.of(context).maybePop();
    _showActionSuccess('凭证已删除', messenger: messenger);
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

  Future<void> _parseAndApply() async {
    if (_isParsing) return;
    setState(() => _isParsing = true);

    final EvidenceParseResult? result;
    try {
      result = await EvidenceDetailFileActions.parse(context, _item);
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }

    if (!mounted || result == null) return;

    final next = _parsedEntry(result);
    if (next == null) {
      _showActionSuccess('识别结果没有可自动填入的空字段');
      return;
    }

    final saveResult = await serviceLocator<SaveEvidenceEntry>().call(
      next,
      markDirty: true,
    );
    final failure = saveResult.failureOrNull;
    if (!mounted) return;
    if (failure != null) {
      _showActionFailure('保存失败', failure.message);
      return;
    }

    setState(() {
      _item
        ..amount = next.amount
        ..currency = next.currency
        ..evidenceDate = next.evidenceDate
        ..merchant = next.merchant
        ..note = next.note;
    });
    _showActionSuccess('已填入识别到的空字段');
  }

  EvidenceEntry? _parsedEntry(EvidenceParseResult result) {
    var changed = false;
    var amount = _item.amount;
    var merchant = _item.merchant;
    var currency = _item.currency;
    var evidenceDate = _item.evidenceDate;
    var note = _item.note;

    if (amount == null && result.amount != null) {
      amount = result.amount;
      changed = true;
    }
    final parsedMerchant = result.merchant?.trim();
    if ((merchant == null || merchant.trim().isEmpty) &&
        parsedMerchant != null &&
        parsedMerchant.isNotEmpty) {
      merchant = parsedMerchant;
      changed = true;
    }
    final parsedCurrency = result.currency?.trim();
    if (currency.trim().isEmpty &&
        parsedCurrency != null &&
        parsedCurrency.isNotEmpty) {
      currency = parsedCurrency;
      changed = true;
    }
    if (result.evidenceDate != null && _isToday(evidenceDate)) {
      evidenceDate = result.evidenceDate!;
      changed = true;
    }
    final nextNote = _appendParsedNoteLines(note, result.noteLines);
    if (nextNote != (note?.trim() ?? '')) {
      note = nextNote;
      changed = true;
    }
    if (!changed) return null;

    return _evidenceEntryFromItem(
      _item,
      amount: amount,
      merchant: merchant,
      currency: currency,
      evidenceDate: evidenceDate,
      note: note,
    );
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

  void _showActionSuccess(String message, {ScaffoldMessengerState? messenger}) {
    final activeMessenger = messenger ?? ScaffoldMessenger.maybeOf(context);
    if (activeMessenger == null) return;
    activeMessenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _showActionFailure(String title, String message) {
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
}

EvidenceEntry _evidenceEntryFromItem(
  ExpenseEvidence item, {
  double? amount,
  String? merchant,
  String? currency,
  DateTime? evidenceDate,
  String? note,
}) {
  return EvidenceEntry(
    id: item.id,
    projectName: item.projectName,
    projectId: item.projectId,
    evidenceDate: evidenceDate ?? item.evidenceDate,
    amount: amount ?? item.amount,
    currency: currency ?? item.currency,
    category: item.category.toEvidenceEntryCategory(),
    status: item.status.toEvidenceEntryStatus(),
    merchant: merchant ?? item.merchant,
    note: note ?? item.note,
    localFilePath: item.localFilePath,
    remoteStoragePath: item.remoteStoragePath,
    fileName: item.fileName,
    mimeType: item.mimeType,
    uploadedAt: item.uploadedAt,
    tripDate: item.tripDate,
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
