import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Photo presentation boundary', () {
    test('keeps views under the feature presentation boundary', () {
      final featurePaths = [
        'lib/features/photo/presentation/photo_view.dart',
        'lib/features/photo/presentation/project_gallery_view.dart',
        'lib/features/photo/presentation/photo_preview_view.dart',
        'lib/features/photo/presentation/gallery_import_view.dart',
        'lib/features/photo/presentation/capture_dialog.dart',
        'lib/features/photo/presentation/project_picker.dart',
        'lib/features/photo/presentation/create_project_sheet.dart',
        'lib/features/photo/presentation/photo_local_ui.dart',
        'lib/features/photo/presentation/photo_add_action_launcher.dart',
      ];
      final legacyPaths = [
        'lib/features/photo/presentation/photo_controller.dart',
        'lib/modules/photo/photo_controller.dart',
        'lib/modules/photo/views/photo_view.dart',
        'lib/modules/photo/views/project_gallery_view.dart',
        'lib/modules/photo/views/photo_preview_view.dart',
        'lib/modules/photo/views/gallery_import_view.dart',
        'lib/modules/photo/views/capture_dialog.dart',
        'lib/modules/photo/views/project_picker.dart',
        'lib/modules/photo/views/create_project_sheet.dart',
      ];

      for (final path in featurePaths) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
      for (final path in legacyPaths) {
        expect(File(path).existsSync(), isFalse, reason: '$path is retired');
      }
    });

    test(
      'blocks production imports from returning to the module photo path',
      () {
        final sources = [
          'lib/common/bindings/tabs_binding.dart',
          'lib/common/db/backup_service.dart',
          'lib/features/photo/presentation/capture_dialog.dart',
          'lib/features/photo/presentation/photo_add_action_launcher.dart',
          'lib/features/photo/presentation/photo_preview_view.dart',
          'lib/features/photo/presentation/photo_view.dart',
          'lib/features/photo/presentation/project_gallery_view.dart',
          'lib/features/shell/presentation/tabs_view.dart',
        ];

        for (final path in sources) {
          final source = File(path).readAsStringSync();
          expect(source, isNot(contains('package:life_log/modules/photo/')));
          expect(source, isNot(contains('../photo/views/photo_view.dart')));
          expect(source, isNot(contains('../../modules/photo/')));
        }
      },
    );

    test(
      'uses local presentation lifecycles for routes, sheets, and feedback',
      () {
        final presentationSources = [
          'lib/features/photo/presentation/photo_view.dart',
          'lib/features/photo/presentation/project_gallery_view.dart',
          'lib/features/photo/presentation/photo_preview_view.dart',
          'lib/features/photo/presentation/gallery_import_view.dart',
          'lib/features/photo/presentation/capture_dialog.dart',
          'lib/features/photo/presentation/project_picker.dart',
          'lib/features/photo/presentation/create_project_sheet.dart',
          'lib/features/photo/presentation/photo_local_ui.dart',
          'lib/features/photo/presentation/photo_add_action_launcher.dart',
        ].map((path) => File(path).readAsStringSync()).join('\n');

        expect(presentationSources, isNot(contains("package:get/get.dart")));
        expect(presentationSources, isNot(contains('Get.')));
        expect(presentationSources, isNot(contains('AppConfirmDialog')));
        expect(presentationSources, isNot(contains('AppActionSheet.show')));
        expect(presentationSources, contains('Navigator.of('));
        expect(presentationSources, contains('showModalBottomSheet'));
        expect(presentationSources, contains('ScaffoldMessenger.of(context)'));
      },
    );
  });
}
