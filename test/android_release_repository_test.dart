import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android keeps only the configured application activity', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(gradle, contains('namespace = "com.wzh.lifelog"'));
    expect(manifest, contains('android:name=".MainActivity"'));
    expect(
      File(
        'android/app/src/main/kotlin/com/wzh/lifelog/MainActivity.kt',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'android/app/src/main/kotlin/com/example/life_log/MainActivity.kt',
      ).existsSync(),
      isFalse,
    );
  });

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

    test('release builds fail instead of falling back to debug signing', () {
      final source = File('android/app/build.gradle.kts').readAsStringSync();

      expect(
        source,
        contains('Release signing config missing'),
        reason:
            'Release builds must fail when the production keystore is absent.',
      );
      expect(
        source,
        contains('gradle.taskGraph.whenReady'),
        reason:
            'The failure should be scoped to release tasks so debug builds still work.',
      );
      expect(
        source,
        isNot(contains('signingConfigs.getByName("debug")')),
        reason: 'Release builds must never silently use the debug key.',
      );
    });
  });
}
