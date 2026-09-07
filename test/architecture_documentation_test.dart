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

  test('project guidance follows the executable architecture', () {
    final source = File('AGENTS.md').readAsStringSync();
    expect(File('CLAUDE.md').existsSync(), isFalse);
    final shell = File(
      'lib/features/shell/presentation/tabs_view.dart',
    ).readAsStringSync();

    expect(source, contains('AGENTS.md'));
    expect(source, contains('GoRouter'));
    expect(source, contains('GetIt'));
    expect(source, contains('Cubit'));
    expect(source, contains('lib/features/<feature>'));
    expect(source, contains('DbService.schemas'));
    expect(source, contains('target three tabs are 工时 / 项目 / 更多'));
    final destinationsMatch = RegExp(
      r'_destinations = \[([\s\S]*?)\];',
    ).firstMatch(shell);
    final labels = RegExp(r"label: '([^']+)'")
        .allMatches(destinationsMatch?.group(1) ?? shell)
        .map((match) => match.group(1)!)
        .toList();
    expect(labels, hasLength(3));
    for (final label in labels) {
      expect(source, contains(label));
    }
    expect(source, isNot(contains('Get.put')));
    expect(source, isNot(contains('Get.find')));
    expect(source, isNot(contains('Six collections')));
    expect(source, contains('Photos are **local-only**'));
    expect(source, contains('migration plan'));
    expect(source, contains('rollback plan'));
    expect(source, contains('BUG_TRACKER.md'));
  });

  // Direction guards complement, rather than replace, current runtime checks.
  // These document assertions do not establish implemented behavior.
  test('ADR 0002 supersedes historical product constraints', () {
    final roadmap = File(
      'docs/adr/0001-architecture-modernization-roadmap.md',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
    final reconstruction = File(
      'docs/adr/0002-worklog-first-reconstruction.md',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');

    expect(roadmap, contains('(0002-worklog-first-reconstruction.md)'));
    expect(roadmap, contains('partially superseded by ADR 0002'));
    expect(roadmap, contains('Historical — superseded by ADR 0002'));
    expect(
      roadmap,
      contains(
        'one-work-log-per-day rule and any fixed navigation/layer-count',
      ),
    );
    expect(reconstruction, contains('Status: accepted direction'));
    expect(
      reconstruction,
      contains("supersedes ADR 0001's one-work-log-per-day rule"),
    );
    expect(reconstruction, contains('any fixed navigation/layer-count'));
    expect(reconstruction, contains('permit multiple same-day types'));
    expect(reconstruction, contains('preserve existing multi-entry records'));
    expect(reconstruction, contains('not the local-only photo rule'));
    expect(
      reconstruction,
      contains('Drafts and project photos remain local-only'),
    );
    expect(
      roadmap,
      contains('local-only photo rule remains a hard constraint'),
    );
  });

  test('guidance reflects approved three-tab shell', () {
    final source = File(
      'AGENTS.md',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');

    expect(source, contains('docs/adr/0002-worklog-first-reconstruction.md'));
    expect(source, contains('approved reconstruction direction'));
    expect(source, contains("supersedes ADR 0001's one-work-log-per-day"));
    expect(source, contains('any fixed navigation/layer-count requirement'));
    expect(source, contains('preserve existing multi-entry records'));
    expect(source, contains('target three tabs are 工时 / 项目 / 更多'));
    expect(source, contains('this target is implemented in the shell'));
    expect(source, contains('Do not change code back to old navigation'));
    expect(
      source,
      contains('ADR 0002 does not supersede the local-only photo rule'),
    );
  });

  test('README describes the current GoRouter GetIt Cubit runtime', () {
    final source = File('README.md').readAsStringSync();

    expect(source, contains('GoRouter'));
    expect(source, contains('GetIt'));
    expect(source, contains('Cubit'));
    expect(source, isNot(contains('GetX：路由、依赖注入和状态管理')));
  });
}
