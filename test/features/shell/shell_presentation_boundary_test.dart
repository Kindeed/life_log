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

    test('exposes Work, Project, and More destinations', () {
      final view = File(
        'lib/features/shell/presentation/tabs_view.dart',
      ).readAsStringSync();
      final controller = File(
        'lib/features/shell/presentation/tabs_controller.dart',
      ).readAsStringSync();

      expect(
        TabsDestination.values.map((destination) => destination.name).toList(),
        ['work', 'project', 'more'],
      );
      expect(
        view,
        contains(
          'package:life_log/features/work_log/presentation/work_log_view.dart',
        ),
      );
      expect(
        view,
        contains(
          'package:life_log/features/photo/presentation/photo_view.dart',
        ),
      );
      expect(
        view,
        contains('package:life_log/features/more/presentation/more_view.dart'),
      );
      expect(view, contains('_KeepAliveTabPage(child: WorkLogView())'));
      expect(view, contains('_KeepAliveTabPage(child: PhotoView())'));
      expect(view, contains('_KeepAliveTabPage(child: MoreView())'));
      expect(view, contains("label: '工时'"));
      expect(view, contains("label: '项目'"));
      expect(view, contains("label: '更多'"));
      expect(view, isNot(contains("label: '今天'")));
      expect(view, isNot(contains("label: '记录'")));
      expect(view, isNot(contains("label: '财务'")));
      expect(view, isNot(contains('_KeepAliveTabPage(child: TodayView())')));
      expect(view, isNot(contains('_KeepAliveTabPage(child: TimelineView())')));
      expect(controller, isNot(contains('finance')));
      expect(controller, isNot(contains('records')));
      expect(controller, isNot(contains('today')));
    });

    test(
      'uses More tab as the primary profile and settings entry without project shortcut',
      () {
        final action = File(
          'lib/features/shell/presentation/profile_action_button.dart',
        );
        final photoView = File(
          'lib/features/photo/presentation/photo_view.dart',
        ).readAsStringSync();
        final tabsView = File(
          'lib/features/shell/presentation/tabs_view.dart',
        ).readAsStringSync();

        expect(action.existsSync(), isTrue);
        final actionSource = action.readAsStringSync();
        expect(actionSource, contains('class ProfileActionButton'));
        expect(actionSource, contains('ProfileView'));
        expect(actionSource, contains('Navigator.of(context).push'));
        expect(tabsView, contains('_KeepAliveTabPage(child: MoreView())'));
        expect(photoView, isNot(contains('ProfileActionButton')));
      },
    );

    test('TabsController switches between work, project, and more', () {
      final controller = TabsController();
      expect(controller.currentIndex, 0);

      controller.goToProject();
      expect(controller.currentIndex, 1);

      controller.goToMore();
      expect(controller.currentIndex, 2);

      controller.goToWork();
      expect(controller.currentIndex, 0);

      controller.goTo(TabsDestination.subscription);
      expect(controller.currentIndex, 2);

      controller.goTo(TabsDestination.settings);
      expect(controller.currentIndex, 2);

      controller.changePage(99);
      expect(controller.currentIndex, 2);

      controller.changePage(-10);
      expect(controller.currentIndex, 0);
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
      final profileView = File(
        'lib/features/profile/presentation/profile_view.dart',
      ).readAsStringSync();
      final moreView = File(
        'lib/features/more/presentation/more_view.dart',
      ).readAsStringSync();
      final combined =
          '$controller\n$view\n$todayView\n$profileView\n$moreView';

      expect(combined, isNot(contains("package:get/get.dart")));
      expect(combined, isNot(contains('Get.find')));
      expect(combined, isNot(contains('Obx(')));
      expect(combined, isNot(contains('.obs')));
      expect(combined, isNot(contains('TabsController.to')));
      expect(controller, contains('extends ChangeNotifier'));
      expect(view, contains('AnimatedBuilder'));
      expect(view, contains('TabsScope('));
    });

    test(
      'MoreView aggregates personal, finance, tools, and settings entries',
      () {
        final diFile = File('lib/features/more/more_feature_di.dart');
        final moreViewFile = File(
          'lib/features/more/presentation/more_view.dart',
        );

        expect(diFile.existsSync(), isTrue);
        expect(moreViewFile.existsSync(), isTrue);

        final diSource = diFile.readAsStringSync();
        final moreSource = moreViewFile.readAsStringSync();

        expect(diSource, contains('configureMoreFeatureDependencies'));

        expect(moreSource, contains('class MoreView'));
        expect(moreSource, contains('个人与账户'));
        expect(moreSource, contains('生活与记账'));
        expect(moreSource, contains('工具箱'));
        expect(moreSource, contains('应用设置'));

        expect(moreSource, contains('ProfileView'));
        expect(moreSource, isNot(contains('SyncCenterView')));
        expect(moreSource, contains('SubscriptionView'));
        expect(moreSource, contains('TimelineView'));
        expect(moreSource, contains('StatisticsView'));
        expect(moreSource, contains('TelemetryCalcView'));
        expect(moreSource, contains('AppearanceView'));
        expect(moreSource, contains('DataManagementView'));
        expect(moreSource, contains('AboutView'));

        expect(moreSource, isNot(contains("package:get/get.dart")));
        expect(moreSource, isNot(contains('Get.')));
      },
    );
  });
}
