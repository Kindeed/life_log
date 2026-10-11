import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_local_thumbnail.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/project/presentation/project_channel_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'channel text and accounting records reflow at 320dp, dark=$dark scale=$scale',
        (tester) async {
          final longText = List.filled(20, '已完成设备检查，等待客户确认后开始试产。').join('\n');
          var taps = 0;
          await _pump(
            tester,
            dark: dark,
            scale: scale,
            children: [
              _record(
                title: '文字记录',
                subtitle: '文字 · 勘查与设备安装阶段',
                typeLabel: '文字',
                content: longText,
                onTap: () => taps++,
              ),
              _record(
                title: '从深圳到香港进行生产设备调试',
                subtitle: '高铁 · 设备调试 · ¥1,234.56 · 未报销',
                typeLabel: '出差',
                content: '客户已确认行程，保留费用原始币种。',
                eventTime: DateTime(2026, 10, 11, 13, 7),
              ),
            ],
          );
          expect(tester.takeException(), isNull);
          expect(find.text('文字记录'), findsNothing);
          expect(find.text('文字 · 勘查与设备安装阶段'), findsOneWidget);
          final body = tester.widget<Text>(find.text(longText));
          expect(body.maxLines, 12);
          expect(body.overflow, TextOverflow.ellipsis);
          final bodyRect = tester.getRect(find.text(longText));
          expect(bodyRect.width, 256);
          await tester.tap(find.text(longText));
          expect(taps, 1);
          await tester.scrollUntilVisible(
            find.textContaining('¥1,234.56'),
            200,
            scrollable: find.byType(Scrollable),
          );
          expect(find.text('高铁 · 设备调试 · ¥1,234.56 · 未报销'), findsNothing);
          expect(
            find.textContaining('¥1,234.56 · 未报销 · 13:07'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'date-only local and UTC records do not fabricate a midnight clock',
    (tester) async {
      await _pump(
        tester,
        children: [
          _record(title: '文字记录', eventTime: DateTime(2026, 10, 11)),
          _record(title: '文字记录', eventTime: DateTime.utc(2026, 10, 11)),
        ],
      );
      expect(find.text('文字 · 未分阶段'), findsNWidgets(2));
      expect(find.textContaining(RegExp(r'\d{2}:\d{2}')), findsNothing);
    },
  );

  testWidgets(
    'photo uses a bounded wide thumbnail with caption and short metadata',
    (tester) async {
      final image = File('assets/icon/app_icon.png');
      final originalBytes = image.readAsBytesSync();
      await _pump(
        tester,
        children: [
          _record(
            title: 'Pixel 8',
            typeLabel: '照片',
            subtitle: 'Pixel 8 · 验收',
            photo: _photo(image.path),
            content: '验收现场，设备已稳定运行。',
            eventTime: DateTime(2026, 10, 11, 9, 35),
          ),
        ],
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(find.text('Pixel 8'), findsNothing);
      expect(find.text('照片 · Pixel 8 · 验收 · 09:35'), findsOneWidget);
      final thumbnailRect = tester.getRect(find.byType(AppLocalThumbnail));
      expect(thumbnailRect.width, 288);
      expect(thumbnailRect.height, 162);
      final captionRect = tester.getRect(find.text('验收现场，设备已稳定运行。'));
      expect(captionRect.top, greaterThanOrEqualTo(thumbnailRect.bottom));
      final imageWidget = tester.widget<Image>(find.byType(Image));
      final resized = imageWidget.image as ResizeImage;
      expect(resized.width, 288);
      expect(resized.height, 162);
      expect(resized.policy, ResizeImagePolicy.fit);
      expect(image.readAsBytesSync(), originalBytes);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets('missing photo placeholder stays readable at 2x, dark=$dark', (
      tester,
    ) async {
      await _pump(
        tester,
        dark: dark,
        scale: 2,
        children: [
          _record(
            title: '项目照片',
            typeLabel: '照片',
            subtitle: '施工现场 · 验收',
            photo: _photo('missing-local-channel-photo.jpg'),
            content: '原文件不可用时仍能阅读这张照片的说明。',
          ),
        ],
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(find.text('照片文件不可用'), findsOneWidget);
      expect(find.text('原文件不可用时仍能阅读这张照片的说明。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'surface and text retain paired theme roles with compact geometry',
    (tester) async {
      await _pump(
        tester,
        dark: true,
        children: [_record(title: '耗材', typeLabel: '费用', content: '设备维护')],
      );
      final theme = Theme.of(tester.element(find.byType(ProjectChannelRecord)));
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(ProjectChannelRecord),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, theme.colorScheme.surface);
      expect(material.borderRadius, BorderRadius.circular(AppRadius.sm));
      expect(material.elevation, 0);
      expect(
        tester.widget<Text>(find.text('设备维护')).style!.color,
        theme.colorScheme.onSurface,
      );
      expect(
        tester.widget<Text>(find.text('费用 · 未分阶段')).style!.color,
        theme.colorScheme.onSurfaceVariant,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.edit_note_rounded)).size,
        16,
      );
    },
  );

  testWidgets(
    'records remain lazy in a long channel and expose the detail action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var built = 0;
      await _pump(
        tester,
        builder: (context) => ListView.builder(
          itemCount: 1000,
          itemBuilder: (_, index) {
            built++;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _record(
                key: ValueKey(index),
                title: '文字记录',
                content: '第 $index 条现场记录',
              ),
            );
          },
        ),
      );
      expect(built, lessThan(30));
      expect(find.bySemanticsLabel(RegExp('查看文字详情')), findsWidgets);
      expect(find.text('第 999 条现场记录'), findsNothing);
      semantics.dispose();
    },
  );
}

ProjectChannelRecord _record({
  Key? key,
  required String title,
  String subtitle = '未分阶段',
  String typeLabel = '文字',
  DateTime? eventTime,
  String? content,
  PhotoEntry? photo,
  VoidCallback? onTap,
}) => ProjectChannelRecord(
  key: key,
  title: title,
  subtitle: subtitle,
  typeLabel: typeLabel,
  eventTime: eventTime ?? DateTime(2026, 10, 11),
  content: content,
  icon: Icons.edit_note_rounded,
  color: AppTheme.light.colorScheme.primary,
  photo: photo,
  onTap: onTap ?? () {},
);

PhotoEntry _photo(String path) => PhotoEntry(
  id: 1,
  ownerUserId: null,
  createdAt: DateTime(2026, 10, 11),
  fileName: 'photo.jpg',
  filePath: path,
  description: '原有说明',
  deviceName: 'Pixel 8',
  projectName: '项目',
  projectId: 1,
  dateIndexed: DateTime(2026, 10, 11),
);

Future<void> _pump(
  WidgetTester tester, {
  bool dark = false,
  double scale = 1,
  List<Widget> children = const [],
  WidgetBuilder? builder,
}) async {
  tester.view.physicalSize = const Size(320, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder:
              builder ??
              (_) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final child in children)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: child,
                    ),
                ],
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
