import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/data/evidence_file_utils.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/data/evidence_parse_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:life_log/common/widgets/app_feedback.dart';

typedef EvidenceActionFeedback = void Function(String message, bool isError);

final class EvidenceDetailFileActions {
  const EvidenceDetailFileActions._();

  static Future<bool> restoreLocalFile(
    BuildContext context,
    ExpenseEvidence item, {
    bool notify = true,
    EvidenceActionFeedback? feedback,
  }) async {
    final path = item.localFilePath;
    if (path != null && await File(path).exists()) return true;
    if (!context.mounted) return false;

    if (item.remoteStoragePath == null ||
        !serviceLocator.isRegistered<SyncService>()) {
      if (notify) {
        _showSnack(context, '本机没有此凭证文件', feedback: feedback, isError: true);
      }
      return false;
    }

    try {
      await serviceLocator<SyncService>().downloadEvidenceFile(item);
      final restoredPath = item.localFilePath;
      final restored =
          restoredPath != null && await File(restoredPath).exists();
      if (!context.mounted) return restored;
      if (restored && notify) {
        _showSnack(context, '凭证文件已从云端下载到本机', feedback: feedback);
      }
      return restored;
    } catch (error, stackTrace) {
      LogService.to.error('Evidence', '恢复凭证文件失败: $error', stackTrace);
      if (!context.mounted) return false;
      if (notify) {
        _showSnack(context, '无法从云端恢复此凭证文件', feedback: feedback, isError: true);
      }
      return false;
    }
  }

  static Future<void> open(
    BuildContext context,
    ExpenseEvidence item, {
    EvidenceActionFeedback? feedback,
  }) async {
    final hasFile = await restoreLocalFile(context, item, notify: false);
    if (!context.mounted) return;
    final path = item.localFilePath;
    if (!hasFile || path == null) {
      _showSnack(context, '本机没有可打开的凭证文件', feedback: feedback, isError: true);
      return;
    }

    try {
      final result = await OpenFilex.open(path);
      if (!context.mounted) return;
      if (result.type != ResultType.done) {
        _showSnack(context, result.message, feedback: feedback, isError: true);
      }
    } catch (error, stackTrace) {
      LogService.to.error('Evidence', '打开凭证文件失败: $error', stackTrace);
      if (!context.mounted) return;
      _showSnack(context, error.toString(), feedback: feedback, isError: true);
    }
  }

  static Future<void> export(
    BuildContext context,
    ExpenseEvidence item, {
    EvidenceActionFeedback? feedback,
  }) async {
    final hasFile = await restoreLocalFile(context, item, notify: false);
    if (!context.mounted) return;
    final path = item.localFilePath;
    if (!hasFile || path == null) {
      _showSnack(context, '本机没有可导出的凭证文件', feedback: feedback, isError: true);
      return;
    }

    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return;

      final fileName = item.fileName ?? path.split(Platform.pathSeparator).last;
      await File(
        path,
      ).copy('$selectedDirectory${Platform.pathSeparator}$fileName');
      if (!context.mounted) return;
      _showSnack(context, '凭证文件已导出', feedback: feedback);
    } catch (error, stackTrace) {
      LogService.to.error('Evidence', '导出凭证文件失败: $error', stackTrace);
      if (!context.mounted) return;
      _showSnack(context, error.toString(), feedback: feedback, isError: true);
    }
  }

  static Future<EvidenceParseResult?> parse(
    BuildContext context,
    ExpenseEvidence item, {
    EvidenceActionFeedback? feedback,
  }) async {
    final hasFile = await restoreLocalFile(context, item, notify: false);
    if (!context.mounted) return null;
    final path = item.localFilePath;
    if (!hasFile || path == null) {
      _showSnack(context, '本机没有可解析的凭证文件', feedback: feedback, isError: true);
      return null;
    }
    if (!isEvidenceParseablePath(path)) {
      _showSnack(
        context,
        '当前仅支持解析图片或 PDF 凭证',
        feedback: feedback,
        isError: true,
      );
      return null;
    }

    try {
      final result = await serviceLocator<EvidenceParseService>().parseFile(
        path,
      );
      if (!context.mounted) return result;
      if (!result.hasAnyField) {
        _showSnack(context, '没有识别到可自动填入的字段', feedback: feedback);
      }
      return result;
    } catch (error, stackTrace) {
      LogService.to.error('Evidence', '解析凭证失败: $error', stackTrace);
      if (!context.mounted) return null;
      _showSnack(context, error.toString(), feedback: feedback, isError: true);
      return null;
    }
  }
}

void _showSnack(
  BuildContext context,
  String message, {
  EvidenceActionFeedback? feedback,
  bool isError = false,
}) {
  if (!context.mounted) return;
  if (feedback != null) {
    feedback(message, isError);
  } else {
    AppFeedback.capture(context).show(
      message,
      kind: isError ? AppFeedbackKind.error : AppFeedbackKind.info,
    );
  }
}
