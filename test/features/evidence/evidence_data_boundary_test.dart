import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Evidence data boundary', () {
    test('keeps Isar model and repository under the feature data boundary', () {
      final featureModel = File(
        'lib/features/evidence/data/evidence_model.dart',
      );
      final featureGenerated = File(
        'lib/features/evidence/data/evidence_model.g.dart',
      );
      final featureRepository = File(
        'lib/features/evidence/data/evidence_repository.dart',
      );
      final featureFileUtils = File(
        'lib/features/evidence/data/evidence_file_utils.dart',
      );
      final featureParseService = File(
        'lib/features/evidence/data/evidence_parse_service.dart',
      );
      final legacyPaths = [
        'lib/modules/evidence/evidence_model.dart',
        'lib/modules/evidence/evidence_model.g.dart',
        'lib/modules/evidence/evidence_repository.dart',
        'lib/modules/evidence/evidence_file_utils.dart',
        'lib/modules/evidence/evidence_parse_service.dart',
      ];

      expect(featureModel.existsSync(), isTrue);
      expect(featureGenerated.existsSync(), isTrue);
      expect(featureRepository.existsSync(), isTrue);
      expect(featureFileUtils.existsSync(), isTrue);
      expect(featureParseService.existsSync(), isTrue);
      for (final path in legacyPaths) {
        expect(File(path).existsSync(), isFalse);
      }

      expect(
        featureModel.readAsStringSync(),
        contains("part 'evidence_model.g.dart';"),
      );
      expect(
        featureGenerated.readAsStringSync(),
        contains("part of 'evidence_model.dart';"),
      );
      expect(
        featureRepository.readAsStringSync(),
        contains('class EvidenceRepository'),
      );
    });

    test('blocks production imports from returning to the legacy data path', () {
      final sources = [
        'lib/common/bindings/tabs_binding.dart',
        'lib/common/db/db_service.dart',
        'lib/common/services/sync_service.dart',
        'lib/common/utils/record_validators.dart',
        'lib/features/evidence/evidence_feature_di.dart',
        'lib/features/evidence/data/evidence_file_store.dart',
        'lib/features/evidence/data/evidence_parse_service.dart',
        'lib/features/evidence/data/evidence_local_data_source.dart',
        'lib/features/evidence/data/evidence_sync_gateway.dart',
        'lib/features/evidence/data/legacy_evidence_repository_adapter.dart',
        'lib/features/evidence/presentation/evidence_attachment_preview.dart',
        'lib/features/evidence/presentation/evidence_detail_file_actions.dart',
        'lib/features/evidence/presentation/evidence_detail_launcher.dart',
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
        'lib/features/evidence/presentation/evidence_editor_launcher.dart',
        'lib/features/evidence/presentation/evidence_editor_sheet.dart',
        'lib/features/evidence/presentation/evidence_legacy_view_adapter.dart',
        'lib/common/bindings/tabs_binding.dart',
      ];

      for (final path in sources) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('modules/evidence/evidence_model.dart')));
        expect(
          source,
          isNot(contains('modules/evidence/evidence_repository.dart')),
        );
        expect(
          source,
          isNot(contains('modules/evidence/evidence_file_utils.dart')),
        );
        expect(
          source,
          isNot(contains('modules/evidence/evidence_parse_service.dart')),
        );
      }
    });

    test('keeps evidence data services owned by GetIt feature DI', () {
      final repositorySource = File(
        'lib/features/evidence/data/evidence_repository.dart',
      ).readAsStringSync();
      final parseServiceSource = File(
        'lib/features/evidence/data/evidence_parse_service.dart',
      ).readAsStringSync();
      final diSource = File(
        'lib/features/evidence/evidence_feature_di.dart',
      ).readAsStringSync();
      final bindingSource = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      final detailActionsSource = File(
        'lib/features/evidence/presentation/evidence_detail_file_actions.dart',
      ).readAsStringSync();
      final editorSource = File(
        'lib/features/evidence/presentation/evidence_editor_sheet.dart',
      ).readAsStringSync();

      expect(repositorySource, isNot(contains("package:get/get.dart")));
      expect(repositorySource, isNot(contains('GetxService')));
      expect(repositorySource, isNot(contains('EvidenceRepository.to')));
      expect(repositorySource, isNot(contains('Get.find')));
      expect(parseServiceSource, isNot(contains("package:get/get.dart")));
      expect(parseServiceSource, isNot(contains('GetxService')));
      expect(parseServiceSource, isNot(contains('EvidenceParseService.to')));
      expect(parseServiceSource, isNot(contains('Get.find')));
      expect(diSource, contains('registerLazySingleton<EvidenceRepository>'));
      expect(diSource, contains('registerLazySingleton<EvidenceParseService>'));
      expect(diSource, contains('activeLocator<EvidenceRepository>()'));
      expect(diSource, isNot(contains('Get.find<EvidenceRepository>')));
      expect(
        bindingSource,
        isNot(contains('Get.lazyPut(() => EvidenceRepository')),
      );
      expect(
        bindingSource,
        isNot(contains('Get.lazyPut(() => EvidenceParseService')),
      );
      expect(
        File(
          'lib/features/evidence/presentation/evidence_controller.dart',
        ).existsSync(),
        isFalse,
      );
      expect(bindingSource, isNot(contains('EvidenceController')));
      for (final source in [detailActionsSource, editorSource]) {
        expect(source, isNot(contains('EvidenceRepository.to')));
        expect(source, isNot(contains('EvidenceParseService.to')));
        expect(source, isNot(contains('Get.put(EvidenceParseService')));
      }
    });
  });
}
