import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_conflict_model.dart';
import 'package:life_log/core/sync/sync_queue_record.dart';
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
import 'package:life_log/features/evidence/data/evidence_dao.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_dao.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import '../utils/date_utils.dart';
import '../services/auth_service.dart';
import '../utils/sync_id_policy.dart';
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

  String? get currentOwnerUserId => serviceLocator.isRegistered<AuthService>()
      ? serviceLocator<AuthService>().userId
      : null;

  bool _belongsToCurrentUser(String? ownerUserId) {
    final currentUserId = currentOwnerUserId;
    return currentUserId == null
        ? ownerUserId == null
        : ownerUserId == currentUserId;
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
    log.remoteId ??= existing.remoteId;
    log.syncId ??= existing.syncId;
    if (log.remoteVersion == 0) log.remoteVersion = existing.remoteVersion;
    log.remoteUpdatedAt ??= existing.remoteUpdatedAt;
    log.syncedAt ??= existing.syncedAt;
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
    sub.remoteId ??= existing.remoteId;
    sub.syncId ??= existing.syncId;
    if (sub.remoteVersion == 0) sub.remoteVersion = existing.remoteVersion;
    sub.remoteUpdatedAt ??= existing.remoteUpdatedAt;
    sub.syncedAt ??= existing.syncedAt;
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
    evidence.remoteId ??= existing.remoteId;
    evidence.syncId ??= existing.syncId;
    if (evidence.remoteVersion == 0) {
      evidence.remoteVersion = existing.remoteVersion;
    }
    evidence.remoteUpdatedAt ??= existing.remoteUpdatedAt;
    evidence.syncedAt ??= existing.syncedAt;
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
    record.remoteId ??= existing.remoteId;
    record.syncId ??= existing.syncId;
    if (record.remoteVersion == 0) {
      record.remoteVersion = existing.remoteVersion;
    }
    record.remoteUpdatedAt ??= existing.remoteUpdatedAt;
    record.syncedAt ??= existing.syncedAt;
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
    project.remoteId ??= existing.remoteId;
    project.syncId ??= existing.syncId;
    if (project.remoteVersion == 0) {
      project.remoteVersion = existing.remoteVersion;
    }
    project.remoteUpdatedAt ??= existing.remoteUpdatedAt;
    project.syncedAt ??= existing.syncedAt;
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
    await isar.writeTxn(() async {
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
    return isar.writeTxn(() => isar.localDataMigrationBatchs.put(batch));
  }

  Future<void> completeLocalDataMigrationBatch(int id) async {
    await isar.writeTxn(() async {
      final batch = await isar.localDataMigrationBatchs.get(id);
      if (batch == null) return;
      batch.completedAt = DateTime.now().toUtc();
      batch.status = 'completed';
      await isar.localDataMigrationBatchs.put(batch);
    });
  }

  Future<void> failLocalDataMigrationBatch(int id) async {
    await isar.writeTxn(() async {
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
    await isar.writeTxn(() async {
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
    database = openedDatabase;
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
    await isar.writeTxn(() async {
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
    await isar.writeTxn(() async {
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
    final id = await isar.writeTxn(() async {
      final existing = log.id == Isar.autoIncrement
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
      return await isar.workLogs.put(log); // Insert or update
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

  Future<List<WorkLog>> getPendingLogsForSync() async {
    return _workLogDao.getPendingForSyncForOwner(currentOwnerUserId);
  }

  // --- 5. 获取单条记录 (供 Repository 查询使用) ---
  Future<WorkLog?> getWorkLog(int id) async {
    final log = await _workLogDao.getById(id);
    if (log == null || !_isVisibleToCurrentUser(log.ownerUserId)) return null;
    return log;
  }

  // 获取日志变更流
  Stream<void> watchWorkLogs() => _workLogDao.watch();

  // --- 5. 删除日志 (出库) ---
  Future<void> deleteLog(int id) async {
    await _workLogDao.delete(id);
  }

  Future<WorkLog?> markLogDeleted(int id) async {
    return await isar.writeTxn(() async {
      final log = await isar.workLogs.get(id);
      if (log == null) return null;
      if (!_isVisibleToCurrentUser(log.ownerUserId)) return null;
      log.deletedAt = DateTime.now().toUtc();
      log.updatedAt = log.deletedAt;
      log.pendingDelete = true;
      log.isDirty = true;
      await isar.workLogs.put(log);
      return log;
    });
  }

  Future<void> purgeDeletedLog(int id) async {
    await _workLogDao.delete(id);
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

  Future<List<Subscription>> getPendingSubscriptionsForSync() async {
    return _subscriptionDao.getPendingForSyncForOwner(currentOwnerUserId);
  }

  // 2. 获取单条订阅
  Future<Subscription?> getSubscription(int id) async {
    final sub = await _subscriptionDao.getById(id);
    if (sub == null || !_isVisibleToCurrentUser(sub.ownerUserId)) return null;
    return sub;
  }

  // 获取订阅变更流
  Stream<void> watchSubscriptions() => _subscriptionDao.watch();

  // 2. 添加/修改订阅
  Future<int> addSubscription(Subscription sub) async {
    final id = await isar.writeTxn(() async {
      final existing = sub.id == Isar.autoIncrement
          ? null
          : await isar.subscriptions.get(sub.id);
      _stampSubscriptionOwner(sub, existing);
      _preserveSubscriptionSyncIdentity(sub, existing);
      sub.isDirty =
          existing?.isDirty == true ||
          sub.isDirty ||
          sub.remoteId == null ||
          (existing != null && sub.hasBusinessChangesComparedTo(existing));
      return await isar.subscriptions.put(sub); // Insert or update
    });
    return id;
  }

  // 3. 删除订阅
  Future<void> deleteSubscription(int id) async {
    await _subscriptionDao.delete(id);
  }

  Future<Subscription?> markSubscriptionDeleted(int id) async {
    return await isar.writeTxn(() async {
      final sub = await isar.subscriptions.get(id);
      if (sub == null) return null;
      if (!_isVisibleToCurrentUser(sub.ownerUserId)) return null;
      sub.deletedAt = DateTime.now().toUtc();
      sub.pendingDelete = true;
      sub.isDirty = true;
      await isar.subscriptions.put(sub);
      return sub;
    });
  }

  Future<void> purgeDeletedSubscription(int id) async {
    await isar.writeTxn(() async {
      await isar.subscriptions.delete(id);
    });
  }

  // 4. Update Subscription Order
  Future<List<Subscription>> reorderSubscriptions(
    List<Subscription> subs,
  ) async {
    return await isar.writeTxn(() async {
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
  Stream<void> watchPhotos() => isar.photoItems.watchLazy();

  Future<void> addPhoto(PhotoItem photo) async {
    await isar.writeTxn(() async {
      _stampPhotoOwner(photo);
      await isar.photoItems.put(photo);
    });
  }

  Future<void> deletePhoto(int id) async {
    await isar.writeTxn(() async {
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

  Future<List<ExpenseEvidence>> getPendingEvidenceForSync() async {
    return _evidenceDao.getPendingForSyncForOwner(currentOwnerUserId);
  }

  Future<ExpenseEvidence?> getEvidenceBySyncId(String syncId) async {
    final item = await _evidenceDao.getBySyncId(syncId);
    if (item == null || !_isVisibleToCurrentUser(item.ownerUserId)) return null;
    return item;
  }

  Future<ExpenseEvidence?> getEvidence(int id) async {
    final item = await _evidenceDao.getById(id);
    if (item == null || !_isVisibleToCurrentUser(item.ownerUserId)) return null;
    return item;
  }

  Stream<void> watchEvidence() => _evidenceDao.watch();

  Future<int> addEvidence(ExpenseEvidence evidence) async {
    final hasLocalAttachment =
        evidence.localFilePath?.trim().isNotEmpty == true;
    if (hasLocalAttachment) {
      evidence.syncId = ensureSyncId(evidence.syncId);
    }
    final id = await isar.writeTxn(() async {
      final existing = evidence.id == Isar.autoIncrement
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
      return await isar.expenseEvidences.put(evidence);
    });
    evidence.id = id;
    if (hasLocalAttachment) {
      await ensureEvidenceAttachmentForEvidence(evidence);
    }
    return id;
  }

  Future<ExpenseEvidence?> markEvidenceDeleted(int id) async {
    return await isar.writeTxn(() async {
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
      return item;
    });
  }

  Future<void> purgeDeletedEvidence(int id) async {
    final item = await _evidenceDao.getById(id);
    final evidenceSyncId = item?.syncId;
    if (evidenceSyncId != null) {
      await isar.writeTxn(() async {
        final attachments = await isar.evidenceAttachments
            .filter()
            .evidenceSyncIdEqualTo(evidenceSyncId)
            .findAll();
        await isar.evidenceAttachments.deleteAll(
          attachments.map((attachment) => attachment.id).toList(),
        );
      });
    }
    await _evidenceDao.delete(id);
  }

  Future<void> updateEvidenceRemoteId(ExpenseEvidence evidence) async {
    await isar.writeTxn(() async {
      await isar.expenseEvidences.put(evidence);
    });
  }

  Future<EvidenceAttachment?> ensureEvidenceAttachmentForEvidence(
    ExpenseEvidence evidence,
  ) async {
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

    return isar.writeTxn(() async {
      final persistedEvidence = await isar.expenseEvidences.get(evidence.id);
      if (persistedEvidence != null && persistedEvidence.syncId == null) {
        persistedEvidence.syncId = evidenceSyncId;
        await isar.expenseEvidences.put(persistedEvidence);
      }

      final existing = await isar.evidenceAttachments
          .filter()
          .evidenceSyncIdEqualTo(evidenceSyncId)
          .findAll();
      EvidenceAttachment? attachment;
      for (final item in existing) {
        if (item.localPath == localPath && item.deletedAt == null) {
          attachment = item;
          break;
        }
      }

      for (final item in existing) {
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
        ..ownerUserId = evidence.ownerUserId ?? currentOwnerUserId
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

  Future<List<EvidenceAttachment>>
  getPendingEvidenceAttachmentsForSync() async {
    final attachments = await isar.evidenceAttachments.where().findAll();
    return attachments
        .where(
          (item) =>
              _belongsToCurrentUser(item.ownerUserId) &&
              (item.uploadState == EvidenceAttachmentUploadState.pending ||
                  item.uploadState == EvidenceAttachmentUploadState.failed ||
                  item.uploadState == EvidenceAttachmentUploadState.deleted),
        )
        .toList();
  }

  Future<EvidenceAttachment?> getEvidenceAttachmentBySyncId(
    String syncId,
  ) async {
    return isar.evidenceAttachments.filter().syncIdEqualTo(syncId).findFirst();
  }

  Future<void> syncRemoteEvidenceAttachmentToLocal(
    Map<String, dynamic> data,
  ) async {
    final remoteSyncId = _parseRemoteString(data['sync_id']);
    final evidenceSyncId = _parseRemoteString(data['evidence_sync_id']);
    if (remoteSyncId == null || evidenceSyncId == null) return;

    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : _parseRemoteDateTime(data['deleted_at']);
    await isar.writeTxn(() async {
      final existing = await isar.evidenceAttachments
          .filter()
          .syncIdEqualTo(remoteSyncId)
          .findFirst();

      if (remoteDeletedAt != null) {
        if (existing != null) {
          await isar.evidenceAttachments.delete(existing.id);
        }
        return;
      }

      final now = DateTime.now().toUtc();
      final item = existing ?? EvidenceAttachment();
      item
        ..ownerUserId = currentOwnerUserId
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

      final evidence = await isar.expenseEvidences
          .filter()
          .syncIdEqualTo(evidenceSyncId)
          .findFirst();
      final remoteStoragePath = item.remoteStoragePath;
      if (evidence != null &&
          remoteStoragePath != null &&
          remoteStoragePath.trim().isNotEmpty) {
        evidence
          ..remoteStoragePath = remoteStoragePath
          ..fileName ??= item.originalFileName
          ..mimeType ??= item.mimeType
          ..uploadedAt ??= item.uploadedAt;
        await isar.expenseEvidences.put(evidence);
      }
    });
  }

  Future<void> markEvidenceAttachmentUploading(EvidenceAttachment attachment) {
    return _updateEvidenceAttachment(attachment.id, (item) {
      item
        ..uploadState = EvidenceAttachmentUploadState.uploading
        ..failureMessage = null
        ..updatedAt = DateTime.now().toUtc();
    });
  }

  Future<void> markEvidenceAttachmentUploaded(
    EvidenceAttachment attachment, {
    required String remoteStoragePath,
  }) {
    return isar.writeTxn(() async {
      final item = await isar.evidenceAttachments.get(attachment.id);
      if (item == null) return;
      final now = DateTime.now().toUtc();
      item
        ..remoteStoragePath = remoteStoragePath
        ..uploadState = EvidenceAttachmentUploadState.uploaded
        ..uploadedAt = now
        ..deletedAt = null
        ..failureMessage = null
        ..updatedAt = now;
      await isar.evidenceAttachments.put(item);

      final evidence = await isar.expenseEvidences
          .filter()
          .syncIdEqualTo(item.evidenceSyncId)
          .findFirst();
      if (evidence != null) {
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
    Object error,
  ) {
    return _updateEvidenceAttachment(attachment.id, (item) {
      item
        ..uploadState = EvidenceAttachmentUploadState.failed
        ..failureMessage = error.toString()
        ..updatedAt = DateTime.now().toUtc();
    });
  }

  Future<void> queueEvidenceAttachmentDeleteForEvidence(
    ExpenseEvidence evidence,
  ) async {
    if (evidence.localFilePath == null && evidence.remoteStoragePath == null) {
      return;
    }
    evidence.syncId = ensureSyncId(evidence.syncId);
    await isar.writeTxn(() async {
      await _queueEvidenceAttachmentDeleteInTxn(evidence);
    });
  }

  Future<void> purgeEvidenceAttachment(int id) async {
    await isar.writeTxn(() => isar.evidenceAttachments.delete(id));
  }

  Future<void> _updateEvidenceAttachment(
    int id,
    void Function(EvidenceAttachment item) update,
  ) async {
    await isar.writeTxn(() async {
      final item = await isar.evidenceAttachments.get(id);
      if (item == null) return;
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

    if (attachments.isEmpty) {
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

    for (final attachment in attachments) {
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

  Future<void> updateWorkLogRemoteId(WorkLog log) async {
    await isar.writeTxn(() async {
      await isar.workLogs.put(log);
    });
  }

  Future<void> updateSubscriptionRemoteId(Subscription sub) async {
    await isar.writeTxn(() async {
      await isar.subscriptions.put(sub);
    });
  }

  // --- 项目 Project ---

  Future<List<Project>> getAllProjects() async {
    return _projectDao.getActiveSortedForOwner(currentOwnerUserId);
  }

  Stream<void> watchProjects() => _projectDao.watch();

  Future<int> addProject(Project project) async {
    final id = await isar.writeTxn(() async {
      project.stageNames = _normalizeStringList(project.stageNames);
      final existing = project.id == Isar.autoIncrement
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
      return await isar.projects.put(project);
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

  Future<List<Project>> getPendingProjectsForSync() async {
    final syncableProjectNames = await _getSyncableProjectNames();
    final projects = await _projectDao.getPendingForSyncForOwner(
      currentOwnerUserId,
    );
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

  Future<Project?> getProject(int id) async {
    final project = await _projectDao.getById(id);
    if (project == null || !_isVisibleToCurrentUser(project.ownerUserId)) {
      return null;
    }
    return project;
  }

  Future<Project?> markProjectDeleted(int id) async {
    return await isar.writeTxn(() async {
      final project = await isar.projects.get(id);
      if (project == null) return null;
      if (!_isVisibleToCurrentUser(project.ownerUserId)) return null;
      project.deletedAt = DateTime.now().toUtc();
      project.pendingDelete = true;
      project.isDirty = true;
      await isar.projects.put(project);
      return project;
    });
  }

  Future<void> purgeDeletedProject(int id) async {
    await _projectDao.delete(id);
  }

  Future<void> updateProjectRemoteId(Project project) async {
    await isar.writeTxn(() async {
      await isar.projects.put(project);
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
      project = await isar.projects
          .filter()
          .syncIdEqualTo(normalizedSyncId)
          .findFirst();
      if (project != null && !_belongsToCurrentUser(project.ownerUserId)) {
        project = null;
      }
    } else if (hasName) {
      final projects = await isar.projects.where().findAll();
      for (final item in projects) {
        if (_belongsToCurrentUser(item.ownerUserId) &&
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
        ..ownerUserId = currentOwnerUserId
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

  Future<List<ExpenseRecord>> getPendingExpenseRecordsForSync() async {
    return _expenseRecordDao.getPendingForSyncForOwner(currentOwnerUserId);
  }

  Stream<void> watchExpenseRecords() => _expenseRecordDao.watch();

  Future<int> addExpenseRecord(ExpenseRecord record) async {
    final id = await isar.writeTxn(() async {
      final existing = record.id == Isar.autoIncrement
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
      return await isar.expenseRecords.put(record);
    });
    return id;
  }

  Future<ExpenseRecord?> getExpenseRecord(int id) async {
    final record = await _expenseRecordDao.getById(id);
    if (record == null || !_isVisibleToCurrentUser(record.ownerUserId)) {
      return null;
    }
    return record;
  }

  Future<ExpenseRecord?> markExpenseRecordDeleted(int id) async {
    return await isar.writeTxn(() async {
      final record = await isar.expenseRecords.get(id);
      if (record == null) return null;
      if (!_isVisibleToCurrentUser(record.ownerUserId)) return null;
      record.deletedAt = DateTime.now().toUtc();
      record.updatedAt = record.deletedAt;
      record.pendingDelete = true;
      record.isDirty = true;
      await isar.expenseRecords.put(record);
      return record;
    });
  }

  Future<void> purgeDeletedExpenseRecord(int id) async {
    await _expenseRecordDao.delete(id);
  }

  Future<void> updateExpenseRecordRemoteId(ExpenseRecord record) async {
    await isar.writeTxn(() async {
      await isar.expenseRecords.put(record);
    });
  }

  // Sync Remote -> Local (WorkLog)
  Future<void> syncRemoteLogsToLocal(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await isar.writeTxn(() async {
      for (final data in rows) {
        await _syncRemoteLogToLocalInTxn(data);
      }
    });
  }

  Future<void> syncRemoteLogToLocal(Map<String, dynamic> data) {
    return syncRemoteLogsToLocal([data]);
  }

  Future<void> _syncRemoteLogToLocalInTxn(Map<String, dynamic> data) async {
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
      log = await isar.workLogs
          .filter()
          .syncIdEqualTo(remoteSyncId)
          .findFirst();
    }
    log ??= await isar.workLogs.filter().remoteIdEqualTo(remoteId).findFirst();

    if (remoteDeletedAt != null) {
      if (log != null) {
        if (!log.isDirty || log.pendingDelete) {
          await isar.workLogs.delete(log.id);
          return;
        }
        log.deletedAt = remoteDeletedAt;
        log.ownerUserId = currentOwnerUserId;
        log.pendingDelete = false;
        log.remoteId = remoteId;
        log.syncId = remoteSyncId ?? log.syncId;
        log.remoteVersion = remoteVersion;
        log.remoteUpdatedAt = remoteUpdatedAt;
        log.syncedAt = remoteUpdatedAt;
        await isar.workLogs.put(log);
      }
      return;
    }

    // Do not match by remote local_id: it is generated per device and can collide.
    log ??= WorkLog();

    if (log.isDirty) {
      log.ownerUserId = currentOwnerUserId;
      if (log.remoteId != remoteId) {
        log.remoteId = remoteId;
      }
      log.syncId = remoteSyncId ?? log.syncId;
      log.remoteVersion = remoteVersion;
      log.remoteUpdatedAt = remoteUpdatedAt;
      await isar.workLogs.put(log);
      return;
    }

    log.remoteId = remoteId;
    log.ownerUserId = currentOwnerUserId;
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
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await isar.writeTxn(() async {
      for (final data in rows) {
        await _syncRemoteSubscriptionToLocalInTxn(data);
      }
    });
  }

  Future<void> syncRemoteSubscriptionToLocal(Map<String, dynamic> data) {
    return syncRemoteSubscriptionsToLocal([data]);
  }

  Future<void> _syncRemoteSubscriptionToLocalInTxn(
    Map<String, dynamic> data,
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
      sub = await isar.subscriptions
          .filter()
          .syncIdEqualTo(remoteSyncId)
          .findFirst();
    }
    sub ??= await isar.subscriptions
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();

    if (remoteDeletedAt != null) {
      if (sub != null) {
        if (!sub.isDirty || sub.pendingDelete) {
          await isar.subscriptions.delete(sub.id);
          return;
        }
        sub.deletedAt = remoteDeletedAt;
        sub.ownerUserId = currentOwnerUserId;
        sub.pendingDelete = false;
        sub.remoteId = remoteId;
        sub.syncId = remoteSyncId ?? sub.syncId;
        sub.remoteVersion = remoteVersion;
        sub.remoteUpdatedAt = remoteUpdatedAt;
        sub.syncedAt = remoteUpdatedAt;
        await isar.subscriptions.put(sub);
      }
      return;
    }

    sub ??= Subscription();

    if (sub.isDirty) {
      sub.ownerUserId = currentOwnerUserId;
      if (sub.remoteId != remoteId) {
        sub.remoteId = remoteId;
      }
      sub.syncId = remoteSyncId ?? sub.syncId;
      sub.remoteVersion = remoteVersion;
      sub.remoteUpdatedAt = remoteUpdatedAt;
      await isar.subscriptions.put(sub);
      return;
    }

    sub.remoteId = remoteId;
    sub.ownerUserId = currentOwnerUserId;
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
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await isar.writeTxn(() async {
      for (final data in rows) {
        await _syncRemoteEvidenceToLocalInTxn(data);
      }
    });
  }

  Future<void> syncRemoteEvidenceToLocal(Map<String, dynamic> data) {
    return syncRemoteEvidenceRowsToLocal([data]);
  }

  Future<void> _syncRemoteEvidenceToLocalInTxn(
    Map<String, dynamic> data,
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
      item = await isar.expenseEvidences
          .filter()
          .syncIdEqualTo(remoteSyncId)
          .findFirst();
    }
    item ??= await isar.expenseEvidences
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();

    if (remoteDeletedAt != null) {
      if (item != null) {
        if (!item.isDirty || item.pendingDelete) {
          await isar.expenseEvidences.delete(item.id);
          return;
        }
        item.deletedAt = remoteDeletedAt;
        item.ownerUserId = currentOwnerUserId;
        item.pendingDelete = false;
        item.remoteId = remoteId;
        item.syncId = remoteSyncId ?? item.syncId;
        item.remoteVersion = remoteVersion;
        item.remoteUpdatedAt = remoteUpdatedAt;
        item.syncedAt = remoteUpdatedAt;
        await isar.expenseEvidences.put(item);
      }
      return;
    }

    item ??= ExpenseEvidence();

    if (item.isDirty) {
      item.ownerUserId = currentOwnerUserId;
      if (item.remoteId != remoteId) {
        item.remoteId = remoteId;
      }
      item.syncId = remoteSyncId ?? item.syncId;
      item.remoteVersion = remoteVersion;
      item.remoteUpdatedAt = remoteUpdatedAt;
      await isar.expenseEvidences.put(item);
      return;
    }

    item.remoteId = remoteId;
    item.ownerUserId = currentOwnerUserId;
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
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await isar.writeTxn(() async {
      for (final data in rows) {
        await _syncRemoteExpenseRecordToLocalInTxn(data);
      }
    });
  }

  Future<void> syncRemoteExpenseRecordToLocal(Map<String, dynamic> data) {
    return syncRemoteExpenseRecordsToLocal([data]);
  }

  Future<void> _syncRemoteExpenseRecordToLocalInTxn(
    Map<String, dynamic> data,
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
      record = await isar.expenseRecords
          .filter()
          .syncIdEqualTo(remoteSyncId)
          .findFirst();
    }
    record ??= await isar.expenseRecords
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();

    if (remoteDeletedAt != null) {
      if (record != null) {
        if (!record.isDirty || record.pendingDelete) {
          await isar.expenseRecords.delete(record.id);
          return;
        }
        record.deletedAt = remoteDeletedAt;
        record.ownerUserId = currentOwnerUserId;
        record.pendingDelete = false;
        record.remoteId = remoteId;
        record.syncId = remoteSyncId ?? record.syncId;
        record.remoteVersion = remoteVersion;
        record.remoteUpdatedAt = remoteUpdatedAt;
        record.syncedAt = remoteUpdatedAt;
        await isar.expenseRecords.put(record);
      }
      return;
    }

    record ??= ExpenseRecord();

    if (record.isDirty) {
      record.ownerUserId = currentOwnerUserId;
      if (record.remoteId != remoteId) {
        record.remoteId = remoteId;
      }
      record.syncId = remoteSyncId ?? record.syncId;
      record.remoteVersion = remoteVersion;
      record.remoteUpdatedAt = remoteUpdatedAt;
      await isar.expenseRecords.put(record);
      return;
    }

    final projectName = _parseRemoteString(data['project_name']);
    final projectSyncId = _parseRemoteString(data['project_sync_id']);
    final projectLink = await _resolveProjectLinkInTxn(
      projectName: projectName,
      projectSyncId: projectSyncId,
    );
    final tripWorkLogSyncId = _parseRemoteString(data['trip_work_log_sync_id']);
    final tripWorkLog = tripWorkLogSyncId == null
        ? null
        : await isar.workLogs
              .filter()
              .syncIdEqualTo(tripWorkLogSyncId)
              .findFirst();

    record.remoteId = remoteId;
    record.ownerUserId = currentOwnerUserId;
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
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await isar.writeTxn(() async {
      for (final data in rows) {
        await _syncRemoteProjectToLocalInTxn(data);
      }
    });
  }

  Future<void> syncRemoteProjectToLocal(Map<String, dynamic> data) {
    return syncRemoteProjectsToLocal([data]);
  }

  Future<void> _syncRemoteProjectToLocalInTxn(Map<String, dynamic> data) async {
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
      project = await isar.projects
          .filter()
          .syncIdEqualTo(remoteSyncId)
          .findFirst();
    }
    project ??= await isar.projects
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();

    if (remoteDeletedAt != null) {
      if (project != null) {
        if (!project.isDirty || project.pendingDelete) {
          await isar.projects.delete(project.id);
          return;
        }
        project.deletedAt = remoteDeletedAt;
        project.ownerUserId = currentOwnerUserId;
        project.pendingDelete = false;
        project.remoteId = remoteId;
        project.syncId = remoteSyncId ?? project.syncId;
        project.remoteVersion = remoteVersion;
        project.remoteUpdatedAt = remoteUpdatedAt;
        project.syncedAt = remoteUpdatedAt;
        await isar.projects.put(project);
      }
      return;
    }

    project ??= Project();

    if (project.isDirty) {
      project.ownerUserId = currentOwnerUserId;
      if (project.remoteId != remoteId) {
        project.remoteId = remoteId;
      }
      project.syncId = remoteSyncId ?? project.syncId;
      project.remoteVersion = remoteVersion;
      project.remoteUpdatedAt = remoteUpdatedAt;
      await isar.projects.put(project);
      return;
    }

    project.remoteId = remoteId;
    project.ownerUserId = currentOwnerUserId;
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
