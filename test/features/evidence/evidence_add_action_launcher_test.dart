import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/evidence_feature_di.dart';
import 'package:life_log/features/evidence/presentation/evidence_add_action_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_sheet.dart';
import 'package:life_log/features/evidence/presentation/evidence_lost_data_recovery.dart';

import '../../support/test_get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  late TestGetStorage fixture;
  late File cameraImage;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('evidence_launch_test_');
    messenger.setMockMethodCallHandler(
      pathChannel,
      (_) async => directory.path,
    );
    fixture = await TestGetStorage.open('GetStorage', directory);
    cameraImage = File('${directory.path}/camera.png');
    await cameraImage.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aOioAAAAASUVORK5CYII=',
      ),
    );
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(pickerChannel, null);
    await serviceLocator.reset();
  });

  tearDownAll(() async {
    await fixture.close();
    messenger.setMockMethodCallHandler(pathChannel, null);
    await cameraImage.delete();
    await directory.delete();
  });

  testWidgets(
    'camera action preserves project and stage through picker and save',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository();
      configureEvidenceFeatureDependencies(repository: repository);
      final pickerResult = Completer<String?>();
      MethodCall? pickerCall;
      messenger.setMockMethodCallHandler(pickerChannel, (call) async {
        expect(call.method, 'pickImage');
        pickerCall = call;
        return pickerResult.future;
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showEvidenceAddActions(
                      context,
                      initialProject: '项目七',
                      initialProjectStageName: '施工',
                    ),
                    child: const Text('add evidence'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('add evidence'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('拍摄凭证'));
        await Future<void>.delayed(Duration.zero);
        await fixture.storage.queue.add<void>(() async {});
      });
      await tester.pumpAndSettle();

      expect(pickerCall, isNotNull);
      expect(
        (pickerCall!.arguments as Map)['source'],
        ImageSource.camera.index,
      );
      final pending = EvidencePendingPickerStore(storage: fixture.storage);
      expect(pending.hasPendingLaunch, isTrue);
      expect(pending.readProject(), '项目七');
      expect(pending.readStage(), '施工');
      expect(pending.readSource(), EvidencePendingPickerSource.camera);

      await tester.runAsync(() async {
        pickerResult.complete(cameraImage.path);
        await Future<void>.delayed(Duration.zero);
        await fixture.storage.queue.add<void>(() async {});
      });
      await tester.pumpAndSettle();
      expect(pending.hasPendingLaunch, isFalse);
      expect(pending.readProject(), isNull);
      expect(pending.readStage(), isNull);
      final editor = tester.widget<EvidenceEditorSheet>(
        find.byType(EvidenceEditorSheet),
      );
      expect(editor.initialProject, '项目七');
      expect(editor.initialProjectStageName, '施工');
      expect(editor.sourcePath, cameraImage.path);

      await tester.ensureVisible(find.text('保存凭证'));
      await tester.tap(find.text('保存凭证'));
      await tester.pumpAndSettle();
      expect(repository.saved.single.projectName, '项目七');
      expect(repository.saved.single.projectStageName, '施工');
      expect(repository.sourcePaths, [cameraImage.path]);
    },
  );
}

final class _Repository implements EvidenceRepositoryPort {
  final saved = <EvidenceEntry>[];
  final sourcePaths = <String?>[];

  @override
  Future<List<EvidenceEntry>> getAllEntries() async => const [];

  @override
  Future<EvidenceEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> saveEntry(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  }) async {
    saved.add(entry);
    sourcePaths.add(sourcePath);
  }

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
