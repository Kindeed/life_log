import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('common design system exposes typography and page templates', () {
    final expectedFiles = [
      'lib/common/theme/app_typography.dart',
      'lib/common/widgets/app_page.dart',
      'lib/common/widgets/app_list_page.dart',
      'lib/common/widgets/app_form_page.dart',
      'lib/common/widgets/app_detail_page.dart',
      'lib/common/widgets/app_section.dart',
      'lib/common/widgets/app_metric_grid.dart',
      'lib/common/widgets/app_swipe_action.dart',
    ];

    for (final path in expectedFiles) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('theme uses AppTypography instead of a private text theme helper', () {
    final theme = File('lib/common/theme/app_theme.dart').readAsStringSync();

    expect(theme, contains('AppTypography.textTheme(colorScheme)'));
    expect(theme, isNot(contains('static TextTheme _textTheme')));
  });

  test(
    'list pages reuse shared page, metric, section, and swipe components',
    () {
      final subscription = File(
        'lib/features/subscription/presentation/subscription_view.dart',
      ).readAsStringSync();
      final evidence = File(
        'lib/features/evidence/presentation/evidence_list_view.dart',
      ).readAsStringSync();

      expect(subscription, contains('AppListPage('));
      expect(subscription, contains('AppMetricGrid('));
      expect(subscription, contains('AppSection('));
      expect(subscription, contains('AppSwipeAction.delete('));
      expect(subscription, isNot(contains('class _DeleteBackground')));

      expect(evidence, contains('AppMetricGrid('));
    },
  );

  test('shared page templates are tokenized and width constrained', () {
    final page = File('lib/common/widgets/app_page.dart').readAsStringSync();
    final listPage = File(
      'lib/common/widgets/app_list_page.dart',
    ).readAsStringSync();
    final section = File(
      'lib/common/widgets/app_section.dart',
    ).readAsStringSync();

    expect(page, contains('AppSpacing.lg'));
    expect(page, contains('ConstrainedPage'));
    expect(listPage, contains('ConstrainedPage'));
    expect(listPage, contains('AppSpacing.lg'));
    expect(section, contains('AppSectionHeader'));
    expect(section, contains('AppSpacing.sm'));
  });
}
