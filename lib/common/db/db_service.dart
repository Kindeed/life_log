import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_conflict_model.dart';
import 'package:life_log/core/sync/sync_queue_record.dart';
import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:life_log/common/db/local_data_migration_batch.dart';
import 'package:life_log/common/db/local_data_migration_summary.dart';
import 'package:life_log/features/subscription/data/subscription_dao.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:life_log/features/work_log/data/work_log_dao.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/project/data/project_dao.dart';
import 'package:life_log/features/project/data/project_cascade_delete_result.dart';
import 'package:life_log/features/evidence/data/evidence_dao.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_dao.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import '../utils/date_utils.dart';
import '../services/auth_service.dart';
import '../utils/sync_id_policy.dart';
import '../../features/subscription/domain/entities/subscription_currency.dart';
// import '../services/sync_service.dart'; // Removed cyclic dependency

class DbService {
  static const _startupMaintenanceVersion = 1;
  static const _startupMaintenanceVersionKey = 'db_startup_maintenance_version';

  static List<CollectionSchema<dynamic>> get schemas => [
    WorkLogSchema,
    SubscriptionSchema,
    PhotoItemSchema,
    ExpenseEvidenceSchema,
    ExpenseRecordSchema,
    ProjectSchema,
    LocalDataMigrationBatchSchema,
    EvidenceAttachmentSchema,
    SyncConflictRecordSchema,
    SyncQueueRecordSchema,
  ];

  late Isar isar; // 数据库实例
  late IsarDatabase database;
  late WorkLogDao _workLogDao;
  late SubscriptionDao _subscriptionDao;
  late ProjectDao _projectDao;
  late ExpenseRecordDao _expenseRecordDao;
  late EvidenceDao _evidenceDao;
  bool _isInitialized = false;
  Future<void>? _startupMaintenanceInFlight;
  bool _restoringDatabase = false;
  int _databaseGeneration = 0;
  final Set<Future<void>> _activeWrites = {};

  // In-flight network operations cannot survive a process restart. An in-memory
  // epoch therefore catches edit/revert races without changing the Isar schema.
  static final Expando<int> _snapshotMutationEpoch = Expando<int>();
  final Map<String, int> _mutationEpochs = {};

  static T _copySnapshotEpoch<T extends Object>(T copy, Object source) {
    _snapshotMutationEpoch[copy] = _snapshotMutationEpoch[source] ?? 0;
    return copy;
  }

  T _tagMutationEpoch<T extends Object>(String collection, int id, T row) {
    _snapshotMutationEpoch[row] = _mutationEpochs['$collection:$id'] ?? 0;
    return row;
  }

  void _recordMutation(String collection, int id, Object row) {
    final key = '$collection:$id';
    _mutationEpochs[key] = (_mutationEpochs[key] ?? 0) + 1;
    _snapshotMutationEpoch[row] = _mutationEpochs[key];
  }

  bool _hasSameMutationEpoch(String collection, int id, Object sent) =>
      (_snapshotMutationEpoch[sent] ?? 0) ==
      (_mutationEpochs['$collection:$id'] ?? 0);

  int get databaseGeneration => _databaseGeneration;

  int mutationRevisionForSyncEntity(String entityName, int id) {
    final collection = switch (entityName) {
      'work_log' => 'workLogs',
      'subscription' => 'subscriptions',
      'project' => 'projects',
      'expense_record' => 'expenseRecords',
      'evidence' => 'expenseEvidences',
      _ => throw ArgumentError.value(entityName, 'entityName'),
    };
    return _mutationEpochs['$collection:$id'] ?? 0;
  }

  Future<T> _writeTxn<T>(Future<T> Function() callback) {
    if (_restoringDatabase) {
      throw StateError('Database restore is in progress');
    }
    final completion = Completer<void>();
    _activeWrites.add(completion.future);
    return database.writeTxn(callback).whenComplete(() {
      _activeWrites.remove(completion.future);
      completion.complete();
    });
  }

  Future<void> prepareForDatabaseRestore() async {
    _restoringDatabase = true;
    _databaseGeneration++;
    await Future.wait(_activeWrites.toList());
    final maintenance = _startupMaintenanceInFlight;
    if (maintenance != null) {
      try {
        await maintenance;
      } catch (_) {
        // A maintenance stage blocked by the restore gate can retry later.
      }
    }
    await database.prepareForRestore();
  }

  Future<void> reopenAfterRestore() async {
    final opened = await IsarDatabase.open(
      schemas: schemas,
      directory:
          database.directory ??
          (throw StateError('Database directory missing')),
      name: database.name,
    );
    database.rebind(opened.isar);
    isar = opened.isar;
  }

  void finishDatabaseRestore() {
    database.finishRestore();
    _restoringDatabase = false;
  }

  void _checkSyncContext(
    SyncRunContext? context,
    String? owner,
    int generation,
  ) {
    context?.checkCurrent();
    if (_restoringDatabase ||
        generation != databaseGeneration ||
        owner != currentOwnerUserId) {
      throw const SyncRunInvalidated();
    }
  }

  Future<T> _syncWrite<T>(
    SyncRunContext? context,
    Future<T> Function(String? owner) callback,
  ) {
    final owner = context?.ownerId ?? currentOwnerUserId;
    final generation = databaseGeneration;
    _checkSyncContext(context, owner, generation);
    return _writeTxn(() async {
      _checkSyncContext(context, owner, generation);
      final result = await callback(owner);
      // Throwing here rolls back the transaction if auth changed during I/O.
      _checkSyncContext(context, owner, generation);
      return result;
    });
  }

  Future<List<T>> _preparePendingSyncRows<T extends Object>({
    required SyncRunContext? context,
    required String entityName,
    required String mutationCollection,
    required IsarCollection<T> collection,
    required Future<List<T>> Function(String? owner) readRows,
    required int Function(T row) idOf,
    required String? Function(T row) syncIdOf,
    required void Function(T row, String syncId) assignSyncId,
  }) {
    return _syncWrite(context, (owner) async {
      final rows = await readRows(owner);
      for (final row in rows) {
        final syncId = ensureSyncId(syncIdOf(row));
        if (syncId != syncIdOf(row)) {
          // Persist legacy identity before any request can leave the device.
          // This changes no business fields or dirty/audit state.
          assignSyncId(row, syncId);
          await collection.put(row);
        }
        if (owner != null) {
          await _migrateLocalRetryKey(
            owner: owner,
            entityName: entityName,
            localId: idOf(row),
            syncId: syncId,
          );
        }
      }
      return rows
          .map((row) => _tagMutationEpoch(mutationCollection, idOf(row), row))
          .toList();
    });
  }

  Future<void> _migrateLocalRetryKey({
    required String owner,
    required String entityName,
    required int localId,
    required String syncId,
  }) async {
    final previousKey = ownerScopedSyncEntityKey(
      ownerId: owner,
      syncId: null,
      localId: localId,
    );
    final nextKey = ownerScopedSyncEntityKey(
      ownerId: owner,
      syncId: syncId,
      localId: localId,
    );
    final previous = await isar.syncQueueRecords
        .filter()
        .entityNameEqualTo(entityName)
        .entityKeyEqualTo(previousKey)
        .findAll();
    if (previous.isEmpty) return;
    final existing = await isar.syncQueueRecords
        .filter()
        .entityNameEqualTo(entityName)
        .entityKeyEqualTo(nextKey)
        .findAll();
    final target = existing.isEmpty ? previous.first : existing.first;
    final records = [...existing, ...previous];
    for (final record in records) {
      if (record.attemptCount > target.attemptCount) {
        target.attemptCount = record.attemptCount;
      }
      if (record.nextAttemptAt.isAfter(target.nextAttemptAt)) {
        target.nextAttemptAt = record.nextAttemptAt;
      }
      final lastAttempt = record.lastAttemptAt;
      if (lastAttempt != null &&
          (target.lastAttemptAt == null ||
              lastAttempt.isAfter(target.lastAttemptAt!))) {
        target.lastAttemptAt = lastAttempt;
        target.lastError = record.lastError;
      }
    }
    target.entityKey = nextKey;
    await isar.syncQueueRecords.put(target);
    await isar.syncQueueRecords.deleteAll(
      records.where((row) => row.id != target.id).map((row) => row.id).toList(),
    );
  }

  T? _firstForOwner<T>(
    Iterable<T> items,
    String? Function(T item) ownerUserIdOf,
    String? owner,
  ) {
    for (final item in items) {
      if (ownerUserIdOf(item) == owner) return item;
    }
    return null;
  }

  bool _remoteRowAllowed(Map<String, dynamic> row, SyncRunContext? context) {
    if (context != null) return context.ownsRemoteRow(row);
    final remoteOwner = _parseRemoteString(row['user_id']);
    return remoteOwner == null || remoteOwner == currentOwnerUserId;
  }

  static WorkLog snapshotWorkLog(WorkLog source) => _copySnapshotEpoch(
    WorkLog()
      ..id = source.id
      ..ownerUserId = source.ownerUserId
      ..remoteId = source.remoteId
      ..syncId = source.syncId
      ..remoteVersion = source.remoteVersion
      ..remoteUpdatedAt = source.remoteUpdatedAt
      ..syncedAt = source.syncedAt
      ..isDirty = source.isDirty
      ..deletedAt = source.deletedAt
      ..pendingDelete = source.pendingDelete
      ..date = source.date
      ..type = source.type
      ..overtimeHours = source.overtimeHours
      ..location = source.location
      ..transport = source.transport
      ..expenses = source.expenses
      ..projectId = source.projectId
      ..projectSyncId = source.projectSyncId
      ..projectName = source.projectName
      ..projectStageName = source.projectStageName
      ..isReimbursed = source.isReimbursed
      ..note = source.note
      ..createdAt = source.createdAt
      ..updatedAt = source.updatedAt,
    source,
  );

  static Subscription snapshotSubscription(Subscription source) =>
      _copySnapshotEpoch(
        Subscription()
          ..id = source.id
          ..ownerUserId = source.ownerUserId
          ..remoteId = source.remoteId
          ..syncId = source.syncId
          ..remoteVersion = source.remoteVersion
          ..remoteUpdatedAt = source.remoteUpdatedAt
          ..syncedAt = source.syncedAt
          ..isDirty = source.isDirty
          ..deletedAt = source.deletedAt
          ..pendingDelete = source.pendingDelete
          ..name = source.name
          ..price = source.price
          ..currency = source.currency
          ..cycle = source.cycle
          ..nextPaymentDate = source.nextPaymentDate
          ..anchorDate = source.anchorDate
          ..endDate = source.endDate
          ..status = source.status
          ..reminderDays = source.reminderDays
          ..note = source.note
          ..sortIndex = source.sortIndex,
        source,
      );

  static Project snapshotProject(Project source) => _copySnapshotEpoch(
    Project()
      ..id = source.id
      ..ownerUserId = source.ownerUserId
      ..remoteId = source.remoteId
      ..syncId = source.syncId
      ..remoteVersion = source.remoteVersion
      ..remoteUpdatedAt = source.remoteUpdatedAt
      ..syncedAt = source.syncedAt
      ..isDirty = source.isDirty
      ..deletedAt = source.deletedAt
      ..pendingDelete = source.pendingDelete
      ..name = source.name
      ..status = source.status
      ..createdAt = source.createdAt
      ..updatedAt = source.updatedAt
      ..localCoverPath = source.localCoverPath
      ..coverImagePath = source.coverImagePath
      ..stageNames = List<String>.of(source.stageNames),
    source,
  );

  static ExpenseRecord snapshotExpenseRecord(ExpenseRecord source) =>
      _copySnapshotEpoch(
        ExpenseRecord()
          ..id = source.id
          ..ownerUserId = source.ownerUserId
          ..remoteId = source.remoteId
          ..syncId = source.syncId
          ..remoteVersion = source.remoteVersion
          ..remoteUpdatedAt = source.remoteUpdatedAt
          ..syncedAt = source.syncedAt
          ..isDirty = source.isDirty
          ..deletedAt = source.deletedAt
          ..pendingDelete = source.pendingDelete
          ..expenseDate = source.expenseDate
          ..amount = source.amount
          ..currency = source.currency
          ..category = source.category
          ..merchant = source.merchant
          ..note = source.note
          ..projectId = source.projectId
          ..projectSyncId = source.projectSyncId
          ..projectName = source.projectName
          ..projectStageName = source.projectStageName
          ..tripWorkLogId = source.tripWorkLogId
          ..tripWorkLogSyncId = source.tripWorkLogSyncId
          ..createdAt = source.createdAt
          ..updatedAt = source.updatedAt,
        source,
      );

  static ExpenseEvidence snapshotEvidence(ExpenseEvidence source) =>
      _copySnapshotEpoch(
        ExpenseEvidence()
          ..id = source.id
          ..ownerUserId = source.ownerUserId
          ..remoteId = source.remoteId
          ..syncId = source.syncId
          ..remoteVersion = source.remoteVersion
          ..remoteUpdatedAt = source.remoteUpdatedAt
          ..syncedAt = source.syncedAt
          ..isDirty = source.isDirty
          ..deletedAt = source.deletedAt
          ..pendingDelete = source.pendingDelete
          ..projectName = source.projectName
          ..projectId = source.projectId
          ..projectSyncId = source.projectSyncId
          ..projectStageName = source.projectStageName
          ..evidenceDate = source.evidenceDate
          ..amount = source.amount
          ..currency = source.currency
          ..category = source.category
          ..status = source.status
          ..merchant = source.merchant
          ..note = source.note
          ..localFilePath = source.localFilePath
          ..remoteStoragePath = source.remoteStoragePath
          ..fileName = source.fileName
          ..mimeType = source.mimeType
          ..uploadedAt = source.uploadedAt
          ..tripDate = source.tripDate
          ..createdAt = source.createdAt
          ..updatedAt = source.updatedAt,
        source,
      );

  String? get currentOwnerUserId => serviceLocator.isRegistered<AuthService>()
      ? serviceLocator<AuthService>().userId
      : null;

  bool _isNewRecordId(Id id) => id == Isar.autoIncrement || id == 0;

  Id _normalizeNewRecordId(Id id) {
    return id == 0 ? Isar.autoIncrement : id;
  }

  bool _belongsToCurrentUser(String? ownerUserId) {
    final currentUserId = currentOwnerUserId;
    return currentUserId == null
        ? ownerUserId == null
        : ownerUserId == currentUserId;
  }

  T? _firstForCurrentOwner<T>(
    Iterable<T> items,
    String? Function(T item) ownerUserIdOf,
  ) {
    for (final item in items) {
      if (_belongsToCurrentUser(ownerUserIdOf(item))) return item;
    }
    return null;
  }

  bool _isVisibleToCurrentUser(String? ownerUserId) {
    final currentUserId = currentOwnerUserId;
    return currentUserId == null
        ? ownerUserId == null
        : ownerUserId == null || ownerUserId == currentUserId;
  }

  void _stampWorkLogOwner(WorkLog log, WorkLog? existing) {
    log.ownerUserId ??= existing?.ownerUserId ?? currentOwnerUserId;
  }

  void _preserveWorkLogSyncIdentity(WorkLog log, WorkLog? existing) {
    if (existing == null) return;
    log.remoteId = existing.remoteId ?? log.remoteId;
    log.syncId = existing.syncId ?? log.syncId;
    log.remoteVersion = existing.remoteVersion;
    log.remoteUpdatedAt = existing.remoteUpdatedAt;
    log.syncedAt = existing.syncedAt;
    log.pendingDelete = log.pendingDelete || existing.pendingDelete;
    log.deletedAt ??= existing.deletedAt;
  }

  void _stampSubscriptionOwner(Subscription sub, Subscription? existing) {
    sub.ownerUserId ??= existing?.ownerUserId ?? currentOwnerUserId;
  }

  void _preserveSubscriptionSyncIdentity(
    Subscription sub,
    Subscription? existing,
  ) {
    if (existing == null) return;
    sub.remoteId = existing.remoteId ?? sub.remoteId;
    sub.syncId = existing.syncId ?? sub.syncId;
    sub.remoteVersion = existing.remoteVersion;
    sub.remoteUpdatedAt = existing.remoteUpdatedAt;
    sub.syncedAt = existing.syncedAt;
    sub.pendingDelete = sub.pendingDelete || existing.pendingDelete;
    sub.deletedAt ??= existing.deletedAt;
  }

  void _stampEvidenceOwner(
    ExpenseEvidence evidence,
    ExpenseEvidence? existing,
  ) {
    evidence.ownerUserId ??= existing?.ownerUserId ?? currentOwnerUserId;
  }

  void _preserveEvidenceSyncIdentity(
    ExpenseEvidence evidence,
    ExpenseEvidence? existing,
  ) {
    if (existing == null) return;
    evidence.remoteId = existing.remoteId ?? evidence.remoteId;
    evidence.syncId = existing.syncId ?? evidence.syncId;
    evidence.remoteVersion = existing.remoteVersion;
    evidence.remoteUpdatedAt = existing.remoteUpdatedAt;
    evidence.syncedAt = existing.syncedAt;
    evidence.pendingDelete = evidence.pendingDelete || existing.pendingDelete;
    evidence.deletedAt ??= existing.deletedAt;
  }

  void _stampExpenseRecordOwner(ExpenseRecord record, ExpenseRecord? existing) {
    record.ownerUserId ??= existing?.ownerUserId ?? currentOwnerUserId;
  }

  void _preserveExpenseRecordSyncIdentity(
    ExpenseRecord record,
    ExpenseRecord? existing,
  ) {
    if (existing == null) return;
    record.remoteId = existing.remoteId ?? record.remoteId;
    record.syncId = existing.syncId ?? record.syncId;
    record.remoteVersion = existing.remoteVersion;
    record.remoteUpdatedAt = existing.remoteUpdatedAt;
    record.syncedAt = existing.syncedAt;
    record.pendingDelete = record.pendingDelete || existing.pendingDelete;
    record.deletedAt ??= existing.deletedAt;
  }

  void _stampPhotoOwner(PhotoItem photo) {
    photo.ownerUserId ??= currentOwnerUserId;
  }

  void _stampProjectOwner(Project project, Project? existing) {
    project.ownerUserId ??= existing?.ownerUserId ?? currentOwnerUserId;
  }

  void _preserveProjectSyncIdentity(Project project, Project? existing) {
    if (existing == null) return;
    project.remoteId = existing.remoteId ?? project.remoteId;
    project.syncId = existing.syncId ?? project.syncId;
    project.remoteVersion = existing.remoteVersion;
    project.remoteUpdatedAt = existing.remoteUpdatedAt;
    project.syncedAt = existing.syncedAt;
    project.pendingDelete = project.pendingDelete || existing.pendingDelete;
    project.deletedAt ??= existing.deletedAt;
  }

  DateTime _parseRemoteDateTime(dynamic value, {DateTime? fallback}) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ??
          fallback ??
          DateTime.now().toUtc();
    }
    return fallback ?? DateTime.now().toUtc();
  }

  DateTime _parseRemoteDateOnly(dynamic value, {DateTime? fallback}) {
    if (value is DateTime) return dateOnlyLocal(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return dateOnlyLocal(parsed);
      return fallback == null ? DateTime.now() : dateOnlyLocal(fallback);
    }
    return fallback == null ? DateTime.now() : dateOnlyLocal(fallback);
  }

  double _parseRemoteDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int? _parseRemoteInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _parseRemoteString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  List<String> _parseRemoteStringList(dynamic value) {
    if (value is Iterable) {
      return _normalizeStringList(value.map((item) => item.toString()));
    }
    if (value is String) {
      return _normalizeStringList(value.split(','));
    }
    return const <String>[];
  }

  List<String> _normalizeStringList(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) result.add(trimmed);
    }
    return result;
  }

  String? _normalizeOptionalString(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  bool _parseRemoteBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  void _stampWorkLogAudit(WorkLog log, WorkLog? existing) {
    final now = DateTime.now().toUtc();
    log.createdAt ??= existing?.createdAt ?? now;
    final businessChanged =
        existing == null || log.hasBusinessChangesComparedTo(existing);
    log.updatedAt = businessChanged ? now : (existing.updatedAt ?? now);
  }

  void _stampEvidenceAudit(
    ExpenseEvidence evidence,
    ExpenseEvidence? existing,
  ) {
    final now = DateTime.now().toUtc();
    evidence.createdAt ??= existing?.createdAt ?? now;
    final businessChanged =
        existing == null || evidence.hasBusinessChangesComparedTo(existing);
    evidence.updatedAt = businessChanged ? now : (existing.updatedAt ?? now);
  }

  void _stampExpenseRecordAudit(ExpenseRecord record, ExpenseRecord? existing) {
    final now = DateTime.now().toUtc();
    record.createdAt ??= existing?.createdAt ?? now;
    final businessChanged =
        existing == null || record.hasBusinessChangesComparedTo(existing);
    record.updatedAt = businessChanged ? now : (existing.updatedAt ?? now);
  }

  bool _isProjectSyncEligible(Project project) {
    return project.remoteId != null ||
        project.syncId != null ||
        project.pendingDelete;
  }

  bool _belongsToOwner(String? recordOwnerUserId, String ownerUserId) {
    return recordOwnerUserId == ownerUserId;
  }

  Future<Set<String>> _getSyncableProjectNames({String? ownerUserId}) async {
    final syncableProjectNames = <String>{};

    final evidenceRefs = await isar.expenseEvidences.where().findAll();
    for (final item in evidenceRefs) {
      final belongs = ownerUserId == null
          ? _belongsToCurrentUser(item.ownerUserId)
          : _belongsToOwner(item.ownerUserId, ownerUserId);
      if (belongs && item.projectName.trim().isNotEmpty) {
        syncableProjectNames.add(item.projectName.trim().toLowerCase());
      }
    }

    final expenseRecordRefs = await isar.expenseRecords.where().findAll();
    for (final item in expenseRecordRefs) {
      final belongs = ownerUserId == null
          ? _belongsToCurrentUser(item.ownerUserId)
          : _belongsToOwner(item.ownerUserId, ownerUserId);
      if (belongs && (item.projectName?.trim().isNotEmpty ?? false)) {
        syncableProjectNames.add(item.projectName!.trim().toLowerCase());
      }
    }

    return syncableProjectNames;
  }

  Future<void> claimUnownedRecordsForCurrentUser() async {
    final currentUserId = currentOwnerUserId;
    if (currentUserId == null) return;
    await _claimUnownedRecordsForOwner(currentUserId);
  }

  Future<LocalDataMigrationSummary> countUnownedRecords() async {
    final logs = await isar.workLogs.filter().ownerUserIdIsNull().count();
    final subs = await isar.subscriptions.filter().ownerUserIdIsNull().count();
    final evidence = await isar.expenseEvidences
        .filter()
        .ownerUserIdIsNull()
        .count();
    final expenseRecords = await isar.expenseRecords
        .filter()
        .ownerUserIdIsNull()
        .count();
    final projects = await isar.projects.filter().ownerUserIdIsNull().count();
    final photos = await isar.photoItems.filter().ownerUserIdIsNull().count();

    return LocalDataMigrationSummary(
      workLogs: logs,
      subscriptions: subs,
      evidence: evidence,
      expenseRecords: expenseRecords,
      projects: projects,
      photos: photos,
    );
  }

  Future<void> deleteUnownedRecords() async {
    await _writeTxn(() async {
      final logs = await isar.workLogs.filter().ownerUserIdIsNull().findAll();
      await isar.workLogs.deleteAll(logs.map((item) => item.id).toList());

      final subs = await isar.subscriptions
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      await isar.subscriptions.deleteAll(subs.map((item) => item.id).toList());

      final evidence = await isar.expenseEvidences
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      await isar.expenseEvidences.deleteAll(
        evidence.map((item) => item.id).toList(),
      );

      final evidenceAttachments = await isar.evidenceAttachments
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      await isar.evidenceAttachments.deleteAll(
        evidenceAttachments.map((item) => item.id).toList(),
      );

      final expenseRecords = await isar.expenseRecords
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      await isar.expenseRecords.deleteAll(
        expenseRecords.map((item) => item.id).toList(),
      );

      final photos = await isar.photoItems
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      await isar.photoItems.deleteAll(photos.map((item) => item.id).toList());

      final projects = await isar.projects
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      await isar.projects.deleteAll(projects.map((item) => item.id).toList());
    });
  }

  Future<int> startLocalDataMigrationBatch({
    required String toUserId,
    required int recordCount,
    String? fromOwner,
  }) async {
    final now = DateTime.now().toUtc();
    final batch = LocalDataMigrationBatch()
      ..fromOwner = fromOwner
      ..toUserId = toUserId
      ..recordCount = recordCount
      ..startedAt = now
      ..status = 'started';
    return _writeTxn(() => isar.localDataMigrationBatchs.put(batch));
  }

  Future<void> completeLocalDataMigrationBatch(int id) async {
    await _writeTxn(() async {
      final batch = await isar.localDataMigrationBatchs.get(id);
      if (batch == null) return;
      batch.completedAt = DateTime.now().toUtc();
      batch.status = 'completed';
      await isar.localDataMigrationBatchs.put(batch);
    });
  }

  Future<void> failLocalDataMigrationBatch(int id) async {
    await _writeTxn(() async {
      final batch = await isar.localDataMigrationBatchs.get(id);
      if (batch == null) return;
      batch.completedAt = DateTime.now().toUtc();
      batch.status = 'failed';
      await isar.localDataMigrationBatchs.put(batch);
    });
  }

  @visibleForTesting
  Future<void> claimUnownedRecordsForOwnerForTest(String ownerUserId) {
    return _claimUnownedRecordsForOwner(ownerUserId);
  }

  Future<void> _claimUnownedRecordsForOwner(String ownerUserId) async {
    await _writeTxn(() async {
      final logs = await isar.workLogs.filter().ownerUserIdIsNull().findAll();
      for (final log in logs) {
        log.ownerUserId = ownerUserId;
        log.isDirty = true;
      }
      if (logs.isNotEmpty) {
        await isar.workLogs.putAll(logs);
      }

      final subs = await isar.subscriptions
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      for (final sub in subs) {
        sub.ownerUserId = ownerUserId;
        sub.isDirty = true;
      }
      if (subs.isNotEmpty) {
        await isar.subscriptions.putAll(subs);
      }

      final evidence = await isar.expenseEvidences
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      for (final item in evidence) {
        item.ownerUserId = ownerUserId;
        item.isDirty = true;
      }
      if (evidence.isNotEmpty) {
        await isar.expenseEvidences.putAll(evidence);
      }

      final evidenceAttachments = await isar.evidenceAttachments
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      for (final item in evidenceAttachments) {
        item.ownerUserId = ownerUserId;
        item.uploadState = EvidenceAttachmentUploadState.pending;
        item.updatedAt = DateTime.now().toUtc();
      }
      if (evidenceAttachments.isNotEmpty) {
        await isar.evidenceAttachments.putAll(evidenceAttachments);
      }

      final expenseRecords = await isar.expenseRecords
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      for (final item in expenseRecords) {
        item.ownerUserId = ownerUserId;
        item.isDirty = true;
      }
      if (expenseRecords.isNotEmpty) {
        await isar.expenseRecords.putAll(expenseRecords);
      }

      final photos = await isar.photoItems
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      for (final photo in photos) {
        photo.ownerUserId = ownerUserId;
      }
      if (photos.isNotEmpty) {
        await isar.photoItems.putAll(photos);
      }

      final syncableProjectNames = await _getSyncableProjectNames(
        ownerUserId: ownerUserId,
      );

      final projects = await isar.projects
          .filter()
          .ownerUserIdIsNull()
          .findAll();
      for (final project in projects) {
        project.ownerUserId = ownerUserId;
        final syncable = syncableProjectNames.contains(
          project.name.trim().toLowerCase(),
        );
        if (syncable || _isProjectSyncEligible(project)) {
          project.syncId = ensureSyncId(project.syncId);
          project.isDirty = true;
        }
      }
      if (projects.isNotEmpty) {
        await isar.projects.putAll(projects);
      }
    });
  }

  // --- 1. 初始化数据库 (开门) ---
  Future<DbService> init({bool runStartupMaintenance = false}) async {
    // 获取手机里专门存文档的路径
    final dir = await getApplicationDocumentsDirectory();

    // 打开数据库
    final openedDatabase = await IsarDatabase.open(
      schemas: schemas,
      directory: dir.path,
    );
    _bindDatabase(openedDatabase);

    if (runStartupMaintenance) {
      await this.runStartupMaintenance(force: true);
    }

    _isInitialized = true;
    return this;
  }

  @visibleForTesting
  Future<DbService> initWithDatabaseForTest(
    IsarDatabase openedDatabase, {
    bool runBackfills = true,
  }) async {
    _bindDatabase(openedDatabase);
    if (runBackfills) {
      await _backfillRecordAuditTimestamps();
    }
    _isInitialized = true;
    return this;
  }

  void _bindDatabase(IsarDatabase openedDatabase) {
    if (_isInitialized) {
      database.rebind(openedDatabase.isar);
    } else {
      database = openedDatabase;
    }
    isar = openedDatabase.isar;
    _workLogDao = WorkLogDao(database);
    _subscriptionDao = SubscriptionDao(database);
    _projectDao = ProjectDao(database);
    _expenseRecordDao = ExpenseRecordDao(database);
    _evidenceDao = EvidenceDao(database);
  }

  Future<void> runStartupMaintenance({bool force = false}) {
    final active = _startupMaintenanceInFlight;
    if (active != null) return active;

    late final Future<void> maintenance;
    maintenance = _runStartupMaintenance(force: force).whenComplete(() {
      if (identical(_startupMaintenanceInFlight, maintenance)) {
        _startupMaintenanceInFlight = null;
      }
    });
    _startupMaintenanceInFlight = maintenance;
    return maintenance;
  }

  Future<void> _runStartupMaintenance({required bool force}) async {
    final storage = GetStorage();
    final completedVersion = storage.read(_startupMaintenanceVersionKey);
    if (!force && completedVersion == _startupMaintenanceVersion) return;

    await _backfillRecordAuditTimestamps();
    await storage.write(
      _startupMaintenanceVersionKey,
      _startupMaintenanceVersion,
    );
  }

  Future<void> _backfillRecordAuditTimestamps() async {
    await _writeTxn(() async {
      final logs = await isar.workLogs.filter().createdAtIsNull().findAll();
      for (final log in logs) {
        final fallback = log.deletedAt ?? log.date.toUtc();
        log.createdAt = fallback;
        log.updatedAt ??= fallback;
      }
      if (logs.isNotEmpty) {
        await isar.workLogs.putAll(logs);
      }

      final evidence = await isar.expenseEvidences
          .filter()
          .createdAtIsNull()
          .findAll();
      for (final item in evidence) {
        final fallback = item.deletedAt ?? item.evidenceDate.toUtc();
        item.createdAt = fallback;
        item.updatedAt ??= fallback;
      }
      if (evidence.isNotEmpty) {
        await isar.expenseEvidences.putAll(evidence);
      }

      final expenseRecords = await isar.expenseRecords
          .filter()
          .createdAtIsNull()
          .findAll();
      for (final record in expenseRecords) {
        final fallback = record.deletedAt ?? record.expenseDate.toUtc();
        record.createdAt = fallback;
        record.updatedAt ??= fallback;
      }
      if (expenseRecords.isNotEmpty) {
        await isar.expenseRecords.putAll(expenseRecords);
      }
    });
    await _normalizeDateOnlyFields();
  }

  Future<void> _normalizeDateOnlyFields() async {
    await _writeTxn(() async {
      final logs = await isar.workLogs.where().findAll();
      for (final log in logs) {
        log.date = dateOnlyLocal(log.date);
      }
      if (logs.isNotEmpty) {
        await isar.workLogs.putAll(logs);
      }

      final subs = await isar.subscriptions.where().findAll();
      for (final sub in subs) {
        sub.nextPaymentDate = dateOnlyLocal(sub.nextPaymentDate);
      }
      if (subs.isNotEmpty) {
        await isar.subscriptions.putAll(subs);
      }

      final evidence = await isar.expenseEvidences.where().findAll();
      for (final item in evidence) {
        item.evidenceDate = dateOnlyLocal(item.evidenceDate);
        if (item.tripDate != null) {
          item.tripDate = dateOnlyLocal(item.tripDate!);
        }
      }
      if (evidence.isNotEmpty) {
        await isar.expenseEvidences.putAll(evidence);
      }

      final records = await isar.expenseRecords.where().findAll();
      for (final record in records) {
        record.expenseDate = dateOnlyLocal(record.expenseDate);
      }
      if (records.isNotEmpty) {
        await isar.expenseRecords.putAll(records);
      }
    });
  }

  void dispose() {
    if (_isInitialized && isar.isOpen) {
      isar.close();
    }
  }

  // --- 2. 增加一条日志 (入库) ---
  Future<int> addLog(WorkLog log) async {
    final id = await _writeTxn(() async {
      log.id = _normalizeNewRecordId(log.id);
      final existing = _isNewRecordId(log.id)
          ? null
          : await isar.workLogs.get(log.id);
      _stampWorkLogOwner(log, existing);
      _preserveWorkLogSyncIdentity(log, existing);
      _stampWorkLogAudit(log, existing);
      log.isDirty =
          existing?.isDirty == true ||
          log.isDirty ||
          log.remoteId == null ||
          (existing != null && log.hasBusinessChangesComparedTo(existing));
      final savedId = await isar.workLogs.put(log);
      _recordMutation('workLogs', savedId, log);
      return savedId;
    });
    return id;
  }

  // --- 3. 查询某个月的日志 (盘点) ---
  Future<List<WorkLog>> getLogsByMonth(DateTime month) async {
    return _workLogDao.getActiveByMonthForOwner(month, currentOwnerUserId);
  }

  // --- 【新增】4. 获取所有日志 (供日历初始化使用) ---
  Future<List<WorkLog>> getAllLogs() async {
    return _workLogDao.getActiveSortedForOwner(currentOwnerUserId);
  }

  Future<List<WorkLog>> getLogsForDay(DateTime date) async {
    return _workLogDao.getActiveByDayForOwner(date, currentOwnerUserId);
  }

  Future<List<WorkLog>> getAllLogsForSync() async {
    final logs = await _workLogDao.getAllForSync();
    return logs.where((log) => _belongsToCurrentUser(log.ownerUserId)).toList();
  }

  Future<List<WorkLog>> getPendingLogsForSync({SyncRunContext? context}) {
    return _preparePendingSyncRows(
      context: context,
      entityName: 'work_log',
      mutationCollection: 'workLogs',
      collection: isar.workLogs,
      readRows: (owner) => _workLogDao.getPendingForSyncForOwner(owner),
      idOf: (row) => row.id,
      syncIdOf: (row) => row.syncId,
      assignSyncId: (row, syncId) => row.syncId = syncId,
    );
  }

  // --- 5. 获取单条记录 (供 Repository 查询使用) ---
  Future<WorkLog?> getWorkLog(int id) async {
    final log = await _workLogDao.getById(id);
    if (log == null || !_isVisibleToCurrentUser(log.ownerUserId)) return null;
    return _tagMutationEpoch<WorkLog>('workLogs', log.id, log);
  }

  // 获取日志变更流
  Stream<void> watchWorkLogs() => _workLogDao.watch();

  // --- 5. 删除日志 (出库) ---
  Future<void> deleteLog(int id) async {
    await _workLogDao.delete(id);
  }

  Future<WorkLog?> markLogDeleted(int id) async {
    return await _writeTxn(() async {
      final log = await isar.workLogs.get(id);
      if (log == null) return null;
      if (!_isVisibleToCurrentUser(log.ownerUserId)) return null;
      log.deletedAt = DateTime.now().toUtc();
      log.updatedAt = log.deletedAt;
      log.pendingDelete = true;
      log.isDirty = true;
      await isar.workLogs.put(log);
      _recordMutation('workLogs', log.id, log);
      return log;
    });
  }

  Future<void> purgeDeletedLog(
    int id, {
    SyncRunContext? context,
    WorkLog? sentSnapshot,
  }) async {
    await _syncWrite(context, (owner) async {
      final live = await isar.workLogs.get(id);
      if (live == null || live.ownerUserId != owner) return;
      if (sentSnapshot != null &&
          (!_hasSameMutationEpoch('workLogs', live.id, sentSnapshot) ||
              !live.pendingDelete ||
              live.deletedAt != sentSnapshot.deletedAt ||
              live.hasBusinessChangesComparedTo(sentSnapshot))) {
        return;
      }
      await isar.workLogs.delete(id);
    });
  }

  // --- 订阅管理相关 ---

  // 1. 获取所有订阅 (按下次付款时间排序)
  Future<List<Subscription>> getAllSubscriptions() async {
    return _subscriptionDao.getActiveSortedForOwner(currentOwnerUserId);
  }

  Future<List<Subscription>> getAllSubscriptionsForSync() async {
    final subs = await _subscriptionDao.getAllForSync();
    return subs.where((sub) => _belongsToCurrentUser(sub.ownerUserId)).toList();
  }

  Future<List<Subscription>> getPendingSubscriptionsForSync({
    SyncRunContext? context,
  }) {
    return _preparePendingSyncRows(
      context: context,
      entityName: 'subscription',
      mutationCollection: 'subscriptions',
      collection: isar.subscriptions,
      readRows: (owner) => _subscriptionDao.getPendingForSyncForOwner(owner),
      idOf: (row) => row.id,
      syncIdOf: (row) => row.syncId,
      assignSyncId: (row, syncId) => row.syncId = syncId,
    );
  }

  // 2. 获取单条订阅
  Future<Subscription?> getSubscription(int id) async {
    final sub = await _subscriptionDao.getById(id);
    if (sub == null || !_isVisibleToCurrentUser(sub.ownerUserId)) return null;
    return _tagMutationEpoch<Subscription>('subscriptions', sub.id, sub);
  }

  // 获取订阅变更流
  Stream<void> watchSubscriptions() => _subscriptionDao.watch();

  // 2. 添加/修改订阅
  Future<int> addSubscription(Subscription sub) async {
    final id = await _writeTxn(() async {
      sub.id = _normalizeNewRecordId(sub.id);
      final existing = _isNewRecordId(sub.id)
          ? null
          : await isar.subscriptions.get(sub.id);
      _stampSubscriptionOwner(sub, existing);
      _preserveSubscriptionSyncIdentity(sub, existing);
      sub.isDirty =
          existing?.isDirty == true ||
          sub.isDirty ||
          sub.remoteId == null ||
          (existing != null && sub.hasBusinessChangesComparedTo(existing));
      final savedId = await isar.subscriptions.put(sub);
      _recordMutation('subscriptions', savedId, sub);
      return savedId;
    });
    return id;
  }

  // 3. 删除订阅
  Future<void> deleteSubscription(int id) async {
    await _subscriptionDao.delete(id);
  }

  Future<Subscription?> markSubscriptionDeleted(int id) async {
    return await _writeTxn(() async {
      final sub = await isar.subscriptions.get(id);
      if (sub == null) return null;
      if (!_isVisibleToCurrentUser(sub.ownerUserId)) return null;
      sub.deletedAt = DateTime.now().toUtc();
      sub.pendingDelete = true;
      sub.isDirty = true;
      await isar.subscriptions.put(sub);
      _recordMutation('subscriptions', sub.id, sub);
      return sub;
    });
  }

  Future<void> purgeDeletedSubscription(
    int id, {
    SyncRunContext? context,
    Subscription? sentSnapshot,
  }) async {
    await _syncWrite(context, (owner) async {
      final live = await isar.subscriptions.get(id);
      if (live == null || live.ownerUserId != owner) return;
      if (sentSnapshot != null &&
          (!_hasSameMutationEpoch('subscriptions', live.id, sentSnapshot) ||
              !live.pendingDelete ||
              live.deletedAt != sentSnapshot.deletedAt ||
              live.hasBusinessChangesComparedTo(sentSnapshot))) {
        return;
      }
      await isar.subscriptions.delete(id);
    });
  }

  // 4. Update Subscription Order
  Future<List<Subscription>> reorderSubscriptions(
    List<Subscription> subs,
  ) async {
    return await _writeTxn(() async {
      final changed = <Subscription>[];
      for (int i = 0; i < subs.length; i++) {
        final sub = subs[i];
        final existing = await isar.subscriptions.get(sub.id);
        _stampSubscriptionOwner(sub, existing);
        _preserveSubscriptionSyncIdentity(sub, existing);
        if (existing == null ||
            !_isVisibleToCurrentUser(existing.ownerUserId)) {
          continue;
        }
        if (existing.sortIndex == i) continue;

        sub.sortIndex = i;
        sub.isDirty = true;
        await isar.subscriptions.put(sub);
        _recordMutation('subscriptions', sub.id, sub);
        changed.add(sub);
      }
      return changed;
    });
  }

  // --- 照片系统 Photo ---

  Future<List<PhotoItem>> getAllPhotos() async {
    final photos = await isar.photoItems
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return photos
        .where((photo) => _isVisibleToCurrentUser(photo.ownerUserId))
        .toList();
  }

  Future<PhotoItem?> getPhoto(int id) async {
    final photo = await isar.photoItems.get(id);
    if (photo == null || !_isVisibleToCurrentUser(photo.ownerUserId)) {
      return null;
    }
    return photo;
  }

  // 获取照片变更流
  Stream<void> watchPhotos() =>
      database.watch((isar) => isar.photoItems.watchLazy());

  Future<void> addPhoto(PhotoItem photo) async {
    await _writeTxn(() async {
      photo.id = _normalizeNewRecordId(photo.id);
      _stampPhotoOwner(photo);
      await isar.photoItems.put(photo);
    });
  }

  Future<int> assignPhotoStage(
    List<PhotoItem> expected,
    String? stageName,
  ) => _writeTxn(() async {
    final snapshots = {for (final photo in expected) photo.id: photo};
    final photos = await isar.photoItems.getAll(snapshots.keys.toList());
    final normalized = stageName?.trim();
    final stage = normalized == null || normalized.isEmpty ? null : normalized;
    final writable = photos
        .whereType<PhotoItem>()
        .where((p) => _isVisibleToCurrentUser(p.ownerUserId))
        .toList();
    // Refuse stale/deleted selection instead of claiming the entire batch saved.
    if (writable.length != snapshots.length ||
        writable.any((photo) {
          final original = snapshots[photo.id]!;
          return photo.projectId != original.projectId ||
              (original.projectId == null &&
                  photo.projectName != original.projectName);
        })) {
      throw StateError('照片已发生变化，请刷新后重试');
    }
    for (final photo in writable) {
      photo.projectStageName = stage;
    }
    await isar.photoItems.putAll(writable);
    return writable.length;
  });

  Future<int> unlinkPhotosFromProject({
    required int projectId,
    required String projectName,
  }) async {
    final normalizedName = projectName.trim().toLowerCase();
    return await _writeTxn(() async {
      final photos = await isar.photoItems.where().findAll();
      var changed = 0;
      for (final photo in photos) {
        if (!_isVisibleToCurrentUser(photo.ownerUserId)) continue;
        final matchesId = photo.projectId == projectId;
        final matchesName =
            photo.projectName?.trim().toLowerCase() == normalizedName;
        if (!matchesId && !matchesName) continue;
        photo.projectId = null;
        photo.projectName = null;
        photo.projectStageName = null;
        await isar.photoItems.put(photo);
        changed++;
      }
      return changed;
    });
  }

  Future<void> deletePhoto(int id) async {
    await _writeTxn(() async {
      final photo = await isar.photoItems.get(id);
      if (photo == null || !_isVisibleToCurrentUser(photo.ownerUserId)) return;
      await isar.photoItems.delete(id);
    });
  }

  // --- 凭证系统 Evidence ---

  Future<List<ExpenseEvidence>> getAllEvidence() async {
    return _evidenceDao.getActiveSortedForOwner(currentOwnerUserId);
  }

  Future<List<ExpenseEvidence>> getAllEvidenceForSync() async {
    final items = await _evidenceDao.getAllSorted();
    return items
        .where((item) => _belongsToCurrentUser(item.ownerUserId))
        .toList();
  }

  Future<List<ExpenseEvidence>> getPendingEvidenceForSync({
    SyncRunContext? context,
  }) {
    return _preparePendingSyncRows(
      context: context,
      entityName: 'evidence',
      mutationCollection: 'expenseEvidences',
      collection: isar.expenseEvidences,
      readRows: (owner) => _evidenceDao.getPendingForSyncForOwner(owner),
      idOf: (row) => row.id,
      syncIdOf: (row) => row.syncId,
      assignSyncId: (row, syncId) => row.syncId = syncId,
    );
  }

  Future<ExpenseEvidence?> getEvidenceBySyncId(String syncId) async {
    final items = await isar.expenseEvidences
        .filter()
        .syncIdEqualTo(syncId)
        .findAll();
    final item = _firstForCurrentOwner(items, (item) => item.ownerUserId);
    return item;
  }

  Future<ExpenseEvidence?> getEvidence(int id) async {
    final item = await _evidenceDao.getById(id);
    if (item == null || !_isVisibleToCurrentUser(item.ownerUserId)) return null;
    return _tagMutationEpoch<ExpenseEvidence>(
      'expenseEvidences',
      item.id,
      item,
    );
  }

  Stream<void> watchEvidence() => _evidenceDao.watch();

  Future<int> addEvidence(ExpenseEvidence evidence) async {
    final hasLocalAttachment =
        evidence.localFilePath?.trim().isNotEmpty == true;
    if (hasLocalAttachment) {
      evidence.syncId = ensureSyncId(evidence.syncId);
    }
    final id = await _writeTxn(() async {
      evidence.id = _normalizeNewRecordId(evidence.id);
      final existing = _isNewRecordId(evidence.id)
          ? null
          : await isar.expenseEvidences.get(evidence.id);
      _stampEvidenceOwner(evidence, existing);
      _preserveEvidenceSyncIdentity(evidence, existing);
      _stampEvidenceAudit(evidence, existing);
      evidence.isDirty =
          existing?.isDirty == true ||
          evidence.isDirty ||
          evidence.remoteId == null ||
          (existing != null && evidence.hasBusinessChangesComparedTo(existing));
      final savedId = await isar.expenseEvidences.put(evidence);
      _recordMutation('expenseEvidences', savedId, evidence);
      return savedId;
    });
    evidence.id = id;
    if (hasLocalAttachment) {
      await ensureEvidenceAttachmentForEvidence(evidence);
    }
    return id;
  }

  Future<ExpenseEvidence?> markEvidenceDeleted(int id) async {
    return await _writeTxn(() async {
      final item = await isar.expenseEvidences.get(id);
      if (item == null) return null;
      if (!_isVisibleToCurrentUser(item.ownerUserId)) return null;
      item.deletedAt = DateTime.now().toUtc();
      item.updatedAt = item.deletedAt;
      item.pendingDelete = true;
      item.isDirty = true;
      if (item.localFilePath != null || item.remoteStoragePath != null) {
        item.syncId = ensureSyncId(item.syncId);
        await _queueEvidenceAttachmentDeleteInTxn(item);
      }
      await isar.expenseEvidences.put(item);
      _recordMutation('expenseEvidences', item.id, item);
      return item;
    });
  }

  Future<void> purgeDeletedEvidence(
    int id, {
    SyncRunContext? context,
    ExpenseEvidence? sentSnapshot,
  }) async {
    await _syncWrite(context, (owner) async {
      final live = await isar.expenseEvidences.get(id);
      if (live == null || live.ownerUserId != owner) return;
      if (sentSnapshot != null &&
          (!_hasSameMutationEpoch('expenseEvidences', live.id, sentSnapshot) ||
              !live.pendingDelete ||
              live.deletedAt != sentSnapshot.deletedAt ||
              live.hasBusinessChangesComparedTo(sentSnapshot))) {
        return;
      }
      await isar.expenseEvidences.delete(id);
    });
  }

  Future<void> updateEvidenceRemoteId(
    ExpenseEvidence ack, {
    SyncRunContext? context,
    ExpenseEvidence? sentSnapshot,
  }) async {
    final sent = sentSnapshot ?? ack;
    await _syncWrite(context, (owner) async {
      final live = await isar.expenseEvidences.get(ack.id);
      if (live == null ||
          live.ownerUserId != owner ||
          sent.ownerUserId != owner ||
          (live.syncId != null &&
              sent.syncId != null &&
              live.syncId != sent.syncId) ||
          ack.remoteVersion < live.remoteVersion) {
        return;
      }
      final unchanged =
          _hasSameMutationEpoch('expenseEvidences', live.id, sent) &&
          !live.hasBusinessChangesComparedTo(sent) &&
          live.deletedAt == sent.deletedAt &&
          live.pendingDelete == sent.pendingDelete &&
          live.updatedAt == sent.updatedAt;
      live
        ..remoteId = ack.remoteId
        ..syncId = ack.syncId ?? live.syncId
        ..remoteVersion = ack.remoteVersion
        ..remoteUpdatedAt = ack.remoteUpdatedAt
        ..syncedAt = ack.syncedAt;
      if (unchanged) live.isDirty = false;
      await isar.expenseEvidences.put(live);
    });
  }

  Future<void> updateDownloadedEvidenceFile(
    ExpenseEvidence snapshot, {
    SyncRunContext? context,
  }) async {
    await _syncWrite(context, (owner) async {
      final live = await isar.expenseEvidences.get(snapshot.id);
      if (live == null ||
          live.ownerUserId != owner ||
          live.deletedAt != null ||
          live.remoteStoragePath != snapshot.remoteStoragePath ||
          live.localFilePath != null) {
        return;
      }
      live.localFilePath = snapshot.localFilePath;
      await isar.expenseEvidences.put(live);
    });
  }

  Future<EvidenceAttachment?> ensureEvidenceAttachmentForEvidence(
    ExpenseEvidence evidence, {
    SyncRunContext? context,
  }) async {
    final owner = context?.ownerId ?? currentOwnerUserId;
    final generation = databaseGeneration;
    _checkSyncContext(context, owner, generation);
    final localPath = evidence.localFilePath?.trim();
    if (localPath == null || localPath.isEmpty) return null;

    evidence.syncId = ensureSyncId(evidence.syncId);
    final evidenceSyncId = evidence.syncId!;
    final now = DateTime.now().toUtc();
    final fileMetadata = await _readEvidenceAttachmentFileMetadata(
      localPath: localPath,
      fallbackFileName: evidence.fileName,
      fallbackMimeType: evidence.mimeType,
    );

    _checkSyncContext(context, owner, generation);
    return _syncWrite(context, (_) async {
      final persistedEvidence = await isar.expenseEvidences.get(evidence.id);
      if (persistedEvidence == null ||
          persistedEvidence.ownerUserId != owner ||
          persistedEvidence.pendingDelete ||
          persistedEvidence.localFilePath?.trim() != localPath) {
        return null;
      }
      if (persistedEvidence.syncId == null) {
        persistedEvidence.syncId = evidenceSyncId;
        await isar.expenseEvidences.put(persistedEvidence);
      }

      final existing = await isar.evidenceAttachments
          .filter()
          .evidenceSyncIdEqualTo(evidenceSyncId)
          .findAll();
      final ownedExisting = existing
          .where((item) => item.ownerUserId == owner)
          .toList();
      EvidenceAttachment? attachment;
      for (final item in ownedExisting) {
        if (item.localPath == localPath && item.deletedAt == null) {
          attachment = item;
          break;
        }
      }

      for (final item in ownedExisting) {
        if (item.id == attachment?.id) continue;
        item.uploadState = EvidenceAttachmentUploadState.deleted;
        item.deletedAt ??= now;
        item.updatedAt = now;
        await isar.evidenceAttachments.put(item);
      }

      attachment ??= EvidenceAttachment()
        ..syncId = ensureSyncId(null)
        ..createdAt = now;

      final fileChanged =
          attachment.localPath != localPath ||
          attachment.contentHash != fileMetadata.contentHash;
      attachment
        ..ownerUserId = owner
        ..evidenceSyncId = evidenceSyncId
        ..evidenceLocalId = evidence.id
        ..localPath = localPath
        ..originalFileName = fileMetadata.fileName
        ..contentHash = fileMetadata.contentHash
        ..sizeBytes = fileMetadata.sizeBytes
        ..mimeType = fileMetadata.mimeType
        ..deletedAt = null
        ..failureMessage = null
        ..updatedAt = now;
      if (fileChanged ||
          attachment.uploadState == EvidenceAttachmentUploadState.failed) {
        attachment.uploadState = EvidenceAttachmentUploadState.pending;
        attachment.uploadedAt = null;
      }
      await isar.evidenceAttachments.put(attachment);
      return attachment;
    });
  }

  Future<List<EvidenceAttachment>> getPendingEvidenceAttachmentsForSync({
    SyncRunContext? context,
  }) async {
    final owner = context?.ownerId ?? currentOwnerUserId;
    final generation = databaseGeneration;
    _checkSyncContext(context, owner, generation);
    final attachments = await isar.evidenceAttachments.where().findAll();
    _checkSyncContext(context, owner, generation);
    return attachments
        .where(
          (item) =>
              item.ownerUserId == owner &&
              (item.uploadState == EvidenceAttachmentUploadState.pending ||
                  item.uploadState == EvidenceAttachmentUploadState.uploading ||
                  item.uploadState == EvidenceAttachmentUploadState.failed ||
                  item.uploadState == EvidenceAttachmentUploadState.deleted),
        )
        .toList();
  }

  Future<EvidenceAttachment?> getEvidenceAttachmentBySyncId(
    String syncId,
  ) async {
    final attachments = await isar.evidenceAttachments
        .filter()
        .syncIdEqualTo(syncId)
        .findAll();
    return _firstForCurrentOwner(
      attachments,
      (attachment) => attachment.ownerUserId,
    );
  }

  Future<void> syncRemoteEvidenceAttachmentToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) async {
    if (!_remoteRowAllowed(data, context)) return;
    final remoteSyncId = _parseRemoteString(data['sync_id']);
    final evidenceSyncId = _parseRemoteString(data['evidence_sync_id']);
    if (remoteSyncId == null || evidenceSyncId == null) return;

    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : _parseRemoteDateTime(data['deleted_at']);
    await _syncWrite(context, (owner) async {
      final existing = _firstForOwner(
        await isar.evidenceAttachments
            .filter()
            .syncIdEqualTo(remoteSyncId)
            .findAll(),
        (attachment) => attachment.ownerUserId,
        owner,
      );

      if (existing != null &&
          existing.uploadState != EvidenceAttachmentUploadState.uploaded) {
        return;
      }
      if (remoteDeletedAt != null) {
        if (existing != null) {
          await isar.evidenceAttachments.delete(existing.id);
        }
        return;
      }

      final now = DateTime.now().toUtc();
      final item = existing ?? EvidenceAttachment();
      item
        ..ownerUserId = owner
        ..syncId = remoteSyncId
        ..evidenceSyncId = evidenceSyncId
        ..remoteStoragePath = _parseRemoteString(data['remote_storage_path'])
        ..originalFileName =
            _parseRemoteString(data['original_file_name']) ??
            _parseRemoteString(data['remote_storage_path']) ??
            'attachment'
        ..contentHash = _parseRemoteString(data['content_hash'])
        ..sizeBytes = _parseRemoteInt(data['size_bytes'])
        ..mimeType = _parseRemoteString(data['mime_type'])
        ..uploadState = EvidenceAttachmentUploadState.values.firstWhere(
          (value) => value.name == _parseRemoteString(data['upload_state']),
          orElse: () => EvidenceAttachmentUploadState.uploaded,
        )
        ..uploadedAt = data['uploaded_at'] == null
            ? null
            : _parseRemoteDateTime(data['uploaded_at'])
        ..deletedAt = null
        ..failureMessage = null
        ..createdAt = existing?.createdAt ?? now
        ..updatedAt = data['updated_at'] == null
            ? now
            : _parseRemoteDateTime(data['updated_at'], fallback: now);
      await isar.evidenceAttachments.put(item);

      final evidence = _firstForOwner(
        await isar.expenseEvidences
            .filter()
            .syncIdEqualTo(evidenceSyncId)
            .findAll(),
        (evidence) => evidence.ownerUserId,
        owner,
      );
      final remoteStoragePath = item.remoteStoragePath;
      if (evidence != null &&
          !evidence.isDirty &&
          !evidence.pendingDelete &&
          evidence.deletedAt == null &&
          remoteStoragePath != null &&
          remoteStoragePath.trim().isNotEmpty &&
          (evidence.remoteStoragePath == null ||
              evidence.remoteStoragePath == remoteStoragePath)) {
        evidence
          ..remoteStoragePath = remoteStoragePath
          ..fileName ??= item.originalFileName
          ..mimeType ??= item.mimeType
          ..uploadedAt ??= item.uploadedAt;
        await isar.expenseEvidences.put(evidence);
      }
    });
  }

  Future<void> markEvidenceAttachmentUploading(
    EvidenceAttachment attachment, {
    SyncRunContext? context,
  }) {
    return _updateEvidenceAttachment(attachment.id, (item) {
      item
        ..uploadState = EvidenceAttachmentUploadState.uploading
        ..failureMessage = null
        ..updatedAt = DateTime.now().toUtc();
    }, context: context);
  }

  Future<void> markEvidenceAttachmentUploaded(
    EvidenceAttachment attachment, {
    required String remoteStoragePath,
    SyncRunContext? context,
  }) {
    return _syncWrite(context, (owner) async {
      final item = await isar.evidenceAttachments.get(attachment.id);
      if (item == null || item.ownerUserId != owner) return;
      if (item.deletedAt != null ||
          item.uploadState == EvidenceAttachmentUploadState.deleted) {
        return;
      }
      if (item.localPath != attachment.localPath ||
          item.contentHash != attachment.contentHash ||
          item.sizeBytes != attachment.sizeBytes) {
        return;
      }
      final now = DateTime.now().toUtc();
      item
        ..remoteStoragePath = remoteStoragePath
        ..uploadState = EvidenceAttachmentUploadState.uploaded
        ..uploadedAt = now
        ..deletedAt = null
        ..failureMessage = null
        ..updatedAt = now;
      await isar.evidenceAttachments.put(item);

      final evidence = _firstForOwner(
        await isar.expenseEvidences
            .filter()
            .syncIdEqualTo(item.evidenceSyncId)
            .findAll(),
        (evidence) => evidence.ownerUserId,
        owner,
      );
      if (evidence != null &&
          evidence.deletedAt == null &&
          !evidence.pendingDelete &&
          (evidence.localFilePath == null ||
              evidence.localFilePath == item.localPath)) {
        if (evidence.remoteStoragePath != remoteStoragePath) {
          evidence
            ..isDirty = true
            ..updatedAt = now;
          _recordMutation('expenseEvidences', evidence.id, evidence);
        }
        evidence
          ..remoteStoragePath = remoteStoragePath
          ..uploadedAt = now
          ..fileName ??= item.originalFileName
          ..mimeType ??= item.mimeType;
        await isar.expenseEvidences.put(evidence);
      }
    });
  }

  Future<void> markEvidenceAttachmentFailed(
    EvidenceAttachment attachment,
    Object error, {
    SyncRunContext? context,
  }) {
    return _updateEvidenceAttachment(attachment.id, (item) {
      item
        ..uploadState = EvidenceAttachmentUploadState.failed
        ..failureMessage = error.toString()
        ..updatedAt = DateTime.now().toUtc();
    }, context: context);
  }

  Future<void> queueEvidenceAttachmentDeleteForEvidence(
    ExpenseEvidence evidence,
  ) async {
    if (evidence.localFilePath == null && evidence.remoteStoragePath == null) {
      return;
    }
    evidence.syncId = ensureSyncId(evidence.syncId);
    await _writeTxn(() async {
      await _queueEvidenceAttachmentDeleteInTxn(evidence);
    });
  }

  Future<void> purgeEvidenceAttachment(
    int id, {
    SyncRunContext? context,
  }) async {
    await _syncWrite(context, (owner) async {
      final item = await isar.evidenceAttachments.get(id);
      if (item == null || item.ownerUserId != owner) return;
      if (context != null && item.deletedAt == null) return;
      await isar.evidenceAttachments.delete(id);
    });
  }

  Future<void> _updateEvidenceAttachment(
    int id,
    void Function(EvidenceAttachment item) update, {
    SyncRunContext? context,
  }) async {
    await _syncWrite(context, (owner) async {
      final item = await isar.evidenceAttachments.get(id);
      if (item == null || item.ownerUserId != owner) return;
      if (item.deletedAt != null ||
          item.uploadState == EvidenceAttachmentUploadState.deleted) {
        return;
      }
      update(item);
      await isar.evidenceAttachments.put(item);
    });
  }

  Future<void> _queueEvidenceAttachmentDeleteInTxn(
    ExpenseEvidence evidence,
  ) async {
    final evidenceSyncId = evidence.syncId;
    if (evidenceSyncId == null) return;

    final now = DateTime.now().toUtc();
    final attachments = await isar.evidenceAttachments
        .filter()
        .evidenceSyncIdEqualTo(evidenceSyncId)
        .findAll();
    final ownedAttachments = attachments
        .where((attachment) => _belongsToCurrentUser(attachment.ownerUserId))
        .toList();

    if (ownedAttachments.isEmpty) {
      final localPath = evidence.localFilePath;
      final fileName = evidence.fileName ?? evidence.remoteStoragePath;
      if (localPath == null && evidence.remoteStoragePath == null) return;
      final attachment = EvidenceAttachment()
        ..ownerUserId = evidence.ownerUserId ?? currentOwnerUserId
        ..syncId = ensureSyncId(null)
        ..evidenceSyncId = evidenceSyncId
        ..evidenceLocalId = evidence.id
        ..localPath = localPath
        ..remoteStoragePath = evidence.remoteStoragePath
        ..originalFileName = fileName == null
            ? 'attachment'
            : p.basename(fileName)
        ..mimeType = evidence.mimeType
        ..uploadState = EvidenceAttachmentUploadState.deleted
        ..createdAt = now
        ..updatedAt = now
        ..deletedAt = now;
      await isar.evidenceAttachments.put(attachment);
      return;
    }

    for (final attachment in ownedAttachments) {
      attachment
        ..uploadState = EvidenceAttachmentUploadState.deleted
        ..deletedAt ??= now
        ..updatedAt = now;
      await isar.evidenceAttachments.put(attachment);
    }
  }

  Future<_EvidenceAttachmentFileMetadata> _readEvidenceAttachmentFileMetadata({
    required String localPath,
    String? fallbackFileName,
    String? fallbackMimeType,
  }) async {
    final file = File(localPath);
    String? contentHash;
    int? sizeBytes;
    if (await file.exists()) {
      sizeBytes = await file.length();
      contentHash = (await sha256.bind(file.openRead()).first).toString();
    }
    final safeFallback = fallbackFileName?.trim();
    return _EvidenceAttachmentFileMetadata(
      fileName: safeFallback?.isNotEmpty == true
          ? safeFallback!
          : p.basename(localPath),
      contentHash: contentHash,
      sizeBytes: sizeBytes,
      mimeType: fallbackMimeType,
    );
  }

  // --- 6. Sync Helpers (Called by SyncService) ---

  Future<void> updateWorkLogRemoteId(
    WorkLog ack, {
    SyncRunContext? context,
    WorkLog? sentSnapshot,
  }) async {
    final sent = sentSnapshot ?? ack;
    await _syncWrite(context, (owner) async {
      final live = await isar.workLogs.get(ack.id);
      if (live == null ||
          live.ownerUserId != owner ||
          sent.ownerUserId != owner ||
          (live.syncId != null &&
              sent.syncId != null &&
              live.syncId != sent.syncId) ||
          ack.remoteVersion < live.remoteVersion) {
        return;
      }
      final unchanged =
          _hasSameMutationEpoch('workLogs', live.id, sent) &&
          !live.hasBusinessChangesComparedTo(sent) &&
          live.deletedAt == sent.deletedAt &&
          live.pendingDelete == sent.pendingDelete &&
          live.updatedAt == sent.updatedAt;
      live
        ..remoteId = ack.remoteId
        ..syncId = ack.syncId ?? live.syncId
        ..remoteVersion = ack.remoteVersion
        ..remoteUpdatedAt = ack.remoteUpdatedAt
        ..syncedAt = ack.syncedAt;
      if (unchanged) live.isDirty = false;
      await isar.workLogs.put(live);
    });
  }

  Future<void> updateSubscriptionRemoteId(
    Subscription ack, {
    SyncRunContext? context,
    Subscription? sentSnapshot,
  }) async {
    final sent = sentSnapshot ?? ack;
    await _syncWrite(context, (owner) async {
      final live = await isar.subscriptions.get(ack.id);
      if (live == null ||
          live.ownerUserId != owner ||
          sent.ownerUserId != owner ||
          (live.syncId != null &&
              sent.syncId != null &&
              live.syncId != sent.syncId) ||
          ack.remoteVersion < live.remoteVersion) {
        return;
      }
      final unchanged =
          _hasSameMutationEpoch('subscriptions', live.id, sent) &&
          !live.hasBusinessChangesComparedTo(sent) &&
          live.deletedAt == sent.deletedAt &&
          live.pendingDelete == sent.pendingDelete;
      live
        ..remoteId = ack.remoteId
        ..syncId = ack.syncId ?? live.syncId
        ..remoteVersion = ack.remoteVersion
        ..remoteUpdatedAt = ack.remoteUpdatedAt
        ..syncedAt = ack.syncedAt;
      if (unchanged) live.isDirty = false;
      await isar.subscriptions.put(live);
    });
  }

  // --- 项目 Project ---

  Future<List<Project>> getAllProjects() async {
    return _projectDao.getActiveSortedForOwner(currentOwnerUserId);
  }

  Stream<void> watchProjects() => _projectDao.watch();

  Future<int> addProject(Project project) async {
    final id = await _writeTxn(() async {
      project.stageNames = _normalizeStringList(project.stageNames);
      project.id = _normalizeNewRecordId(project.id);
      final existing = _isNewRecordId(project.id)
          ? null
          : await isar.projects.get(project.id);
      _stampProjectOwner(project, existing);
      _preserveProjectSyncIdentity(project, existing);
      if (existing != null) {
        project.isDirty =
            project.isDirty ||
            existing.isDirty ||
            project.hasBusinessChangesComparedTo(existing);
      } else {
        project.isDirty =
            project.isDirty ||
            project.remoteId == null && project.syncId != null;
      }
      final savedId = await isar.projects.put(project);
      _recordMutation('projects', savedId, project);
      return savedId;
    });
    return id;
  }

  Future<List<Project>> getAllProjectsForSync() async {
    final syncableProjectNames = await _getSyncableProjectNames();
    final projects = await _projectDao.getAllSorted();
    return projects
        .where(
          (project) =>
              _belongsToCurrentUser(project.ownerUserId) &&
              (_isProjectSyncEligible(project) ||
                  syncableProjectNames.contains(
                    project.name.trim().toLowerCase(),
                  )),
        )
        .toList();
  }

  Future<List<Project>> getPendingProjectsForSync({SyncRunContext? context}) {
    return _preparePendingSyncRows(
      context: context,
      entityName: 'project',
      mutationCollection: 'projects',
      collection: isar.projects,
      readRows: (owner) async {
        final syncableProjectNames = await _getSyncableProjectNames(
          ownerUserId: owner,
        );
        final projects = await _projectDao.getPendingForSyncForOwner(owner);
        return projects
            .where(
              (project) =>
                  project.ownerUserId == owner &&
                  (_isProjectSyncEligible(project) ||
                      syncableProjectNames.contains(
                        project.name.trim().toLowerCase(),
                      )),
            )
            .toList();
      },
      idOf: (row) => row.id,
      syncIdOf: (row) => row.syncId,
      assignSyncId: (row, syncId) => row.syncId = syncId,
    );
  }

  Future<Project?> getProject(int id) async {
    final project = await _projectDao.getById(id);
    if (project == null || !_isVisibleToCurrentUser(project.ownerUserId)) {
      return null;
    }
    return _tagMutationEpoch<Project>('projects', project.id, project);
  }

  Future<Project?> markProjectDeleted(int id) async {
    return await _writeTxn(() async {
      final project = await isar.projects.get(id);
      if (project == null) return null;
      if (!_isVisibleToCurrentUser(project.ownerUserId)) return null;
      project.deletedAt = DateTime.now().toUtc();
      project.pendingDelete = true;
      project.isDirty = true;
      await isar.projects.put(project);
      _recordMutation('projects', project.id, project);
      return project;
    });
  }

  /// Applies the local part of a project cascade in one Isar transaction.
  ///
  /// Photos are deliberately unlinked, never deleted. Syncable records are
  /// retained as tombstones or dirty relationship updates for the normal sync
  /// pipeline; records without a remote identity are removed in this same
  /// transaction. Filesystem cleanup is returned to the repository because it
  /// cannot be rolled back by Isar.
  Future<ProjectCascadeDeleteResult?> deleteProjectCascade({
    required int projectId,
    required String projectName,
  }) async {
    return await _writeTxn(() async {
      final project = await isar.projects.get(projectId);
      if (project == null || !_isVisibleToCurrentUser(project.ownerUserId)) {
        return null;
      }

      final projectNames = {
        project.name.trim().toLowerCase(),
        projectName.trim().toLowerCase(),
      }..removeWhere((name) => name.isEmpty);

      bool matchesProject(int? linkedProjectId, String? linkedProjectName) {
        if (linkedProjectId != null) return linkedProjectId == projectId;
        return projectNames.contains(linkedProjectName?.trim().toLowerCase());
      }

      final localEvidenceFiles = <ExpenseEvidence>[];
      final pendingEvidenceFiles = <ExpenseEvidence>[];
      final attachments = await isar.evidenceAttachments.where().findAll();

      final evidence = await isar.expenseEvidences.where().findAll();
      for (final item in evidence) {
        if (item.deletedAt != null ||
            !_isVisibleToCurrentUser(item.ownerUserId) ||
            !matchesProject(item.projectId, item.projectName)) {
          continue;
        }

        final hasRemoteIdentity = item.remoteId != null || item.syncId != null;
        final localFilePath = item.localFilePath?.trim();
        if (hasRemoteIdentity) {
          final now = DateTime.now().toUtc();
          item
            ..deletedAt = now
            ..updatedAt = now
            ..pendingDelete = true
            ..isDirty = true;
          if (item.localFilePath != null || item.remoteStoragePath != null) {
            item.syncId = ensureSyncId(item.syncId);
            await _queueEvidenceAttachmentDeleteInTxn(item);
          }
          await isar.expenseEvidences.put(item);
          if (localFilePath != null && localFilePath.isNotEmpty) {
            pendingEvidenceFiles.add(item);
          }
        } else {
          final attachmentIds = attachments
              .where(
                (attachment) =>
                    _isVisibleToCurrentUser(attachment.ownerUserId) &&
                    (attachment.evidenceLocalId == item.id ||
                        attachment.evidenceSyncId == item.syncId),
              )
              .map((attachment) => attachment.id)
              .toList();
          if (attachmentIds.isNotEmpty) {
            await isar.evidenceAttachments.deleteAll(attachmentIds);
          }
          await isar.expenseEvidences.delete(item.id);
          if (localFilePath != null && localFilePath.isNotEmpty) {
            localEvidenceFiles.add(item);
          }
        }
      }

      final records = await isar.expenseRecords.where().findAll();
      for (final record in records) {
        if (record.deletedAt != null ||
            !_isVisibleToCurrentUser(record.ownerUserId) ||
            !matchesProject(record.projectId, record.projectName)) {
          continue;
        }

        if (record.remoteId == null && record.syncId == null) {
          await isar.expenseRecords.delete(record.id);
        } else {
          final now = DateTime.now().toUtc();
          record
            ..deletedAt = now
            ..updatedAt = now
            ..pendingDelete = true
            ..isDirty = true;
          await isar.expenseRecords.put(record);
        }
      }

      final logs = await isar.workLogs.where().findAll();
      for (final log in logs) {
        if (log.deletedAt != null ||
            log.type != LogType.businessTrip ||
            !_isVisibleToCurrentUser(log.ownerUserId) ||
            !matchesProject(log.projectId, log.projectName)) {
          continue;
        }

        log
          ..projectId = null
          ..projectSyncId = null
          ..projectName = null
          ..projectStageName = null
          ..updatedAt = DateTime.now().toUtc()
          ..isDirty = true;
        await isar.workLogs.put(log);
      }

      final photos = await isar.photoItems.where().findAll();
      for (final photo in photos) {
        if (!_isVisibleToCurrentUser(photo.ownerUserId) ||
            !matchesProject(photo.projectId, photo.projectName)) {
          continue;
        }

        photo
          ..projectId = null
          ..projectName = null;
        await isar.photoItems.put(photo);
      }

      Project? deletedProject;
      if (project.remoteId == null && project.syncId == null) {
        await isar.projects.delete(project.id);
      } else {
        final now = DateTime.now().toUtc();
        project
          ..deletedAt = now
          ..updatedAt = now
          ..pendingDelete = true
          ..isDirty = true;
        await isar.projects.put(project);
        deletedProject = project;
      }

      return ProjectCascadeDeleteResult(
        deletedProject: deletedProject,
        localEvidenceFiles: localEvidenceFiles,
        pendingEvidenceFiles: pendingEvidenceFiles,
      );
    });
  }

  Future<void> purgeDeletedProject(
    int id, {
    SyncRunContext? context,
    Project? sentSnapshot,
  }) async {
    await _syncWrite(context, (owner) async {
      final live = await isar.projects.get(id);
      if (live == null || live.ownerUserId != owner) return;
      if (sentSnapshot != null &&
          (!_hasSameMutationEpoch('projects', live.id, sentSnapshot) ||
              !live.pendingDelete ||
              live.deletedAt != sentSnapshot.deletedAt ||
              live.hasBusinessChangesComparedTo(sentSnapshot))) {
        return;
      }
      await isar.projects.delete(id);
    });
  }

  Future<void> updateProjectRemoteId(
    Project ack, {
    SyncRunContext? context,
    Project? sentSnapshot,
  }) async {
    final sent = sentSnapshot ?? ack;
    await _syncWrite(context, (owner) async {
      final live = await isar.projects.get(ack.id);
      if (live == null ||
          live.ownerUserId != owner ||
          sent.ownerUserId != owner ||
          (live.syncId != null &&
              sent.syncId != null &&
              live.syncId != sent.syncId) ||
          ack.remoteVersion < live.remoteVersion) {
        return;
      }
      final unchanged =
          _hasSameMutationEpoch('projects', live.id, sent) &&
          !live.hasBusinessChangesComparedTo(sent) &&
          live.deletedAt == sent.deletedAt &&
          live.pendingDelete == sent.pendingDelete &&
          live.updatedAt == sent.updatedAt;
      live
        ..remoteId = ack.remoteId
        ..syncId = ack.syncId ?? live.syncId
        ..remoteVersion = ack.remoteVersion
        ..remoteUpdatedAt = ack.remoteUpdatedAt
        ..syncedAt = ack.syncedAt;
      if (unchanged) live.isDirty = false;
      await isar.projects.put(live);
    });
  }

  /// Saves local-only cover metadata without changing sync dirty state.
  Future<Project?> updateProjectCover(Project project) async {
    return await _writeTxn(() async {
      final existing = await isar.projects.get(project.id);
      if (existing == null || !_isVisibleToCurrentUser(existing.ownerUserId)) {
        return null;
      }
      existing.localCoverPath = project.localCoverPath;
      existing.coverImagePath = project.coverImagePath;
      await isar.projects.put(existing);
      return existing;
    });
  }

  Future<Project> ensureProject(String name, {bool syncable = false}) async {
    final safeName = name.trim().isEmpty ? 'DefaultProject' : name.trim();
    for (final project in await getAllProjects()) {
      if (project.name.toLowerCase() == safeName.toLowerCase()) {
        if (syncable && project.syncId == null) {
          project.syncId = ensureSyncId(project.syncId);
          project.isDirty = true;
          await addProject(project);
        }
        return project;
      }
    }

    final now = DateTime.now();
    final project = Project()
      ..name = safeName
      ..createdAt = now
      ..updatedAt = now
      ..syncId = syncable ? ensureSyncId(null) : null
      ..isDirty = syncable;
    project.id = await addProject(project);
    return project;
  }

  Future<_ProjectLink?> _resolveProjectLinkInTxn({
    String? owner,
    String? projectName,
    String? projectSyncId,
  }) async {
    final normalizedSyncId = projectSyncId?.trim();
    final hasSyncId = normalizedSyncId?.isNotEmpty == true;
    final normalizedName = projectName?.trim();
    final hasName = normalizedName?.isNotEmpty == true;

    if (!hasSyncId && !hasName) return null;

    Project? project;
    if (hasSyncId) {
      project = _firstForOwner(
        await isar.projects.filter().syncIdEqualTo(normalizedSyncId).findAll(),
        (project) => project.ownerUserId,
        owner,
      );
    }
    if (project == null && hasName) {
      final projects = await isar.projects.where().findAll();
      for (final item in projects) {
        if (item.ownerUserId == owner &&
            item.name.toLowerCase() == normalizedName!.toLowerCase()) {
          project = item;
          break;
        }
      }
    }

    if (project == null) {
      final now = DateTime.now();
      project = Project()
        ..name = hasName ? normalizedName! : 'DefaultProject'
        ..ownerUserId = owner
        ..createdAt = now
        ..updatedAt = now
        ..syncId = hasSyncId ? normalizedSyncId : ensureSyncId(null)
        ..isDirty = !hasSyncId;
      project.id = await isar.projects.put(project);
    }

    return _ProjectLink(
      id: project.id,
      name: project.name,
      syncId: project.syncId,
    );
  }

  // --- 一次性消费 ExpenseRecord ---

  Future<List<ExpenseRecord>> getAllExpenseRecords() async {
    return _expenseRecordDao.getActiveSortedForOwner(currentOwnerUserId);
  }

  Future<List<ExpenseRecord>> getAllExpenseRecordsForSync() async {
    final records = await _expenseRecordDao.getAllSorted();
    return records
        .where((record) => _belongsToCurrentUser(record.ownerUserId))
        .toList();
  }

  Future<List<ExpenseRecord>> getPendingExpenseRecordsForSync({
    SyncRunContext? context,
  }) {
    return _preparePendingSyncRows(
      context: context,
      entityName: 'expense_record',
      mutationCollection: 'expenseRecords',
      collection: isar.expenseRecords,
      readRows: (owner) => _expenseRecordDao.getPendingForSyncForOwner(owner),
      idOf: (row) => row.id,
      syncIdOf: (row) => row.syncId,
      assignSyncId: (row, syncId) => row.syncId = syncId,
    );
  }

  Stream<void> watchExpenseRecords() => _expenseRecordDao.watch();

  Future<int> addExpenseRecord(ExpenseRecord record) async {
    final id = await _writeTxn(() async {
      record.id = _normalizeNewRecordId(record.id);
      final existing = _isNewRecordId(record.id)
          ? null
          : await isar.expenseRecords.get(record.id);
      _stampExpenseRecordOwner(record, existing);
      _preserveExpenseRecordSyncIdentity(record, existing);
      _stampExpenseRecordAudit(record, existing);
      record.isDirty =
          existing?.isDirty == true ||
          record.isDirty ||
          record.remoteId == null ||
          (existing != null && record.hasBusinessChangesComparedTo(existing));
      final savedId = await isar.expenseRecords.put(record);
      _recordMutation('expenseRecords', savedId, record);
      return savedId;
    });
    return id;
  }

  Future<ExpenseRecord?> getExpenseRecord(int id) async {
    final record = await _expenseRecordDao.getById(id);
    if (record == null || !_isVisibleToCurrentUser(record.ownerUserId)) {
      return null;
    }
    return _tagMutationEpoch<ExpenseRecord>(
      'expenseRecords',
      record.id,
      record,
    );
  }

  Future<ExpenseRecord?> markExpenseRecordDeleted(int id) async {
    return await _writeTxn(() async {
      final record = await isar.expenseRecords.get(id);
      if (record == null) return null;
      if (!_isVisibleToCurrentUser(record.ownerUserId)) return null;
      record.deletedAt = DateTime.now().toUtc();
      record.updatedAt = record.deletedAt;
      record.pendingDelete = true;
      record.isDirty = true;
      await isar.expenseRecords.put(record);
      _recordMutation('expenseRecords', record.id, record);
      return record;
    });
  }

  Future<void> purgeDeletedExpenseRecord(
    int id, {
    SyncRunContext? context,
    ExpenseRecord? sentSnapshot,
  }) async {
    await _syncWrite(context, (owner) async {
      final live = await isar.expenseRecords.get(id);
      if (live == null || live.ownerUserId != owner) return;
      if (sentSnapshot != null &&
          (!_hasSameMutationEpoch('expenseRecords', live.id, sentSnapshot) ||
              !live.pendingDelete ||
              live.deletedAt != sentSnapshot.deletedAt ||
              live.hasBusinessChangesComparedTo(sentSnapshot))) {
        return;
      }
      await isar.expenseRecords.delete(id);
    });
  }

  Future<void> updateExpenseRecordRemoteId(
    ExpenseRecord ack, {
    SyncRunContext? context,
    ExpenseRecord? sentSnapshot,
  }) async {
    final sent = sentSnapshot ?? ack;
    await _syncWrite(context, (owner) async {
      final live = await isar.expenseRecords.get(ack.id);
      if (live == null ||
          live.ownerUserId != owner ||
          sent.ownerUserId != owner ||
          (live.syncId != null &&
              sent.syncId != null &&
              live.syncId != sent.syncId) ||
          ack.remoteVersion < live.remoteVersion) {
        return;
      }
      final unchanged =
          _hasSameMutationEpoch('expenseRecords', live.id, sent) &&
          !live.hasBusinessChangesComparedTo(sent) &&
          live.deletedAt == sent.deletedAt &&
          live.pendingDelete == sent.pendingDelete &&
          live.updatedAt == sent.updatedAt;
      live
        ..remoteId = ack.remoteId
        ..syncId = ack.syncId ?? live.syncId
        ..remoteVersion = ack.remoteVersion
        ..remoteUpdatedAt = ack.remoteUpdatedAt
        ..syncedAt = ack.syncedAt;
      if (unchanged) live.isDirty = false;
      await isar.expenseRecords.put(live);
    });
  }

  // Sync Remote -> Local (WorkLog)
  Future<void> syncRemoteLogsToLocal(
    List<Map<String, dynamic>> rows, {
    SyncRunContext? context,
  }) async {
    if (rows.isEmpty) return;
    await _syncWrite(context, (owner) async {
      for (final data in rows) {
        if (!_remoteRowAllowed(data, context)) continue;
        await _syncRemoteLogToLocalInTxn(data, owner);
      }
    });
  }

  Future<void> syncRemoteLogToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) {
    return syncRemoteLogsToLocal([data], context: context);
  }

  Future<void> _syncRemoteLogToLocalInTxn(
    Map<String, dynamic> data,
    String? owner,
  ) async {
    final remoteId = _parseRemoteInt(data['id']);
    if (remoteId == null) return;
    final remoteSyncId = _parseRemoteString(data['sync_id']);
    final remoteVersion = _parseRemoteInt(data['version']) ?? 0;
    final remoteUpdatedAt = _parseRemoteDateTime(
      data['updated_at'],
      fallback: DateTime.now().toUtc(),
    );
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : _parseRemoteDateTime(data['deleted_at']);

    WorkLog? log;
    if (remoteSyncId != null) {
      log = _firstForOwner(
        await isar.workLogs.filter().syncIdEqualTo(remoteSyncId).findAll(),
        (log) => log.ownerUserId,
        owner,
      );
    }
    log ??= _firstForOwner(
      await isar.workLogs.filter().remoteIdEqualTo(remoteId).findAll(),
      (log) => log.ownerUserId,
      owner,
    );

    if (log != null && log.isDirty) {
      // Pulls keep the local edit's base version and tombstone. The versioned
      // push must detect a competing remote edit rather than silently rebase.
      log.remoteId ??= remoteId;
      log.syncId ??= remoteSyncId;
      await isar.workLogs.put(log);
      return;
    }
    if (remoteDeletedAt != null) {
      if (log != null) await isar.workLogs.delete(log.id);
      return;
    }
    log ??= WorkLog();

    log.remoteId = remoteId;
    log.ownerUserId = owner;
    log.syncId = remoteSyncId ?? log.syncId;
    log.remoteVersion = remoteVersion;
    log.remoteUpdatedAt = remoteUpdatedAt;
    log.syncedAt = remoteUpdatedAt;
    log.isDirty = false;
    log.deletedAt = null;
    log.pendingDelete = false;
    final now = DateTime.now().toUtc();
    log.createdAt ??= now;
    log.updatedAt = now;
    log.date = _parseRemoteDateOnly(data['date'], fallback: remoteUpdatedAt);

    final typeStr = _parseRemoteString(data['type']);
    log.type = LogType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => LogType.work,
    );

    log.overtimeHours = data['duration'] == null
        ? null
        : _parseRemoteDouble(data['duration']);
    log.note = _parseRemoteString(data['notes']);
    log.transport = _parseRemoteString(data['transport']);
    log.expenses = data['expenses'] == null
        ? null
        : _parseRemoteDouble(data['expenses']);
    log.isReimbursed = _parseRemoteBool(data['is_reimbursed']);

    if (log.type == LogType.businessTrip) {
      log.location = _parseRemoteString(data['project_name']);
    } else {
      log.location = null;
    }
    final linkedProjectName = _parseRemoteString(data['linked_project_name']);
    final projectSyncId = _parseRemoteString(data['project_sync_id']);
    final projectLink = await _resolveProjectLinkInTxn(
      owner: owner,
      projectName: linkedProjectName,
      projectSyncId: projectSyncId,
    );
    log.projectName = projectLink?.name ?? linkedProjectName;
    log.projectId = projectLink?.id;
    log.projectSyncId = projectLink?.syncId ?? projectSyncId;
    log.projectStageName = _normalizeOptionalString(
      _parseRemoteString(data['project_stage_name']),
    );

    await isar.workLogs.put(log);
  }

  // Sync Remote -> Local (Subscription)
  Future<void> syncRemoteSubscriptionsToLocal(
    List<Map<String, dynamic>> rows, {
    SyncRunContext? context,
  }) async {
    if (rows.isEmpty) return;
    await _syncWrite(context, (owner) async {
      for (final data in rows) {
        if (!_remoteRowAllowed(data, context)) continue;
        await _syncRemoteSubscriptionToLocalInTxn(data, owner);
      }
    });
  }

  Future<void> syncRemoteSubscriptionToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) {
    return syncRemoteSubscriptionsToLocal([data], context: context);
  }

  Future<void> _syncRemoteSubscriptionToLocalInTxn(
    Map<String, dynamic> data,
    String? owner,
  ) async {
    final remoteId = _parseRemoteInt(data['id']);
    if (remoteId == null) return;
    final remoteSyncId = _parseRemoteString(data['sync_id']);
    final remoteVersion = _parseRemoteInt(data['version']) ?? 0;
    final remoteUpdatedAt = _parseRemoteDateTime(
      data['updated_at'],
      fallback: DateTime.now().toUtc(),
    );
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : _parseRemoteDateTime(data['deleted_at']);

    Subscription? sub;
    if (remoteSyncId != null) {
      sub = _firstForOwner(
        await isar.subscriptions.filter().syncIdEqualTo(remoteSyncId).findAll(),
        (sub) => sub.ownerUserId,
        owner,
      );
    }
    sub ??= _firstForOwner(
      await isar.subscriptions.filter().remoteIdEqualTo(remoteId).findAll(),
      (sub) => sub.ownerUserId,
      owner,
    );

    if (sub != null && sub.isDirty) {
      // Pulls keep the local edit's base version and tombstone. The versioned
      // push must detect a competing remote edit rather than silently rebase.
      sub.remoteId ??= remoteId;
      sub.syncId ??= remoteSyncId;
      await isar.subscriptions.put(sub);
      return;
    }
    if (remoteDeletedAt != null) {
      if (sub != null) await isar.subscriptions.delete(sub.id);
      return;
    }
    sub ??= Subscription();

    sub.remoteId = remoteId;
    sub.ownerUserId = owner;
    sub.syncId = remoteSyncId ?? sub.syncId;
    sub.remoteVersion = remoteVersion;
    sub.remoteUpdatedAt = remoteUpdatedAt;
    sub.syncedAt = remoteUpdatedAt;
    sub.isDirty = false;
    sub.deletedAt = null;
    sub.pendingDelete = false;
    sub.name = _parseRemoteString(data['name']) ?? 'Untitled';
    sub.price = data['price'] == null
        ? null
        : _parseRemoteDouble(data['price']);
    sub.currency = subscriptionCurrencyFromCode(data['currency']).code;

    final cycleStr = _parseRemoteString(data['cycle']);
    sub.cycle = SubscriptionCycle.values.firstWhere(
      (e) => e.name == cycleStr,
      orElse: () => SubscriptionCycle.monthly,
    );

    sub.nextPaymentDate = _parseRemoteDateOnly(
      data['next_due_date'] ?? data['start_date'],
      fallback: remoteUpdatedAt,
    );
    sub.anchorDate = _parseRemoteDateOnly(
      data['anchor_date'] ?? data['start_date'] ?? data['next_due_date'],
      fallback: sub.nextPaymentDate,
    );
    sub.endDate = data['end_date'] == null
        ? null
        : _parseRemoteDateOnly(data['end_date']);
    final statusStr = _parseRemoteString(data['status']);
    sub.status = SubscriptionRecordStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => SubscriptionRecordStatus.active,
    );
    sub.reminderDays = _parseRemoteInt(data['reminder_days']) ?? 1;
    sub.note = _parseRemoteString(data['description']);
    sub.sortIndex = _parseRemoteInt(data['sort_index']);

    await isar.subscriptions.put(sub);
  }

  Future<void> syncRemoteEvidenceRowsToLocal(
    List<Map<String, dynamic>> rows, {
    SyncRunContext? context,
  }) async {
    if (rows.isEmpty) return;
    await _syncWrite(context, (owner) async {
      for (final data in rows) {
        if (!_remoteRowAllowed(data, context)) continue;
        await _syncRemoteEvidenceToLocalInTxn(data, owner);
      }
    });
  }

  Future<void> syncRemoteEvidenceToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) {
    return syncRemoteEvidenceRowsToLocal([data], context: context);
  }

  Future<void> _syncRemoteEvidenceToLocalInTxn(
    Map<String, dynamic> data,
    String? owner,
  ) async {
    final remoteId = _parseRemoteInt(data['id']);
    if (remoteId == null) return;
    final remoteSyncId = _parseRemoteString(data['sync_id']);
    final remoteVersion = _parseRemoteInt(data['version']) ?? 0;
    final remoteUpdatedAt = _parseRemoteDateTime(
      data['updated_at'],
      fallback: DateTime.now().toUtc(),
    );
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : _parseRemoteDateTime(data['deleted_at']);

    ExpenseEvidence? item;
    if (remoteSyncId != null) {
      item = _firstForOwner(
        await isar.expenseEvidences
            .filter()
            .syncIdEqualTo(remoteSyncId)
            .findAll(),
        (item) => item.ownerUserId,
        owner,
      );
    }
    item ??= _firstForOwner(
      await isar.expenseEvidences.filter().remoteIdEqualTo(remoteId).findAll(),
      (item) => item.ownerUserId,
      owner,
    );

    if (item != null && item.isDirty) {
      // Pulls keep the local edit's base version and tombstone. The versioned
      // push must detect a competing remote edit rather than silently rebase.
      item.remoteId ??= remoteId;
      item.syncId ??= remoteSyncId;
      await isar.expenseEvidences.put(item);
      return;
    }
    if (remoteDeletedAt != null) {
      if (item != null) await isar.expenseEvidences.delete(item.id);
      return;
    }
    item ??= ExpenseEvidence();

    item.remoteId = remoteId;
    item.ownerUserId = owner;
    item.syncId = remoteSyncId ?? item.syncId;
    item.remoteVersion = remoteVersion;
    item.remoteUpdatedAt = remoteUpdatedAt;
    item.syncedAt = remoteUpdatedAt;
    item.isDirty = false;
    item.deletedAt = null;
    item.pendingDelete = false;
    final now = DateTime.now().toUtc();
    item.createdAt ??= now;
    item.updatedAt = now;
    final projectName = _parseRemoteString(data['project_name']);
    final projectSyncId = _parseRemoteString(data['project_sync_id']);
    final projectLink = await _resolveProjectLinkInTxn(
      owner: owner,
      projectName: projectName,
      projectSyncId: projectSyncId,
    );
    item.projectName = projectLink?.name ?? projectName ?? 'DefaultProject';
    item.projectId = projectLink?.id;
    item.projectSyncId = projectLink?.syncId ?? projectSyncId;
    item.projectStageName = _normalizeOptionalString(
      _parseRemoteString(data['project_stage_name']),
    );
    item.evidenceDate = _parseRemoteDateOnly(
      data['evidence_date'],
      fallback: remoteUpdatedAt,
    );
    item.amount = data['amount'] == null
        ? null
        : _parseRemoteDouble(data['amount']);
    item.currency = _parseRemoteString(data['currency']) ?? 'CNY';
    item.category = EvidenceCategory.values.firstWhere(
      (value) => value.name == _parseRemoteString(data['category']),
      orElse: () => EvidenceCategory.invoice,
    );
    item.status = EvidenceStatus.values.firstWhere(
      (value) => value.name == _parseRemoteString(data['status']),
      orElse: () => EvidenceStatus.pending,
    );
    item.merchant = _parseRemoteString(data['merchant']);
    item.note = _parseRemoteString(data['note']);
    item.localFilePath = _parseRemoteString(data['local_file_path']);
    item.remoteStoragePath = _parseRemoteString(data['remote_storage_path']);
    item.fileName = _parseRemoteString(data['file_name']);
    item.mimeType = _parseRemoteString(data['mime_type']);
    item.uploadedAt = data['uploaded_at'] == null
        ? null
        : _parseRemoteDateTime(data['uploaded_at']);
    item.tripDate = data['trip_date'] == null
        ? null
        : _parseRemoteDateOnly(data['trip_date']);

    await isar.expenseEvidences.put(item);
  }

  Future<void> syncRemoteExpenseRecordsToLocal(
    List<Map<String, dynamic>> rows, {
    SyncRunContext? context,
  }) async {
    if (rows.isEmpty) return;
    await _syncWrite(context, (owner) async {
      for (final data in rows) {
        if (!_remoteRowAllowed(data, context)) continue;
        await _syncRemoteExpenseRecordToLocalInTxn(data, owner);
      }
    });
  }

  Future<void> syncRemoteExpenseRecordToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) {
    return syncRemoteExpenseRecordsToLocal([data], context: context);
  }

  Future<void> _syncRemoteExpenseRecordToLocalInTxn(
    Map<String, dynamic> data,
    String? owner,
  ) async {
    final remoteId = _parseRemoteInt(data['id']);
    if (remoteId == null) return;
    final remoteSyncId = _parseRemoteString(data['sync_id']);
    final remoteVersion = _parseRemoteInt(data['version']) ?? 0;
    final remoteUpdatedAt = _parseRemoteDateTime(
      data['updated_at'],
      fallback: DateTime.now().toUtc(),
    );
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : _parseRemoteDateTime(data['deleted_at']);

    ExpenseRecord? record;
    if (remoteSyncId != null) {
      record = _firstForOwner(
        await isar.expenseRecords
            .filter()
            .syncIdEqualTo(remoteSyncId)
            .findAll(),
        (record) => record.ownerUserId,
        owner,
      );
    }
    record ??= _firstForOwner(
      await isar.expenseRecords.filter().remoteIdEqualTo(remoteId).findAll(),
      (record) => record.ownerUserId,
      owner,
    );

    if (record != null && record.isDirty) {
      // Pulls keep the local edit's base version and tombstone. The versioned
      // push must detect a competing remote edit rather than silently rebase.
      record.remoteId ??= remoteId;
      record.syncId ??= remoteSyncId;
      await isar.expenseRecords.put(record);
      return;
    }
    if (remoteDeletedAt != null) {
      if (record != null) await isar.expenseRecords.delete(record.id);
      return;
    }
    record ??= ExpenseRecord();

    final projectName = _parseRemoteString(data['project_name']);
    final projectSyncId = _parseRemoteString(data['project_sync_id']);
    final projectLink = await _resolveProjectLinkInTxn(
      owner: owner,
      projectName: projectName,
      projectSyncId: projectSyncId,
    );
    final tripWorkLogSyncId = _parseRemoteString(data['trip_work_log_sync_id']);
    final tripWorkLog = tripWorkLogSyncId == null
        ? null
        : _firstForOwner(
            await isar.workLogs
                .filter()
                .syncIdEqualTo(tripWorkLogSyncId)
                .findAll(),
            (log) => log.ownerUserId,
            owner,
          );

    record.remoteId = remoteId;
    record.ownerUserId = owner;
    record.syncId = remoteSyncId ?? record.syncId;
    record.remoteVersion = remoteVersion;
    record.remoteUpdatedAt = remoteUpdatedAt;
    record.syncedAt = remoteUpdatedAt;
    record.isDirty = false;
    record.deletedAt = null;
    record.pendingDelete = false;
    final now = DateTime.now().toUtc();
    record.createdAt ??= now;
    record.updatedAt = now;
    record.expenseDate = _parseRemoteDateOnly(
      data['expense_date'],
      fallback: remoteUpdatedAt,
    );
    record.amount = _parseRemoteDouble(data['amount']);
    record.currency = _parseRemoteString(data['currency']) ?? 'CNY';
    record.category = ExpenseCategory.values.firstWhere(
      (value) => value.name == _parseRemoteString(data['category']),
      orElse: () => ExpenseCategory.other,
    );
    record.merchant = _parseRemoteString(data['merchant']);
    record.note = _parseRemoteString(data['note']);
    record.projectName = projectLink?.name ?? projectName;
    record.projectId = projectLink?.id;
    record.projectSyncId = projectLink?.syncId ?? projectSyncId;
    record.projectStageName = _normalizeOptionalString(
      _parseRemoteString(data['project_stage_name']),
    );
    record.tripWorkLogId = tripWorkLog?.id;
    record.tripWorkLogSyncId = tripWorkLog?.syncId ?? tripWorkLogSyncId;

    await isar.expenseRecords.put(record);
  }

  Future<void> syncRemoteProjectsToLocal(
    List<Map<String, dynamic>> rows, {
    SyncRunContext? context,
  }) async {
    if (rows.isEmpty) return;
    await _syncWrite(context, (owner) async {
      for (final data in rows) {
        if (!_remoteRowAllowed(data, context)) continue;
        await _syncRemoteProjectToLocalInTxn(data, owner);
      }
    });
  }

  Future<void> syncRemoteProjectToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) {
    return syncRemoteProjectsToLocal([data], context: context);
  }

  Future<void> _syncRemoteProjectToLocalInTxn(
    Map<String, dynamic> data,
    String? owner,
  ) async {
    final remoteId = _parseRemoteInt(data['id']);
    if (remoteId == null) return;
    final remoteSyncId = _parseRemoteString(data['sync_id']);
    final remoteVersion = _parseRemoteInt(data['version']) ?? 0;
    final remoteUpdatedAt = _parseRemoteDateTime(
      data['updated_at'],
      fallback: DateTime.now().toUtc(),
    );
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : _parseRemoteDateTime(data['deleted_at']);

    Project? project;
    if (remoteSyncId != null) {
      project = _firstForOwner(
        await isar.projects.filter().syncIdEqualTo(remoteSyncId).findAll(),
        (project) => project.ownerUserId,
        owner,
      );
    }
    project ??= _firstForOwner(
      await isar.projects.filter().remoteIdEqualTo(remoteId).findAll(),
      (project) => project.ownerUserId,
      owner,
    );

    if (project != null && project.isDirty) {
      // Pulls keep the local edit's base version and tombstone. The versioned
      // push must detect a competing remote edit rather than silently rebase.
      project.remoteId ??= remoteId;
      project.syncId ??= remoteSyncId;
      await isar.projects.put(project);
      return;
    }
    if (remoteDeletedAt != null) {
      if (project != null) await isar.projects.delete(project.id);
      return;
    }
    project ??= Project();

    project.remoteId = remoteId;
    project.ownerUserId = owner;
    project.syncId = remoteSyncId ?? project.syncId;
    project.remoteVersion = remoteVersion;
    project.remoteUpdatedAt = remoteUpdatedAt;
    project.syncedAt = remoteUpdatedAt;
    project.isDirty = false;
    project.deletedAt = null;
    project.pendingDelete = false;
    project.name = _parseRemoteString(data['name']) ?? 'Untitled';
    project.stageNames = _parseRemoteStringList(data['stage_names']);
    final statusStr =
        _parseRemoteString(data['status']) ?? ProjectStatus.active.name;
    project.status = ProjectStatus.values.firstWhere(
      (value) => value.name == statusStr,
      orElse: () => ProjectStatus.active,
    );
    project.createdAt = data['created_at'] == null
        ? remoteUpdatedAt
        : _parseRemoteDateTime(data['created_at'], fallback: remoteUpdatedAt);
    project.updatedAt = data['updated_at'] == null
        ? remoteUpdatedAt
        : _parseRemoteDateTime(data['updated_at'], fallback: remoteUpdatedAt);

    await isar.projects.put(project);
  }
}

class _ProjectLink {
  final int id;
  final String name;
  final String? syncId;

  const _ProjectLink({
    required this.id,
    required this.name,
    required this.syncId,
  });
}

class _EvidenceAttachmentFileMetadata {
  final String fileName;
  final String? contentHash;
  final int? sizeBytes;
  final String? mimeType;

  const _EvidenceAttachmentFileMetadata({
    required this.fileName,
    required this.contentHash,
    required this.sizeBytes,
    required this.mimeType,
  });
}
