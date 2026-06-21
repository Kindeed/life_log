import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('release and test APK workflows', () {
    test('run format, fatal analyze, and tests before APK builds', () {
      final workflowPaths = [
        '.github/workflows/build.yml',
        '.github/workflows/test-apk.yml',
      ];

      for (final path in workflowPaths) {
        final source = File(path).readAsStringSync();
        final formatIndex = source.indexOf(
          'dart format --set-exit-if-changed .',
        );
        final analyzeIndex = source.indexOf(
          'flutter analyze --fatal-infos --fatal-warnings',
        );
        final testIndex = source.indexOf('flutter test');
        final firstBuildIndex = source.indexOf('flutter build apk');

        expect(formatIndex, isNonNegative, reason: '$path must check format.');
        expect(
          analyzeIndex,
          isNonNegative,
          reason: '$path must use fatal analyzer gates.',
        );
        expect(testIndex, isNonNegative, reason: '$path must run tests.');
        expect(
          source,
          isNot(contains('flutter analyze --no-fatal-infos')),
          reason: '$path should not allow analyzer infos in CI.',
        );
        expect(
          formatIndex,
          lessThan(analyzeIndex),
          reason: '$path should reject unformatted code before analysis.',
        );
        expect(
          analyzeIndex,
          lessThan(testIndex),
          reason: '$path should analyze before running the test suite.',
        );
        expect(
          testIndex,
          lessThan(firstBuildIndex),
          reason: '$path should run tests before building APKs.',
        );
      }
    });
  });
}
