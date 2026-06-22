import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/subscription/application/delete_subscription_entry.dart';
import 'package:life_log/features/subscription/application/load_subscription_edit_draft.dart';
import 'package:life_log/features/subscription/application/reorder_subscription_entries.dart';
import 'package:life_log/features/subscription/application/save_subscription_entry.dart';
import 'package:life_log/features/subscription/data/legacy_subscription_repository_adapter.dart';
import 'package:life_log/features/subscription/data/subscription_local_data_source.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/subscription/data/subscription_repository.dart';
import 'package:life_log/features/subscription/data/subscription_sync_gateway.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

void main() {
  group('SaveSubscriptionEntry', () {
    test('delegates entry save with the dirty decision', () async {
      final repository = _WritePathRepository();
      final result = await SaveSubscriptionEntry(
        repository,
      ).call(_entry(id: 7, name: 'Cloud', price: 18), markDirty: true);

      expect(result.isSuccess, isTrue);
      expect(repository.savedEntries.single.entry.id, 7);
      expect(repository.savedEntries.single.entry.name, 'Cloud');
      expect(repository.savedEntries.single.markDirty, isTrue);
    });

    test('returns app failure when saving throws', () async {
      final result = await SaveSubscriptionEntry(
        _WritePathRepository(saveError: StateError('save down')),
      ).call(_entry(id: 8), markDirty: true);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'subscription/save-entry');
      expect(result.failureOrNull?.message, contains('save down'));
    });
  });

  group('LoadSubscriptionEditDraft', () {
    test(
      'returns edit draft with dirty metadata from repository port',
      () async {
        final repository = _WritePathRepository(
          editDraft: SubscriptionEditDraft(
            entry: _entry(id: 31, name: 'Draft'),
            alreadyDirty: true,
          ),
        );

        final result = await LoadSubscriptionEditDraft(repository).call(31);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull?.entry.id, 31);
        expect(result.valueOrNull?.alreadyDirty, isTrue);
      },
    );
  });

  group('DeleteSubscriptionEntry', () {
    test('delegates delete by id', () async {
      final repository = _WritePathRepository();

      final result = await DeleteSubscriptionEntry(repository).call(12);

      expect(result.isSuccess, isTrue);
      expect(repository.deletedIds, [12]);
    });

    test('returns app failure when deleting throws', () async {
      final result = await DeleteSubscriptionEntry(
        _WritePathRepository(deleteError: StateError('delete down')),
      ).call(13);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'subscription/delete-entry');
      expect(result.failureOrNull?.message, contains('delete down'));
    });
  });

  group('ReorderSubscriptionEntries', () {
    test('reorders entries before delegating to the repository', () async {
      final repository = _WritePathRepository();

      final result = await ReorderSubscriptionEntries(repository).call(
        [_entry(id: 1), _entry(id: 2), _entry(id: 3)],
        oldIndex: 0,
        newIndex: 3,
      );

      expect(result.isSuccess, isTrue);
      expect(repository.reorderedEntries.single.map((entry) => entry.id), [
        2,
        3,
        1,
      ]);
    });

    test('returns app failure when reordering throws', () async {
      final result = await ReorderSubscriptionEntries(
        _WritePathRepository(reorderError: StateError('reorder down')),
      ).call([_entry(id: 1), _entry(id: 2)], oldIndex: 0, newIndex: 1);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'subscription/reorder-entries');
      expect(result.failureOrNull?.message, contains('reorder down'));
    });
  });

  group('LegacySubscriptionRepositoryAdapter write path', () {
    test('uses the feature data SubscriptionRepository boundary', () {
      final repositoryFile = File(
        'lib/features/subscription/data/subscription_repository.dart',
      );
      final legacyRepositoryFile = File(
        'lib/modules/subscription/subscription_repository.dart',
      );

      expect(repositoryFile.existsSync(), isTrue);
      expect(legacyRepositoryFile.existsSync(), isFalse);
      expect(
        _libDartSources(),
        isNot(contains('modules/subscription/subscription_repository.dart')),
      );
    });

    test('uses the feature data Subscription Isar model boundary', () {
      final modelFile = File(
        'lib/features/subscription/data/subscription_model.dart',
      );
      final generatedModelFile = File(
        'lib/features/subscription/data/subscription_model.g.dart',
      );
      final legacyModelFile = File(
        'lib/modules/subscription/subscription_model.dart',
      );
      final legacyGeneratedModelFile = File(
        'lib/modules/subscription/subscription_model.g.dart',
      );

      expect(modelFile.existsSync(), isTrue);
      expect(generatedModelFile.existsSync(), isTrue);
      expect(legacyModelFile.existsSync(), isFalse);
      expect(legacyGeneratedModelFile.existsSync(), isFalse);
      expect(
        _libDartSources(),
        isNot(contains('modules/subscription/subscription_model.dart')),
      );
    });

    test('keeps DbService and SyncService behind feature data seams', () {
      final repositorySource = File(
        'lib/features/subscription/data/subscription_repository.dart',
      ).readAsStringSync();
      final localDataSourceFile = File(
        'lib/features/subscription/data/subscription_local_data_source.dart',
      );
      final syncGatewayFile = File(
        'lib/features/subscription/data/subscription_sync_gateway.dart',
      );

      expect(localDataSourceFile.existsSync(), isTrue);
      expect(syncGatewayFile.existsSync(), isTrue);
      expect(repositorySource, contains('SubscriptionLocalDataSource'));
      expect(repositorySource, contains('SubscriptionSyncGateway'));
      expect(repositorySource, isNot(contains('DbService.to')));
      expect(repositorySource, isNot(contains('SyncService.to')));
    });

    test('keeps SubscriptionRepository owned by GetIt feature DI', () {
      final repositorySource = File(
        'lib/features/subscription/data/subscription_repository.dart',
      ).readAsStringSync();
      final diSource = File(
        'lib/features/subscription/subscription_feature_di.dart',
      ).readAsStringSync();
      final bindingSource = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();

      expect(repositorySource, isNot(contains("package:get/get.dart")));
      expect(repositorySource, isNot(contains('GetxService')));
      expect(repositorySource, isNot(contains('SubscriptionRepository.to')));
      expect(repositorySource, isNot(contains('Get.find')));
      expect(repositorySource, isNot(contains('Get.isRegistered')));
      expect(
        diSource,
        contains('registerLazySingleton<SubscriptionRepository>'),
      );
      expect(diSource, contains('activeLocator<SubscriptionRepository>()'));
      expect(diSource, isNot(contains('Get.find<SubscriptionRepository>')));
      expect(
        bindingSource,
        isNot(contains('Get.lazyPut(() => SubscriptionRepository')),
      );
    });

    test('routes saves through injected local and sync seams', () async {
      final localDataSource = _SubscriptionLocalDataSourceSpy();
      final syncGateway = _SubscriptionSyncGatewaySpy(isAvailable: true);
      final repository = SubscriptionRepository(
        localDataSource: localDataSource,
        syncGateway: syncGateway,
      );
      final subscription = Subscription()
        ..name = 'Cloud'
        ..price = 18
        ..cycle = SubscriptionCycle.monthly
        ..nextPaymentDate = DateTime(2026, 5, 10);

      await repository.saveSubscription(subscription, 2);

      expect(subscription.sortIndex, 2);
      expect(localDataSource.addedSubscriptions, [same(subscription)]);
      expect(syncGateway.syncRequests, [same(subscription)]);
      expect(syncGateway.syncReasons, ['subscription-save']);
    });

    test(
      'routes remote deletes through injected local and sync seams',
      () async {
        final deleted = Subscription()
          ..id = 17
          ..name = 'Cloud'
          ..price = 18
          ..cycle = SubscriptionCycle.monthly
          ..nextPaymentDate = DateTime(2026, 5, 10)
          ..remoteId = 99;
        final localDataSource = _SubscriptionLocalDataSourceSpy(
          markedDeleted: deleted,
        );
        final syncGateway = _SubscriptionSyncGatewaySpy(isAvailable: true);
        final repository = SubscriptionRepository(
          localDataSource: localDataSource,
          syncGateway: syncGateway,
        );

        await repository.deleteSubscription(17);

        expect(localDataSource.markDeletedIds, [17]);
        expect(syncGateway.syncRequests, [same(deleted)]);
        expect(syncGateway.syncReasons, ['subscription-delete']);
        expect(localDataSource.purgedIds, [17]);
      },
    );

    test('routes changed reorder rows through injected sync seam', () async {
      final first = Subscription()
        ..id = 1
        ..name = 'One'
        ..price = 1
        ..cycle = SubscriptionCycle.monthly
        ..nextPaymentDate = DateTime(2026, 5, 1);
      final second = Subscription()
        ..id = 2
        ..name = 'Two'
        ..price = 2
        ..cycle = SubscriptionCycle.monthly
        ..nextPaymentDate = DateTime(2026, 5, 2);
      final localDataSource = _SubscriptionLocalDataSourceSpy(
        reorderChanged: [second],
      );
      final syncGateway = _SubscriptionSyncGatewaySpy(isAvailable: true);
      final repository = SubscriptionRepository(
        localDataSource: localDataSource,
        syncGateway: syncGateway,
      );

      await repository.reorderSubscriptions([first, second]);

      expect(localDataSource.reorderedSubscriptions.single, [first, second]);
      expect(syncGateway.syncRequests, [same(second)]);
      expect(syncGateway.syncReasons, ['subscription-reorder']);
    });

    test(
      'maps feature save entries back to legacy subscription records',
      () async {
        final repository = _LegacySubscriptionRepositorySpy();
        final adapter = LegacySubscriptionRepositoryAdapter(repository);

        await adapter.saveEntry(
          _entry(
            id: 21,
            name: 'Music',
            price: 12,
            cycle: SubscriptionBillingCycle.yearly,
            nextPaymentDate: DateTime(2026, 5, 20),
            reminderDays: 3,
            note: 'renew',
            sortIndex: 4,
          ),
          markDirty: true,
        );

        final saved = repository.savedSubscriptions.single;
        expect(saved.id, 21);
        expect(saved.name, 'Music');
        expect(saved.price, 12);
        expect(saved.cycle, SubscriptionCycle.yearly);
        expect(saved.nextPaymentDate, DateTime(2026, 5, 20));
        expect(saved.reminderDays, 3);
        expect(saved.note, 'renew');
        expect(saved.sortIndex, 4);
        expect(saved.isDirty, isTrue);
        expect(repository.currentCounts, [0]);
      },
    );

    test('preserves legacy sync metadata behind the adapter', () async {
      final repository = _LegacySubscriptionRepositorySpy()
        ..storedSubscriptions.add(
          Subscription()
            ..id = 23
            ..ownerUserId = 'owner-1'
            ..remoteId = 99
            ..syncId = 'sync-23'
            ..remoteVersion = 5
            ..remoteUpdatedAt = DateTime(2026, 5, 1)
            ..syncedAt = DateTime(2026, 5, 2)
            ..deletedAt = DateTime(2026, 5, 3)
            ..pendingDelete = true
            ..name = 'Old'
            ..price = 10
            ..cycle = SubscriptionCycle.monthly
            ..nextPaymentDate = DateTime(2026, 5, 10)
            ..reminderDays = 1
            ..note = 'old'
            ..sortIndex = 2,
        );
      final adapter = LegacySubscriptionRepositoryAdapter(repository);

      await adapter.saveEntry(
        _entry(
          id: 23,
          name: 'Updated',
          price: 16,
          cycle: SubscriptionBillingCycle.monthly,
          nextPaymentDate: DateTime(2026, 6, 10),
          sortIndex: 2,
        ),
        markDirty: true,
      );

      final saved = repository.savedSubscriptions.single;
      expect(saved.id, 23);
      expect(saved.name, 'Updated');
      expect(saved.ownerUserId, 'owner-1');
      expect(saved.remoteId, 99);
      expect(saved.syncId, 'sync-23');
      expect(saved.remoteVersion, 5);
      expect(saved.remoteUpdatedAt, DateTime(2026, 5, 1));
      expect(saved.syncedAt, DateTime(2026, 5, 2));
      expect(saved.deletedAt, DateTime(2026, 5, 3));
      expect(saved.pendingDelete, isTrue);
      expect(saved.isDirty, isTrue);
      expect(repository.currentCounts, [1]);
    });

    test('maps legacy dirty state into an edit draft', () async {
      final repository = _LegacySubscriptionRepositorySpy()
        ..storedSubscriptions.add(
          Subscription()
            ..id = 33
            ..name = 'Draft'
            ..price = 10
            ..cycle = SubscriptionCycle.monthly
            ..nextPaymentDate = DateTime(2026, 5, 10)
            ..isDirty = true,
        );
      final adapter = LegacySubscriptionRepositoryAdapter(repository);

      final draft = await adapter.getEditDraft(33);

      expect(draft?.entry.id, 33);
      expect(draft?.entry.name, 'Draft');
      expect(draft?.alreadyDirty, isTrue);
    });

    test('delegates feature delete entries to the legacy repository', () async {
      final repository = _LegacySubscriptionRepositorySpy();
      final adapter = LegacySubscriptionRepositoryAdapter(repository);

      await adapter.deleteEntry(42);

      expect(repository.deletedIds, [42]);
    });

    test('maps feature reorder entries back to legacy records', () async {
      final repository = _LegacySubscriptionRepositorySpy()
        ..storedSubscriptions.addAll([
          Subscription()
            ..id = 1
            ..name = 'One'
            ..price = 1
            ..cycle = SubscriptionCycle.monthly
            ..nextPaymentDate = DateTime(2026, 5, 1)
            ..remoteId = 11
            ..syncId = 'sync-1',
          Subscription()
            ..id = 2
            ..name = 'Two'
            ..price = 2
            ..cycle = SubscriptionCycle.yearly
            ..nextPaymentDate = DateTime(2026, 5, 2)
            ..remoteId = 22
            ..syncId = 'sync-2',
        ]);
      final adapter = LegacySubscriptionRepositoryAdapter(repository);

      await adapter.reorderEntries([
        _entry(id: 2, name: 'Two', cycle: SubscriptionBillingCycle.yearly),
        _entry(id: 1, name: 'One'),
      ]);

      final reordered = repository.reorderedSubscriptions.single;
      expect(reordered.map((sub) => sub.id), [2, 1]);
      expect(reordered.first.remoteId, 22);
      expect(reordered.first.syncId, 'sync-2');
      expect(reordered.last.remoteId, 11);
      expect(reordered.last.syncId, 'sync-1');
    });
  });
}

SubscriptionEntry _entry({
  required int id,
  String name = 'Service',
  double? price = 10,
  SubscriptionBillingCycle cycle = SubscriptionBillingCycle.monthly,
  DateTime? nextPaymentDate,
  int reminderDays = 1,
  String? note,
  int? sortIndex,
}) {
  return SubscriptionEntry(
    id: id,
    name: name,
    price: price,
    cycle: cycle,
    nextPaymentDate: nextPaymentDate ?? DateTime(2026, 5, 10),
    reminderDays: reminderDays,
    note: note,
    sortIndex: sortIndex,
  );
}

final class _SavedEntryCall {
  final SubscriptionEntry entry;
  final bool markDirty;

  const _SavedEntryCall({required this.entry, required this.markDirty});
}

final class _WritePathRepository implements SubscriptionRepositoryPort {
  final Object? saveError;
  final Object? deleteError;
  final Object? reorderError;
  final SubscriptionEditDraft? editDraft;
  final savedEntries = <_SavedEntryCall>[];
  final deletedIds = <int>[];
  final reorderedEntries = <List<SubscriptionEntry>>[];

  _WritePathRepository({
    this.saveError,
    this.deleteError,
    this.reorderError,
    this.editDraft,
  });

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async => const [];

  @override
  Future<SubscriptionEditDraft?> getEditDraft(int id) async => editDraft;

  @override
  Future<void> saveEntry(
    SubscriptionEntry entry, {
    required bool markDirty,
  }) async {
    final error = saveError;
    if (error != null) {
      throw error;
    }
    savedEntries.add(_SavedEntryCall(entry: entry, markDirty: markDirty));
  }

  @override
  Future<void> deleteEntry(int id) async {
    final error = deleteError;
    if (error != null) {
      throw error;
    }
    deletedIds.add(id);
  }

  @override
  Future<void> reorderEntries(List<SubscriptionEntry> entries) async {
    final error = reorderError;
    if (error != null) {
      throw error;
    }
    reorderedEntries.add(entries);
  }

  @override
  Stream<void> watchEntries() => const Stream.empty();
}

final class _LegacySubscriptionRepositorySpy extends SubscriptionRepository {
  final storedSubscriptions = <Subscription>[];
  final savedSubscriptions = <Subscription>[];
  final deletedIds = <int>[];
  final currentCounts = <int>[];
  final reorderedSubscriptions = <List<Subscription>>[];

  @override
  Future<List<Subscription>> getAllSubscriptions() async => storedSubscriptions;

  @override
  Future<void> saveSubscription(Subscription sub, int currentCount) async {
    savedSubscriptions.add(sub);
    currentCounts.add(currentCount);
  }

  @override
  Future<void> deleteSubscription(int id) async {
    deletedIds.add(id);
  }

  @override
  Future<void> reorderSubscriptions(List<Subscription> subs) async {
    reorderedSubscriptions.add(subs);
  }
}

final class _SubscriptionLocalDataSourceSpy
    implements SubscriptionLocalDataSource {
  final List<Subscription> addedSubscriptions = [];
  final List<List<Subscription>> reorderedSubscriptions = [];
  final List<int> markDeletedIds = [];
  final List<int> purgedIds = [];
  final Subscription? markedDeleted;
  final List<Subscription> reorderChanged;

  _SubscriptionLocalDataSourceSpy({
    this.markedDeleted,
    this.reorderChanged = const [],
  });

  @override
  Future<int> addSubscription(Subscription subscription) async {
    addedSubscriptions.add(subscription);
    return subscription.id;
  }

  @override
  Future<List<Subscription>> getAllSubscriptions() async => const [];

  @override
  Future<Subscription?> markSubscriptionDeleted(int id) async {
    markDeletedIds.add(id);
    return markedDeleted;
  }

  @override
  Future<void> purgeDeletedSubscription(int id) async {
    purgedIds.add(id);
  }

  @override
  Future<List<Subscription>> reorderSubscriptions(
    List<Subscription> subscriptions,
  ) async {
    reorderedSubscriptions.add(subscriptions);
    return reorderChanged;
  }

  @override
  Stream<void> watchSubscriptions() => const Stream.empty();
}

final class _SubscriptionSyncGatewaySpy implements SubscriptionSyncGateway {
  @override
  final bool isAvailable;
  final List<Subscription> syncRequests = [];
  final List<String> syncReasons = [];

  _SubscriptionSyncGatewaySpy({required this.isAvailable});

  @override
  Future<bool> requestSync(
    Subscription subscription, {
    required String reason,
  }) async {
    syncRequests.add(subscription);
    syncReasons.add(reason);
    return true;
  }
}

String _libDartSources() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}
