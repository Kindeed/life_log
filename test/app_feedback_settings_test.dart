import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_status_colors.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
import 'package:life_log/common/widgets/app_feedback.dart';
import 'package:life_log/common/widgets/app_form_feedback.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_settings.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry_stats.dart';
import 'package:life_log/features/profile/presentation/views/about_view.dart';
import 'package:life_log/features/profile/presentation/views/data_management_view.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/presentation/evidence_detail_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_detail_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _directory = String.fromEnvironment('UI_REVIEW_DIR');

void main() {
  test(
    'trip reimbursement totals retain decimal amounts without binary tails',
    () {
      final entries = [
        for (final reimbursed in [true, false])
          for (final amount in [0.1, 0.2])
            WorkLogEntry(
              id: amount == .1 ? 1 : 2,
              date: DateTime(2026, 10, 1),
              type: WorkLogEntryType.businessTrip,
              expenses: amount,
              isReimbursed: reimbursed,
            ),
      ];
      expect(formatMoney(entries.totalReimbursedAmount), '¥0.30');
      expect(formatMoney(entries.totalUnreimbursedAmount), '¥0.30');
    },
  );

  testWidgets('settings switch announces its label and toggle state together', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var enabled = true;
    await tester.pumpWidget(
      _app(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppSettingsGroup(
              children: [
                AppSettingsTile(
                  icon: Icons.auto_awesome_rounded,
                  title: '动态取色',
                  subtitle: '跟随系统壁纸颜色',
                  onTap: () => setState(() => enabled = !enabled),
                  trailing: Switch(
                    value: enabled,
                    onChanged: (value) => setState(() => enabled = value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(Switch)).getSemanticsData();
    expect(node.label, contains('动态取色'));
    expect(node.flagsCollection.isToggled, ui.Tristate.isTrue);
    await tester.tap(find.text('动态取色'));
    await tester.pumpAndSettle();
    expect(enabled, isFalse);
    expect(tester.getSemantics(find.byType(Switch)).label, contains('动态取色'));
    semantics.dispose();
  });
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'LifeLog',
      packageName: 'com.wzh.lifelog',
      version: '1.4.38',
      buildNumber: '44',
      buildSignature: '',
    );
    for (final spec in [
      ('Roboto', const String.fromEnvironment('UI_REVIEW_FONT')),
      ('MaterialIcons', const String.fromEnvironment('UI_REVIEW_ICONS')),
    ]) {
      if (spec.$2.isEmpty) continue;
      final loader = FontLoader(spec.$1);
      loader.addFont(
        Future.value(ByteData.sublistView(await File(spec.$2).readAsBytes())),
      );
      await loader.load();
    }
  });

  for (final dark in [false, true]) {
    test('small status roles retain readable contrast dark=$dark', () {
      for (final theme in [
        dark ? AppTheme.dark : AppTheme.light,
        dark
            ? AppTheme.darkWith(
                ColorScheme.fromSeed(
                  seedColor: Colors.orange,
                  brightness: Brightness.dark,
                ),
              )
            : AppTheme.lightWith(
                ColorScheme.fromSeed(seedColor: Colors.purple),
              ),
      ]) {
        final colors = theme.semanticColors;
        final log = theme.logColors;
        for (final color in [
          colors.work,
          colors.expense,
          colors.success,
          colors.warning,
          log.work,
          log.businessTrip,
          log.rest,
          log.leave,
          log.overtime,
        ]) {
          for (final selected in [false, true]) {
            final pair = AppStatusColors.fromTint(
              theme,
              color,
              selected: selected,
            );
            expect(
              AppStatusColors.contrast(pair.foreground, pair.container),
              greaterThanOrEqualTo(4.49),
            );
          }
        }
      }
    });

    testWidgets(
      'save feedback stays compact after the editor closes dark=$dark',
      (tester) async {
        _phone(tester, 390);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          _app(
            dark: dark,
            boundary: boundary,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showAppBottomSheet<void>(
                      context: context,
                      builder: (context) => TextButton(
                        onPressed: () {
                          final feedback = AppFeedback.capture(context);
                          Navigator.of(context).pop();
                          feedback.success('工时已保存');
                        },
                        child: const Text('保存'),
                      ),
                    ),
                    child: const Text('编辑'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('编辑'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();
        expect(find.text('工时已保存'), findsOneWidget);
        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackbar.width, lessThan(300));
        expect(snackbar.margin, isNull);
        expect(snackbar.duration, const Duration(seconds: 2));
        expect(find.text('保存'), findsNothing);
        expect(tester.takeException(), isNull);
        await _capture(tester, boundary, 'feedback-${dark ? 'dark' : 'light'}');
      },
    );
  }

  testWidgets('long errors wrap at 320dp and replace queued confirmations', (
    tester,
  ) async {
    _phone(tester, 320);
    await tester.pumpWidget(
      _app(
        scale: 2,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                final feedback = AppFeedback.capture(context);
                feedback.success('旧提示');
                feedback.error('保存失败：本地记录暂时无法读取，请保留草稿后重试。');
              },
              child: const Text('显示'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('显示'));
    await tester.pumpAndSettle();
    expect(find.text('旧提示'), findsNothing);
    final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackbar.width, lessThanOrEqualTo(288));
    expect(tester.getSize(find.byType(SnackBar)).height, greaterThan(48));
    expect(tester.takeException(), isNull);
  });

  for (final reduced in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets(
        'missing evidence export is visible within narrow modal dark=$dark reduced=$reduced',
        (tester) async {
          _phone(tester, 320);
          final boundary = GlobalKey();
          final item = ExpenseEvidence()
            ..projectName = '项目与报销'
            ..evidenceDate = DateTime(2026, 10, 11)
            ..note = List.filled(8, '用于测试长内容滚动及反馈定位。').join();
          await tester.pumpWidget(
            _app(
              dark: dark,
              scale: 2,
              reducedMotion: reduced,
              boundary: boundary,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showEvidenceDetailSheet(context, item),
                    child: const Text('凭证详情'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('凭证详情'));
          await tester.pumpAndSettle();
          final scrollable = find
              .descendant(
                of: find.byType(EvidenceDetailSheet),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            find.text('导出'),
            250,
            scrollable: scrollable,
          );
          await tester.tap(find.text('导出'));
          await tester.pumpAndSettle();
          expect(find.byType(EvidenceDetailSheet), findsOneWidget);
          expect(find.byType(SnackBar), findsNothing);
          final feedback = find.descendant(
            of: find.byType(AppFormFeedback),
            matching: find.text('本机没有可导出的凭证文件'),
          );
          expect(feedback, findsOneWidget);
          expect(feedback.hitTestable(), findsOneWidget);
          expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
          expect(tester.takeException(), isNull);
          await _capture(
            tester,
            boundary,
            'evidence-feedback-${dark ? 'dark' : 'light'}-${reduced ? 'reduced' : 'motion'}',
          );
        },
      );
    }
  }

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('secondary settings reflow dark=$dark text=$scale', (
        tester,
      ) async {
        _phone(tester, scale == 2 ? 320 : 390);
        for (final entry in {
          'about': const AboutView(),
          'backup': const DataManagementView(),
        }.entries) {
          final boundary = GlobalKey();
          await tester.pumpWidget(
            _app(
              dark: dark,
              scale: scale,
              home: entry.value,
              boundary: boundary,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await _capture(
            tester,
            boundary,
            '${entry.key}-${dark ? 'dark' : 'light'}-${scale.toInt()}x',
          );
        }
        await tester.pumpWidget(
          _app(
            dark: dark,
            scale: scale,
            home: const Scaffold(
              body: SizedBox(
                width: 220,
                child: AppPill(label: '待报销 USD 12.345', color: Colors.orange),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('待报销 USD 12.345'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Widget _app({
  required Widget home,
  bool dark = false,
  double scale = 1,
  bool reducedMotion = false,
  GlobalKey? boundary,
}) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reducedMotion,
      ),
      child: RepaintBoundary(key: boundary, child: child!),
    ),
    home: home,
  ),
);

void _phone(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (_directory.isEmpty) return;
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final snapshot = await render.toImage(pixelRatio: 2);
    final data = await snapshot.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '$_directory/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    snapshot.dispose();
  });
}
