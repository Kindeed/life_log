import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_load_failure.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_local_thumbnail.dart';
import 'package:life_log/common/widgets/app_press_feedback.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/sync_center/application/load_sync_center_snapshot.dart';
import 'package:life_log/features/sync_center/application/resolve_sync_conflict.dart';
import 'package:life_log/features/sync_center/domain/sync_center_repository_port.dart';
import 'package:life_log/features/sync_center/domain/sync_center_snapshot.dart';
import 'package:life_log/features/sync_center/presentation/sync_center_view.dart';

void main() {
  setUpAll(() async {
    const font = String.fromEnvironment('UI_REVIEW_FONT');
    if (font.isNotEmpty) {
      final loader = FontLoader('NotoSansCJK')
        ..addFont(
          Future.value(ByteData.sublistView(await File(font).readAsBytes())),
        );
      await loader.load();
    }
    const icons = String.fromEnvironment('UI_REVIEW_ICONS');
    if (icons.isNotEmpty) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(ByteData.sublistView(await File(icons).readAsBytes())),
        );
      await loader.load();
    }
  });
  tearDown(() async => serviceLocator.reset());

  testWidgets(
    '1000 queued tasks build visible rows only and preserve content/scroll through refresh error and retry',
    (tester) async {
      final repository = _Snapshots();
      _register(repository);
      await tester.pumpWidget(_app(const SyncCenterView()));
      repository.reads[0].complete(_snapshot(1000));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('queue:work_log:owner:task-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('queue:work_log:owner:task-999')),
        findsNothing,
      );
      expect(find.text('工时记录'), findsAtLeastNWidgets(1));
      expect(find.text('工时记录').evaluate().length, lessThan(20));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      final offset = position.pixels;
      await tester.tap(find.byTooltip('刷新'));
      await tester.pump();
      expect(repository.reads, hasLength(2));
      expect(find.byType(AppLoading), findsNothing);
      expect(position.pixels, offset);
      expect(find.text('工时记录').evaluate().length, greaterThan(0));
      repository.reads[1].completeError(StateError('read unavailable'));
      await tester.pumpAndSettle();
      expect(position.pixels, offset);
      expect(find.text('工时记录').evaluate().length, greaterThan(0));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 1500));
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadFailure), findsOneWidget);
      await tester.tap(find.text('重试'));
      await tester.pump();
      repository.reads[2].complete(_snapshot(0));
      await tester.pumpAndSettle();
      expect(find.text('没有待重试任务'), findsOneWidget);
      expect(find.byType(AppLoadFailure), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'task and conflict titles are readable and technical identifiers remain available on demand',
    (tester) async {
      final repository = _Snapshots();
      _register(repository);
      await tester.pumpWidget(_app(const SyncCenterView()));
      repository.reads[0].complete(_snapshot(1, conflicts: 1));
      await tester.pumpAndSettle();
      expect(find.text('工时记录'), findsOneWidget);
      expect(find.text('项目 · 冲突'), findsOneWidget);
      expect(find.textContaining('owner:task-0'), findsNothing);
      expect(find.textContaining('version-mismatch'), findsNothing);
      await tester.tap(find.byTooltip('查看任务详情'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains('owner:task-0'),
      );
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('查看冲突详情'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains('version-mismatch'),
      );
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains('本地版本 2'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'initial read failure has an actionable retry and late completion after exit is safe',
    (tester) async {
      final repository = _Snapshots();
      _register(repository);
      await tester.pumpWidget(_app(const SyncCenterView()));
      repository.reads[0].completeError(StateError('initial read failed'));
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadFailure), findsOneWidget);
      await tester.tap(find.text('重试'));
      await tester.pump();
      await tester.pumpWidget(_app(const SizedBox()));
      repository.reads[1].complete(_snapshot(1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'in-flight conflict remains single-flight after scrolling away and back',
    (tester) async {
      final repository = _Snapshots();
      _register(repository);
      await tester.pumpWidget(_app(const SyncCenterView()));
      repository.reads[0].complete(_snapshot(0, conflicts: 30));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保留本地').first);
      await tester.pump();
      expect(repository.resolutions, [(1, 'keep-local')]);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2200));
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 4000));
      await tester.pump(const Duration(seconds: 1));
      final firstButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保留本地').first,
      );
      expect(firstButton.onPressed, isNull);
      expect(repository.resolutions, hasLength(1));
      repository.resolveGate.complete();
      await tester.pump();
      expect(repository.reads, hasLength(2));
      repository.reads[1].complete(_snapshot(0));
      await tester.pumpAndSettle();
      expect(find.text('没有待处理冲突'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    for (final largeText in [false, true]) {
      testWidgets(
        'sync center ${dark ? 'dark' : 'light'} ${largeText ? '320px 2x' : '390px'}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(largeText ? 320 : 390, 844);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = _Snapshots();
          _register(repository);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            _app(
              RepaintBoundary(key: boundary, child: const SyncCenterView()),
              dark: dark,
              textScale: largeText ? 2 : 1,
            ),
          );
          repository.reads[0].complete(_snapshot(2, conflicts: 2));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester
                .renderObject<RenderParagraph>(find.text('需处理'))
                .didExceedMaxLines,
            isFalse,
          );
          if (!largeText) {
            final metrics = find.descendant(
              of: find.byType(AppCard).first,
              matching: find.byType(Icon),
            );
            final first = tester.getCenter(metrics.at(0)).dx;
            final second = tester.getCenter(metrics.at(1)).dx;
            final third = tester.getCenter(metrics.at(2)).dx;
            expect(second - first, closeTo(third - second, 1));
          }
          const directory = String.fromEnvironment('UI_REVIEW_DIR');
          if (directory.isNotEmpty) {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final picture = await render.toImage();
              final bytes = await picture.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$directory/sync-${dark ? 'dark' : 'light'}-${largeText ? 'large' : 'normal'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              picture.dispose();
            });
          }
        },
      );
    }
  }

  testWidgets(
    'thumbnail respects cell bounds and density without rewriting local bytes',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'lifelog_thumbnail_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/photo.png');
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
      );
      file.writeAsBytesSync(bytes);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 101,
              height: 137,
              child: AppLocalThumbnail(filePath: file.path),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var resized =
          tester.widget<Image>(find.byType(Image)).image as ResizeImage;
      expect(resized.width, 303);
      expect(resized.height, 411);
      expect(resized.policy, ResizeImagePolicy.fit);
      expect((resized.imageProvider as FileImage).file.path, file.path);
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 51,
              height: 70,
              child: AppLocalThumbnail(filePath: file.path),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      resized = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
      expect(resized.width, 153);
      expect(resized.height, 210);
      expect(file.readAsBytesSync(), bytes);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'scroll cancels press before pointer-up without interrupting the drag',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          ListView(
            children: [
              AppPressFeedback(
                child: InkWell(
                  onTap: () => taps++,
                  child: const SizedBox(height: 100, child: Text('card')),
                ),
              ),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      );
      final pointer = await tester.startGesture(
        tester.getCenter(find.text('card')),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.98,
      );
      await pointer.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await pointer.moveBy(const Offset(0, -120));
      await tester.pump();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        greaterThan(0),
      );
      await pointer.up();
      await tester.pumpAndSettle();
      expect(taps, 0);
    },
  );

  testWidgets(
    'secondary pointer release does not reset active press; cancellation releases it',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: AppPressFeedback(
              child: GestureDetector(
                onTap: () {},
                child: const SizedBox(
                  width: 160,
                  height: 90,
                  child: Text('card'),
                ),
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.text('card'));
      final first = await tester.startGesture(center, pointer: 1);
      final second = await tester.startGesture(
        center + const Offset(2, 2),
        pointer: 2,
      );
      await second.up();
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.98,
      );
      await first.cancel();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    },
  );

  testWidgets(
    'tap still fires once and disabled/reduced motion removes press animation',
    (tester) async {
      var taps = 0;
      Widget card({bool enabled = true, bool reduceMotion = false}) => _app(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Center(
            child: AppPressFeedback(
              enabled: enabled,
              child: InkWell(
                onTap: () => taps++,
                child: const SizedBox(
                  width: 160,
                  height: 90,
                  child: Text('card'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(card());
      await tester.tap(find.text('card'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      for (final enabled in [false, true]) {
        await tester.pumpWidget(card(enabled: enabled, reduceMotion: enabled));
        final pointer = await tester.startGesture(
          tester.getCenter(find.text('card')),
        );
        await tester.pump();
        final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
        expect(scale.scale, 1);
        if (enabled) expect(scale.duration, Duration.zero);
        await pointer.up();
        await tester.pumpAndSettle();
      }
    },
  );
}

Widget _app(
  Widget child, {
  bool dark = false,
  double textScale = 1,
}) => MaterialApp(
  theme: (dark ? AppTheme.dark : AppTheme.light).copyWith(
    appBarTheme: (dark ? AppTheme.dark : AppTheme.light).appBarTheme.copyWith(
      titleTextStyle: (dark ? AppTheme.dark : AppTheme.light)
          .appBarTheme
          .titleTextStyle
          ?.copyWith(
            fontFamily: const String.fromEnvironment('UI_REVIEW_FONT').isEmpty
                ? 'Roboto'
                : 'NotoSansCJK',
          ),
    ),
    textTheme: (dark ? AppTheme.dark : AppTheme.light).textTheme.apply(
      fontFamily: const String.fromEnvironment('UI_REVIEW_FONT').isEmpty
          ? null
          : 'NotoSansCJK',
    ),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void _register(_Snapshots repository) {
  serviceLocator.registerSingleton(LoadSyncCenterSnapshot(repository));
  serviceLocator.registerSingleton(ResolveSyncConflict(repository));
}

SyncCenterSnapshot _snapshot(int count, {int conflicts = 0}) =>
    SyncCenterSnapshot(
      pendingQueueEntries: List.generate(
        count,
        (i) => SyncQueueEntry(
          entityName: 'work_log',
          entityKey: 'owner:task-$i',
          attemptCount: 2,
          nextAttemptAt: DateTime(2026, 10, 7, 12),
          lastError: '网络暂时不可用',
        ),
      ),
      unresolvedConflicts: List.generate(
        conflicts,
        (i) => SyncConflictEntry(
          id: i + 1,
          entityName: 'project',
          entitySyncId: 'project-${i + 1}',
          conflictType: 'version-mismatch',
          message: '其他设备更新了这条记录，请选择要保留的版本。',
          detectedAt: DateTime(2026, 10, 7),
          localVersion: 2,
          remoteVersion: 3,
        ),
      ),
    );

class _Snapshots implements SyncCenterRepositoryPort {
  final reads = <Completer<SyncCenterSnapshot>>[];
  final resolutions = <(int, String)>[];
  final resolveGate = Completer<void>();
  @override
  Future<SyncCenterSnapshot> loadSnapshot() {
    final read = Completer<SyncCenterSnapshot>();
    reads.add(read);
    return read.future;
  }

  @override
  Future<void> resolveConflict(int id, {required String resolution}) {
    resolutions.add((id, resolution));
    return resolveGate.future;
  }
}
