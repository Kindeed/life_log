import 'dart:io';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/common/utils/sync_id_generator.dart';
import 'package:path_provider/path_provider.dart';

import 'evidence_model.dart';

class EvidenceRepository extends GetxService {
  static EvidenceRepository get to => Get.find();

  String _sanitizePathSegment(String value, {String fallback = 'Untitled'}) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (sanitized.isEmpty) return fallback;
    return sanitized;
  }

  Future<String> _availablePath(String directory, String fileName) async {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex <= 0 ? fileName : fileName.substring(0, dotIndex);
    final extension = dotIndex <= 0 ? '' : fileName.substring(dotIndex);

    var candidate = '$directory/$fileName';
    var suffix = 1;
    while (await File(candidate).exists()) {
      candidate = '$directory/${baseName}_$suffix$extension';
      suffix++;
    }
    return candidate;
  }

  Future<List<ExpenseEvidence>> getAllEvidence() {
    return DbService.to.getAllEvidence();
  }

  Stream<void> watchEvidence() {
    return DbService.to.watchEvidence();
  }

  Future<ExpenseEvidence> saveEvidence(
    ExpenseEvidence evidence, {
    String? sourcePath,
    String? sourceExtension,
  }) async {
    evidence.syncId ??= SyncIdGenerator.newSyncId();

    if (sourcePath != null && sourcePath.isNotEmpty) {
      await _copyEvidenceFile(
        evidence,
        sourcePath: sourcePath,
        sourceExtension: sourceExtension,
      );
    }

    await DbService.to.addEvidence(evidence);
    if (!Get.isRegistered<SyncService>()) {
      LogService.to.info('EvidenceRepository', '本地模式：跳过云端同步');
      return evidence;
    }

    try {
      final success = await SyncService.to.pushEvidence(evidence);
      if (!success) {
        LogService.to.error('EvidenceRepository', '云端同步未完成，保留待同步状态');
      }
    } catch (e) {
      LogService.to.error('EvidenceRepository', '云端同步失败: $e');
    }
    return evidence;
  }

  Future<void> _copyEvidenceFile(
    ExpenseEvidence evidence, {
    required String sourcePath,
    String? sourceExtension,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final safeProject = _sanitizePathSegment(
      evidence.projectName,
      fallback: 'DefaultProject',
    );
    final folder = Directory('${appDir.path}/Evidence/$safeProject');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final extension = (sourceExtension?.trim().isNotEmpty == true)
        ? sourceExtension!.trim()
        : sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final normalizedExtension = extension.startsWith('.')
        ? extension.toLowerCase()
        : '.${extension.toLowerCase()}';
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(evidence.evidenceDate);
    final category = evidence.category.name;
    final fileName = '${category}_$dateStr$normalizedExtension';
    final targetPath = await _availablePath(folder.path, fileName);

    await sourceFile.copy(targetPath);
    evidence.localFilePath = targetPath;
    evidence.fileName = targetPath.substring(targetPath.lastIndexOf('/') + 1);
    evidence.mimeType = normalizedExtension == '.png'
        ? 'image/png'
        : normalizedExtension == '.pdf'
        ? 'application/pdf'
        : 'image/jpeg';
    evidence.uploadedAt = null;
    evidence.remoteStoragePath = null;
  }

  Future<void> deleteEvidence(int id) async {
    final evidence = await DbService.to.markEvidenceDeleted(id);

    try {
      if (evidence == null || evidence.remoteId == null) {
        await _deleteLocalFile(evidence);
        await DbService.to.purgeDeletedEvidence(id);
      } else if (!Get.isRegistered<SyncService>()) {
        LogService.to.info('EvidenceRepository', '本地模式：跳过云端删除');
      } else {
        final success = await SyncService.to.deleteEvidence(evidence);
        if (success) {
          await _deleteLocalFile(evidence);
          await DbService.to.purgeDeletedEvidence(id);
        }
      }
    } catch (e) {
      LogService.to.error('EvidenceRepository', '云端删除失败: $e');
    }
  }

  Future<void> _deleteLocalFile(ExpenseEvidence? evidence) async {
    final path = evidence?.localFilePath;
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
