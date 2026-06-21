import 'dart:io';

import 'package:intl/intl.dart';
import 'package:life_log/common/utils/file_path_utils.dart';
import 'package:life_log/features/evidence/data/evidence_file_utils.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class EvidenceFileStore {
  Future<void> copyEvidenceFile(
    ExpenseEvidence evidence, {
    required String sourcePath,
    String? sourceExtension,
  });

  Future<void> deleteEvidenceFile(ExpenseEvidence? evidence);
}

final class AppEvidenceFileStore implements EvidenceFileStore {
  const AppEvidenceFileStore();

  @override
  Future<void> copyEvidenceFile(
    ExpenseEvidence evidence, {
    required String sourcePath,
    String? sourceExtension,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final safeProject = sanitizePathSegment(
      evidence.projectName,
      fallback: 'DefaultProject',
    );
    final folder = Directory('${appDir.path}/Evidence/$safeProject');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final normalizedExtension = evidenceExtensionForPath(
      sourcePath,
      fallbackExtension: sourceExtension,
    );
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(evidence.evidenceDate);
    final category = evidence.category.name;
    final fileName = '${category}_$dateStr$normalizedExtension';
    final targetPath = await availablePath(folder.path, fileName);

    await sourceFile.copy(targetPath);
    evidence.localFilePath = targetPath;
    evidence.fileName = p.basename(targetPath);
    evidence.mimeType = evidenceMimeTypeForPath(targetPath);
    evidence.uploadedAt = null;
    evidence.remoteStoragePath = null;
  }

  @override
  Future<void> deleteEvidenceFile(ExpenseEvidence? evidence) async {
    final path = evidence?.localFilePath;
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
