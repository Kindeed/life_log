import 'dart:io';

String sanitizePathSegment(String value, {String fallback = 'Untitled'}) {
  final sanitized = value
      .trim()
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (sanitized.isEmpty) return fallback;
  return sanitized;
}

Future<String> availablePath(String directory, String fileName) async {
  final dotIndex = fileName.lastIndexOf('.');
  final baseName = dotIndex <= 0 ? fileName : fileName.substring(0, dotIndex);
  final extension = dotIndex <= 0 ? '' : fileName.substring(dotIndex);

  var candidate = '$directory${Platform.pathSeparator}$fileName';
  var suffix = 1;
  while (await File(candidate).exists()) {
    candidate =
        '$directory${Platform.pathSeparator}${baseName}_$suffix$extension';
    suffix++;
  }
  return candidate;
}
