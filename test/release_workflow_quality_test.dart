import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('release and test APK workflows', () {
    test('run format, fatal analyze, and tests before APK builds', () {
      final workflowPaths = [
        '.github/workflows/build.yml',
        '.github/workflows/test-apk.yml',
        '.github/workflows/ci-main-apk.yml',
      ];

      for (final path in workflowPaths) {
        final source = File(path).readAsStringSync();
        final formatIndex = source.indexOf(
          'dart format --set-exit-if-changed .',
        );
        final buildRunnerIndex = source.indexOf(
          'dart run build_runner build --delete-conflicting-outputs',
        );
        final generatedFormatIndex = source.indexOf('dart format .');
        final analyzeIndex = source.indexOf(
          'flutter analyze --fatal-infos --fatal-warnings',
        );
        final testIndex = source.indexOf('flutter test');
        final firstBuildIndex = source.indexOf('flutter build apk');

        expect(formatIndex, isNonNegative, reason: '$path must check format.');
        expect(
          buildRunnerIndex,
          isNonNegative,
          reason: '$path must regenerate checked-in Isar outputs.',
        );
        expect(
          generatedFormatIndex,
          isNonNegative,
          reason: '$path must normalize generated code before analysis.',
        );
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
          lessThan(buildRunnerIndex),
          reason: '$path should reject unformatted source before generators.',
        );
        expect(
          buildRunnerIndex,
          lessThan(generatedFormatIndex),
          reason: '$path should format Isar generator output.',
        );
        expect(
          generatedFormatIndex,
          lessThan(analyzeIndex),
          reason: '$path should normalize generated code before analysis.',
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

    test('main branch pushes publish a CI debug APK artifact', () {
      final source = File(
        '.github/workflows/ci-main-apk.yml',
      ).readAsStringSync();

      expect(source, contains('name: Main CI Test APK'));
      expect(source, contains('push:'));
      expect(source, contains('branches:'));
      expect(source, contains('- main'));
      expect(source, contains('flutter build apk --debug'));
      expect(source, contains('lifelog-main-debug.apk'));
      expect(source, contains('actions/upload-artifact@v4'));
    });

    test('release assets include the tag in downloadable file names', () {
      final source = File('.github/workflows/build.yml').readAsStringSync();

      expect(
        source,
        contains('LifeLog-\${GITHUB_REF_NAME}-arm64-v8a-release.apk'),
      );
      expect(
        source,
        contains('LifeLog-\${GITHUB_REF_NAME}-armeabi-v7a-release.apk'),
      );
      expect(
        source,
        contains('LifeLog-\${GITHUB_REF_NAME}-x86_64-release.apk'),
      );
      expect(
        source,
        contains('LifeLog-\${GITHUB_REF_NAME}-apk-size-report.md'),
      );
      expect(
        source,
        contains(
          'LifeLog-\${{ steps.version.outputs.TAG_NAME }}-arm64-v8a-release.apk',
        ),
      );
      expect(
        source,
        contains(
          'LifeLog-\${{ steps.version.outputs.TAG_NAME }}-armeabi-v7a-release.apk',
        ),
      );
      expect(
        source,
        contains(
          'LifeLog-\${{ steps.version.outputs.TAG_NAME }}-x86_64-release.apk',
        ),
      );
      expect(
        source,
        contains(
          'LifeLog-\${{ steps.version.outputs.TAG_NAME }}-apk-size-report.md',
        ),
      );
      expect(
        source,
        isNot(
          contains(
            'build/app/outputs/flutter-apk/lifelog-arm64-v8a-release.apk',
          ),
        ),
      );
      expect(
        source,
        isNot(
          contains(
            'build/app/outputs/flutter-apk/lifelog-armeabi-v7a-release.apk',
          ),
        ),
      );
      expect(
        source,
        isNot(
          contains('build/app/outputs/flutter-apk/lifelog-x86_64-release.apk'),
        ),
      );
    });
  });
}
