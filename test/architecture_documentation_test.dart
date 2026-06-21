import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'framework migration document reflects the current GetX-free runtime',
    () {
      final source = File(
        'docs/architecture/2026-06-17-framework-migration.md',
      ).readAsStringSync();

      expect(source, contains('Status: current architecture snapshot'));
      expect(source, contains('No production GetX runtime APIs remain'));
      expect(source, isNot(contains('Status: active migration baseline')));
      expect(source, isNot(contains('Keep the current GetX app running')));
      expect(source, isNot(contains('GetX and BLoC may temporarily coexist')));
      expect(source, isNot(contains('legacy Get path')));
      expect(source, isNot(contains('the shell remains on GetX')));
      expect(source, isNot(contains('GetX-backed statistics runtime')));
    },
  );

  test('UI AI handoff keeps UI design away from storage and sync changes', () {
    final source = File('docs/ui_ai_handoff.md').readAsStringSync();

    expect(source, contains('Photos are local-only'));
    expect(source, contains('Do not change persistence'));
    expect(source, contains('No generated backend code'));
    expect(source, contains('schema changes'));
    expect(source, contains('covered by widget/source tests'));
  });

  test('README describes the current GoRouter GetIt Cubit runtime', () {
    final source = File('README.md').readAsStringSync();

    expect(source, contains('GoRouter'));
    expect(source, contains('GetIt'));
    expect(source, contains('Cubit'));
    expect(source, isNot(contains('GetX：路由、依赖注入和状态管理')));
  });
}
