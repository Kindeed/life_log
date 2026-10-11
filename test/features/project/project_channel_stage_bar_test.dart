import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_status_colors.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/features/project/presentation/project_channel_stage_bar.dart';

void main() {
  for (final stage in <String?>[null, '', '  现场交付  ']) {
    testWidgets('stage selection conveys the current scope stage=$stage', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        var selections = 0;
        await _show(tester, selected: stage, onSelect: () => selections++);
        final label = stage == null
            ? '全部阶段'
            : stage.trim().isEmpty
            ? '未分阶段'
            : stage.trim();
        expect(find.text(label), findsOneWidget);
        expect(find.text('27 条记录'), findsOneWidget);
        expect(find.text('查看阶段'), findsNothing);
        expect(find.byType(Card), findsNothing);
        expect(find.byTooltip('选择阶段（3 个阶段）'), findsOneWidget);
        final stageNode = find.bySemanticsLabel('选择项目阶段，$label，共 3 个阶段');
        expect(
          tester.getSemantics(stageNode),
          matchesSemantics(
            label: '选择项目阶段，$label，共 3 个阶段',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
        await tester.pumpAndSettle();
        expect(selections, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('stage control can be disabled without implying an action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _show(tester, selected: '生产', onSelect: null);
      final button = tester.widget<TextButton>(
        find.byKey(const ValueKey('project-stage-selector')),
      );
      expect(button.onPressed, isNull);
      final node = tester.getSemantics(
        find.bySemanticsLabel('选择项目阶段，生产，共 3 个阶段'),
      );
      expect(node.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final dark in [false, true]) {
    for (final spec in [(390.0, 1.0), (320.0, 2.0)]) {
      testWidgets(
        'stage and record count fit long history dark=$dark width=${spec.$1} scale=${spec.$2}',
        (tester) async {
          await _show(
            tester,
            dark: dark,
            width: spec.$1,
            scale: spec.$2,
            selected: '需要与施工及验收团队共同确认的历史交付阶段',
            records: 12345,
            onSelect: () {},
          );
          final control = find.byKey(const ValueKey('project-stage-selector'));
          final controlRect = tester.getRect(control);
          final countRect = tester.getRect(find.text('12345 条记录'));
          expect(controlRect.width, greaterThanOrEqualTo(48));
          expect(controlRect.height, greaterThanOrEqualTo(48));
          expect(controlRect.left, greaterThanOrEqualTo(0));
          expect(controlRect.bottom, lessThanOrEqualTo(countRect.top));
          expect(controlRect.width, closeTo(spec.$1 - 24, 0.01));
          expect(countRect.right, lessThanOrEqualTo(spec.$1));
          expect(_lineCount(tester, '12345 条记录'), 1);
          final text = tester.widget<Text>(find.text('12345 条记录'));
          final theme = dark ? AppTheme.dark : AppTheme.light;
          expect(
            AppStatusColors.contrast(
              text.style!.color!,
              theme.scaffoldBackgroundColor,
            ),
            greaterThanOrEqualTo(4.5),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets('narrow enlarged stage and count stay whole dark=$dark', (
      tester,
    ) async {
      await _show(
        tester,
        selected: null,
        records: 4,
        width: 320,
        scale: 2,
        dark: dark,
        trailingFilter: true,
        onSelect: () {},
      );
      final control = find.byKey(const ValueKey('project-stage-selector'));
      final stage = tester.getRect(find.text('全部阶段'));
      final count = tester.getRect(find.text('4 条记录'));
      expect(_lineCount(tester, '全部阶段'), 1);
      expect(_lineCount(tester, '4 条记录'), 1);
      expect(tester.getRect(control).width, closeTo(224, 0.01));
      expect(stage.left, closeTo(count.left, 0.01));
      expect(tester.getRect(control).bottom, lessThanOrEqualTo(count.top));
      expect(tester.widget<Text>(find.text('4 条记录')).textAlign, TextAlign.left);
      expect(_paragraph(tester, '全部阶段').didExceedMaxLines, isFalse);
      expect(_paragraph(tester, '4 条记录').didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a two-line stage keeps the count on its own full-width row', (
    tester,
  ) async {
    const stage = '勘查与现场交付阶段';
    await _show(
      tester,
      selected: stage,
      records: 4,
      width: 320,
      scale: 2,
      trailingFilter: true,
      onSelect: () {},
    );
    expect(_lineCount(tester, stage), 2);
    expect(_paragraph(tester, stage).didExceedMaxLines, isFalse);
    expect(_lineCount(tester, '4 条记录'), 1);
    expect(
      tester.getRect(find.text(stage)).bottom,
      lessThan(tester.getRect(find.text('4 条记录')).top),
    );
    expect(tester.takeException(), isNull);
  });

  for (final spec in [(390.0, 1.0), (540.0, 2.0)]) {
    testWidgets(
      'sufficient measured width keeps one line width=${spec.$1} scale=${spec.$2}',
      (tester) async {
        await _show(
          tester,
          selected: null,
          records: 4,
          width: spec.$1,
          scale: spec.$2,
          trailingFilter: true,
          onSelect: () {},
        );
        final control = find.byKey(const ValueKey('project-stage-selector'));
        final count = tester.getRect(find.text('4 条记录'));
        expect(tester.getRect(control).right, lessThanOrEqualTo(count.left));
        expect(
          tester.getRect(control).center.dy,
          closeTo(count.center.dy, 0.01),
        );
        expect(_lineCount(tester, '全部阶段'), 1);
        expect(_lineCount(tester, '4 条记录'), 1);
        expect(
          tester.widget<Text>(find.text('4 条记录')).textAlign,
          TextAlign.right,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reduced motion keeps stage press stationary and actionable', (
    tester,
  ) async {
    var selections = 0;
    await _show(
      tester,
      reduced: true,
      selected: null,
      onSelect: () => selections++,
    );
    final control = find.byKey(const ValueKey('project-stage-selector'));
    final gesture = await tester.startGesture(tester.getCenter(control));
    await tester.pump();
    final press = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(press.scale, 1);
    expect(press.duration, Duration.zero);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, 1);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _show(
  WidgetTester tester, {
  String? selected,
  required VoidCallback? onSelect,
  int records = 27,
  bool dark = false,
  double width = 390,
  double scale = 1,
  bool reduced = false,
  bool trailingFilter = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: trailingFilter ? 12 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProjectChannelStageBar(
                      selectedStage: selected,
                      stageCount: 3,
                      recordCount: records,
                      onSelect: onSelect,
                    ),
                  ),
                  if (trailingFilter)
                    IconButton(
                      tooltip: '筛选动态',
                      onPressed: () {},
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(Icons.filter_list_rounded),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );

int _lineCount(WidgetTester tester, String text) => _paragraph(tester, text)
    .getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    )
    .map((box) => box.top)
    .toSet()
    .length;
