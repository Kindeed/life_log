final class LogRedactor {
  static final RegExp _emailPattern = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _uuidPattern = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
  );
  static final RegExp _supabaseUrlPattern = RegExp(
    r'https://[A-Za-z0-9.-]+\.supabase\.co[^\s\)]*',
  );
  static final RegExp _windowsPathPattern = RegExp(
    r"""[A-Za-z]:\\[^\s\]\)'"]+""",
  );
  static final RegExp _storageAssignmentPattern = RegExp(
    r'\b(storage|storage_path|remote_storage_path)=\S+',
    caseSensitive: false,
  );

  static String redact(String input) {
    return input
        .replaceAll(_supabaseUrlPattern, 'https://[supabase-url]')
        .replaceAll(_emailPattern, '[email]')
        .replaceAll(_uuidPattern, '[id]')
        .replaceAllMapped(
          _storageAssignmentPattern,
          (match) => '${match.group(1)}=[storage-path]',
        )
        .replaceAll(_windowsPathPattern, '[local-path]');
  }
}
