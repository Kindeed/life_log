import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Statistics presentation boundary', () {
    test(
      'keeps statistics surface under the feature presentation boundary',
      () {
        final featurePaths = [
          'lib/features/statistics/presentation/statistics_controller.dart',
          'lib/features/statistics/presentation/statistics_view.dart',
        ];
        final legacyPaths = [
          'lib/modules/statistics/statistics_controller.dart',
          'lib/modules/statistics/statistics_view.dart',
        ];

        for (final path in featurePaths) {
          expect(File(path).existsSync(), isTrue, reason: '$path should exist');
        }
        for (final path in legacyPaths) {
          expect(File(path).existsSync(), isFalse, reason: '$path is retired');
        }
      },
    );

    test('keeps runtime entry points on the feature statistics path', () {
      final sources = [
        'lib/common/bindings/tabs_binding.dart',
        'lib/common/db/backup_service.dart',
        'lib/features/profile/presentation/profile_view.dart',
      ];

      for (final path in sources) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('package:life_log/modules/statistics/')));
        expect(source, isNot(contains('../../modules/statistics/')));
      }

      final profileView = File(
        'lib/features/profile/presentation/profile_view.dart',
      ).readAsStringSync();
      expect(
        profileView,
        contains(
          'package:life_log/features/statistics/presentation/statistics_view.dart',
        ),
      );
      expect(
        profileView,
        contains(
          'package:life_log/features/statistics/presentation/statistics_controller.dart',
        ),
      );
    });

    test('owns statistics presentation state without GetX coupling', () {
      final controller = File(
        'lib/features/statistics/presentation/statistics_controller.dart',
      ).readAsStringSync();
      final view = File(
        'lib/features/statistics/presentation/statistics_view.dart',
      ).readAsStringSync();
      final combined = '$controller\n$view';

      expect(combined, isNot(contains("package:get/get.dart")));
      expect(combined, isNot(contains('Get.find')));
      expect(combined, isNot(contains('GetxController')));
      expect(combined, isNot(contains('Obx(')));
      expect(combined, isNot(contains('.obs')));
      expect(controller, contains('extends ChangeNotifier'));
      expect(view, contains('serviceLocator<StatisticsController>()'));
      expect(view, contains('AnimatedBuilder'));
    });
  });
}
