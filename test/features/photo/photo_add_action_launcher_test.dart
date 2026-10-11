import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/save_photo_from_path.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/capture_dialog.dart';
import 'package:life_log/features/photo/presentation/photo_add_action_launcher.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_stage_field.dart';

import '../../support/test_get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  late TestGetStorage fixture;
  late _Photos repository;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('photo_launcher_');
    messenger.setMockMethodCallHandler(
      pathChannel,
      (_) async => directory.path,
    );
    fixture = await TestGetStorage.open('GetStorage', directory);
  });

  setUp(() {
    repository = _Photos();
    serviceLocator.registerFactory<PhotoCubit>(
      () => PhotoCubit(
        loadEntries: LoadPhotoEntries(repository),
        watchEntries: WatchPhotoEntries(repository),
      ),
    );
    serviceLocator.registerSingleton<SavePhotoFromPath>(
      SavePhotoFromPath(repository),
    );
    serviceLocator.registerSingleton<LoadProjectEntries>(
      LoadProjectEntries(_Projects()),
    );
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(pickerChannel, null);
    await serviceLocator.reset();
  });
  tearDownAll(() async {
    await fixture.close();
    messenger.setMockMethodCallHandler(pathChannel, null);
    await directory.delete();
  });

  testWidgets(
    'camera preserves project id and exact namesake stages through picker and save',
    (tester) async {
      final pickerResult = Completer<String?>();
      messenger.setMockMethodCallHandler(pickerChannel, (call) async {
        expect(call.method, 'pickImage');
        return pickerResult.future;
      });
      await _pump(
        tester,
        (context) => capturePhotoWithSystemCamera(
          context,
          initialProject: '同名项目',
          initialProjectId: 16,
          initialProjectStageName: '施工',
        ),
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('launch'));
        await Future<void>.delayed(Duration.zero);
        await fixture.storage.queue.add<void>(() async {});
      });
      await tester.pumpAndSettle();
      final pending = PhotoPendingCaptureStore(storage: fixture.storage);
      expect(pending.readProject(), '同名项目');
      expect(pending.readProjectId(), 16);
      expect(pending.readStage(), '施工');
      await tester.runAsync(() async {
        pickerResult.complete('${directory.path}/camera.jpg');
        await Future<void>.delayed(Duration.zero);
        await fixture.storage.queue.add<void>(() async {});
      });
      await tester.pumpAndSettle();
      expect(pending.readProjectId(), isNull);
      expect(pending.readStage(), isNull);
      final stageField = tester.widget<ProjectStageField>(
        find.byType(ProjectStageField),
      );
      expect(stageField.projectId, 16);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('误匹配阶段'), findsNothing);
      expect(find.text('验收'), findsOneWidget);
      await tester.tap(find.text('验收'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('确认录入'));
      await tester.tap(find.text('确认录入'));
      await tester.pumpAndSettle();
      expect(repository.saved.single.projectId, 16);
      expect(repository.saved.single.projectStageName, '验收');
      expect(repository.deleteSources, [true]);
    },
  );

  for (final rename in [false, true]) {
    testWidgets(
      'dialog ${rename ? 'clears' : 'preserves'} initial id and stage when the name ${rename ? 'changes' : 'stays the same'}',
      (tester) async {
        (String, String?, int?)? selected;
        await _pump(
          tester,
          (context) => showCaptureDialog(
            context,
            initialProject: '同名项目',
            initialProjectId: 16,
            initialProjectStageName: '施工',
            onConfirm: (_, _) {},
            onConfirmWithProject: (name, description, stage, id) {
              selected = (name, stage, id);
            },
          ),
        );
        await tester.tap(find.text('launch'));
        await tester.pumpAndSettle();
        if (rename) {
          await tester.tap(
            find
                .ancestor(
                  of: find.widgetWithText(TextFormField, '选择或创建项目'),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is GestureDetector && widget.onTap != null,
                  ),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, '搜索或创建新项目...'),
            '新项目',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('创建新项目: "新项目"'));
        } else {
          final input = tester.widget<TextFormField>(
            find.widgetWithText(TextFormField, '选择或创建项目'),
          );
          input.controller!.text = '同名项目 ';
        }
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('确认录入'));
        await tester.tap(find.text('确认录入'));
        await tester.pumpAndSettle();
        expect(selected, rename ? ('新项目', null, null) : ('同名项目', '施工', 16));
      },
    );
  }

  test(
    'pending captures overwrite and clear old identity independently of stage',
    () async {
      final pending = PhotoPendingCaptureStore(storage: fixture.storage);
      await pending.rememberProject('项目', projectId: 16, stageName: '施工');
      expect(pending.readProjectId(), 16);
      await pending.rememberProject('新项目');
      expect(pending.readProjectId(), isNull);
      expect(pending.readStage(), isNull);
      await pending.clear();
      expect(pending.readProject(), isNull);
      expect(pending.readProjectId(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  void Function(BuildContext) launch,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => launch(context),
                child: const Text('launch'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _Projects implements ProjectRepositoryPort {
  @override
  Future<List<ProjectEntry>> getAllEntries() async => [
    const ProjectEntry(
      id: 99,
      name: '同名项目',
      status: ProjectEntryStatus.active,
      stageNames: ['误匹配阶段'],
    ),
    const ProjectEntry(
      id: 16,
      name: '同名项目',
      status: ProjectEntryStatus.archived,
      isLocalArchive: true,
      stageNames: ['施工', '验收'],
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _Photos implements PhotoRepositoryPort {
  final saved = <PhotoEntry>[];
  final deleteSources = <bool>[];
  @override
  Future<List<PhotoEntry>> getAllEntries() async => [];
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  Future<PhotoEntry> saveEntryFromPath({
    required String tempPath,
    required String projectName,
    int? projectId,
    String? projectStageName,
    required String description,
    required String deviceName,
    required bool deleteSource,
    DateTime? capturedAt,
    String? capturedAtSource,
    double? gpsLatitude,
    double? gpsLongitude,
  }) async {
    final photo = PhotoEntry(
      id: saved.length + 1,
      ownerUserId: null,
      createdAt: DateTime(2026),
      fileName: 'photo.jpg',
      filePath: tempPath,
      projectName: projectName,
      projectId: projectId,
      projectStageName: projectStageName,
      description: description,
      deviceName: deviceName,
      dateIndexed: DateTime(2026),
    );
    saved.add(photo);
    deleteSources.add(deleteSource);
    return photo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
