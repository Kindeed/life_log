import 'package:path/path.dart' as p;

/// Cloud metadata is untrusted. Keep downloaded bytes in the chosen directory,
/// including when another client supplies a filename with path separators.
String safeEvidenceDownloadPath({
  required String directory,
  required String remoteFileName,
}) {
  final name = remoteFileName.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  if (name.isEmpty || name == '.' || name == '..') {
    throw StateError('Evidence file name is invalid');
  }
  final base = p.normalize(p.absolute(directory));
  final result = p.normalize(p.join(base, name));
  if (!p.isWithin(base, result)) {
    throw StateError('Evidence file path escapes its download directory');
  }
  return result;
}

bool evidenceStoragePathBelongsToOwner(String storagePath, String ownerId) {
  return storagePath.startsWith('$ownerId/') &&
      storagePath
          .split('/')
          .every(
            (part) =>
                part.isNotEmpty &&
                part != '.' &&
                part != '..' &&
                !part.contains('\\'),
          );
}

String evidenceAttachmentStoragePath({
  required String ownerId,
  required String evidenceSyncId,
  required String attachmentSyncId,
  required String originalFileName,
  String? remoteStoragePath,
}) {
  if (remoteStoragePath != null && remoteStoragePath.trim().isNotEmpty) {
    if (!evidenceStoragePathBelongsToOwner(remoteStoragePath, ownerId)) {
      throw StateError('Evidence storage path belongs to another owner');
    }
    return remoteStoragePath;
  }
  for (final identity in [ownerId, evidenceSyncId, attachmentSyncId]) {
    if (identity.isEmpty ||
        identity == '.' ||
        identity == '..' ||
        identity.contains('/') ||
        identity.contains('\\')) {
      throw StateError('Evidence storage identity is invalid');
    }
  }
  final basename = p.posix.basename(originalFileName.replaceAll('\\', '/'));
  final dot = basename.lastIndexOf('.');
  final extension = dot <= 0
      ? ''
      : basename.substring(dot).replaceAll(RegExp(r'[^.a-zA-Z0-9]'), '_');
  return '$ownerId/$evidenceSyncId/$attachmentSyncId$extension';
}
