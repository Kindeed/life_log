import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';

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

  testWidgets(
    'fixed chip grids render four items as 2x2 and three as one row',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: Column(
                children: [
                  AppFilterChipBar<int>(
                    value: 0,
                    columns: 2,
                    onChanged: (_) {},
                    items: const [
                      AppFilterChipItem(value: 0, label: '全部'),
                      AppFilterChipItem(value: 1, label: '每月'),
                      AppFilterChipItem(value: 2, label: '每年'),
                      AppFilterChipItem(value: 3, label: '一次性'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppFilterChipBar<int>(
                    value: 0,
                    columns: 3,
                    onChanged: (_) {},
                    items: const [
                      AppFilterChipItem(value: 0, label: '手动'),
                      AppFilterChipItem(value: 1, label: '日期'),
                      AppFilterChipItem(value: 2, label: '金额'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final allTop = tester.getTopLeft(find.text('全部'));
      final monthlyTop = tester.getTopLeft(find.text('每月'));
      final yearlyTop = tester.getTopLeft(find.text('每年'));
      final oneTimeTop = tester.getTopLeft(find.text('一次性'));
      expect(monthlyTop.dy, allTop.dy);
      expect(oneTimeTop.dy, yearlyTop.dy);
      expect(yearlyTop.dy, greaterThan(allTop.dy));

      final manualTop = tester.getTopLeft(find.text('手动'));
      final dateTop = tester.getTopLeft(find.text('日期'));
      final priceTop = tester.getTopLeft(find.text('金额'));
      expect(dateTop.dy, manualTop.dy);
      expect(priceTop.dy, manualTop.dy);
    },
  );

  test('subscription and project filter controls use fixed columns', () {
    final subscription = File(
      'lib/features/subscription/presentation/subscription_view.dart',
    ).readAsStringSync();
    final project = File(
      'lib/features/photo/presentation/photo_view.dart',
    ).readAsStringSync();

    expect(subscription, contains('columns: 2'));
    expect(subscription, contains('columns: 3'));
    expect(project, contains('columns: 3'));
  });
}
