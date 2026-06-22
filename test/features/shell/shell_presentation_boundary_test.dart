import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/shell/presentation/tabs_controller.dart';

void main() {
  group('Shell presentation boundary', () {
    test('keeps tabs shell under the feature presentation boundary', () {
      final featurePaths = [
        'lib/features/shell/presentation/tabs_controller.dart',
        'lib/features/shell/presentation/tabs_view.dart',
      ];
      final legacyPaths = [
        'lib/modules/tabs/tabs_controller.dart',
        'lib/modules/tabs/tabs_view.dart',
      ];

      for (final path in featurePaths) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
      for (final path in legacyPaths) {
        expect(File(path).existsSync(), isFalse, reason: '$path is retired');
      }
    });

    test('blocks production imports from returning to module tabs', () {
      final sources = [
        'lib/app/lifelog_mobile_entry.dart',
        'lib/common/bindings/tabs_binding.dart',
        'lib/common/db/backup_service.dart',
        'lib/features/today/presentation/today_view.dart',
      ];

      for (final path in sources) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('package:life_log/modules/tabs/')));
        expect(source, isNot(contains('../../modules/tabs/')));
        expect(source, isNot(contains('../tabs/')));
      }
    });

    test(
      'routes app shell entry and runtime binding through feature paths',
      () {
        final appEntry = File(
          'lib/app/lifelog_mobile_entry.dart',
        ).readAsStringSync();
        final binding = File(
          'lib/common/bindings/tabs_binding.dart',
        ).readAsStringSync();
        final backupService = File(
          'lib/common/db/backup_service.dart',
        ).readAsStringSync();

        expect(
          appEntry,
          contains(
            'package:life_log/features/shell/presentation/tabs_view.dart',
          ),
        );
        expect(
          binding,
          contains(
            'package:life_log/features/shell/presentation/tabs_controller.dart',
          ),
        );
        expect(
          binding,
          contains('serviceLocator.registerLazySingleton<TabsController>'),
        );
        expect(backupService, isNot(contains('TabsController')));
      },
    );

    test('exposes only Today, Records, and Project as primary destinations', () {
      final view = File(
        'lib/features/shell/presentation/tabs_view.dart',
      ).readAsStringSync();
      final controller = File(
        'lib/features/shell/presentation/tabs_controller.dart',
      ).readAsStringSync();

      expect(
        TabsDestination.values.map((destination) => destination.name).toList(),
        ['today', 'records', 'project'],
      );
      expect(
        view,
        contains(
          'package:life_log/features/today/presentation/today_view.dart',
        ),
      );
      expect(
        view,
        contains(
          'package:life_log/features/timeline/presentation/timeline_view.dart',
        ),
      );
      expect(view, contains('_KeepAliveTabPage(child: TodayView())'));
      expect(view, contains('_KeepAliveTabPage(child: TimelineView())'));
      expect(view, contains('_KeepAliveTabPage(child: PhotoView())'));
      expect(view, contains("label: '今天'"));
      expect(view, contains("label: '记录'"));
      expect(view, contains("label: '项目'"));
      expect(view, isNot(contains("label: '我的'")));
      expect(view, isNot(contains("label: '财务'")));
      expect(view, isNot(contains('_KeepAliveTabPage(child: WorkLogView())')));
      expect(
        view,
        isNot(contains('_KeepAliveTabPage(child: SubscriptionView())')),
      );
      expect(view, isNot(contains('_KeepAliveTabPage(child: ProfileView())')));
      expect(controller, isNot(contains('finance')));
      expect(controller, isNot(contains('profile')));
    });

    test('moves Profile to a secondary app-bar action', () {
      final action = File(
        'lib/features/shell/presentation/profile_action_button.dart',
      );
      final todayView = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();
      final photoView = File(
        'lib/features/photo/presentation/photo_view.dart',
      ).readAsStringSync();

      expect(action.existsSync(), isTrue);
      final actionSource = action.readAsStringSync();
      expect(actionSource, contains('class ProfileActionButton'));
      expect(actionSource, contains('ProfileView'));
      expect(actionSource, contains('Navigator.of(context).push'));
      expect(todayView, contains('ProfileActionButton'));
      expect(photoView, contains('ProfileActionButton'));
    });

    test('owns tab state without GetX presentation state coupling', () {
      final controller = File(
        'lib/features/shell/presentation/tabs_controller.dart',
      ).readAsStringSync();
      final view = File(
        'lib/features/shell/presentation/tabs_view.dart',
      ).readAsStringSync();
      final todayView = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();
      final combined = '$controller\n$view\n$todayView';

      expect(combined, isNot(contains("package:get/get.dart")));
      expect(combined, isNot(contains('Get.find')));
      expect(combined, isNot(contains('Obx(')));
      expect(combined, isNot(contains('.obs')));
      expect(combined, isNot(contains('TabsController.to')));
      expect(controller, contains('extends ChangeNotifier'));
      expect(view, contains('AnimatedBuilder'));
      expect(todayView, contains('TabsScope.of(context).goTo'));
    });
  });
}
