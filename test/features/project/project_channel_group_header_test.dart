import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_status_colors.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/features/project/presentation/project_channel_group_header.dart';

final _date = DateTime(2026, 10, 11);

void main() {
  for (final level in ProjectChannelDateLevel.values) {
    for (final expanded in [false, true]) {
      testWidgets('date heading conveys level and expansion $level/$expanded', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          var toggles = 0;
          await _show(
            tester,
            level: level,
            expanded: expanded,
            onToggle: () => toggles++,
          );
          final month = level == ProjectChannelDateLevel.month;
          final label = month ? '2026年10月' : '2026-10-11';
          final semanticsLabel = month
              ? '2026年10月，3 天，24 条记录'
              : '2026-10-11，24 条记录';
          expect(find.text(label), findsOneWidget);
          expect(find.text('24 条记录'), findsOneWidget);
          expect(find.text('3 天'), month ? findsOneWidget : findsNothing);
          final node = tester.getSemantics(
            find.bySemanticsLabel(semanticsLabel),
          );
          expect(node.flagsCollection.isButton, isTrue);
          expect(
            node.flagsCollection.isExpanded,
            expanded ? ui.Tristate.isTrue : ui.Tristate.isFalse,
          );
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          expect(
            node.getSemanticsData().hint,
            '${expanded ? '收起' : '展开'}${month ? '本月' : '当天'}记录',
          );
          expect(
            tester.getSize(find.byType(TextButton)).height,
            greaterThanOrEqualTo(48),
          );
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(toggles, 1);
          expect(
            tester
                .widget<ProjectChannelGroupHeader>(
                  find.byType(ProjectChannelGroupHeader),
                )
                .expanded,
            expanded,
          );
          expect(tester.takeException(), isNull);
        } finally {
          handle.dispose();
        }
      });
    }
  }

  testWidgets(
    'month without a day count and a zero-count day remain readable',
    (tester) async {
      await _show(tester, dayCount: null, records: 0, onToggle: () {});
      expect(find.text('0 条记录'), findsOneWidget);
      expect(find.text('·'), findsNothing);
      expect(find.textContaining('天'), findsNothing);
      await _show(
        tester,
        level: ProjectChannelDateLevel.day,
        dayCount: 99,
        records: 0,
        onToggle: () {},
      );
      expect(find.text('2026-10-11'), findsOneWidget);
      expect(find.text('99 天'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'month/day hierarchy reflows without splitting text dark=$dark',
      (tester) async {
        await _show(
          tester,
          dark: dark,
          width: 320,
          scale: 2,
          both: true,
          onToggle: () {},
        );
        final monthButton = _buttonFor('2026年10月');
        final dayButton = _buttonFor('2026-10-11');
        final monthRect = tester.getRect(monthButton);
        final dayRect = tester.getRect(dayButton);
        expect(dayRect.left - monthRect.left, closeTo(8, 0.01));
        expect(monthRect.height, greaterThanOrEqualTo(48));
        expect(dayRect.height, greaterThanOrEqualTo(48));
        for (final label in ['2026年10月', '2026-10-11', '3 天']) {
          expect(_lineCount(tester, find.text(label), label), 1);
          expect(
            _paragraph(tester, find.text(label)).didExceedMaxLines,
            isFalse,
          );
        }
        for (final button in [monthButton, dayButton]) {
          final count = find.descendant(
            of: button,
            matching: find.text('24 条记录'),
          );
          expect(_lineCount(tester, count, '24 条记录'), 1);
          expect(_paragraph(tester, count).didExceedMaxLines, isFalse);
          final title = find.descendant(
            of: button,
            matching: find.text(
              button == monthButton ? '2026年10月' : '2026-10-11',
            ),
          );
          expect(
            tester.getRect(title).bottom,
            lessThan(tester.getRect(count).top),
          );
          final text = tester.widget<Text>(count);
          final theme = dark ? AppTheme.dark : AppTheme.light;
          expect(
            AppStatusColors.contrast(
              text.style!.color!,
              theme.scaffoldBackgroundColor,
            ),
            greaterThanOrEqualTo(4.5),
          );
          expect(tester.getRect(count).right, lessThanOrEqualTo(304));
        }
        expect(find.byType(Card), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('normal-width headings keep title and counts on one line', (
    tester,
  ) async {
    await _show(tester, both: true, onToggle: () {});
    for (final label in ['2026年10月', '2026-10-11']) {
      final button = _buttonFor(label);
      final count = find.descendant(of: button, matching: find.text('24 条记录'));
      expect(
        tester.getRect(find.text(label)).center.dy,
        closeTo(tester.getRect(count).center.dy, 0.01),
      );
      expect(
        tester.getRect(find.text(label)).right,
        lessThan(tester.getRect(count).left),
      );
      expect(_lineCount(tester, find.text(label), label), 1);
    }
    expect(tester.takeException(), isNull);
  });

  for (final reduced in [false, true]) {
    testWidgets('controlled toggle updates arrow reduced=$reduced', (
      tester,
    ) async {
      var expanded = false;
      var toggles = 0;
      await _phone(tester, 390);
      await tester.pumpWidget(
        _app(
          reduced: reduced,
          child: StatefulBuilder(
            builder: (context, update) => ProjectChannelGroupHeader(
              date: _date,
              level: ProjectChannelDateLevel.month,
              recordCount: 24,
              dayCount: 3,
              expanded: expanded,
              onToggle: () => update(() {
                toggles++;
                expanded = !expanded;
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TextButton)),
      );
      await tester.pump();
      final press = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(press.scale, reduced ? 1 : 0.98);
      await gesture.up();
      await tester.pumpAndSettle();
      final arrow = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(arrow.turns, 0.25);
      expect(arrow.duration, reduced ? Duration.zero : AppMotion.fast);
      await tester.tap(find.text('2026年10月'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0,
      );
      expect(toggles, 2);
      expect(tester.takeException(), isNull);
    });
  }
}

Finder _buttonFor(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextButton));

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );

int _lineCount(WidgetTester tester, Finder text, String label) =>
    _paragraph(tester, text)
        .getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: label.length),
        )
        .map((box) => box.top)
        .toSet()
        .length;

Future<void> _phone(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _show(
  WidgetTester tester, {
  ProjectChannelDateLevel level = ProjectChannelDateLevel.month,
  bool expanded = true,
  int records = 24,
  int? dayCount = 3,
  bool dark = false,
  double width = 390,
  double scale = 1,
  bool both = false,
  required VoidCallback onToggle,
}) async {
  await _phone(tester, width);
  await tester.pumpWidget(
    _app(
      dark: dark,
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final current in both ? ProjectChannelDateLevel.values : [level])
            ProjectChannelGroupHeader(
              date: _date,
              level: current,
              recordCount: records,
              dayCount: dayCount,
              expanded: expanded,
              onToggle: onToggle,
            ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _app({
  required Widget child,
  bool dark = false,
  double scale = 1,
  bool reduced = false,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      disableAnimations: reduced,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    ),
  ),
);
