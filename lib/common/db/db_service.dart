import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import '../utils/date_utils.dart';
import '../services/auth_service.dart';
import '../utils/sync_id_policy.dart';
// import '../services/sync_service.dart'; // Removed cyclic dependency

class DbService {
  late Isar isar; // 数据库实例
  bool _isInitialized = false;

  String? get currentOwnerUserId => serviceLocator.isRegistered<AuthService>()
      ? serviceLocator<AuthService>().userId
      : null;

  bool _belongsToCurrentUser(String? ownerUserId) {
    final currentUserId = currentOwnerUserId;
    return currentUserId == null
        ? ownerUserId == null
        : ownerUserId == currentUserId;
  }

  void _stampWorkLogOwner(WorkLog log) {
    log.ownerUserId ??= currentOwnerUserId;
  }

  void _stampSubscriptionOwner(Subscription sub) {
    sub.ownerUserId ??= currentOwnerUserId;
  }

  void _stampEvidenceOwner(ExpenseEvidence evidence) {
    evidence.ownerUserId ??= currentOwnerUserId;
  }

  void _stampExpenseRecordOwner(ExpenseRecord record) {
    record.ownerUserId ??= currentOwnerUserId;
  }

  void _stampPhotoOwner(PhotoItem photo) {
    photo.ownerUserId ??= currentOwnerUserId;
  }

  void _stampProjectOwner(Project project) {
    project.ownerUserId ??= currentOwnerUserId;
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
  Future<DbService> init() async {
    // 获取手机里专门存文档的路径
    final dir = await getApplicationDocumentsDirectory();

    // 打开数据库
    isar = await Isar.open([
      WorkLogSchema,
      SubscriptionSchema,
      PhotoItemSchema,
      ExpenseEvidenceSchema,
      ExpenseRecordSchema,
      ProjectSchema,
    ], directory: dir.path);

    await _backfillRecordAuditTimestamps();

    _isInitialized = true;
    return this;
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
      _stampWorkLogOwner(log);
      final existing = log.id == Isar.autoIncrement
          ? null
          : await isar.workLogs.get(log.id);
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
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final logs = await isar.workLogs
        .filter()
        .dateGreaterThan(start, include: true)
        .and()
        .dateLessThan(end, include: false)
        .sortByDate()
        .findAll();
    return logs
        .where(
          (log) =>
              log.deletedAt == null && _belongsToCurrentUser(log.ownerUserId),
        )
        .toList();
  }

  // --- 【新增】4. 获取所有日志 (供日历初始化使用) ---
  Future<List<WorkLog>> getAllLogs() async {
    final logs = await isar.workLogs
        .where()
        .sortByDate() // 按日期排序，保证日历加载顺序
        .findAll();
    return logs
        .where(
          (log) =>
              log.deletedAt == null && _belongsToCurrentUser(log.ownerUserId),
        )
        .toList();
  }

  Future<List<WorkLog>> getLogsForDay(DateTime date) async {
    final day = dateOnlyLocal(date);
    final nextDay = day.add(const Duration(days: 1));
    final logs = await isar.workLogs
        .filter()
        .dateGreaterThan(day, include: true)
        .and()
        .dateLessThan(nextDay, include: false)
        .sortByDate()
        .findAll();
    return logs
        .where(
          (log) =>
              log.deletedAt == null && _belongsToCurrentUser(log.ownerUserId),
        )
        .toList();
  }

  Future<List<WorkLog>> getAllLogsForSync() async {
    final logs = await isar.workLogs.where().sortByDate().findAll();
    return logs.where((log) => _belongsToCurrentUser(log.ownerUserId)).toList();
  }

  Future<List<WorkLog>> getPendingLogsForSync() async {
    final logs = await isar.workLogs
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByDate()
        .findAll();
    return logs.where((log) => _belongsToCurrentUser(log.ownerUserId)).toList();
  }

  // --- 5. 获取单条记录 (供 Repository 查询使用) ---
  Future<WorkLog?> getWorkLog(int id) async {
    final log = await isar.workLogs.get(id);
    if (log == null || !_belongsToCurrentUser(log.ownerUserId)) return null;
    return log;
  }

  // 获取日志变更流
  Stream<void> watchWorkLogs() => isar.workLogs.watchLazy();

  // --- 5. 删除日志 (出库) ---
  Future<void> deleteLog(int id) async {
    await isar.writeTxn(() async {
      await isar.workLogs.delete(id);
    });
  }

  Future<WorkLog?> markLogDeleted(int id) async {
    return await isar.writeTxn(() async {
      final log = await isar.workLogs.get(id);
      if (log == null) return null;
      if (!_belongsToCurrentUser(log.ownerUserId)) return null;
      log.deletedAt = DateTime.now().toUtc();
      log.updatedAt = log.deletedAt;
      log.pendingDelete = true;
      log.isDirty = true;
      await isar.workLogs.put(log);
      return log;
    });
  }

  Future<void> purgeDeletedLog(int id) async {
    await isar.writeTxn(() async {
      await isar.workLogs.delete(id);
    });
  }

  // --- 订阅管理相关 ---

  // 1. 获取所有订阅 (按下次付款时间排序)
  Future<List<Subscription>> getAllSubscriptions() async {
    final subs = await isar.subscriptions
        .where()
        .sortByNextPaymentDate()
        .findAll();
    return subs
        .where(
          (sub) =>
              sub.deletedAt == null && _belongsToCurrentUser(sub.ownerUserId),
        )
        .toList();
  }

  Future<List<Subscription>> getAllSubscriptionsForSync() async {
    final subs = await isar.subscriptions
        .where()
        .sortByNextPaymentDate()
        .findAll();
    return subs.where((sub) => _belongsToCurrentUser(sub.ownerUserId)).toList();
  }

  Future<List<Subscription>> getPendingSubscriptionsForSync() async {
    final subs = await isar.subscriptions
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByNextPaymentDate()
        .findAll();
    return subs.where((sub) => _belongsToCurrentUser(sub.ownerUserId)).toList();
  }

  // 2. 获取单条订阅
  Future<Subscription?> getSubscription(int id) async {
    final sub = await isar.subscriptions.get(id);
    if (sub == null || !_belongsToCurrentUser(sub.ownerUserId)) return null;
    return sub;
  }

  // 获取订阅变更流
  Stream<void> watchSubscriptions() => isar.subscriptions.watchLazy();

  // 2. 添加/修改订阅
  Future<int> addSubscription(Subscription sub) async {
    final id = await isar.writeTxn(() async {
      _stampSubscriptionOwner(sub);
      final existing = sub.id == Isar.autoIncrement
          ? null
          : await isar.subscriptions.get(sub.id);
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
    await isar.writeTxn(() async {
      await isar.subscriptions.delete(id);
    });
  }

  Future<Subscription?> markSubscriptionDeleted(int id) async {
    return await isar.writeTxn(() async {
      final sub = await isar.subscriptions.get(id);
      if (sub == null) return null;
      if (!_belongsToCurrentUser(sub.ownerUserId)) return null;
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
        _stampSubscriptionOwner(sub);
        final existing = await isar.subscriptions.get(sub.id);
        if (existing == null || !_belongsToCurrentUser(existing.ownerUserId)) {
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
        .where((photo) => _belongsToCurrentUser(photo.ownerUserId))
        .toList();
  }

  Future<PhotoItem?> getPhoto(int id) async {
    final photo = await isar.photoItems.get(id);
    if (photo == null || !_belongsToCurrentUser(photo.ownerUserId)) return null;
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
      if (photo == null || !_belongsToCurrentUser(photo.ownerUserId)) return;
      await isar.photoItems.delete(id);
    });
  }

  // --- 凭证系统 Evidence ---

  Future<List<ExpenseEvidence>> getAllEvidence() async {
    final items = await isar.expenseEvidences
        .where()
        .sortByEvidenceDateDesc()
        .findAll();
    return items
        .where(
          (item) =>
              item.deletedAt == null && _belongsToCurrentUser(item.ownerUserId),
        )
        .toList();
  }

  Future<List<ExpenseEvidence>> getAllEvidenceForSync() async {
    final items = await isar.expenseEvidences
        .where()
        .sortByEvidenceDateDesc()
        .findAll();
    return items
        .where((item) => _belongsToCurrentUser(item.ownerUserId))
        .toList();
  }

  Future<List<ExpenseEvidence>> getPendingEvidenceForSync() async {
    final items = await isar.expenseEvidences
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByEvidenceDateDesc()
        .findAll();
    return items
        .where((item) => _belongsToCurrentUser(item.ownerUserId))
        .toList();
  }

  Future<ExpenseEvidence?> getEvidenceBySyncId(String syncId) async {
    final item = await isar.expenseEvidences
        .filter()
        .syncIdEqualTo(syncId)
        .findFirst();
    if (item == null || !_belongsToCurrentUser(item.ownerUserId)) return null;
    return item;
  }

  Future<ExpenseEvidence?> getEvidence(int id) async {
    final item = await isar.expenseEvidences.get(id);
    if (item == null || !_belongsToCurrentUser(item.ownerUserId)) return null;
    return item;
  }

  Stream<void> watchEvidence() => isar.expenseEvidences.watchLazy();

  Future<int> addEvidence(ExpenseEvidence evidence) async {
    final id = await isar.writeTxn(() async {
      _stampEvidenceOwner(evidence);
      final existing = evidence.id == Isar.autoIncrement
          ? null
          : await isar.expenseEvidences.get(evidence.id);
      _stampEvidenceAudit(evidence, existing);
      evidence.isDirty =
          existing?.isDirty == true ||
          evidence.isDirty ||
          evidence.remoteId == null ||
          (existing != null && evidence.hasBusinessChangesComparedTo(existing));
      return await isar.expenseEvidences.put(evidence);
    });
    return id;
  }

  Future<ExpenseEvidence?> markEvidenceDeleted(int id) async {
    return await isar.writeTxn(() async {
      final item = await isar.expenseEvidences.get(id);
      if (item == null) return null;
      if (!_belongsToCurrentUser(item.ownerUserId)) return null;
      item.deletedAt = DateTime.now().toUtc();
      item.updatedAt = item.deletedAt;
      item.pendingDelete = true;
      item.isDirty = true;
      await isar.expenseEvidences.put(item);
      return item;
    });
  }

  Future<void> purgeDeletedEvidence(int id) async {
    await isar.writeTxn(() async {
      await isar.expenseEvidences.delete(id);
    });
  }

  Future<void> updateEvidenceRemoteId(ExpenseEvidence evidence) async {
    await isar.writeTxn(() async {
      await isar.expenseEvidences.put(evidence);
    });
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
    final projects = await isar.projects
        .where()
        .sortByUpdatedAtDesc()
        .findAll();
    return projects
        .where(
          (project) =>
              project.deletedAt == null &&
              _belongsToCurrentUser(project.ownerUserId),
        )
        .toList();
  }

  Stream<void> watchProjects() => isar.projects.watchLazy();

  Future<int> addProject(Project project) async {
    final id = await isar.writeTxn(() async {
      _stampProjectOwner(project);
      final existing = project.id == Isar.autoIncrement
          ? null
          : await isar.projects.get(project.id);
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
    final projects = await isar.projects
        .where()
        .sortByUpdatedAtDesc()
        .findAll();
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
    final projects = await isar.projects
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();
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
    final project = await isar.projects.get(id);
    if (project == null || !_belongsToCurrentUser(project.ownerUserId)) {
      return null;
    }
    return project;
  }

  Future<Project?> markProjectDeleted(int id) async {
    return await isar.writeTxn(() async {
      final project = await isar.projects.get(id);
      if (project == null) return null;
      if (!_belongsToCurrentUser(project.ownerUserId)) return null;
      project.deletedAt = DateTime.now().toUtc();
      project.pendingDelete = true;
      project.isDirty = true;
      await isar.projects.put(project);
      return project;
    });
  }

  Future<void> purgeDeletedProject(int id) async {
    await isar.writeTxn(() async {
      await isar.projects.delete(id);
    });
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

  // --- 一次性消费 ExpenseRecord ---

  Future<List<ExpenseRecord>> getAllExpenseRecords() async {
    final records = await isar.expenseRecords
        .where()
        .sortByExpenseDateDesc()
        .findAll();
    return records
        .where(
          (record) =>
              record.deletedAt == null &&
              _belongsToCurrentUser(record.ownerUserId),
        )
        .toList();
  }

  Future<List<ExpenseRecord>> getAllExpenseRecordsForSync() async {
    final records = await isar.expenseRecords
        .where()
        .sortByExpenseDateDesc()
        .findAll();
    return records
        .where((record) => _belongsToCurrentUser(record.ownerUserId))
        .toList();
  }

  Future<List<ExpenseRecord>> getPendingExpenseRecordsForSync() async {
    final records = await isar.expenseRecords
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByExpenseDateDesc()
        .findAll();
    return records
        .where((record) => _belongsToCurrentUser(record.ownerUserId))
        .toList();
  }

  Stream<void> watchExpenseRecords() => isar.expenseRecords.watchLazy();

  Future<int> addExpenseRecord(ExpenseRecord record) async {
    final id = await isar.writeTxn(() async {
      _stampExpenseRecordOwner(record);
      final existing = record.id == Isar.autoIncrement
          ? null
          : await isar.expenseRecords.get(record.id);
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
    final record = await isar.expenseRecords.get(id);
    if (record == null || !_belongsToCurrentUser(record.ownerUserId)) {
      return null;
    }
    return record;
  }

  Future<ExpenseRecord?> markExpenseRecordDeleted(int id) async {
    return await isar.writeTxn(() async {
      final record = await isar.expenseRecords.get(id);
      if (record == null) return null;
      if (!_belongsToCurrentUser(record.ownerUserId)) return null;
      record.deletedAt = DateTime.now().toUtc();
      record.updatedAt = record.deletedAt;
      record.pendingDelete = true;
      record.isDirty = true;
      await isar.expenseRecords.put(record);
      return record;
    });
  }

  Future<void> purgeDeletedExpenseRecord(int id) async {
    await isar.writeTxn(() async {
      await isar.expenseRecords.delete(id);
    });
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
      data['start_date'],
      fallback: remoteUpdatedAt,
    );
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
    item.projectName =
        _parseRemoteString(data['project_name']) ?? 'DefaultProject';
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
    int? projectId;
    if (projectName != null && projectName.trim().isNotEmpty) {
      final safeProjectName = projectName.trim();
      final projects = await isar.projects.where().findAll();
      Project? project;
      for (final item in projects) {
        if (_belongsToCurrentUser(item.ownerUserId) &&
            item.name.toLowerCase() == safeProjectName.toLowerCase()) {
          project = item;
          break;
        }
      }
      if (project == null) {
        final now = DateTime.now();
        project = Project()
          ..name = safeProjectName
          ..ownerUserId = currentOwnerUserId
          ..createdAt = now
          ..updatedAt = now
          ..syncId = ensureSyncId(null)
          ..isDirty = true;
        project.id = await isar.projects.put(project);
      }
      projectId = project.id;
    }

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
    record.projectName = projectName;
    record.projectId = projectId;

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
