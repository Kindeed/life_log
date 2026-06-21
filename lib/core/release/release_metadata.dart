final class ReleaseMetadata {
  static const int localSchemaVersion = 2026062101;
  static const int syncProtocolVersion = 2;
  static const String minimumSupportedAppVersion = '1.4.17';
  static const int minimumSupportedBuildNumber = 23;
  static const int minimumSupportedSyncProtocolVersion = 2;

  static Iterable<String> diagnosticLines() sync* {
    yield '本地 schema version: $localSchemaVersion';
    yield '同步协议 version: $syncProtocolVersion';
    yield '最低支持 App: $minimumSupportedAppVersion+$minimumSupportedBuildNumber';
    yield '最低支持同步协议: $minimumSupportedSyncProtocolVersion';
  }
}
