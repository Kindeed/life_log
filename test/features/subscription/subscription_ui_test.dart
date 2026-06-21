import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subscription edit UI ownership', () {
    test('owns the page presentation from the feature folder', () {
      final featureView = File(
        'lib/features/subscription/presentation/subscription_view.dart',
      );
      final legacyView = File(
        'lib/modules/subscription/subscription_view.dart',
      );
      final tabsView = File(
        'lib/features/shell/presentation/tabs_view.dart',
      ).readAsStringSync();

      expect(featureView.existsSync(), isTrue);
      expect(legacyView.existsSync(), isFalse);
      expect(
        tabsView,
        contains(
          'package:life_log/features/subscription/presentation/subscription_view.dart',
        ),
      );
      expect(
        tabsView,
        isNot(contains('../subscription/subscription_view.dart')),
      );
    });

    test('owns the edit surface from the feature folder', () {
      final featureSheet = File(
        'lib/features/subscription/presentation/add_subscription_sheet.dart',
      );
      final featureEditView = File(
        'lib/features/subscription/presentation/subscription_edit_view.dart',
      );
      final legacySheet = File(
        'lib/modules/subscription/add_subscription_sheet.dart',
      );
      final legacyEditView = File(
        'lib/modules/subscription/views/subscription_edit_view.dart',
      );
      final editorLauncher = File(
        'lib/features/subscription/presentation/subscription_editor_launcher.dart',
      ).readAsStringSync();
      final todayView = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();

      expect(featureSheet.existsSync(), isTrue);
      expect(featureEditView.existsSync(), isTrue);
      expect(legacySheet.existsSync(), isFalse);
      expect(legacyEditView.existsSync(), isFalse);
      expect(editorLauncher, contains('subscription_edit_view.dart'));
      expect(
        editorLauncher,
        isNot(
          contains('modules/subscription/views/subscription_edit_view.dart'),
        ),
      );
      expect(todayView, contains('openSubscriptionEditorPage'));
      expect(todayView, isNot(contains('SubscriptionEditView')));
      expect(
        todayView,
        isNot(
          contains('modules/subscription/views/subscription_edit_view.dart'),
        ),
      );
    });

    test('uses local Flutter modal and snackbar lifecycles', () {
      final source = File(
        'lib/features/subscription/presentation/add_subscription_sheet.dart',
      ).readAsStringSync();

      expect(source, contains('showModalBottomSheet'));
      expect(source, contains('ScaffoldMessenger'));
      expect(source, contains('Navigator.of('));
      expect(source, isNot(contains('Get.bottomSheet')));
      expect(source, isNot(contains('Get.back')));
      expect(source, isNot(contains('Get.snackbar')));
    });

    test('keeps write failure feedback in local presentation paths', () {
      final controller = File(
        'lib/modules/subscription/subscription_controller.dart',
      );
      final view = File(
        'lib/features/subscription/presentation/subscription_view.dart',
      ).readAsStringSync();
      final sheet = File(
        'lib/features/subscription/presentation/add_subscription_sheet.dart',
      ).readAsStringSync();

      expect(controller.existsSync(), isFalse);
      expect(view, contains('ScaffoldMessenger'));
      expect(view, contains('_showSubscriptionMessage'));
      expect(sheet, contains('ScaffoldMessenger'));
      expect(sheet, contains('_showMessage'));
    });

    test(
      'submits edits through feature save command without sync metadata',
      () {
        final sheet = File(
          'lib/features/subscription/presentation/add_subscription_sheet.dart',
        ).readAsStringSync();
        final editView = File(
          'lib/features/subscription/presentation/subscription_edit_view.dart',
        ).readAsStringSync();

        expect(sheet, contains('SaveSubscriptionEntry'));
        expect(sheet, contains('serviceLocator<SaveSubscriptionEntry>'));
        expect(sheet, isNot(contains('SubscriptionController.to.addSub')));
        expect(sheet, isNot(contains('remoteId')));
        expect(sheet, isNot(contains('syncId')));
        expect(sheet, isNot(contains('remoteVersion')));
        expect(sheet, isNot(contains('remoteUpdatedAt')));
        expect(sheet, isNot(contains('syncedAt')));
        expect(sheet, isNot(contains('deletedAt')));
        expect(sheet, isNot(contains('pendingDelete')));
        expect(editView, isNot(contains('subscription_model.dart')));
      },
    );

    test('keeps presentation surfaces on domain entries', () {
      final presentationSource =
          Directory('lib/features/subscription/presentation')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))
              .map((file) => file.readAsStringSync())
              .join('\n');
      final editorLauncher = File(
        'lib/features/subscription/presentation/subscription_editor_launcher.dart',
      ).readAsStringSync();

      expect(presentationSource, isNot(contains('subscription_model.dart')));
      expect(
        presentationSource,
        isNot(contains('features/subscription/data/subscription_model.dart')),
      );
      expect(editorLauncher, isNot(contains('Subscription? sub')));
      expect(editorLauncher, isNot(contains('toSubscriptionEntry')));
    });

    test('reads page display state from the feature cubit', () {
      final view = File(
        'lib/features/subscription/presentation/subscription_view.dart',
      ).readAsStringSync();
      final di = File(
        'lib/features/subscription/subscription_feature_di.dart',
      ).readAsStringSync();

      expect(view, contains('BlocProvider<SubscriptionCubit>'));
      expect(
        view,
        contains('BlocBuilder<SubscriptionCubit, SubscriptionState>'),
      );
      expect(view, contains('state.visibleEntries'));
      expect(view, contains('state.currentMonthCost'));
      expect(view, contains('state.yearlyCost'));
      expect(view, contains('state.filter'));
      expect(view, contains('state.sortMode'));
      expect(view, isNot(contains('Obx')));
      expect(view, isNot(contains('logic.visibleSubs')));
      expect(view, isNot(contains('logic.currentMonthCost')));
      expect(view, isNot(contains('logic.yearlyCost')));
      expect(view, isNot(contains('logic.dueSoonCount')));
      expect(view, isNot(contains('logic.filter.value')));
      expect(view, isNot(contains('logic.sortMode.value')));
      expect(di, contains('registerFactory<SubscriptionCubit>'));
    });

    test('moves editor routing and delete confirmation behind local helpers', () {
      final view = File(
        'lib/features/subscription/presentation/subscription_view.dart',
      ).readAsStringSync();
      final editorLauncher = File(
        'lib/features/subscription/presentation/subscription_editor_launcher.dart',
      ).readAsStringSync();
      final dialogs = File(
        'lib/features/subscription/presentation/subscription_dialogs.dart',
      ).readAsStringSync();

      expect(view, contains('openSubscriptionEditorPage'));
      expect(view, contains('confirmSubscriptionDelete'));
      expect(view, isNot(contains('Get.to')));
      expect(view, isNot(contains('SubscriptionEditView')));
      expect(view, isNot(contains('AppConfirmDialog')));
      expect(editorLauncher, contains('Navigator.of(context).push'));
      expect(editorLauncher, isNot(contains('Get.to')));
      expect(dialogs, contains('showDialog<bool>'));
      expect(dialogs, isNot(contains('AppConfirmDialog')));
      expect(dialogs, isNot(contains('Get.dialog')));
      expect(dialogs, isNot(contains('Get.back')));
    });

    test('routes page delete and reorder through feature commands', () {
      final view = File(
        'lib/features/subscription/presentation/subscription_view.dart',
      ).readAsStringSync();
      final di = File(
        'lib/features/subscription/subscription_feature_di.dart',
      ).readAsStringSync();

      expect(view, contains('DeleteSubscriptionEntry'));
      expect(view, contains('ReorderSubscriptionEntries'));
      expect(view, contains('serviceLocator<DeleteSubscriptionEntry>'));
      expect(view, contains('serviceLocator<ReorderSubscriptionEntries>'));
      expect(view, isNot(contains('legacy.SubscriptionController')));
      expect(
        view,
        isNot(contains('modules/subscription/subscription_controller.dart')),
      );
      expect(view, isNot(contains('Get.find<')));
      expect(view, isNot(contains('deleteSub(')));
      expect(view, isNot(contains('reorderSub(')));
      expect(di, contains('registerLazySingleton<DeleteSubscriptionEntry>'));
      expect(di, contains('registerLazySingleton<ReorderSubscriptionEntries>'));
    });

    test('retires the legacy SubscriptionController runtime path', () {
      final controller = File(
        'lib/modules/subscription/subscription_controller.dart',
      );
      final tabsBinding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      final backupService = File(
        'lib/common/db/backup_service.dart',
      ).readAsStringSync();

      expect(controller.existsSync(), isFalse);
      expect(tabsBinding, isNot(contains('SubscriptionController')));
      expect(tabsBinding, isNot(contains('subscription_controller.dart')));
      expect(backupService, isNot(contains('SubscriptionController')));
      expect(backupService, isNot(contains('subscription_controller.dart')));
    });
  });
}
