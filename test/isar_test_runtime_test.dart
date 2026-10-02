import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/isar_test_runtime.dart';

void main() {
  test(
    'Flutter tester resolves the native core from the locked package',
    () async {
      final path = await locateTestIsarLibrary(environment: {});

      expect(File(path).existsSync(), isTrue);
      expect(File(path).isAbsolute, isTrue);
    },
  );

  test(
    'an invalid explicit core fails without falling back to another core',
    () async {
      final temp = await Directory.systemTemp.createTemp('isar_core_override_');
      addTearDown(() => temp.delete(recursive: true));
      final packagedCore = File('${temp.path}/linux/libisar.so');
      await packagedCore.parent.create(recursive: true);
      await packagedCore.writeAsBytes([]);

      await expectLater(
        locateTestIsarLibrary(
          environment: {'ISAR_LIBRARY_PATH': '${temp.path}/missing/libisar.so'},
          packageLibraryUri: Uri.file(
            '${temp.path}/lib/isar_flutter_libs.dart',
          ),
          abi: Abi.linuxX64,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('ISAR_LIBRARY_PATH points to a missing Isar core'),
          ),
        ),
      );
    },
  );

  test(
    'an absent locked native core cannot silently skip database tests',
    () async {
      final temp = await Directory.systemTemp.createTemp('isar_core_missing_');
      addTearDown(() => temp.delete(recursive: true));

      await expectLater(
        locateTestIsarLibrary(
          environment: {},
          packageLibraryUri: Uri.file(
            '${temp.path}/lib/isar_flutter_libs.dart',
          ),
          abi: Abi.linuxX64,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Database tests are required'),
          ),
        ),
      );
    },
  );
}
