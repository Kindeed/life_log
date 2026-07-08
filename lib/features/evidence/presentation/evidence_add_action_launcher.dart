import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/features/evidence/data/evidence_file_utils.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_lost_data_recovery.dart';

void showEvidenceAddActions(
  BuildContext context, {
  String? initialProject,
  String? title,
  String galleryTitle = '从相册导入',
  String fileSubtitle = '发票、PDF 或截图文件',
  String? manualSubtitle = '没有截图时先记录金额和状态',
}) {
  final sheetTitle =
      title ?? (initialProject == null ? '添加凭证' : '添加到 $initialProject');

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final semantic = theme.semanticColors;
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: semantic.border.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                sheetTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _EvidenceActionTile(
                icon: Icons.camera_alt_rounded,
                title: '拍摄凭证',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(
                    _captureEvidence(context, initialProject: initialProject),
                  );
                },
              ),
              _EvidenceActionTile(
                icon: Icons.photo_library_rounded,
                title: galleryTitle,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(
                    _importEvidenceImage(
                      context,
                      initialProject: initialProject,
                    ),
                  );
                },
              ),
              _EvidenceActionTile(
                icon: Icons.upload_file_rounded,
                title: '导入文件',
                subtitle: fileSubtitle,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(
                    _importEvidenceFile(
                      context,
                      initialProject: initialProject,
                    ),
                  );
                },
              ),
              _EvidenceActionTile(
                icon: Icons.edit_note_rounded,
                title: '手动记录',
                subtitle: manualSubtitle,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(
                    showEvidenceEditorSheet(
                      context,
                      initialProject: initialProject,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _captureEvidence(
  BuildContext context, {
  String? initialProject,
}) async {
  final pendingPickerStore = EvidencePendingPickerStore();
  try {
    await pendingPickerStore.rememberLaunch(
      initialProject: initialProject,
      source: EvidencePendingPickerSource.camera,
    );
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    await pendingPickerStore.clear();
    if (image == null || !context.mounted) return;
    await showEvidenceEditorSheet(
      context,
      initialProject: initialProject,
      sourcePath: image.path,
    );
  } catch (error, stackTrace) {
    await pendingPickerStore.clear();
    LogService.to.error('Evidence', '无法打开系统相机: $error', stackTrace);
    if (!context.mounted) return;
    _showSnack(context, '无法打开系统相机: $error');
  }
}

Future<void> _importEvidenceImage(
  BuildContext context, {
  String? initialProject,
}) async {
  final pendingPickerStore = EvidencePendingPickerStore();
  try {
    await pendingPickerStore.rememberLaunch(
      initialProject: initialProject,
      source: EvidencePendingPickerSource.gallery,
    );
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    await pendingPickerStore.clear();
    if (image == null || !context.mounted) return;
    await showEvidenceEditorSheet(
      context,
      initialProject: initialProject,
      sourcePath: image.path,
    );
  } catch (error, stackTrace) {
    await pendingPickerStore.clear();
    LogService.to.error('Evidence', '无法导入凭证图片: $error', stackTrace);
    if (!context.mounted) return;
    _showSnack(context, '无法导入凭证图片: $error');
  }
}

Future<void> _importEvidenceFile(
  BuildContext context, {
  String? initialProject,
}) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: evidenceImportExtensions,
    );
    final file = result?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty || !context.mounted) return;
    await showEvidenceEditorSheet(
      context,
      initialProject: initialProject,
      sourcePath: path,
      sourceExtension: file?.extension,
    );
  } catch (error, stackTrace) {
    LogService.to.error('Evidence', '无法导入凭证文件: $error', stackTrace);
    if (!context.mounted) return;
    _showSnack(context, '无法导入凭证文件: $error');
  }
}

void _showSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _EvidenceActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _EvidenceActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minTileHeight: 56,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}
