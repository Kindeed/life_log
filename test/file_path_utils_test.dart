import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/utils/file_path_utils.dart';

void main() {
  test('sanitizePathSegment replaces invalid filesystem characters', () {
    expect(sanitizePathSegment('  a<b>:c/d\\e|f?g*h  '), 'a_b__c_d_e_f_g_h');
  });

  test('sanitizePathSegment uses fallback for empty names', () {
    expect(sanitizePathSegment('   ', fallback: 'Default'), 'Default');
  });

  test('availablePath appends a suffix when the target exists', () async {
    final dir = await Directory.systemTemp.createTemp('lifelog_path_test_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    await File(
      '${dir.path}${Platform.pathSeparator}photo.jpg',
    ).writeAsString('existing');

    final path = await availablePath(dir.path, 'photo.jpg');
    expect(path, endsWith('${Platform.pathSeparator}photo_1.jpg'));
  });
}
