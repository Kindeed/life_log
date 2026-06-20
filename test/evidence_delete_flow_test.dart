import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Evidence delete flow', () {
    test(
      'detail sheet exposes title-bar delete without breaking action grid',
      () {
        final featureDetailSheet = File(
          'lib/features/evidence/presentation/evidence_detail_sheet.dart',
        );
        final legacyDetailSheet = File(
          'lib/modules/evidence/views/evidence_detail_sheet.dart',
        );

        expect(featureDetailSheet.existsSync(), isTrue);
        expect(legacyDetailSheet.existsSync(), isFalse);
        final source = featureDetailSheet.readAsStringSync();

        expect(source, contains("tooltip: '删除'"));
        expect(source, contains('Icons.delete_outline_rounded'));
        expect(source, contains('showDialog<bool>'));
        expect(source, contains('DeleteEvidenceEntry'));
        expect(source, contains('SaveEvidenceEntry'));
        expect(source, contains('EvidenceEntry'));
        expect(source, isNot(contains('EvidenceController.to.deleteEvidence')));
        expect(source, isNot(contains('controller.saveEvidence')));
        expect(source, isNot(contains('ExpenseEvidence()')));
        expect(source, isNot(contains('remoteId')));
        expect(source, isNot(contains('syncId')));
        expect(source, isNot(contains('remoteVersion')));
        expect(source, isNot(contains('remoteUpdatedAt')));
        expect(source, isNot(contains('syncedAt')));
        expect(source, isNot(contains('deletedAt')));
        expect(source, isNot(contains('pendingDelete')));
        expect(source, isNot(contains("label: '删除'")));
      },
    );

    test('routes file actions through the feature helper', () {
      final source = File(
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
      ).readAsStringSync();
      final helper = File(
        'lib/features/evidence/presentation/evidence_detail_file_actions.dart',
      );

      expect(helper.existsSync(), isTrue);
      final helperSource = helper.readAsStringSync();
      expect(source, contains('EvidenceDetailFileActions'));
      expect(source, contains('showEvidenceEditorSheet'));
      expect(source, isNot(contains('EvidenceController')));
      expect(helperSource, isNot(contains('EvidenceController')));
      expect(helperSource, isNot(contains('ensureLocalEvidenceFile')));
      expect(helperSource, isNot(contains('openEvidenceFile')));
      expect(helperSource, isNot(contains('exportEvidenceFile')));
      expect(helperSource, isNot(contains('parseEvidenceFile')));
      expect(source, isNot(contains('ensureLocalEvidenceFile')));
      expect(source, isNot(contains('openEvidenceFile')));
      expect(source, isNot(contains('exportEvidenceFile')));
      expect(source, isNot(contains('parseEvidenceFile')));
      expect(source, isNot(contains('editEvidence')));
      expect(source, isNot(contains('Obx(')));
    });

    test('uses local detail feedback and confirmation lifecycles', () {
      final detailSheet = File(
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
      ).readAsStringSync();
      final fileActions = File(
        'lib/features/evidence/presentation/evidence_detail_file_actions.dart',
      ).readAsStringSync();
      final combined = '$detailSheet\n$fileActions';

      expect(combined, isNot(contains('AppConfirmDialog.show')));
      expect(combined, isNot(contains('Get.snackbar')));
      expect(detailSheet, contains('showDialog<bool>'));
      expect(fileActions, contains('BuildContext context'));
      expect(combined, contains('ScaffoldMessenger'));
    });

    test('routes detail sheet opening through the feature launcher', () {
      final detailSheet = File(
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
      ).readAsStringSync();
      final legacyDetailSheet = File(
        'lib/modules/evidence/views/evidence_detail_sheet.dart',
      );
      final evidenceList = File(
        'lib/features/evidence/presentation/evidence_list_view.dart',
      ).readAsStringSync();
      final legacyEvidenceList = File(
        'lib/modules/evidence/views/evidence_list_view.dart',
      );
      final projectGallery = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();
      final launcher = File(
        'lib/features/evidence/presentation/evidence_detail_launcher.dart',
      );

      expect(launcher.existsSync(), isTrue);
      expect(legacyDetailSheet.existsSync(), isFalse);
      expect(legacyEvidenceList.existsSync(), isFalse);
      final launcherSource = launcher.readAsStringSync();
      expect(
        launcherSource,
        contains('features/evidence/presentation/evidence_detail_sheet.dart'),
      );
      expect(
        launcherSource,
        isNot(contains('modules/evidence/views/evidence_detail_sheet.dart')),
      );
      expect(detailSheet, isNot(contains('void showEvidenceDetailSheet')));
      expect(detailSheet, isNot(contains('Get.bottomSheet(')));
      for (final source in [evidenceList, projectGallery]) {
        expect(
          source,
          contains(
            'features/evidence/presentation/evidence_detail_launcher.dart',
          ),
        );
        expect(
          source,
          isNot(contains('modules/evidence/views/evidence_detail_sheet.dart')),
        );
        expect(source, contains('showEvidenceDetailSheet'));
      }
    });

    test('keeps attachment preview in feature presentation widgets', () {
      final detailSheet = File(
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
      ).readAsStringSync();
      final evidenceList = File(
        'lib/features/evidence/presentation/evidence_list_view.dart',
      ).readAsStringSync();
      final launcher = File(
        'lib/features/evidence/presentation/evidence_detail_launcher.dart',
      ).readAsStringSync();
      final preview = File(
        'lib/features/evidence/presentation/evidence_attachment_preview.dart',
      );

      expect(preview.existsSync(), isTrue);
      expect(detailSheet, contains('evidence_attachment_preview.dart'));
      expect(evidenceList, contains('evidence_attachment_preview.dart'));
      expect(launcher, isNot(contains('EvidenceAttachmentPreview')));
      expect(detailSheet, isNot(contains('class EvidenceAttachmentPreview')));
      expect(detailSheet, isNot(contains('class _PdfAttachmentPreview')));
      expect(detailSheet, isNot(contains('class _FileAttachmentPreview')));
      expect(
        preview.readAsStringSync(),
        contains('class EvidenceAttachmentPreview'),
      );
    });
  });
}
