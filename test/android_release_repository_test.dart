import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android release repositories', () {
    test('resolve Flutter engine artifacts before Aliyun fallback mirrors', () {
      final source = File('android/settings.gradle.kts').readAsStringSync();

      final flutterStorage = source.indexOf(
        'https://storage.flutter-io.cn/download.flutter.io',
      );
      final aliyunPublic = source.indexOf(
        'https://maven.aliyun.com/repository/public',
      );

      expect(
        flutterStorage,
        isNonNegative,
        reason: 'Release builds need Flutter engine artifacts.',
      );
      expect(
        aliyunPublic,
        isNonNegative,
        reason: 'Aliyun can stay as a fallback mirror.',
      );
      expect(
        flutterStorage,
        lessThan(aliyunPublic),
        reason:
            'CI release builds should not hit Aliyun before Flutter storage.',
      );
    });
  });
}
