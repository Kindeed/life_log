import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_cubit.dart';

void main() {
  group('EvidenceEditorCubit', () {
    test('initializes an edit draft from an existing entry', () {
      final cubit = _editor(
        existingEntry: _entry(
          id: 9,
          amount: 32.5,
          category: EvidenceEntryCategory.travel,
          status: EvidenceEntryStatus.submitted,
          merchant: '高铁',
          projectName: '上海项目',
          note: '已提交',
          tripDate: DateTime(2026, 5, 8),
        ),
        existingAlreadyDirty: true,
      );
      addTearDown(cubit.close);

      expect(cubit.state.amountText, '32.5');
      expect(cubit.state.category, EvidenceEntryCategory.travel);
      expect(cubit.state.evidenceStatus, EvidenceEntryStatus.submitted);
      expect(cubit.state.merchant, '高铁');
      expect(cubit.state.projectName, '上海项目');
      expect(cubit.state.note, '已提交');
      expect(cubit.state.tripDate, DateTime(2026, 5, 8));
      expect(cubit.state.existingAlreadyDirty, isTrue);
    });

    test('rejects missing project before saving', () async {
      final repository = _EditorRepository();
      final cubit = _editor(repository: repository, initialProjectName: '');
      addTearDown(cubit.close);

      cubit.changeAmountText('18');

      await cubit.submit();

      expect(repository.savedEntries, isEmpty);
      expect(cubit.state.status, EvidenceEditorStatus.failure);
      expect(cubit.state.failure?.code, 'evidence/editor/missing-project');
    });

    test('saves a new draft as dirty evidence entry with attachment', () async {
      final repository = _EditorRepository();
      final cubit = _editor(repository: repository, initialProjectName: '新项目');
      addTearDown(cubit.close);

      cubit
        ..changeAmountText('108.6')
        ..changeCategory(EvidenceEntryCategory.travel)
        ..changeEvidenceStatus(EvidenceEntryStatus.submitted)
        ..changeMerchant('铁路')
        ..changeNote('车票')
        ..changeAttachment('C:/tmp/ticket.pdf', sourceExtension: 'pdf');

      await cubit.submit();

      final call = repository.savedEntries.single;
      expect(call.markDirty, isTrue);
      expect(call.entry.id, 0);
      expect(call.entry.evidenceDate, DateTime(2026, 5, 9));
      expect(call.entry.amount, 108.6);
      expect(call.entry.category, EvidenceEntryCategory.travel);
      expect(call.entry.status, EvidenceEntryStatus.submitted);
      expect(call.entry.merchant, '铁路');
      expect(call.entry.projectName, '新项目');
      expect(call.entry.note, '车票');
      expect(call.sourcePath, 'C:/tmp/ticket.pdf');
      expect(call.sourceExtension, 'pdf');
      expect(cubit.state.status, EvidenceEditorStatus.saved);
    });

    test(
      'keeps an unchanged existing draft clean unless it was already dirty',
      () async {
        final repository = _EditorRepository();
        final existing = _entry(id: 12, amount: 42, note: '未改动');
        final cubit = _editor(repository: repository, existingEntry: existing);
        addTearDown(cubit.close);

        await cubit.submit();

        expect(repository.savedEntries.single.markDirty, isFalse);
        expect(repository.savedEntries.single.entry.id, 12);
      },
    );

    test(
      'marks an existing draft dirty when a new attachment is selected',
      () async {
        final repository = _EditorRepository();
        final existing = _entry(
          id: 14,
          amount: 42,
          localFilePath: 'C:/old/a.png',
        );
        final cubit = _editor(repository: repository, existingEntry: existing);
        addTearDown(cubit.close);

        cubit.changeAttachment('C:/new/b.png');

        await cubit.submit();

        final call = repository.savedEntries.single;
        expect(call.markDirty, isTrue);
        expect(call.sourcePath, 'C:/new/b.png');
      },
    );

    test('deletes the existing entry through the delete command', () async {
      final repository = _EditorRepository();
      final cubit = _editor(
        repository: repository,
        existingEntry: _entry(id: 13),
      );
      addTearDown(cubit.close);

      await cubit.delete();

      expect(repository.deletedIds, [13]);
      expect(cubit.state.status, EvidenceEditorStatus.deleted);
    });
  });

  group('Evidence editor UI ownership', () {
    test('routes edit writes through feature commands', () {
      final featureEditorSheet = File(
        'lib/features/evidence/presentation/evidence_editor_sheet.dart',
      );
      final legacyEditorSheet = File(
        'lib/modules/evidence/views/evidence_editor_sheet.dart',
      );

      expect(featureEditorSheet.existsSync(), isTrue);
      expect(legacyEditorSheet.existsSync(), isFalse);
      final source = featureEditorSheet.readAsStringSync();

      expect(source, contains('EvidenceEditorCubit'));
      expect(source, contains('BlocListener<EvidenceEditorCubit'));
      expect(source, contains('SaveEvidenceEntry'));
      expect(source, contains('DeleteEvidenceEntry'));
      expect(source, contains('ScaffoldMessenger'));
      expect(source, isNot(contains('EvidenceController.to.saveEvidence')));
      expect(source, isNot(contains('EvidenceController.to.deleteEvidence')));
      expect(source, isNot(contains('ExpenseEvidence()')));
      expect(source, isNot(contains('remoteId')));
      expect(source, isNot(contains('syncId')));
      expect(source, isNot(contains('remoteVersion')));
      expect(source, isNot(contains('remoteUpdatedAt')));
      expect(source, isNot(contains('syncedAt')));
      expect(source, isNot(contains('deletedAt')));
      expect(source, isNot(contains('pendingDelete')));
    });

    test('uses local editor close, confirmation, and feedback lifecycles', () {
      final source = File(
        'lib/features/evidence/presentation/evidence_editor_sheet.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('Get.back')));
      expect(source, isNot(contains('Get.snackbar')));
      expect(source, isNot(contains('AppConfirmDialog.show')));
      expect(source, contains('Navigator.of(context).maybePop'));
      expect(source, contains('showDialog<bool>'));
      expect(source, contains('ScaffoldMessenger'));
    });

    test('routes editor opening through the feature launcher', () {
      final editorSheet = File(
        'lib/features/evidence/presentation/evidence_editor_sheet.dart',
      ).readAsStringSync();
      final legacyEditorSheet = File(
        'lib/modules/evidence/views/evidence_editor_sheet.dart',
      );
      final detailSheet = File(
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
      ).readAsStringSync();
      final legacyController = File(
        'lib/modules/evidence/evidence_controller.dart',
      );
      final launcher = File(
        'lib/features/evidence/presentation/evidence_editor_launcher.dart',
      );

      expect(launcher.existsSync(), isTrue);
      expect(legacyEditorSheet.existsSync(), isFalse);
      expect(legacyController.existsSync(), isFalse);
      final launcherSource = launcher.readAsStringSync();
      expect(
        launcherSource,
        contains('features/evidence/presentation/evidence_editor_sheet.dart'),
      );
      expect(
        launcherSource,
        isNot(contains('modules/evidence/views/evidence_editor_sheet.dart')),
      );
      expect(editorSheet, isNot(contains('void showEvidenceEditorSheet')));
      expect(
        editorSheet,
        isNot(contains('void showEvidenceEditorBottomSheet')),
      );
      expect(editorSheet, isNot(contains('Get.to(')));
      expect(editorSheet, isNot(contains('Get.bottomSheet(')));
      expect(
        detailSheet,
        contains(
          'features/evidence/presentation/evidence_editor_launcher.dart',
        ),
      );
      expect(
        detailSheet,
        isNot(contains('modules/evidence/views/evidence_editor_sheet.dart')),
      );
    });

    test('retires the compatibility controller runtime path', () {
      final binding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      final backupService = File(
        'lib/common/db/backup_service.dart',
      ).readAsStringSync();

      expect(
        File(
          'lib/features/evidence/presentation/evidence_controller.dart',
        ).existsSync(),
        isFalse,
      );
      expect(binding, isNot(contains('EvidenceController')));
      expect(backupService, isNot(contains('EvidenceController')));
    });

    test('applies parsed invoice dates instead of keeping import dates', () {
      final editorSheet = File(
        'lib/features/evidence/presentation/evidence_editor_sheet.dart',
      ).readAsStringSync();
      final detailSheet = File(
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
      ).readAsStringSync();

      expect(
        editorSheet,
        contains(
          'if (result.evidenceDate != null && _shouldApplyParsedDate())',
        ),
      );
      expect(
        editorSheet,
        contains('return editorState.existingEntry == null;'),
      );
      expect(detailSheet, contains('if (result.evidenceDate != null) {'));
      expect(detailSheet, isNot(contains('&& _isToday(evidenceDate)')));
    });

    test('makes recognized evidence detail text selectable', () {
      final detailSheet = File(
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
      ).readAsStringSync();

      expect(detailSheet, contains('SelectableText('));
      expect(detailSheet, contains("label: '备注'"));
    });
  });
}

EvidenceEditorCubit _editor({
  _EditorRepository? repository,
  EvidenceEntry? existingEntry,
  bool existingAlreadyDirty = false,
  String? initialProjectName,
}) {
  final activeRepository = repository ?? _EditorRepository();
  return EvidenceEditorCubit(
    saveEntry: SaveEvidenceEntry(activeRepository),
    deleteEntry: DeleteEvidenceEntry(activeRepository),
    selectedDate: DateTime(2026, 5, 9, 18),
    existingEntry: existingEntry,
    existingAlreadyDirty: existingAlreadyDirty,
    initialProjectName: initialProjectName,
  );
}

EvidenceEntry _entry({
  required int id,
  double? amount = 12,
  EvidenceEntryCategory category = EvidenceEntryCategory.invoice,
  EvidenceEntryStatus status = EvidenceEntryStatus.pending,
  String projectName = 'Alpha',
  String? merchant,
  String? note,
  String? localFilePath,
  DateTime? tripDate,
}) {
  return EvidenceEntry(
    id: id,
    projectName: projectName,
    evidenceDate: DateTime(2026, 5, 9),
    amount: amount,
    category: category,
    status: status,
    merchant: merchant,
    note: note,
    localFilePath: localFilePath,
    tripDate: tripDate,
  );
}

final class _SavedEditorEntry {
  final EvidenceEntry entry;
  final bool markDirty;
  final String? sourcePath;
  final String? sourceExtension;

  const _SavedEditorEntry({
    required this.entry,
    required this.markDirty,
    this.sourcePath,
    this.sourceExtension,
  });
}

final class _EditorRepository implements EvidenceRepositoryPort {
  final savedEntries = <_SavedEditorEntry>[];
  final deletedIds = <int>[];

  @override
  Future<List<EvidenceEntry>> getAllEntries() async => const [];

  @override
  Future<EvidenceEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> saveEntry(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  }) async {
    savedEntries.add(
      _SavedEditorEntry(
        entry: entry,
        markDirty: markDirty,
        sourcePath: sourcePath,
        sourceExtension: sourceExtension,
      ),
    );
  }

  @override
  Future<void> deleteEntry(int id) async {
    deletedIds.add(id);
  }

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
