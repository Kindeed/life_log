import 'package:path/path.dart' as p;

const evidenceImportExtensions = [
  'jpg',
  'jpeg',
  'png',
  'webp',
  'gif',
  'heic',
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'xml',
  'tif',
  'tiff',
];

String evidenceExtensionForPath(String path, {String? fallbackExtension}) {
  final fromFallback = fallbackExtension?.trim();
  if (fromFallback != null && fromFallback.isNotEmpty) {
    return fromFallback.startsWith('.')
        ? fromFallback.toLowerCase()
        : '.${fromFallback.toLowerCase()}';
  }

  final extension = p.extension(path).trim();
  return extension.isEmpty ? '.jpg' : extension.toLowerCase();
}

String evidenceFileName(String path) => p.basename(path);

bool isEvidenceImagePath(String path) {
  final extension = evidenceExtensionForPath(path);
  return const {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.heic',
  }.contains(extension);
}

bool isEvidencePdfPath(String path) => evidenceExtensionForPath(path) == '.pdf';

bool isEvidenceParseablePath(String path) {
  return isEvidenceImagePath(path) || isEvidencePdfPath(path);
}

String evidenceMimeTypeForPath(String path, {String? fallbackExtension}) {
  switch (evidenceExtensionForPath(
    path,
    fallbackExtension: fallbackExtension,
  )) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.heic':
      return 'image/heic';
    case '.pdf':
      return 'application/pdf';
    case '.doc':
      return 'application/msword';
    case '.docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case '.xls':
      return 'application/vnd.ms-excel';
    case '.xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case '.xml':
      return 'application/xml';
    case '.tif':
    case '.tiff':
      return 'image/tiff';
    default:
      return 'application/octet-stream';
  }
}

String evidenceAttachmentTypeLabel(String path) {
  if (isEvidencePdfPath(path)) return 'PDF 发票';
  if (isEvidenceImagePath(path)) return '图片附件';
  return '文件附件';
}
