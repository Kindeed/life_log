import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quality gate script', () {
    test('documents the repeatable local verification loop', () {
      final script = File('tool/quality_gate.ps1');

      expect(
        script.existsSync(),
        isTrue,
        reason: 'A repeatable local quality gate keeps iteration consistent.',
      );

      final source = script.readAsStringSync();

      expect(source, contains("-Name 'dart-format-check'"));
      expect(
        source,
        contains("'dart', 'format', '--set-exit-if-changed', '.'"),
      );
      expect(source, contains("-Name 'flutter-analyze'"));
      expect(
        source,
        contains("'flutter', 'analyze', '--fatal-infos', '--fatal-warnings'"),
      );
      expect(source, isNot(contains('--no-fatal-infos')));
      expect(source, contains("-Name 'flutter-test'"));
      expect(source, contains("'flutter', 'test'"));
      expect(source, contains("-Name 'flutter-build-apk-debug'"));
      expect(source, contains("'flutter', 'build', 'apk', '--debug'"));
      expect(source, contains("-Name 'flutter-devices'"));
      expect(source, contains("'flutter', 'devices'"));
      expect(source, contains("-Name 'git-diff-check'"));
      expect(source, contains("'git', 'diff', '--check'"));
      expect(source, contains('package:life_log/modules'));
      expect(source, contains('PhotoItem'));
      expect(source, contains('syncId'));
      expect(source, contains('logs'));
      expect(source, contains('quality-gate'));
    });

    test('does not treat native stderr as a gate failure', () {
      final source = File('tool/quality_gate.ps1').readAsStringSync();

      expect(source, contains("\$ErrorActionPreference = 'Continue'"));
      expect(source, contains('Start-Process'));
      expect(source, contains('-RedirectStandardError'));
      expect(source, contains('-RedirectStandardOutput'));
      expect(source, isNot(contains(r'& $Executable @Arguments 2>&1')));
      expect(source, contains(r'$ExitCode = $LASTEXITCODE'));
      expect(source, contains(r'throw "Quality gate failed at $Name'));
    });
  });
}
