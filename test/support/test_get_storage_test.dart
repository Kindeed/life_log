import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  test(
    'storage uses real disk and closes files before directory deletion',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'storage_handles_',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => directory.path);
      final container = 'disk_${DateTime.now().microsecondsSinceEpoch}';
      final fixture = await TestGetStorage.open(container, directory);
      try {
        await fixture.storage.write('owner-a', {'epoch': 4, 'cursor': '21'});
        await fixture.storage.queue.add<void>(() async {});
        final data = jsonDecode(
          await File('${directory.path}/$container.gs').readAsString(),
        );
        expect(data, {
          'owner-a': {'epoch': 4, 'cursor': '21'},
        });
        final untouched = File('${directory.path}/unrelated.txt');
        await untouched.writeAsString('keep');
        expect(
          await FileSystemEntity.type(untouched.path, followLinks: false),
          FileSystemEntityType.file,
        );
        expect(
          FileSystemEntity.typeSync(directory.path, followLinks: false),
          FileSystemEntityType.directory,
        );
        await fixture.close();
        expect(await File('${directory.path}/$container.gs').exists(), isFalse);
        expect(
          await File('${directory.path}/$container.bak').exists(),
          isFalse,
        );
        expect(await untouched.readAsString(), 'keep');
        expect(IOOverrides.current, isNull);
        await directory.delete(recursive: true);
        expect(await directory.exists(), isFalse);
      } finally {
        await fixture.close();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );

  test('close waits for detached backups with a delayed path lookup', () async {
    final directory = await Directory.systemTemp.createTemp('storage_delayed_');
    final blocked = Completer<void>();
    final release = Completer<void>();
    var holdLookups = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          if (holdLookups) {
            if (!blocked.isCompleted) blocked.complete();
            await release.future;
          }
          return directory.path;
        });
    final container = 'delayed_${DateTime.now().microsecondsSinceEpoch}';
    final fixture = await TestGetStorage.open(container, directory);
    await fixture.storage.write('value', 42);
    await fixture.storage.queue.add<void>(() async {});
    holdLookups = true;
    await fixture.storage.write('value', 43);
    var isClosed = false;
    final closing = fixture.close().then((_) => isClosed = true);
    try {
      await blocked.future.timeout(const Duration(seconds: 5));
      expect(isClosed, isFalse);
      release.complete();
      await closing;
      expect(await File('${directory.path}/$container.gs').exists(), isFalse);
      expect(await File('${directory.path}/$container.bak').exists(), isFalse);
      expect(IOOverrides.current, isNull);
    } finally {
      if (!release.isCompleted) release.complete();
      await closing;
      await directory.delete(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  test(
    'initialization failure restores overrides and preserves the error',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'storage_failed_',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => throw PlatformException(code: 'fixture_lookup_failed'),
          );
      try {
        await expectLater(
          TestGetStorage.open(
            'failed_${DateTime.now().microsecondsSinceEpoch}',
            directory,
          ),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              'fixture_lookup_failed',
            ),
          ),
        );
        expect(IOOverrides.current, isNull);
        expect(await directory.list().toList(), isEmpty);
      } finally {
        await directory.delete(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );

  test(
    'native close failure restores overrides and keeps the real files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'storage_failed_close_',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => directory.path);
      final container = 'failed_close_${DateTime.now().microsecondsSinceEpoch}';
      final fixture = await TestGetStorage.open(container, directory);
      try {
        await fixture.storage.write('value', 42);
        await fixture.storage.queue.add<void>(() async {});
        // A genuinely closed native handle must remain a visible error if
        // cleanup tries to close it again; no fake filesystem is involved.
        final extraHandle = await File(
          '${directory.path}/$container.gs',
        ).open();
        await extraHandle.close();
        await expectLater(fixture.close(), throwsA(isA<FileSystemException>()));
        expect(IOOverrides.current, isNull);
        final file = File('${directory.path}/$container.gs');
        expect(await file.exists(), isTrue);
        expect(jsonDecode(await file.readAsString()), {'value': 42});
        await directory.delete(recursive: true);
      } finally {
        await fixture.close();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );

  test(
    'closing one active fixture preserves instrumentation for another',
    () async {
      final firstDirectory = await Directory.systemTemp.createTemp(
        'storage_active_',
      );
      final secondDirectory = await Directory.systemTemp.createTemp(
        'storage_active_',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => firstDirectory.path);
      final first = await TestGetStorage.open(
        'active_first_${DateTime.now().microsecondsSinceEpoch}',
        firstDirectory,
      );
      final second = await TestGetStorage.open(
        'active_second_${DateTime.now().microsecondsSinceEpoch}',
        secondDirectory,
      );
      try {
        await first.close();
        expect(IOOverrides.current, isNotNull);
        await second.storage.write('value', 42);
        await second.close();
        expect(IOOverrides.current, isNull);
        expect(await firstDirectory.list().toList(), isEmpty);
        expect(await secondDirectory.list().toList(), isEmpty);
      } finally {
        await first.close();
        await second.close();
        await firstDirectory.delete(recursive: true);
        await secondDirectory.delete(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );

  test(
    'repeated fixtures remove both native storage and detached backups',
    () async {
      for (var index = 0; index < 3; index++) {
        final directory = await Directory.systemTemp.createTemp(
          'storage_repeat_',
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (_) async => directory.path);
        final fixture = await TestGetStorage.open(
          'repeat_${DateTime.now().microsecondsSinceEpoch}',
          directory,
        );
        try {
          for (var value = 0; value < 20; value++) {
            await fixture.storage.write('value', value);
          }
          expect(fixture.storage.read<int>('value'), 19);
        } finally {
          await fixture.close();
          await directory.delete(recursive: true);
          expect(await directory.exists(), isFalse);
          expect(IOOverrides.current, isNull);
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        }
      }
    },
  );
}
