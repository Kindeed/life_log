import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_form_feedback.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/update_photo_description.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/photo_display_preferences.dart';
import 'package:life_log/features/photo/presentation/photo_preview_view.dart';

import '../../support/test_get_storage.dart';

const _reviewDirectory = String.fromEnvironment('UI_REVIEW_DIR');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  late TestGetStorage fixture;
  late PhotoDisplayPreferences preferences;
  late _Photos repository;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('photo_preview_u386_');
    messenger.setMockMethodCallHandler(
      pathChannel,
      (_) async => directory.path,
    );
    fixture = await TestGetStorage.open('PhotoPreviewU386', directory);
    for (final font in [
      ('Roboto', const String.fromEnvironment('UI_REVIEW_FONT')),
      ('MaterialIcons', const String.fromEnvironment('UI_REVIEW_ICONS')),
    ]) {
      if (font.$2.isEmpty) continue;
      final loader = FontLoader(font.$1);
      loader.addFont(
        Future.value(ByteData.sublistView(await File(font.$2).readAsBytes())),
      );
      await loader.load();
    }
  });

  setUp(() async {
    await fixture.storage.write('photo.showGpsMetadata', false);
    preferences = PhotoDisplayPreferences(storage: fixture.storage);
    repository = _Photos();
    serviceLocator.registerSingleton<PhotoDisplayPreferences>(preferences);
    serviceLocator.registerSingleton<UpdatePhotoDescription>(
      UpdatePhotoDescription(repository),
    );
  });

  tearDown(() async {
    await serviceLocator.reset();
    preferences.dispose();
  });

  tearDownAll(() async {
    await fixture.close();
    messenger.setMockMethodCallHandler(pathChannel, null);
    await directory.delete();
  });

  for (final dark in [false, true]) {
    for (final spec in [(390.0, 1.0), (320.0, 2.0)]) {
      testWidgets(
        'complete caption stays readable and bounded dark=$dark width=${spec.$1} scale=${spec.$2}',
        (tester) async {
          const tail = '最后一行：已完成现场验收。';
          final description =
              '${List.filled(30, '设备已检查，等待客户确认后进行试产。').join('\n')}\n$tail';
          await _open(
            tester,
            [_photo(1, description: description)],
            dark: dark,
            width: spec.$1,
            scale: spec.$2,
          );
          final caption = find.byKey(
            const ValueKey('photo-preview-description'),
          );
          final text = tester.widget<Text>(caption);
          expect(text.data, description);
          expect(text.maxLines, isNull);
          expect(text.style?.color, Colors.white);
          final panel = tester.getRect(_panel);
          final imageArea = tester.getRect(find.byType(PageView));
          expect(panel.width, spec.$1 - 32);
          expect(
            panel.height,
            lessThanOrEqualTo(imageArea.height * 0.3 + 0.01),
          );
          if (dark && spec.$1 == 320) {
            await _capture(tester, 'photo-preview-320-2x.png');
          }
          final scroll = _metadataScroll(tester);
          expect(scroll.position.maxScrollExtent, greaterThan(0));
          await tester.drag(
            find.byKey(const ValueKey('photo-preview-metadata-1')),
            const Offset(0, -5000),
          );
          await tester.pumpAndSettle();
          expect(
            scroll.position.pixels,
            closeTo(scroll.position.maxScrollExtent, 0.01),
          );
          final paragraph = tester.renderObject<RenderParagraph>(caption);
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(
              baseOffset: description.length - tail.length,
              extentOffset: description.length,
            ),
          );
          expect(boxes, isNotEmpty);
          for (final box in boxes) {
            final top = paragraph.localToGlobal(Offset(box.left, box.top));
            final bottom = paragraph.localToGlobal(
              Offset(box.right, box.bottom),
            );
            expect(top.dy, greaterThanOrEqualTo(panel.top));
            expect(bottom.dy, lessThanOrEqualTo(panel.bottom));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('blank caption reserves no image space and GPS stays opt in', (
    tester,
  ) async {
    await _open(tester, [_photo(1, description: '  \n ', gps: true)]);
    expect(_panel, findsNothing);
    expect(find.textContaining('GPS '), findsNothing);
    await tester.runAsync(() => preferences.setShowGpsMetadata(true));
    await tester.pumpAndSettle();
    expect(_panel, findsOneWidget);
    expect(
      find.byKey(const ValueKey('photo-preview-description')),
      findsNothing,
    );
    expect(find.text('GPS 22.543096, 114.057865'), findsOneWidget);
    await tester.runAsync(() => preferences.setShowGpsMetadata(false));
    await tester.pumpAndSettle();
    expect(_panel, findsNothing);
  });

  testWidgets(
    'caption and GPS share a wrapping bottom region at 320dp and 2x',
    (tester) async {
      await preferences.setShowGpsMetadata(true);
      await _open(
        tester,
        [_photo(1, description: '验收通过，设备运行正常。', gps: true)],
        width: 320,
        scale: 2,
      );
      final captionRect = tester.getRect(find.text('验收通过，设备运行正常。'));
      final gps = find.text('GPS 22.543096, 114.057865');
      expect(tester.getRect(gps).top, greaterThan(captionRect.bottom));
      expect(tester.widget<Text>(gps).maxLines, isNull);
      final panel = tester.getRect(_panel);
      expect(panel.right, lessThanOrEqualTo(320));
      await tester.drag(
        find.byKey(const ValueKey('photo-preview-metadata-1')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(gps).bottom, lessThanOrEqualTo(panel.bottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'real page swipe replaces caption and resets its reading position',
    (tester) async {
      final long = List.filled(25, '首张照片的设备检查记录。').join('\n');
      await _open(tester, [
        _photo(1, description: long),
        _photo(2, description: '第二张：验收结果。'),
      ]);
      await tester.drag(
        find.byKey(const ValueKey('photo-preview-metadata-1')),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      expect(_metadataScroll(tester).position.pixels, greaterThan(0));
      await tester.drag(find.byType(PageView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('第二张：验收结果。'), findsOneWidget);
      expect(find.text(long), findsNothing);
      expect(_metadataScroll(tester).position.pixels, 0);
      await tester.drag(find.byType(PageView), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text(long), findsOneWidget);
      expect(_metadataScroll(tester).position.pixels, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'successful edits update caption, editor and current photo only',
    (tester) async {
      final image = File('assets/icon/app_icon.png');
      final bytes = image.readAsBytesSync();
      final photos = [
        _photo(1, description: '原始备注'),
        _photo(2, description: '另一张照片的备注'),
      ];
      await _open(tester, photos);
      await _edit(tester, '新备注：客户已确认。');
      await tester.tap(find.text('保存备注'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('新备注：客户已确认。'), findsOneWidget);
      expect(repository.saves, [(1, '新备注：客户已确认。')]);
      expect(photos.first.description, '原始备注');
      expect(image.readAsBytesSync(), bytes);
      for (final viewer in tester.widgetList<InteractiveViewer>(
        find.byType(InteractiveViewer),
      )) {
        expect(viewer.minScale, 0.8);
        expect(viewer.maxScale, 4);
      }
      for (final widget in tester.widgetList<Image>(find.byType(Image))) {
        expect(widget.image, isA<FileImage>());
        expect(widget.fit, BoxFit.contain);
      }
      await tester.tap(find.byTooltip('编辑备注'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '新备注：客户已确认。',
      );
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(find.text('另一张照片的备注'), findsOneWidget);
      expect(find.text('新备注：客户已确认。'), findsNothing);
      await tester.drag(find.byType(PageView), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text('新备注：客户已确认。'), findsOneWidget);
    },
  );

  testWidgets('saving an empty caption removes its read-only region', (
    tester,
  ) async {
    await _open(tester, [_photo(1, description: '待删除的备注')]);
    await _edit(tester, '   ');
    await tester.tap(find.text('保存备注'));
    await tester.pumpAndSettle();
    expect(_panel, findsNothing);
    expect(repository.saves, [(1, '')]);
    await tester.tap(find.byTooltip('编辑备注'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '',
    );
  });

  testWidgets('failed edit keeps old caption and editable draft for retry', (
    tester,
  ) async {
    repository.failure = StateError('备注更新失败');
    await _open(tester, [_photo(1, description: '保留原备注')]);
    await _edit(tester, '修改后的草稿');
    await tester.tap(find.text('保存备注'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.textContaining('备注更新失败'), findsOneWidget);
    expect(find.byType(AppFormFeedback), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '修改后的草稿',
    );
    expect(find.text('保留原备注'), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.byType(AppButton)).onPressed,
      isNotNull,
    );
    repository.failure = null;
    await tester.tap(find.text('保存备注'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('修改后的草稿'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending edit is single flight and cannot pop after sheet dismissal',
    (tester) async {
      repository.pending = Completer<String?>();
      await _open(tester, [_photo(1, description: '旧备注')]);
      await _edit(tester, '较晚保存的新备注');
      // Invoke the original callback twice before its disabled rebuild.
      final button = tester.widget<AppButton>(find.byType(AppButton));
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(repository.saves, [(1, '较晚保存的新备注')]);
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
        isFalse,
      );
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.edit_note_rounded),
            )
            .onPressed,
        isNull,
      );
      repository.pending!.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(PhotoPreviewView), findsOneWidget);
      expect(find.text('较晚保存的新备注'), findsOneWidget);
      expect(find.text('打开照片'), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.edit_note_rounded),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('completion during sheet exit cannot pop the preview route', (
    tester,
  ) async {
    repository.pending = Completer<String?>();
    await _open(tester, [_photo(1, description: '旧备注')]);
    await _edit(tester, '退出动画期间保存完成');
    await tester.tap(find.text('保存备注'));
    await tester.pump();
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(TextFormField), findsOneWidget);
    repository.pending!.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoPreviewView), findsOneWidget);
    expect(find.text('退出动画期间保存完成'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renamed file refresh updates only its image and keeps gallery order',
    (tester) async {
      final original = _photo(1, description: '旧备注');
      final newPath = File('assets/icon/../icon/app_icon.png').absolute.path;
      repository.oldPathToEvict = original.filePath;
      repository.entries = [
        _photo(99, description: '另一个项目的照片'),
        _photo(2, description: '第二张'),
        _photo(
          1,
          description: '已改备注',
          filePath: newPath,
          createdAt: original.createdAt.toUtc(),
        ),
      ];
      serviceLocator.registerSingleton<LoadPhotoEntries>(
        LoadPhotoEntries(repository),
      );
      await _open(tester, [original, _photo(2, description: '第二张')]);
      await _edit(tester, '已改备注');
      await tester.tap(find.text('保存备注'));
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byWidgetPredicate(
            (widget) => widget is Hero && widget.tag == 'photo-1',
          ),
          matching: find.byType(Image),
        ),
      );
      expect((image.image as FileImage).file.path, newPath);
      expect(original.filePath, isNot(newPath));
      expect(repository.loads, 1);
      expect(find.text('已改备注'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('第二张'), findsOneWidget);
      expect(find.text('另一个项目的照片'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed post-save lookup preserves caption after sheet dismissal',
    (tester) async {
      final original = _photo(1, description: '旧备注');
      repository.oldPathToEvict = original.filePath;
      repository.pendingRead = Completer<List<PhotoEntry>>();
      serviceLocator.registerSingleton<LoadPhotoEntries>(
        LoadPhotoEntries(repository),
      );
      await _open(tester, [original]);
      await _edit(tester, '提交已完成的新备注');
      await tester.tap(find.text('保存备注'));
      await tester.pump();
      expect(repository.loads, 1);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      repository.pendingRead!.completeError(StateError('读取失败'));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoPreviewView), findsOneWidget);
      expect(find.text('提交已完成的新备注'), findsOneWidget);
      expect(find.text('备注已保存，但照片预览刷新失败，请返回项目后重新打开。'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mismatch in ['owner', 'project', 'name', 'created']) {
    testWidgets(
      'renamed-file refresh rejects reused identity mismatch=$mismatch',
      (tester) async {
        final original = _photo(1, description: '旧备注');
        repository.oldPathToEvict = original.filePath;
        repository.entries = [
          _photo(
            1,
            description: '不应显示的其他记录',
            filePath: 'foreign-file-$mismatch.jpg',
            ownerUserId: mismatch == 'owner' ? 'foreign' : null,
            projectId: mismatch == 'project' ? 999 : 9,
            projectName: mismatch == 'name' ? '另一项目' : '设备安装',
            createdAt: mismatch == 'created' ? DateTime(2026, 10, 12) : null,
          ),
        ];
        serviceLocator.registerSingleton<LoadPhotoEntries>(
          LoadPhotoEntries(repository),
        );
        await _open(tester, [original]);
        await _edit(tester, '已提交的备注');
        await tester.tap(find.text('保存备注'));
        await tester.pumpAndSettle();
        expect(find.text('已提交的备注'), findsOneWidget);
        expect(find.text('不应显示的其他记录'), findsNothing);
        expect(find.text('备注已保存，但照片预览刷新失败，请返回项目后重新打开。'), findsOneWidget);
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          expect((image.image as FileImage).file.path, original.filePath);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

final _panel = find.byKey(const ValueKey('photo-preview-metadata'));

ScrollableState _metadataScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find.descendant(of: _panel, matching: find.byType(Scrollable)),
    );

Future<void> _edit(WidgetTester tester, String value) async {
  await tester.tap(find.byTooltip('编辑备注'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), value);
}

Future<void> _open(
  WidgetTester tester,
  List<PhotoEntry> photos, {
  bool dark = false,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('zh', 'CN')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => RepaintBoundary(
                    key: const ValueKey('photo-preview-capture'),
                    child: PhotoPreviewView(photos: photos, initialIndex: 0),
                  ),
                ),
              ),
              child: const Text('打开照片'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开照片'));
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_reviewDirectory.isEmpty) return;
  for (var attempt = 0; attempt < 30; attempt++) {
    if (tester
        .widgetList<RawImage>(find.byType(RawImage))
        .any((image) => image.image != null)) {
      break;
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
  }
  expect(
    tester
        .widgetList<RawImage>(find.byType(RawImage))
        .any((image) => image.image != null),
    isTrue,
    reason: 'Screenshot capture waits for a genuine decoded photo.',
  );
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('photo-preview-capture')),
    );
    final image = await boundary.toImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(_reviewDirectory).create(recursive: true);
      await File('$_reviewDirectory/$name').writeAsBytes(
        data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

PhotoEntry _photo(
  int id, {
  String? description,
  bool gps = false,
  String? filePath,
  String? ownerUserId,
  int projectId = 9,
  String projectName = '设备安装',
  DateTime? createdAt,
}) => PhotoEntry(
  id: id,
  ownerUserId: ownerUserId,
  createdAt: createdAt ?? DateTime(2026, 10, 11, 9),
  fileName: 'app_icon.png',
  filePath: filePath ?? File('assets/icon/app_icon.png').absolute.path,
  description: description,
  deviceName: '现场相机',
  projectName: projectName,
  projectId: projectId,
  gpsLatitude: gps ? 22.543096 : null,
  gpsLongitude: gps ? 114.057865 : null,
  dateIndexed: DateTime(2026, 10, 11),
);

final class _Photos implements PhotoRepositoryPort {
  final saves = <(int, String)>[];
  Object? failure;
  Completer<String?>? pending;
  String? oldPathToEvict;
  int loads = 0;
  List<PhotoEntry> entries = [];
  Completer<List<PhotoEntry>>? pendingRead;

  @override
  Future<String?> updateEntryDescription(
    PhotoEntry entry,
    String description,
  ) async {
    saves.add((entry.id, description));
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return oldPathToEvict;
  }

  @override
  Future<List<PhotoEntry>> getAllEntries() async {
    loads++;
    if (pendingRead != null) return pendingRead!.future;
    return entries;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
