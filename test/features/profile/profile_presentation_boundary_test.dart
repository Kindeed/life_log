import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile presentation boundary', () {
    test('keeps profile surfaces under the feature presentation boundary', () {
      final featurePaths = [
        'lib/features/profile/presentation/profile_view.dart',
        'lib/features/profile/presentation/views/about_view.dart',
        'lib/features/profile/presentation/views/appearance_view.dart',
        'lib/features/profile/presentation/views/data_management_view.dart',
        'lib/features/profile/presentation/views/design_gallery_view.dart',
        'lib/features/profile/presentation/views/developer_view.dart',
        'lib/features/profile/presentation/views/login_view.dart',
      ];
      final legacyPaths = [
        'lib/common/bindings/login_binding.dart',
        'lib/features/profile/presentation/login_controller.dart',
        'lib/features/profile/presentation/profile_controller.dart',
        'lib/modules/profile/profile_controller.dart',
        'lib/modules/profile/login_controller.dart',
        'lib/modules/profile/profile_view.dart',
        'lib/modules/profile/views/about_view.dart',
        'lib/modules/profile/views/appearance_view.dart',
        'lib/modules/profile/views/data_management_view.dart',
        'lib/modules/profile/views/design_gallery_view.dart',
        'lib/modules/profile/views/developer_view.dart',
        'lib/modules/profile/views/login_view.dart',
      ];

      for (final path in featurePaths) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
      for (final path in legacyPaths) {
        expect(File(path).existsSync(), isFalse, reason: '$path is retired');
      }
    });

    test('retires ProfileController in favor of profile feature state', () {
      final view = File(
        'lib/features/profile/presentation/profile_view.dart',
      ).readAsStringSync();
      final binding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final di = File('lib/features/profile/profile_feature_di.dart');

      expect(di.existsSync(), isTrue);
      expect(appEntry, contains('configureProfileFeatureDependencies'));
      expect(binding, isNot(contains('configureProfileFeatureDependencies')));
      expect(binding, isNot(contains('ProfileController')));
      expect(binding, isNot(contains('profile_controller.dart')));
      expect(view, contains('ProfileAccountCubit'));
      expect(view, contains('SyncProfileData'));
      expect(view, contains('SignOutProfileAccount'));
      expect(view, isNot(contains('Get.find<ProfileController>')));
      expect(view, isNot(contains('ProfileController.to')));
      expect(view, isNot(contains('controller.syncData')));
      expect(view, isNot(contains('controller.logout')));
    });

    test('retires LoginController in favor of profile auth commands', () {
      final loginView = File(
        'lib/features/profile/presentation/views/login_view.dart',
      ).readAsStringSync();
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final di = File(
        'lib/features/profile/profile_feature_di.dart',
      ).readAsStringSync();

      expect(appEntry, isNot(contains('LoginBinding')));
      expect(appEntry, isNot(contains('login_binding.dart')));
      expect(loginView, contains('LoginCubit'));
      expect(loginView, isNot(contains('Get.find<LoginController>')));
      expect(loginView, isNot(contains('login_controller.dart')));
      expect(di, contains('LoginCubit'));
      expect(di, contains('SignInProfileAccount'));
      expect(di, contains('SignUpProfileAccount'));
    });

    test('profile main page uses local navigation and feedback lifecycles', () {
      final view = File(
        'lib/features/profile/presentation/profile_view.dart',
      ).readAsStringSync();
      final binding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();

      expect(view, isNot(contains('Get.to(')));
      expect(view, isNot(contains('Get.toNamed')));
      expect(view, isNot(contains('Get.offAllNamed')));
      expect(view, isNot(contains('Get.snackbar')));
      expect(view, isNot(contains('Get.find<StatisticsController>')));
      expect(view, isNot(contains('AppConfirmDialog')));
      expect(view, contains('serviceLocator<StatisticsController>()'));
      expect(
        binding,
        contains('serviceLocator.registerLazySingleton<StatisticsController>'),
      );
      expect(view, contains('Navigator.of('));
      expect(view, contains('MaterialPageRoute'));
      expect(view, contains('context.go(AppRoutes.login)'));
      expect(view, contains('ScaffoldMessenger.of(context)'));
    });

    test('login page uses GoRouter and local feedback lifecycles', () {
      final view = File(
        'lib/features/profile/presentation/views/login_view.dart',
      ).readAsStringSync();

      expect(view, isNot(contains("package:get/get.dart")));
      expect(view, isNot(contains('Get.back')));
      expect(view, isNot(contains('Get.snackbar')));
      expect(view, contains('context.go(AppRoutes.root)'));
      expect(view, contains('ScaffoldMessenger.of(context)'));
    });

    test('about page describes the current runtime stack', () {
      final view = File(
        'lib/features/profile/presentation/views/about_view.dart',
      ).readAsStringSync();

      expect(view, contains('Flutter + GoRouter'));
      expect(view, isNot(contains('Flutter + GetX')));
    });

    test('data management page uses local dialog and feedback lifecycles', () {
      final view = File(
        'lib/features/profile/presentation/views/data_management_view.dart',
      ).readAsStringSync();

      expect(view, isNot(contains("package:get/get.dart")));
      expect(view, isNot(contains('Get.snackbar')));
      expect(view, isNot(contains('Get.back')));
      expect(view, isNot(contains('Get.offAllNamed')));
      expect(view, isNot(contains('AppConfirmDialog')));
      expect(view, contains('showDialog<bool>'));
      expect(view, contains('showDialog<void>'));
      expect(view, contains('Navigator.of('));
      expect(view, contains('context.go(AppRoutes.root)'));
      expect(view, contains('ScaffoldMessenger.of(context)'));
    });

    test('appearance page uses injected theme controller access', () {
      final view = File(
        'lib/features/profile/presentation/views/appearance_view.dart',
      ).readAsStringSync();
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final themeController = File(
        'lib/common/theme/theme_controller.dart',
      ).readAsStringSync();
      final combined = '$view\n$themeController';

      expect(view, isNot(contains('Get.find<ThemeController>')));
      expect(combined, isNot(contains("package:get/get.dart")));
      expect(combined, isNot(contains('GetxController')));
      expect(combined, isNot(contains('Obx(')));
      expect(combined, isNot(contains('.obs')));
      expect(combined, isNot(contains('Get.changeThemeMode')));
      expect(themeController, contains('extends ChangeNotifier'));
      expect(view, contains('serviceLocator<ThemeController>()'));
      expect(view, contains('AnimatedBuilder'));
      expect(appEntry, isNot(contains('Get.put(ThemeController')));
      expect(appEntry, isNot(contains('GetBuilder<ThemeController>')));
      expect(appEntry, contains('AnimatedBuilder'));
      expect(
        appEntry,
        contains('serviceLocator.registerSingleton<ThemeController>'),
      );
    });

    test(
      'developer page uses local route, dialog, feedback, and DI lifecycles',
      () {
        final view = File(
          'lib/features/profile/presentation/views/developer_view.dart',
        ).readAsStringSync();
        final appEntry = File(
          'lib/app/lifelog_mobile_entry.dart',
        ).readAsStringSync();
        final logService = File(
          'lib/common/services/log_service.dart',
        ).readAsStringSync();
        final cloudConfig = File(
          'lib/common/services/cloud_config_service.dart',
        ).readAsStringSync();
        final commonServiceState = '$logService\n$cloudConfig';

        expect(view, isNot(contains("package:get/get.dart")));
        expect(view, isNot(contains('Get.find<LogService>')));
        expect(view, isNot(contains('Get.find<CloudConfigService>')));
        expect(view, isNot(contains('Obx(')));
        expect(view, isNot(contains('.value')));
        expect(view, isNot(contains('Get.to(')));
        expect(view, isNot(contains('Get.snackbar')));
        expect(view, isNot(contains('AppConfirmDialog')));
        expect(view, contains('serviceLocator<LogService>()'));
        expect(view, contains('serviceLocator<CloudConfigService>()'));
        expect(view, contains('AnimatedBuilder'));
        expect(commonServiceState, isNot(contains("package:get/get.dart")));
        expect(commonServiceState, isNot(contains('GetxService')));
        expect(commonServiceState, isNot(contains('.obs')));
        expect(commonServiceState, contains('extends ChangeNotifier'));
        expect(logService, contains('setDebugEnabled'));
        expect(cloudConfig, contains('bool isConfigured'));
        expect(view, contains('Navigator.of(context).push'));
        expect(view, contains('MaterialPageRoute'));
        expect(view, contains('showDialog<bool>'));
        expect(view, contains('ScaffoldMessenger.of(context)'));
        expect(
          appEntry,
          contains('serviceLocator.registerSingleton<CloudConfigService>'),
        );
        expect(
          appEntry,
          contains('serviceLocator.registerSingleton<LogService>'),
        );
      },
    );

    test(
      'blocks production imports from returning to the module profile path',
      () {
        final sources = [
          'lib/app/lifelog_mobile_entry.dart',
          'lib/common/bindings/tabs_binding.dart',
          'lib/features/profile/presentation/profile_view.dart',
          'lib/features/profile/presentation/views/login_view.dart',
          'lib/features/shell/presentation/tabs_view.dart',
        ];

        for (final path in sources) {
          final source = File(path).readAsStringSync();
          expect(source, isNot(contains('package:life_log/modules/profile/')));
          expect(source, isNot(contains('../../modules/profile/')));
          expect(source, isNot(contains('../profile/profile_view.dart')));
        }
      },
    );
  });
}
