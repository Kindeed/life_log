import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
import 'package:life_log/common/widgets/app_page_route.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/common/widgets/app_unsaved_changes_guard.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/add_log_sheet.dart';

void main() {
  tearDown(() async => serviceLocator.reset());

  for (final reduced in [false, true]) {
    testWidgets('page push/pop preserves typed result reduced=$reduced', (
      tester,
    ) async {
      late BuildContext launchContext;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _harness(
          navigatorKey: navigator,
          reduced: reduced,
          child: Builder(
            builder: (context) {
              launchContext = context;
              return const Scaffold(body: Text('caller'));
            },
          ),
        ),
      );
      final route =
          appPageRoute<int>(
                launchContext,
                const Scaffold(body: Text('destination')),
                settings: const RouteSettings(name: '/motion-test'),
              )
              as PageRoute<int>;
      expect(route, isA<MaterialPageRoute<int>>());
      expect(
        route.transitionDuration,
        reduced ? Duration.zero : AppMotion.normal,
      );
      expect(
        route.reverseTransitionDuration,
        reduced ? Duration.zero : AppMotion.pageExit,
      );
      final result = navigator.currentState!.push<int>(route);
      await tester.pumpAndSettle();
      expect(find.text('destination'), findsOneWidget);
      navigator.currentState!.pop(42);
      await tester.pumpAndSettle();
      expect(await result, 42);
      expect(find.text('caller'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Android predictive back cancels and commits reduced=$reduced',
      (tester) async {
        late BuildContext launchContext;
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          _harness(
            navigatorKey: navigator,
            reduced: reduced,
            child: Builder(
              builder: (context) {
                launchContext = context;
                return const Scaffold(body: Text('caller'));
              },
            ),
          ),
        );
        final route =
            appPageRoute<void>(
                  launchContext,
                  const Scaffold(body: Text('destination')),
                )
                as PageRoute<void>;
        navigator.currentState!.push(route);
        await tester.pumpAndSettle();
        expect(await _back(tester, 'startBackGesture', progress: 0), isTrue);
        await tester.pump();
        await _back(tester, 'updateBackGestureProgress', progress: 0.4);
        await tester.pump();
        expect(route.popGestureInProgress, isTrue);
        expect(route.animation!.value, closeTo(0.6, 0.001));
        await _back(tester, 'cancelBackGesture');
        await tester.pumpAndSettle();
        expect(route.isCurrent, isTrue);
        expect(route.animation!.value, 1);
        expect(await _back(tester, 'startBackGesture', progress: 0), isTrue);
        await tester.pump();
        await _back(tester, 'updateBackGestureProgress', progress: 0.7);
        await tester.pump();
        await _back(tester, 'commitBackGesture');
        await tester.pumpAndSettle();
        expect(find.text('caller'), findsOneWidget);
        expect(find.text('destination'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('dirty page keeps its exit guard reduced=$reduced', (
      tester,
    ) async {
      late BuildContext launchContext;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _harness(
          navigatorKey: navigator,
          reduced: reduced,
          child: Builder(
            builder: (context) {
              launchContext = context;
              return const Scaffold(body: Text('caller'));
            },
          ),
        ),
      );
      navigator.currentState!.push(
        appPageRoute<void>(
          launchContext,
          const AppUnsavedChangesGuard(
            hasChanges: true,
            child: Scaffold(body: Text('draft')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(await _back(tester, 'startBackGesture', progress: 0), isFalse);
      await _back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('放弃未保存的修改？'), findsOneWidget);
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();
      expect(find.text('draft'), findsOneWidget);
      await navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('放弃修改'));
      await tester.pumpAndSettle();
      expect(find.text('caller'), findsOneWidget);
      expect(find.text('draft'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sheet options and caller controller survive reduced=$reduced', (
      tester,
    ) async {
      late BuildContext launchContext;
      late BuildContext sheetContext;
      final observer = _RouteObserver();
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 1),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _harness(
          reduced: reduced,
          observers: [observer],
          child: Builder(
            builder: (context) {
              launchContext = context;
              return const Scaffold(body: Text('caller'));
            },
          ),
        ),
      );
      final result = showAppBottomSheet<int>(
        context: launchContext,
        transitionAnimationController: controller,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        barrierColor: Colors.black54,
        barrierLabel: '测试弹层',
        routeSettings: const RouteSettings(name: '/sheet-test'),
        builder: (context) {
          sheetContext = context;
          return const SizedBox(height: 240, child: Text('sheet'));
        },
      );
      await tester.pumpAndSettle();
      final route = observer.last! as ModalBottomSheetRoute<int>;
      expect(route.isScrollControlled, isTrue);
      expect(route.isDismissible, isFalse);
      expect(route.enableDrag, isFalse);
      expect(route.useSafeArea, isTrue);
      expect(route.barrierColor, Colors.black54);
      expect(route.barrierLabel, '测试弹层');
      expect(route.settings.name, '/sheet-test');
      expect(controller.duration, reduced ? Duration.zero : AppMotion.sheet);
      expect(
        controller.reverseDuration,
        reduced ? Duration.zero : AppMotion.normal,
      );
      await tester.tapAt(const Offset(20, 30));
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsOneWidget);
      Navigator.of(sheetContext).pop(7);
      await tester.pumpAndSettle();
      expect(await result, 7);
      // Flutter must not dispose a controller whose lifetime belongs to callers.
      controller.value = 0.25;
      expect(controller.value, 0.25);
      expect(tester.takeException(), isNull);
    });

    testWidgets('type reversal preserves overtime and note reduced=$reduced', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _EditorRepository();
      serviceLocator.registerSingleton(SaveWorkLogEntry(repository));
      serviceLocator.registerSingleton(DeleteWorkLogEntry(repository));
      await _openEditor(tester, reduced: reduced);
      final overtime = _field('自定义时长 (小时)');
      final note = _field('备注 (可选)...');
      final noteField = tester.widget<AppTextField>(note);
      final typeRegion = find.byKey(const ValueKey('work-log-type-transition'));
      expect(
        tester.widget<AnimatedSwitcher>(typeRegion).duration,
        reduced ? Duration.zero : AppMotion.fast,
      );
      await tester.enterText(_editable(overtime), '2.75');
      await tester.pumpAndSettle();
      await tester.enterText(_editable(note), '保留这条备注');
      await tester.pumpAndSettle();
      // Typing in one form must not restart its entry animation.
      final beforeSwitch = find.descendant(
        of: typeRegion,
        matching: find.byType(FadeTransition),
      );
      expect(
        tester.widget<FadeTransition>(beforeSwitch.first).opacity.value,
        1,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      for (final label in ['出差', '工作', '出差', '工作']) {
        await tester.tap(find.text(label).hitTestable());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(_field('自定义时长 (小时)'), findsOneWidget);
      expect(tester.widget<AppTextField>(overtime).controller!.text, '2.75');
      expect(
        tester.widget<AppTextField>(note).controller,
        same(noteField.controller),
      );
      expect(
        tester.widget<AppTextField>(note).focusNode,
        same(noteField.focusNode),
      );
      expect(noteField.controller!.text, '保留这条备注');
      await tester.tap(find.text('保存').hitTestable());
      await tester.pumpAndSettle();
      expect(repository.saved.single.overtimeHours, 2.75);
      expect(repository.saved.single.note, '保留这条备注');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('overtime presets update both visible text and saved value', (
    tester,
  ) async {
    final repository = _EditorRepository();
    serviceLocator.registerSingleton(SaveWorkLogEntry(repository));
    serviceLocator.registerSingleton(DeleteWorkLogEntry(repository));
    await _openEditor(tester);
    final overtime = _field('自定义时长 (小时)');
    await tester.enterText(_editable(overtime), '3.5');
    await tester.tap(find.text('2.0 h'));
    await tester.pumpAndSettle();
    expect(tester.widget<AppTextField>(overtime).controller!.text, '2');
    await tester.tap(find.text('保存').hitTestable());
    await tester.pumpAndSettle();
    expect(repository.saved.single.overtimeHours, 2);
    expect(tester.takeException(), isNull);
  });
}

Future<Object?> _back(
  WidgetTester tester,
  String method, {
  double? progress,
}) async {
  final response = await tester.binding.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.backGesture.name,
        SystemChannels.backGesture.codec.encodeMethodCall(
          MethodCall(
            method,
            progress == null
                ? null
                : {
                    'touchOffset': [0.0, 200.0],
                    'progress': progress,
                    'swipeEdge': 0,
                  },
          ),
        ),
        null,
      );
  return response == null
      ? null
      : SystemChannels.backGesture.codec.decodeEnvelope(response);
}

Widget _harness({
  required Widget child,
  bool reduced = false,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver> observers = const [],
}) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(
    navigatorKey: navigatorKey,
    navigatorObservers: observers,
    theme: AppTheme.light.copyWith(platform: TargetPlatform.android),
    builder: (context, routed) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: routed!,
    ),
    home: child,
  ),
);

Future<void> _openEditor(WidgetTester tester, {bool reduced = false}) async {
  await tester.pumpWidget(
    _harness(
      reduced: reduced,
      child: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              appPageRoute<void>(
                context,
                Scaffold(
                  body: AddLogSheet(
                    selectedDate: DateTime(2026, 9, 25),
                    asPage: true,
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _field(String hint) => find.byWidgetPredicate(
  (widget) => widget is AppTextField && widget.hintText == hint,
);

Finder _editable(Finder field) =>
    find.descendant(of: field, matching: find.byType(EditableText));

class _RouteObserver extends NavigatorObserver {
  Route<dynamic>? last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      last = route;
}

class _EditorRepository implements WorkLogRepositoryPort {
  final saved = <WorkLogEntry>[];

  @override
  Future<List<WorkLogEntry>> getAllEntries() async => const [];

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async =>
      const [];

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async =>
      saved.add(entry);

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
