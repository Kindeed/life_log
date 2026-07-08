import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/evidence/application/load_evidence_entries.dart';
import 'package:life_log/features/evidence/application/watch_evidence_entries.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';

void main() {
  group('EvidenceCubit', () {
    test('loads entries and derives project summaries and totals', () async {
      final repository = _EvidenceCubitRepository(
        entries: [
          _entry(
            id: 1,
            projectName: 'Alpha',
            evidenceDate: DateTime(2026, 5, 2),
            amount: 10,
          ),
          _entry(
            id: 2,
            projectName: 'Alpha',
            evidenceDate: DateTime(2026, 5, 8),
            amount: 6,
            status: EvidenceEntryStatus.reimbursed,
          ),
          _entry(
            id: 3,
            projectName: 'Beta',
            evidenceDate: DateTime(2026, 5, 9),
            amount: 20,
          ),
        ],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.loadEntries();

      expect(cubit.state.status, EvidenceStatus.ready);
      expect(cubit.state.totalEvidenceCount, 3);
      expect(cubit.state.totalPendingAmount, 30);
      expect(
        cubit.state.projectSummaries.map((summary) => summary.projectName),
        ['Beta', 'Alpha'],
      );
      final alpha = cubit.state.projectSummaries.last;
      expect(alpha.count, 2);
      expect(alpha.pendingAmount, 10);
      expect(alpha.reimbursedAmount, 6);
      expect(alpha.latest.id, 2);
    });

    test(
      'exposes project entries and pending totals from domain state',
      () async {
        final repository = _EvidenceCubitRepository(
          entries: [
            _entry(
              id: 1,
              projectName: 'Alpha',
              evidenceDate: DateTime(2026, 5, 2),
              amount: 15,
            ),
            _entry(
              id: 2,
              projectName: 'Alpha',
              evidenceDate: DateTime(2026, 5, 8),
              amount: 7,
              status: EvidenceEntryStatus.reimbursed,
            ),
            _entry(
              id: 3,
              projectName: 'Beta',
              evidenceDate: DateTime(2026, 5, 6),
              amount: 12,
            ),
          ],
        );
        final cubit = _cubit(repository);
        addTearDown(cubit.close);

        await cubit.loadEntries();

        expect(
          cubit.state.entriesForProject('Alpha').map((entry) => entry.id),
          [2, 1],
        );
        expect(cubit.state.pendingAmountForProject('Alpha'), 15);
        expect(cubit.state.entriesForProject('Missing'), isEmpty);
        expect(cubit.state.pendingAmountForProject('Missing'), 0);
      },
    );

    test('filters and sorts summaries from cached domain entries', () async {
      final repository = _EvidenceCubitRepository(
        entries: [
          _entry(id: 1, projectName: 'Beta', amount: 5),
          _entry(
            id: 2,
            projectName: 'Alpha',
            amount: 50,
            evidenceDate: DateTime(2026, 5, 3),
          ),
          _entry(
            id: 3,
            projectName: 'Gamma',
            amount: 20,
            evidenceDate: DateTime(2026, 5, 4),
          ),
        ],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      await cubit.loadEntries();

      cubit.updateSearch('a');
      cubit.setSortMode(EvidenceSortMode.project);
      expect(
        cubit.state.filteredProjectSummaries.map(
          (summary) => summary.projectName,
        ),
        ['Alpha', 'Beta', 'Gamma'],
      );

      cubit.setSortMode(EvidenceSortMode.amount);
      expect(
        cubit.state.filteredProjectSummaries.map(
          (summary) => summary.projectName,
        ),
        ['Alpha', 'Gamma', 'Beta'],
      );
    });

    test('reloads entries when repository emits changes', () async {
      final repository = _EvidenceCubitRepository(
        entries: [_entry(id: 1, projectName: 'Before')],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      cubit.start();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.entries.single.projectName, 'Before');

      repository.entries = [_entry(id: 2, projectName: 'After')];
      repository.emitChange();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.entries.single.projectName, 'After');
      expect(cubit.state.projectSummaries.single.projectName, 'After');
    });

    test('emits failure state when loading entries fails', () async {
      final repository = _EvidenceCubitRepository(
        entries: const [],
        loadError: StateError('evidence down'),
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.loadEntries();

      expect(cubit.state.status, EvidenceStatus.failure);
      expect(cubit.state.failure?.code, 'evidence/load-entries');
      expect(cubit.state.failure?.message, contains('evidence down'));
    });
  });

  group('Evidence read UI ownership', () {
    test('routes EvidenceListView read state through the feature cubit', () {
      final featureListView = File(
        'lib/features/evidence/presentation/evidence_list_view.dart',
      );
      final legacyListView = File(
        'lib/modules/evidence/views/evidence_list_view.dart',
      );

      expect(featureListView.existsSync(), isTrue);
      expect(legacyListView.existsSync(), isFalse);
      final source = featureListView.readAsStringSync();

      expect(source, contains('BlocProvider<EvidenceCubit>'));
      expect(
        source,
        matches(RegExp(r'BlocBuilder<\s*EvidenceCubit', multiLine: true)),
      );
      expect(source, contains('state.filteredProjectSummaries'));
      expect(source, contains('state.totalEvidenceCount'));
      expect(source, contains('state.totalPendingAmount'));
      expect(source, isNot(contains('controller.evidence')));
      expect(source, isNot(contains('controller.filteredProjectSummaries')));
      expect(source, isNot(contains('controller.totalEvidenceCount')));
      expect(source, isNot(contains('controller.totalPendingAmount')));
      expect(source, isNot(contains('controller.updateSearch')));
      expect(source, isNot(contains('controller.setSortMode')));
      expect(source, isNot(contains('controller.sortMode')));
      expect(source, isNot(contains('return Obx(')));
    });

    test(
      'routes photo and project evidence read state through feature cubit',
      () {
        final photoView = File(
          'lib/features/photo/presentation/photo_view.dart',
        ).readAsStringSync();
        final projectGallery = File(
          'lib/features/photo/presentation/project_gallery_view.dart',
        ).readAsStringSync();

        expect(photoView, contains('EvidenceCubit'));
        expect(photoView, contains('EvidenceEntry'));
        expect(photoView, contains('BlocBuilder<EvidenceCubit'));
        expect(photoView, isNot(contains('evidenceController.evidence')));
        expect(photoView, isNot(contains('groupedEvidence')));
        expect(photoView, isNot(contains('evidence_model.dart')));
        expect(
          photoView,
          isNot(contains('Get.find<EvidenceController>()')),
          reason: 'PhotoView should not fetch the legacy controller for reads.',
        );

        expect(projectGallery, contains('EvidenceCubit'));
        expect(projectGallery, contains('EvidenceEntry'));
        expect(projectGallery, contains('BlocBuilder<EvidenceCubit'));
        expect(projectGallery, isNot(contains('evidenceController.evidence')));
        expect(projectGallery, isNot(contains('groupedEvidence')));
        expect(projectGallery, isNot(contains('evidence_model.dart')));
      },
    );

    test('routes Today evidence totals through the feature cubit', () {
      final todayView = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();

      expect(todayView, contains('BlocProvider<EvidenceCubit>'));
      expect(
        todayView,
        matches(RegExp(r'BlocBuilder<\s*EvidenceCubit', multiLine: true)),
      );
      expect(todayView, contains('totalPendingAmount'));
      expect(todayView, isNot(contains('final evidence = Get.find')));
      expect(todayView, isNot(contains('evidence.totalPendingAmount')));
      expect(todayView, isNot(contains('evidence.loadEvidence()')));
    });

    test('routes add-entry action sheets through the feature launcher', () {
      final evidenceList = File(
        'lib/features/evidence/presentation/evidence_list_view.dart',
      ).readAsStringSync();
      final projectGallery = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();
      final todayView = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();
      final launcher = File(
        'lib/features/evidence/presentation/evidence_add_action_launcher.dart',
      );

      expect(launcher.existsSync(), isTrue);
      final launcherSource = launcher.readAsStringSync();
      expect(launcherSource, contains('showEvidenceEditorSheet'));
      expect(launcherSource, isNot(contains('EvidenceController')));
      expect(launcherSource, isNot(contains('Get.find')));
      for (final source in [evidenceList, projectGallery, todayView]) {
        expect(source, contains('showEvidenceAddActions'));
        expect(source, isNot(contains('EvidenceController')));
        expect(source, isNot(contains('captureEvidence(')));
        expect(source, isNot(contains('importEvidence(')));
        expect(source, isNot(contains('importEvidenceFile(')));
        expect(source, isNot(contains('createManualEvidence(')));
      }
    });

    test('uses local launcher lifecycles for evidence routes and sheets', () {
      final sources = [
        'lib/features/evidence/presentation/evidence_add_action_launcher.dart',
        'lib/features/evidence/presentation/evidence_detail_launcher.dart',
        'lib/features/evidence/presentation/evidence_editor_launcher.dart',
        'lib/features/evidence/presentation/evidence_list_view.dart',
        'lib/features/evidence/presentation/evidence_detail_sheet.dart',
        'lib/features/photo/presentation/project_gallery_view.dart',
      ].map((path) => File(path).readAsStringSync()).join('\n');
      final todaySource = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync().replaceAll('\r\n', '\n');

      expect(sources, isNot(contains('Get.to(')));
      expect(sources, isNot(contains('Get.bottomSheet(')));
      expect(sources, isNot(contains('AppActionSheet.show')));
      expect(sources, contains('showModalBottomSheet'));
      expect(sources, contains('Navigator.of(context).push'));
      expect(sources, contains('BuildContext context'));
      expect(
        todaySource,
        contains('showEvidenceAddActions(\n              context,'),
      );
    });

    test(
      'recovers Android image picker results lost across Activity restart',
      () {
        final appEntry = File(
          'lib/app/lifelog_mobile_entry.dart',
        ).readAsStringSync();
        final launcher = File(
          'lib/features/evidence/presentation/evidence_add_action_launcher.dart',
        ).readAsStringSync();
        final editorSheet = File(
          'lib/features/evidence/presentation/evidence_editor_sheet.dart',
        ).readAsStringSync();
        final recoveryFile = File(
          'lib/features/evidence/presentation/evidence_lost_data_recovery.dart',
        );

        expect(recoveryFile.existsSync(), isTrue);
        final recovery = recoveryFile.existsSync()
            ? recoveryFile.readAsStringSync()
            : '';
        expect(appEntry, contains('recoverLostEvidenceData'));
        expect(appEntry, contains('_rootNavigatorKey'));
        expect(launcher, contains('EvidencePendingPickerStore'));
        expect(launcher, contains('initialProject: initialProject'));
        expect(launcher, contains('EvidencePendingPickerSource.camera'));
        expect(launcher, contains('EvidencePendingPickerSource.gallery'));
        expect(editorSheet, contains('EvidencePendingPickerStore'));
        expect(editorSheet, contains('rememberLaunch('));
        expect(recovery, contains('retrieveLostData()'));
        expect(recovery, contains('showEvidenceEditorSheet'));
        expect(recovery, isNot(contains('PhotoItem')));
        expect(recovery, isNot(contains('showCaptureDialog')));
        expect(recovery, isNot(contains('recoverLostPhotoData')));
      },
    );
  });
}

EvidenceCubit _cubit(_EvidenceCubitRepository repository) {
  return EvidenceCubit(
    loadEntries: LoadEvidenceEntries(repository),
    watchEntries: WatchEvidenceEntries(repository),
  );
}

EvidenceEntry _entry({
  required int id,
  String projectName = 'Alpha',
  DateTime? evidenceDate,
  double? amount = 10,
  EvidenceEntryStatus status = EvidenceEntryStatus.pending,
}) {
  return EvidenceEntry(
    id: id,
    projectName: projectName,
    evidenceDate: evidenceDate ?? DateTime(2026, 5, 1),
    amount: amount,
    status: status,
  );
}

final class _EvidenceCubitRepository implements EvidenceRepositoryPort {
  final _controller = StreamController<void>.broadcast();
  Object? loadError;
  List<EvidenceEntry> entries;

  _EvidenceCubitRepository({required this.entries, this.loadError});

  @override
  Future<List<EvidenceEntry>> getAllEntries() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return entries;
  }

  @override
  Future<EvidenceEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> saveEntry(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  }) async {}

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => _controller.stream;

  void emitChange() {
    _controller.add(null);
  }
}
