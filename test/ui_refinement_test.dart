import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_unsaved_changes_guard.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/more/presentation/more_view.dart';
import 'package:life_log/features/subscription/application/save_subscription_entry.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';
import 'package:life_log/features/subscription/presentation/subscription_cubit.dart';
import 'package:life_log/features/subscription/presentation/subscription_view.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/presentation/subscription_edit_view.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_view.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';

// Optional local screenshots use an explicitly supplied font/output directory.
// Normal CI tests neither depend on host fonts nor generate visual baselines.
const _reviewDirectory = String.fromEnvironment('UI_REVIEW_DIR');
const _reviewFont = String.fromEnvironment('UI_REVIEW_FONT');
const _reviewIcons = String.fromEnvironment('UI_REVIEW_ICONS');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
    if (_reviewFont.isNotEmpty) {
      final loader = FontLoader('Roboto');
      loader.addFont(
        Future.value(
          ByteData.sublistView(await File(_reviewFont).readAsBytes()),
        ),
      );
      await loader.load();
      if (_reviewIcons.isNotEmpty) {
        final icons = FontLoader('MaterialIcons');
        icons.addFont(
          Future.value(
            ByteData.sublistView(await File(_reviewIcons).readAsBytes()),
          ),
        );
        await icons.load();
      }
    }
  });
  tearDown(() async => serviceLocator.reset());

  test('dynamic themes preserve readable foreground/background pairs', () {
    for (final brightness in Brightness.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.amber,
        brightness: brightness,
      );
      final theme = brightness == Brightness.dark
          ? AppTheme.darkWith(scheme)
          : AppTheme.lightWith(scheme);
      expect(theme.colorScheme.onPrimary, scheme.onPrimary);
      final a = scheme.primary.computeLuminance();
      final b = theme.colorScheme.onPrimary.computeLuminance();
      expect(
        (a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05)),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('changed forms require an explicit discard decision', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const AppUnsavedChangesGuard(
                  hasChanges: true,
                  child: Scaffold(body: Text('编辑内容')),
                ),
              ),
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('编辑内容'));
    await Navigator.of(context).maybePop();
    await tester.pumpAndSettle();
    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(find.text('编辑内容'), findsOneWidget);
    await Navigator.of(context).maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃修改'));
    await tester.pumpAndSettle();
    expect(find.text('编辑内容'), findsNothing);
  });

  testWidgets('subscription save is single flight and recovers after failure', (
    tester,
  ) async {
    _phone(tester, 390);
    final repository = _DelayedSubscriptionRepository();
    serviceLocator.registerSingleton(SaveSubscriptionEntry(repository));
    await tester.pumpWidget(_harness(const SubscriptionEditView()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '测试订阅');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.text('保存订阅'));
    await tester.pump();
    // Invoke the disabled button through its widget contract, without relying
    // on hit-testing an intentionally absorbed in-flight form.
    final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
    expect(button.onPressed, isNull);
    expect(repository.calls, 1);
    repository.pending.completeError(StateError('fixture failure'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
      isNotNull,
    );
    expect(find.textContaining('保存失败'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('subscription layout dark=$dark scale=$scale', (
        tester,
      ) async {
        _phone(tester, scale == 2 ? 320 : 390);
        final shadowSetting = debugDisableShadows;
        debugDisableShadows = false;
        try {
          final repository = _SubscriptionPreviewRepository(
            largeAmounts: scale == 2,
          );
          serviceLocator.registerFactory<SubscriptionCubit>(
            () => SubscriptionCubit(
              loadEntries: LoadSubscriptionEntries(repository),
              watchEntries: WatchSubscriptionEntries(repository),
              initialNow: () => DateTime(2026, 9, 16),
              loadExchangeRates: (now) async => SubscriptionExchangeRates(
                rateDate: now,
                fetchedAt: now,
                cnyPerUnit: scale == 2
                    ? const {'CNY': 1}
                    : const {'CNY': 1, 'USD': 7.1},
              ),
            ),
          );
          final boundary = GlobalKey();
          await tester.pumpWidget(
            _harness(
              const SubscriptionView(),
              dark: dark,
              scale: scale,
              boundary: boundary,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (scale == 2) {
            expect(find.textContaining('缺少 USD 汇率'), findsOneWidget);
          }
          if (_reviewDirectory.isNotEmpty) {
            final render =
                boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final snapshot = await render.toImage(pixelRatio: 2);
              final bytes = await snapshot.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$_reviewDirectory/subscription-${dark ? 'dark' : 'light'}-$scale.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              snapshot.dispose();
            });
          }
          // Filtering remains reachable with large text and an empty category.
          if (scale == 2) {
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -450),
            );
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(find.widgetWithText(ChoiceChip, '一次性'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, '一次性'));
          await tester.pumpAndSettle();
          expect(find.text('该分类暂无支出'), findsOneWidget);
          await tester.tap(find.widgetWithText(ChoiceChip, '每年'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('专业设计工具与团队协作年度订阅'));
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byTooltip('订阅操作').first);
          await tester.tap(find.byTooltip('订阅操作').first);
          await tester.pumpAndSettle();
          expect(find.text('编辑订阅'), findsOneWidget);
          expect(find.text('删除订阅'), findsOneWidget);
          await tester.tap(find.text('删除订阅'));
          await tester.pumpAndSettle();
          expect(find.textContaining('确定删除「'), findsOneWidget);
          await tester.tap(find.text('取消'));
          await tester.pumpAndSettle();
          expect(find.text('专业设计工具与团队协作年度订阅'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          debugDisableShadows = shadowSetting;
        }
      });
      testWidgets('work and more layout dark=$dark scale=$scale', (
        tester,
      ) async {
        _phone(tester, scale == 2 ? 320 : 390);
        configureWorkLogFeatureDependencies(
          repository: _WorkRepository(),
          initialNow: () => DateTime(2026, 9, 16),
        );
        for (final page in <String, Widget>{
          'work': const WorkLogView(),
          'more': const MoreView(),
        }.entries) {
          final boundary = GlobalKey();
          await tester.pumpWidget(
            _harness(page.value, dark: dark, scale: scale, boundary: boundary),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: page.key);
          if (_reviewDirectory.isNotEmpty && scale == 1) {
            final render =
                boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final snapshot = await render.toImage(pixelRatio: 2);
              final bytes = await snapshot.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(_reviewDirectory).create(recursive: true);
              await File(
                '$_reviewDirectory/${page.key}-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              snapshot.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        }
      });
    }
  }

  testWidgets('work read failure offers retry instead of false empty state', (
    tester,
  ) async {
    _phone(tester, 390);
    configureWorkLogFeatureDependencies(
      repository: _WorkRepository(fail: true),
      initialNow: () => DateTime(2026, 9, 16),
    );
    await tester.pumpWidget(_harness(const WorkLogView()));
    await tester.pumpAndSettle();
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('这天还没有记录'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _phone(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _harness(
  Widget child, {
  bool dark = false,
  double scale = 1,
  GlobalKey? boundary,
}) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (context, _) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: RepaintBoundary(key: boundary, child: child!),
    ),
    home: child,
  ),
);

class _DelayedSubscriptionRepository implements SubscriptionRepositoryPort {
  final pending = Completer<void>();
  int calls = 0;
  @override
  Future<void> saveEntry(SubscriptionEntry entry, {required bool markDirty}) {
    calls++;
    return pending.future;
  }

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async => [];
  @override
  Future<SubscriptionEditDraft?> getEditDraft(int id) async => null;
  @override
  Future<void> deleteEntry(int id) async {}
  @override
  Future<void> reorderEntries(List<SubscriptionEntry> entries) async {}
  @override
  Stream<void> watchEntries() => const Stream.empty();
}

class _SubscriptionPreviewRepository extends _DelayedSubscriptionRepository {
  final bool largeAmounts;
  _SubscriptionPreviewRepository({this.largeAmounts = false});
  @override
  Future<List<SubscriptionEntry>> getAllEntries() async => [
    SubscriptionEntry(
      id: 1,
      name: 'Apple Music',
      price: 11,
      cycle: SubscriptionBillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 9, 17),
    ),
    SubscriptionEntry(
      id: 2,
      name: 'iCloud+',
      price: 21,
      cycle: SubscriptionBillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 9, 23),
    ),
    SubscriptionEntry(
      id: 3,
      name: 'Netflix',
      price: 15.49,
      currency: SubscriptionCurrency.usd,
      cycle: SubscriptionBillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 9, 28),
    ),
    SubscriptionEntry(
      id: 4,
      name: '专业设计工具与团队协作年度订阅',
      price: largeAmounts ? 1234567.89 : 1298,
      cycle: SubscriptionBillingCycle.yearly,
      nextPaymentDate: DateTime(2026, 12, 1),
    ),
    SubscriptionEntry(
      id: 5,
      name: '☕ 生活会员',
      price: 88,
      cycle: SubscriptionBillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 10, 3),
    ),
  ];
}

class _WorkRepository implements WorkLogRepositoryPort {
  final bool fail;
  _WorkRepository({this.fail = false});
  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async {
    if (fail) throw StateError('fixture read failure');
    return [
      WorkLogEntry(
        id: 1,
        date: DateTime(2026, 9, 16),
        type: WorkLogEntryType.work,
        overtimeHours: 2,
        note: '完成项目联调',
      ),
    ];
  }

  @override
  Future<List<WorkLogEntry>> getAllEntries() =>
      getEntriesByMonth(DateTime(2026, 9));
  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;
  @override
  Future<void> normalizeDuplicateDays() async {}
  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {}
  @override
  Future<void> deleteEntry(int id) async {}
  @override
  Stream<void> watchEntries() => const Stream.empty();
}
