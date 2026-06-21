import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('package and release hardening', () {
    test('Android OCR dependencies keep only the used Chinese text pack', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final parser = File(
        'lib/features/evidence/data/evidence_parse_service.dart',
      ).readAsStringSync();

      expect(parser, contains('TextRecognitionScript.chinese'));
      expect(
        gradle,
        contains('com.google.mlkit:text-recognition-chinese:16.0.1'),
      );
      expect(gradle, isNot(contains('text-recognition-devanagari')));
      expect(gradle, isNot(contains('text-recognition-japanese')));
      expect(gradle, isNot(contains('text-recognition-korean')));
    });

    test('GitHub APK workflows generate a size report with thresholds', () {
      final releaseWorkflow = File(
        '.github/workflows/build.yml',
      ).readAsStringSync();
      final testWorkflow = File(
        '.github/workflows/test-apk.yml',
      ).readAsStringSync();
      final mainCiWorkflow = File(
        '.github/workflows/ci-main-apk.yml',
      ).readAsStringSync();

      for (final source in [releaseWorkflow, testWorkflow, mainCiWorkflow]) {
        expect(source, contains('tool/apk_size_report.dart'));
        expect(source, contains('lifelog-apk-size-report.md'));
      }
      expect(releaseWorkflow, contains('--max-mb=120'));
      expect(testWorkflow, contains('--max-mb=250'));
      expect(mainCiWorkflow, contains('--max-mb=250'));
      expect(
        releaseWorkflow,
        contains('build/app/outputs/flutter-apk/lifelog-apk-size-report.md'),
      );
      expect(
        testWorkflow,
        contains('build/app/outputs/flutter-apk/lifelog-apk-size-report.md'),
      );
      expect(
        mainCiWorkflow,
        contains('build/app/outputs/flutter-apk/lifelog-apk-size-report.md'),
      );
    });

    test('APK size report script writes reviewed APK sizes', () async {
      final temp = Directory.systemTemp.createTempSync('lifelog_apk_size_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final apk = File('${temp.path}/lifelog-arm64-v8a-release.apk');
      apk.writeAsBytesSync(List<int>.filled(2048, 0));
      final report = File('${temp.path}/report.md');

      final result = await Process.run('dart', [
        'tool/apk_size_report.dart',
        temp.path,
        report.path,
        '--max-mb=1',
      ], runInShell: true);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final source = report.readAsStringSync();
      expect(source, contains('LifeLog APK Size Report'));
      expect(source, contains('lifelog-arm64-v8a-release.apk'));
      expect(source, contains('Threshold: 1.0 MB per APK'));
    });

    test('release metadata is visible in diagnostics and protocol docs', () {
      final metadata = File(
        'lib/core/release/release_metadata.dart',
      ).readAsStringSync();
      final logs = File(
        'lib/common/services/log_service.dart',
      ).readAsStringSync();
      final protocol = File('docs/sync-protocol.md').readAsStringSync();

      expect(metadata, contains('localSchemaVersion = 2026062101'));
      expect(metadata, contains('syncProtocolVersion = 2'));
      expect(metadata, contains("minimumSupportedAppVersion = '1.4.16'"));
      expect(metadata, contains('minimumSupportedBuildNumber = 22'));
      expect(logs, contains('ReleaseMetadata.diagnosticLines()'));
      expect(protocol, contains('Sync protocol version: `2`'));
      expect(protocol, contains('Minimum supported app version: `1.4.16+22`'));
      expect(protocol, contains('Photos are local-only'));
    });
  });
}
