import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/load_evidence_edit_draft.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/data/evidence_file_store.dart';
import 'package:life_log/features/evidence/data/evidence_local_data_source.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/data/evidence_project_linker.dart';
import 'package:life_log/features/evidence/data/evidence_repository.dart';
import 'package:life_log/features/evidence/data/evidence_sync_gateway.dart';
import 'package:life_log/features/evidence/data/legacy_evidence_repository_adapter.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry_stats.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';

void main() {
  group('EvidenceEntryStats', () {
    test(
      'filters by local month and splits reimbursed and pending amounts',
      () {
        final entries = [
          EvidenceEntry(
            id: 1,
            projectName: 'Alpha',
            evidenceDate: DateTime(2026, 5, 1, 23),
            amount: 10,
          ),
          EvidenceEntry(
            id: 2,
            projectName: 'Alpha',
            evidenceDate: DateTime(2026, 5, 9),
            amount: 5,
            status: EvidenceEntryStatus.submitted,
          ),
          EvidenceEntry(
            id: 3,
            projectName: 'Beta',
            evidenceDate: DateTime(2026, 5, 10),
            amount: 20,
            status: EvidenceEntryStatus.reimbursed,
          ),
          EvidenceEntry(
            id: 4,
            projectName: 'Beta',
            evidenceDate: DateTime(2026, 6, 1),
            amount: 99,
            status: EvidenceEntryStatus.reimbursed,
          ),
        ];

        final mayEntries = entries.inMonth(DateTime(2026, 5)).toList();

        expect(mayEntries.map((entry) => entry.id), [1, 2, 3]);
        expect(mayEntries.totalPendingAmount, 15);
        expect(mayEntries.totalReimbursedAmount, 20);
      },
    );
  });

  group('SaveEvidenceEntry', () {
    test('delegates entry save with dirty and attachment inputs', () async {
      final repository = _WritePathRepository();

      final result = await SaveEvidenceEntry(repository).call(
        _entry(
          id: 7,
          amount: 18,
          category: EvidenceEntryCategory.travel,
          merchant: 'Railway',
          note: 'trip',
        ),
        markDirty: true,
        sourcePath: 'C:/tmp/ticket.pdf',
        sourceExtension: 'pdf',
      );

      expect(result.isSuccess, isTrue);
      final saved = repository.savedEntries.single;
      expect(saved.entry.id, 7);
      expect(saved.entry.amount, 18);
      expect(saved.entry.category, EvidenceEntryCategory.travel);
      expect(saved.markDirty, isTrue);
      expect(saved.sourcePath, 'C:/tmp/ticket.pdf');
      expect(saved.sourceExtension, 'pdf');
    });

    test('returns app failure when saving throws', () async {
      final result = await SaveEvidenceEntry(
        _WritePathRepository(saveError: StateError('save down')),
      ).call(_entry(id: 8), markDirty: true);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'evidence/save-entry');
      expect(result.failureOrNull?.message, contains('save down'));
    });
  });

  group('DeleteEvidenceEntry', () {
    test('delegates delete by id', () async {
      final repository = _WritePathRepository();

      final result = await DeleteEvidenceEntry(repository).call(12);

      expect(result.isSuccess, isTrue);
      expect(repository.deletedIds, [12]);
    });

    test('returns app failure when deleting throws', () async {
      final result = await DeleteEvidenceEntry(
        _WritePathRepository(deleteError: StateError('delete down')),
      ).call(13);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'evidence/delete-entry');
      expect(result.failureOrNull?.message, contains('delete down'));
    });
  });

  group('Project delete Evidence boundary', () {
    test('routes project evidence deletes through feature commands', () {
      final source = File(
        'lib/features/project/application/delete_project_entry.dart',
      ).readAsStringSync();

      expect(source, contains('LoadEvidenceEntries'));
      expect(source, contains('DeleteEvidenceEntry'));
      expect(
        source,
        isNot(contains('modules/evidence/evidence_repository.dart')),
      );
      expect(source, isNot(contains('EvidenceRepository.to')));
      expect(source, isNot(contains('getAllEvidence()')));
      expect(source, isNot(contains('deleteEvidence(')));
    });
  });

  group('LoadEvidenceEditDraft', () {
    test(
      'returns edit draft with dirty metadata from repository port',
      () async {
        final repository = _WritePathRepository(
          editDraft: EvidenceEditDraft(
            entry: _entry(id: 31, amount: 44),
            alreadyDirty: true,
          ),
        );

        final result = await LoadEvidenceEditDraft(repository).call(31);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull?.entry.id, 31);
        expect(result.valueOrNull?.entry.amount, 44);
        expect(result.valueOrNull?.alreadyDirty, isTrue);
      },
    );
  });

  group('LegacyEvidenceRepositoryAdapter', () {
    test('keeps Evidence repository infrastructure behind data seams', () {
      final repositorySource = File(
        'lib/features/evidence/data/evidence_repository.dart',
      ).readAsStringSync();
      final localDataSourceFile = File(
        'lib/features/evidence/data/evidence_local_data_source.dart',
      );
      final syncGatewayFile = File(
        'lib/features/evidence/data/evidence_sync_gateway.dart',
      );
      final projectLinkerFile = File(
        'lib/features/evidence/data/evidence_project_linker.dart',
      );
      final fileStoreFile = File(
        'lib/features/evidence/data/evidence_file_store.dart',
      );

      expect(localDataSourceFile.existsSync(), isTrue);
      expect(syncGatewayFile.existsSync(), isTrue);
      expect(projectLinkerFile.existsSync(), isTrue);
      expect(fileStoreFile.existsSync(), isTrue);
      expect(repositorySource, contains('EvidenceLocalDataSource'));
      expect(repositorySource, contains('EvidenceSyncGateway'));
      expect(repositorySource, contains('EvidenceProjectLinker'));
      expect(repositorySource, contains('EvidenceFileStore'));
      expect(repositorySource, isNot(contains('DbService.to')));
      expect(repositorySource, isNot(contains('SyncService.to')));
      expect(repositorySource, isNot(contains('ProjectRepository.to')));
      expect(
        repositorySource,
        isNot(contains('getApplicationDocumentsDirectory')),
      );
      expect(repositorySource, isNot(contains('sourceFile.copy')));
    });

    test('routes reads and watches through the injected local seam', () async {
      final streamController = StreamController<void>();
      final stored = _evidence(id: 9, amount: 42);
      final localDataSource = _EvidenceLocalDataSourceSpy(
        storedEvidence: [stored],
        watchStream: streamController.stream,
      );
      final repository = EvidenceRepository(
        localDataSource: localDataSource,
        syncGateway: _EvidenceSyncGatewaySpy(isAvailable: false),
      );

      expect(await repository.getAllEvidence(), [same(stored)]);

      final values = <void>[];
      final sub = repository.watchEvidence().listen(values.add);
      streamController.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(values, hasLength(1));
      await sub.cancel();
      await streamController.close();
    });

    test(
      'routes saves through injected local, project, file, and sync seams',
      () async {
        final localDataSource = _EvidenceLocalDataSourceSpy();
        final syncGateway = _EvidenceSyncGatewaySpy(isAvailable: true);
        final projectLinker = _EvidenceProjectLinkerSpy(
          linkedProject: const EvidenceLinkedProject(
            id: 42,
            name: 'Canonical Project',
            syncId: 'project-sync-42',
          ),
        );
        final fileStore = _EvidenceFileStoreSpy();
        final repository = EvidenceRepository(
          localDataSource: localDataSource,
          syncGateway: syncGateway,
          projectLinker: projectLinker,
          fileStore: fileStore,
        );
        final evidence = _evidence(projectName: '  canonical project  ');

        final saved = await repository.saveEvidence(
          evidence,
          sourcePath: 'C:/tmp/ticket.pdf',
          sourceExtension: 'pdf',
        );

        expect(saved, same(evidence));
        expect(evidence.syncId, isNotEmpty);
        expect(projectLinker.linkedNames, ['canonical project']);
        expect(evidence.projectId, 42);
        expect(evidence.projectName, 'Canonical Project');
        expect(evidence.projectSyncId, 'project-sync-42');
        expect(fileStore.copiedEvidence, [same(evidence)]);
        expect(fileStore.copiedSourcePaths, ['C:/tmp/ticket.pdf']);
        expect(fileStore.copiedSourceExtensions, ['pdf']);
        expect(localDataSource.addedEvidence, [same(evidence)]);
        expect(syncGateway.syncRequests, [same(evidence)]);
        expect(syncGateway.syncReasons, ['evidence-save']);
      },
    );

    test(
      'does not push already clean remote records after local save',
      () async {
        final localDataSource = _EvidenceLocalDataSourceSpy();
        final syncGateway = _EvidenceSyncGatewaySpy(isAvailable: true);
        final repository = EvidenceRepository(
          localDataSource: localDataSource,
          syncGateway: syncGateway,
          projectLinker: _EvidenceProjectLinkerSpy(
            linkedProject: const EvidenceLinkedProject(id: 1, name: 'Alpha'),
          ),
        );
        final evidence = _evidence(remoteId: 99, isDirty: false);

        await repository.saveEvidence(evidence);

        expect(localDataSource.addedEvidence, [same(evidence)]);
        expect(syncGateway.syncRequests, isEmpty);
      },
    );

    test(
      'purges local-only deletes through injected local and file seams',
      () async {
        final deleted = _evidence(id: 17);
        final localDataSource = _EvidenceLocalDataSourceSpy(
          markedDeleted: deleted,
        );
        final syncGateway = _EvidenceSyncGatewaySpy(isAvailable: true);
        final fileStore = _EvidenceFileStoreSpy();
        final repository = EvidenceRepository(
          localDataSource: localDataSource,
          syncGateway: syncGateway,
          fileStore: fileStore,
        );

        await repository.deleteEvidence(17);

        expect(localDataSource.markDeletedIds, [17]);
        expect(fileStore.deletedEvidence, [same(deleted)]);
        expect(localDataSource.purgedIds, [17]);
        expect(syncGateway.syncRequests, isEmpty);
      },
    );

    test(
      'routes remote deletes through injected local, sync, and file seams',
      () async {
        final deleted = _evidence(id: 18, remoteId: 77);
        final localDataSource = _EvidenceLocalDataSourceSpy(
          markedDeleted: deleted,
        );
        final syncGateway = _EvidenceSyncGatewaySpy(isAvailable: true);
        final fileStore = _EvidenceFileStoreSpy();
        final repository = EvidenceRepository(
          localDataSource: localDataSource,
          syncGateway: syncGateway,
          fileStore: fileStore,
        );

        await repository.deleteEvidence(18);

        expect(localDataSource.markDeletedIds, [18]);
        expect(syncGateway.syncRequests, [same(deleted)]);
        expect(syncGateway.syncReasons, ['evidence-delete']);
        expect(fileStore.deletedEvidence, [same(deleted)]);
        expect(localDataSource.purgedIds, [18]);
      },
    );

    test(
      'maps legacy records to domain entries and exposes watch stream',
      () async {
        final streamController = StreamController<void>();
        final repository = _FakeEvidenceRepository(
          records: [
            ExpenseEvidence()
              ..id = 7
              ..projectName = 'Alpha'
              ..projectId = 11
              ..evidenceDate = DateTime(2026, 5, 3)
              ..amount = 12
              ..status = EvidenceStatus.reimbursed,
          ],
          streamController: streamController,
        );
        final adapter = LegacyEvidenceRepositoryAdapter(repository);

        final entries = await adapter.getAllEntries();

        expect(entries.single.id, 7);
        expect(entries.single.projectName, 'Alpha');
        expect(entries.single.projectId, 11);
        expect(entries.single.evidenceDate, DateTime(2026, 5, 3));
        expect(entries.single.amount, 12);
        expect(entries.single.status, EvidenceEntryStatus.reimbursed);
        final watchExpectation = expectLater(
          adapter.watchEntries(),
          emits(null),
        );

        streamController.add(null);
        await watchExpectation;
        await streamController.close();
      },
    );

    test('maps feature save entries back to legacy records', () async {
      final repository = _FakeEvidenceRepository();
      final adapter = LegacyEvidenceRepositoryAdapter(repository);

      await adapter.saveEntry(
        _entry(
          id: 21,
          projectName: 'Alpha',
          projectId: 4,
          amount: 33,
          category: EvidenceEntryCategory.travel,
          status: EvidenceEntryStatus.submitted,
          merchant: 'Railway',
          note: 'ticket',
          localFilePath: 'C:/old/ticket.pdf',
          fileName: 'ticket.pdf',
          mimeType: 'application/pdf',
          tripDate: DateTime(2026, 5, 2),
        ),
        markDirty: true,
        sourcePath: 'C:/tmp/ticket.pdf',
        sourceExtension: 'pdf',
      );

      final saved = repository.savedRecords.single;
      expect(saved.id, 21);
      expect(saved.projectName, 'Alpha');
      expect(saved.projectId, 4);
      expect(saved.amount, 33);
      expect(saved.category, EvidenceCategory.travel);
      expect(saved.status, EvidenceStatus.submitted);
      expect(saved.merchant, 'Railway');
      expect(saved.note, 'ticket');
      expect(saved.localFilePath, 'C:/old/ticket.pdf');
      expect(saved.fileName, 'ticket.pdf');
      expect(saved.mimeType, 'application/pdf');
      expect(saved.tripDate, DateTime(2026, 5, 2));
      expect(saved.isDirty, isTrue);
      expect(repository.savedSourcePath, 'C:/tmp/ticket.pdf');
      expect(repository.savedSourceExtension, 'pdf');
    });

    test('preserves legacy sync metadata behind the adapter', () async {
      final repository = _FakeEvidenceRepository(
        records: [
          ExpenseEvidence()
            ..id = 23
            ..ownerUserId = 'owner-1'
            ..remoteId = 99
            ..syncId = 'sync-23'
            ..remoteVersion = 5
            ..remoteUpdatedAt = DateTime(2026, 5, 1)
            ..syncedAt = DateTime(2026, 5, 2)
            ..deletedAt = DateTime(2026, 5, 3)
            ..pendingDelete = true
            ..projectName = 'Old Project'
            ..projectId = 7
            ..evidenceDate = DateTime(2026, 5, 10)
            ..amount = 10
            ..currency = 'CNY'
            ..category = EvidenceCategory.invoice
            ..status = EvidenceStatus.pending
            ..merchant = 'Old',
        ],
      );
      final adapter = LegacyEvidenceRepositoryAdapter(repository);

      await adapter.saveEntry(
        _entry(
          id: 23,
          amount: 16,
          merchant: 'Updated',
          projectName: 'New Project',
        ),
        markDirty: true,
      );

      final saved = repository.savedRecords.single;
      expect(saved.id, 23);
      expect(saved.amount, 16);
      expect(saved.merchant, 'Updated');
      expect(saved.ownerUserId, 'owner-1');
      expect(saved.remoteId, 99);
      expect(saved.syncId, 'sync-23');
      expect(saved.remoteVersion, 5);
      expect(saved.remoteUpdatedAt, DateTime(2026, 5, 1));
      expect(saved.syncedAt, DateTime(2026, 5, 2));
      expect(saved.deletedAt, DateTime(2026, 5, 3));
      expect(saved.pendingDelete, isTrue);
      expect(saved.isDirty, isTrue);
    });

    test('maps legacy dirty state into an edit draft', () async {
      final repository = _FakeEvidenceRepository(
        records: [
          ExpenseEvidence()
            ..id = 33
            ..projectName = 'Alpha'
            ..evidenceDate = DateTime(2026, 5, 10)
            ..amount = 10
            ..isDirty = true,
        ],
      );
      final adapter = LegacyEvidenceRepositoryAdapter(repository);

      final draft = await adapter.getEditDraft(33);

      expect(draft?.entry.id, 33);
      expect(draft?.entry.amount, 10);
      expect(draft?.alreadyDirty, isTrue);
    });

    test('delegates feature delete entries to the legacy repository', () async {
      final repository = _FakeEvidenceRepository();
      final adapter = LegacyEvidenceRepositoryAdapter(repository);

      await adapter.deleteEntry(42);

      expect(repository.deletedIds, [42]);
    });
  });
}

EvidenceEntry _entry({
  required int id,
  String projectName = 'Alpha',
  int? projectId,
  DateTime? evidenceDate,
  double? amount = 10,
  String currency = 'CNY',
  EvidenceEntryCategory category = EvidenceEntryCategory.invoice,
  EvidenceEntryStatus status = EvidenceEntryStatus.pending,
  String? merchant,
  String? note,
  String? localFilePath,
  String? remoteStoragePath,
  String? fileName,
  String? mimeType,
  DateTime? uploadedAt,
  DateTime? tripDate,
}) {
  return EvidenceEntry(
    id: id,
    projectName: projectName,
    projectId: projectId,
    evidenceDate: evidenceDate ?? DateTime(2026, 5, 1),
    amount: amount,
    currency: currency,
    category: category,
    status: status,
    merchant: merchant,
    note: note,
    localFilePath: localFilePath,
    remoteStoragePath: remoteStoragePath,
    fileName: fileName,
    mimeType: mimeType,
    uploadedAt: uploadedAt,
    tripDate: tripDate,
  );
}

ExpenseEvidence _evidence({
  int id = 1,
  String projectName = 'Alpha',
  int? projectId,
  DateTime? evidenceDate,
  double? amount = 10,
  String currency = 'CNY',
  EvidenceCategory category = EvidenceCategory.invoice,
  EvidenceStatus status = EvidenceStatus.pending,
  int? remoteId,
  String? localFilePath,
  bool isDirty = true,
}) {
  return ExpenseEvidence()
    ..id = id
    ..projectName = projectName
    ..projectId = projectId
    ..evidenceDate = evidenceDate ?? DateTime(2026, 5, 1)
    ..amount = amount
    ..currency = currency
    ..category = category
    ..status = status
    ..remoteId = remoteId
    ..localFilePath = localFilePath
    ..isDirty = isDirty;
}

final class _SavedEntryCall {
  final EvidenceEntry entry;
  final bool markDirty;
  final String? sourcePath;
  final String? sourceExtension;

  const _SavedEntryCall({
    required this.entry,
    required this.markDirty,
    this.sourcePath,
    this.sourceExtension,
  });
}

final class _WritePathRepository implements EvidenceRepositoryPort {
  final Object? saveError;
  final Object? deleteError;
  final EvidenceEditDraft? editDraft;

  final savedEntries = <_SavedEntryCall>[];
  final deletedIds = <int>[];

  _WritePathRepository({this.saveError, this.deleteError, this.editDraft});

  @override
  Future<List<EvidenceEntry>> getAllEntries() async => const [];

  @override
  Future<EvidenceEditDraft?> getEditDraft(int id) async => editDraft;

  @override
  Future<void> saveEntry(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  }) async {
    final error = saveError;
    if (error != null) throw error;
    savedEntries.add(
      _SavedEntryCall(
        entry: entry,
        markDirty: markDirty,
        sourcePath: sourcePath,
        sourceExtension: sourceExtension,
      ),
    );
  }

  @override
  Future<void> deleteEntry(int id) async {
    final error = deleteError;
    if (error != null) throw error;
    deletedIds.add(id);
  }

  @override
  Stream<void> watchEntries() => const Stream.empty();
}

final class _FakeEvidenceRepository extends EvidenceRepository {
  final List<ExpenseEvidence> records;
  final StreamController<void> streamController;
  final savedRecords = <ExpenseEvidence>[];
  final deletedIds = <int>[];
  String? savedSourcePath;
  String? savedSourceExtension;

  _FakeEvidenceRepository({
    List<ExpenseEvidence>? records,
    StreamController<void>? streamController,
  }) : records = records ?? <ExpenseEvidence>[],
       streamController = streamController ?? StreamController<void>();

  @override
  Future<List<ExpenseEvidence>> getAllEvidence() async => records;

  @override
  Stream<void> watchEvidence() => streamController.stream;

  @override
  Future<ExpenseEvidence> saveEvidence(
    ExpenseEvidence evidence, {
    String? sourcePath,
    String? sourceExtension,
  }) async {
    savedRecords.add(evidence);
    savedSourcePath = sourcePath;
    savedSourceExtension = sourceExtension;
    return evidence;
  }

  @override
  Future<void> deleteEvidence(int id) async {
    deletedIds.add(id);
  }
}

final class _EvidenceLocalDataSourceSpy implements EvidenceLocalDataSource {
  final List<ExpenseEvidence> storedEvidence;
  final List<ExpenseEvidence> addedEvidence = [];
  final List<int> markDeletedIds = [];
  final List<int> purgedIds = [];
  final ExpenseEvidence? markedDeleted;
  final Stream<void> watchStream;

  _EvidenceLocalDataSourceSpy({
    this.storedEvidence = const [],
    this.markedDeleted,
    this.watchStream = const Stream.empty(),
  });

  @override
  Future<int> addEvidence(ExpenseEvidence evidence) async {
    addedEvidence.add(evidence);
    return evidence.id;
  }

  @override
  Future<List<ExpenseEvidence>> getAllEvidence() async => storedEvidence;

  @override
  Future<ExpenseEvidence?> markEvidenceDeleted(int id) async {
    markDeletedIds.add(id);
    return markedDeleted;
  }

  @override
  Future<void> purgeDeletedEvidence(int id) async {
    purgedIds.add(id);
  }

  @override
  Stream<void> watchEvidence() => watchStream;
}

final class _EvidenceSyncGatewaySpy implements EvidenceSyncGateway {
  @override
  final bool isAvailable;
  final List<ExpenseEvidence> syncRequests = [];
  final List<String> syncReasons = [];

  _EvidenceSyncGatewaySpy({required this.isAvailable});

  @override
  Future<bool> requestSync(
    ExpenseEvidence evidence, {
    required String reason,
  }) async {
    syncRequests.add(evidence);
    syncReasons.add(reason);
    return true;
  }
}

final class _EvidenceProjectLinkerSpy implements EvidenceProjectLinker {
  final EvidenceLinkedProject linkedProject;
  final linkedNames = <String>[];

  _EvidenceProjectLinkerSpy({required this.linkedProject});

  @override
  Future<EvidenceLinkedProject> ensureSyncableProject(String name) async {
    linkedNames.add(name);
    return linkedProject;
  }
}

final class _EvidenceFileStoreSpy implements EvidenceFileStore {
  final copiedEvidence = <ExpenseEvidence>[];
  final copiedSourcePaths = <String>[];
  final copiedSourceExtensions = <String?>[];
  final deletedEvidence = <ExpenseEvidence?>[];

  @override
  Future<void> copyEvidenceFile(
    ExpenseEvidence evidence, {
    required String sourcePath,
    String? sourceExtension,
  }) async {
    copiedEvidence.add(evidence);
    copiedSourcePaths.add(sourcePath);
    copiedSourceExtensions.add(sourceExtension);
  }

  @override
  Future<void> deleteEvidenceFile(ExpenseEvidence? evidence) async {
    deletedEvidence.add(evidence);
  }
}
