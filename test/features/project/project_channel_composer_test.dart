import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_status_colors.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/features/project/presentation/project_channel_composer.dart';

void main() {
  testWidgets(
    'writing and adding attachments invoke separate channel actions',
    (tester) async {
      var writes = 0;
      var additions = 0;
      final semantics = tester.ensureSemantics();
      try {
        await _show(tester, onWrite: () => writes++, onAdd: () => additions++);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('写记录…'), findsOneWidget);
        expect(find.byTooltip('添加记录'), findsOneWidget);
        expect(find.byTooltip('写文字记录'), findsOneWidget);
        expect(
          tester.getSemantics(
            find.byKey(const ValueKey('project-channel-write')),
          ),
          matchesSemantics(
            label: '写记录…',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
        await tester.tap(find.text('写记录…'));
        await tester.pumpAndSettle();
        expect(writes, 1);
        expect(additions, 0);
        await tester.tap(find.byTooltip('添加记录'));
        await tester.pumpAndSettle();
        expect(writes, 1);
        expect(additions, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('disabled composer actions remain visible and inert', (
    tester,
  ) async {
    await _show(tester, onWrite: null, onAdd: null);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('project-channel-write')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('project-channel-add')))
          .onPressed,
      isNull,
    );
    expect(find.text('写记录…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final spec in [(390.0, 1.0), (320.0, 2.0)]) {
      testWidgets(
        'composer respects safe area, large text and contrast dark=$dark width=${spec.$1} scale=${spec.$2}',
        (tester) async {
          var writes = 0;
          var additions = 0;
          await _show(
            tester,
            dark: dark,
            width: spec.$1,
            scale: spec.$2,
            bottomSafe: 24,
            onWrite: () => writes++,
            onAdd: () => additions++,
          );
          final write = find.byKey(const ValueKey('project-channel-write'));
          final add = find.byKey(const ValueKey('project-channel-add'));
          final surface = find.byKey(
            const ValueKey('project-channel-composer-surface'),
          );
          for (final control in [write, add]) {
            final rect = tester.getRect(control);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(spec.$1));
          }
          expect(tester.getRect(write).right, tester.getRect(add).left);
          expect(tester.getRect(surface).bottom, closeTo(820, 0.01));
          final material = tester.widget<Material>(surface);
          final theme = dark ? AppTheme.dark : AppTheme.light;
          expect(material.color, theme.semanticColors.mutedSurface);
          expect(material.elevation, 0);
          final text = tester.widget<Text>(find.text('写记录…'));
          expect(
            AppStatusColors.contrast(text.style!.color!, material.color!),
            greaterThanOrEqualTo(4.5),
          );
          await tester.tap(write);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(writes, 1);
          expect(additions, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final reduced in [false, true]) {
    testWidgets('keyboard inset lifts composer once reduced=$reduced', (
      tester,
    ) async {
      var writes = 0;
      await _show(
        tester,
        keyboard: 300,
        bottomSafe: 24,
        reduced: reduced,
        onWrite: () => writes++,
        onAdd: () {},
      );
      final surface = find.byKey(
        const ValueKey('project-channel-composer-surface'),
      );
      expect(tester.getRect(surface).bottom, closeTo(536, 0.01));
      expect(tester.getRect(surface).top, greaterThan(0));
      await tester.tap(find.text('写记录…'));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reduced motion suppresses press and inset animation', (
    tester,
  ) async {
    var additions = 0;
    await _show(
      tester,
      reduced: true,
      onWrite: () {},
      onAdd: () => additions++,
    );
    final add = find.byKey(const ValueKey('project-channel-add'));
    final gesture = await tester.startGesture(tester.getCenter(add));
    await tester.pump();
    for (final press in tester.widgetList<AnimatedScale>(
      find.descendant(
        of: find.byType(ProjectChannelComposer),
        matching: find.byType(AnimatedScale),
      ),
    )) {
      expect(press.scale, 1);
      expect(press.duration, Duration.zero);
    }
    final inset = tester.widget<AnimatedPadding>(
      find.descendant(
        of: find.byType(ProjectChannelComposer),
        matching: find.byType(AnimatedPadding),
      ),
    );
    expect(inset.duration, Duration.zero);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(additions, 1);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _show(
  WidgetTester tester, {
  required VoidCallback? onWrite,
  required VoidCallback? onAdd,
  bool dark = false,
  double width = 390,
  double scale = 1,
  double bottomSafe = 0,
  double keyboard = 0,
  bool reduced = false,
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
          viewInsets: EdgeInsets.only(bottom: keyboard),
          viewPadding: EdgeInsets.only(bottom: bottomSafe),
          padding: EdgeInsets.only(bottom: keyboard == 0 ? bottomSafe : 0),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: const Text('项目记录'),
        bottomNavigationBar: ProjectChannelComposer(
          onWrite: onWrite,
          onAdd: onAdd,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
