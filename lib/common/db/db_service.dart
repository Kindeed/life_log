import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../modules/work_log/work_log_model.dart';
import '../../modules/subscription/subscription_model.dart';
import '../../modules/photo/photo_model.dart'; // Import PhotoModel
import '../../modules/evidence/evidence_model.dart';
import '../../modules/expense/expense_record_model.dart';
import '../../modules/project/project_model.dart';
import '../services/auth_service.dart';
import '../utils/sync_id_generator.dart';
// import '../services/sync_service.dart'; // Removed cyclic dependency

class DbService extends GetxService {
  // 单例模式：确保整个App只有一个仓库管理员
  static DbService get to => Get.find();

  late Isar isar; // 数据库实例

  String? get currentOwnerUserId =>
      Get.isRegistered<AuthService>() ? AuthService.to.userId : null;

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

  bool _isProjectSyncEligible(Project project) {
    return project.remoteId != null ||
        project.syncId != null ||
        project.pendingDelete;
  }

  Future<Set<String>> _getSyncableProjectNames() async {
    final syncableProjectNames = <String>{};

    final evidenceRefs = await isar.expenseEvidences.where().findAll();
    for (final item in evidenceRefs) {
      if (_belongsToCurrentUser(item.ownerUserId) &&
          item.projectName.trim().isNotEmpty) {
        syncableProjectNames.add(item.projectName.trim().toLowerCase());
      }
    }

    final expenseRecordRefs = await isar.expenseRecords.where().findAll();
    for (final item in expenseRecordRefs) {
      if (_belongsToCurrentUser(item.ownerUserId) &&
          (item.projectName?.trim().isNotEmpty ?? false)) {
        syncableProjectNames.add(item.projectName!.trim().toLowerCase());
      }
    }

    return syncableProjectNames;
  }

  Future<void> claimUnownedRecordsForCurrentUser() async {
    final currentUserId = currentOwnerUserId;
    if (currentUserId == null) return;

    await isar.writeTxn(() async {
      final logs = await isar.workLogs.filter().ownerUserIdIsNull().findAll();
      for (final log in logs) {
        log.ownerUserId = currentUserId;
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
        sub.ownerUserId = currentUserId;
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
        item.ownerUserId = currentUserId;
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
        item.ownerUserId = currentUserId;
        item.isDirty = true;
      }
      if (expenseRecords.isNotEmpty) {
        await isar.expenseRecords.putAll(expenseRecords);
      }

      final syncableProjectNames = await _getSyncableProjectNames();

      final projects = await isar.projects.filter().ownerUserIdIsNull().findAll();
      for (final project in projects) {
        project.ownerUserId = currentUserId;
        final syncable = syncableProjectNames.contains(
          project.name.trim().toLowerCase(),
        );
        if (syncable || _isProjectSyncEligible(project)) {
          project.syncId ??= SyncIdGenerator.newSyncId();
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

    return this;
  }

  @override
  void onClose() {
    if (isar.isOpen) {
      isar.close();
    }
    super.onClose();
  }

  // --- 2. 增加一条日志 (入库) ---
  Future<int> addLog(WorkLog log) async {
    final id = await isar.writeTxn(() async {
      _stampWorkLogOwner(log);
      final existing = log.id == Isar.autoIncrement
          ? null
          : await isar.workLogs.get(log.id);
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

  Future<List<WorkLog>> getAllLogsForSync() async {
    final logs = await isar.workLogs.where().sortByDate().findAll();
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
  Future<void> reorderSubscriptions(List<Subscription> subs) async {
    await isar.writeTxn(() async {
      for (int i = 0; i < subs.length; i++) {
        _stampSubscriptionOwner(subs[i]);
        subs[i].sortIndex = i;
        subs[i].isDirty = true;
        await isar.subscriptions.put(subs[i]);
      }
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
            project.isDirty || existing.isDirty || project.hasBusinessChangesComparedTo(existing);
      } else {
        project.isDirty =
            project.isDirty || project.remoteId == null && project.syncId != null;
      }
      return await isar.projects.put(project);
    });
    return id;
  }

  Future<List<Project>> getAllProjectsForSync() async {
    final syncableProjectNames = await _getSyncableProjectNames();
    final projects = await isar.projects.where().sortByUpdatedAtDesc().findAll();
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
          project.syncId = SyncIdGenerator.newSyncId();
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
      ..syncId = syncable ? SyncIdGenerator.newSyncId() : null
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

  Stream<void> watchExpenseRecords() => isar.expenseRecords.watchLazy();

  Future<int> addExpenseRecord(ExpenseRecord record) async {
    final id = await isar.writeTxn(() async {
      _stampExpenseRecordOwner(record);
      final existing = record.id == Isar.autoIncrement
          ? null
          : await isar.expenseRecords.get(record.id);
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
  Future<void> syncRemoteLogToLocal(Map<String, dynamic> data) async {
    final remoteId = data['id'] as int;
    final remoteSyncId = data['sync_id'] as String?;
    final remoteVersion = (data['version'] as num?)?.toInt() ?? 0;
    final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : DateTime.parse(data['deleted_at'] as String);

    await isar.writeTxn(() async {
      WorkLog? log;
      if (remoteSyncId != null) {
        log = await isar.workLogs
            .filter()
            .syncIdEqualTo(remoteSyncId)
            .findFirst();
      }
      log ??= await isar.workLogs
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();

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

      // 2. Create new if still null. Do not match by remote local_id: it is
      // generated per device and can collide with unrelated rows.
      log ??= WorkLog();

      // 冲突检测：如果本地数据处于脏标记，优先保留本地修改等待 Push，防止被旧数据覆盖
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

      // 4. Update fields
      log.remoteId = remoteId;
      log.ownerUserId = currentOwnerUserId;
      log.syncId = remoteSyncId ?? log.syncId;
      log.remoteVersion = remoteVersion;
      log.remoteUpdatedAt = remoteUpdatedAt;
      log.syncedAt = remoteUpdatedAt;
      log.isDirty = false;
      log.deletedAt = null;
      log.pendingDelete = false;
      log.date = DateTime.parse(data['date']);

      // Parse Type
      final typeStr = data['type'] as String;
      log.type = LogType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => LogType.work,
      );

      log.overtimeHours = (data['duration'] as num?)?.toDouble();
      log.note = data['notes'];
      log.transport = data['transport'];
      log.expenses = (data['expenses'] as num?)?.toDouble();
      log.isReimbursed = data['is_reimbursed'] ?? false;

      if (log.type == LogType.businessTrip) {
        log.location =
            data['project_name']; // Map project_name back to location
      } else {
        log.location = null;
      }

      // Save
      await isar.workLogs.put(log);
    });
  }

  // Sync Remote -> Local (Subscription)
  Future<void> syncRemoteSubscriptionToLocal(Map<String, dynamic> data) async {
    final remoteId = data['id'] as int;
    final remoteSyncId = data['sync_id'] as String?;
    final remoteVersion = (data['version'] as num?)?.toInt() ?? 0;
    final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : DateTime.parse(data['deleted_at'] as String);

    await isar.writeTxn(() async {
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

      // 2. Create new if still null. Remote local_id belongs to the source
      // device only and is unsafe for cross-device merging.
      sub ??= Subscription();

      // 冲突检测：如果本地数据处于脏标记，优先保留本地修改等待 Push
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
      sub.name = data['name'];
      sub.price = (data['price'] as num?)?.toDouble();

      final cycleStr = data['cycle'] as String;
      sub.cycle = SubscriptionCycle.values.firstWhere(
        (e) => e.name == cycleStr,
        orElse: () => SubscriptionCycle.monthly,
      );

      // Using nextPaymentDate as the date anchor
      sub.nextPaymentDate = DateTime.parse(data['start_date']);
      sub.note = data['description'];
      sub.sortIndex = data['sort_index'];

      await isar.subscriptions.put(sub);
    });
  }

  Future<void> syncRemoteEvidenceToLocal(Map<String, dynamic> data) async {
    final remoteId = data['id'] as int;
    final remoteSyncId = data['sync_id'] as String?;
    final remoteVersion = (data['version'] as num?)?.toInt() ?? 0;
    final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : DateTime.parse(data['deleted_at'] as String);

    await isar.writeTxn(() async {
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
      item.projectName = data['project_name'] ?? 'DefaultProject';
      item.evidenceDate = DateTime.parse(data['evidence_date']);
      item.amount = (data['amount'] as num?)?.toDouble();
      item.currency = data['currency'] ?? 'CNY';
      item.category = EvidenceCategory.values.firstWhere(
        (value) => value.name == data['category'],
        orElse: () => EvidenceCategory.invoice,
      );
      item.status = EvidenceStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => EvidenceStatus.pending,
      );
      item.merchant = data['merchant'];
      item.note = data['note'];
      item.localFilePath = data['local_file_path'];
      item.remoteStoragePath = data['remote_storage_path'];
      item.fileName = data['file_name'];
      item.mimeType = data['mime_type'];
      item.uploadedAt = data['uploaded_at'] == null
          ? null
          : DateTime.parse(data['uploaded_at'] as String);
      item.tripDate = data['trip_date'] == null
          ? null
          : DateTime.parse(data['trip_date'] as String);

      await isar.expenseEvidences.put(item);
    });
  }

  Future<void> syncRemoteExpenseRecordToLocal(Map<String, dynamic> data) async {
    final remoteId = data['id'] as int;
    final remoteSyncId = data['sync_id'] as String?;
    final remoteVersion = (data['version'] as num?)?.toInt() ?? 0;
    final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : DateTime.parse(data['deleted_at'] as String);

    await isar.writeTxn(() async {
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
        record.remoteId = remoteId;
        record.syncId = remoteSyncId ?? record.syncId;
        record.remoteVersion = remoteVersion;
        record.remoteUpdatedAt = remoteUpdatedAt;
        await isar.expenseRecords.put(record);
        return;
      }

      final projectName = data['project_name'] as String?;
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
            ..isDirty = false;
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
      record.expenseDate = DateTime.parse(data['expense_date'] as String);
      record.amount = (data['amount'] as num).toDouble();
      record.currency = data['currency'] ?? 'CNY';
      record.category = ExpenseCategory.values.firstWhere(
        (value) => value.name == data['category'],
        orElse: () => ExpenseCategory.other,
      );
      record.merchant = data['merchant'];
      record.note = data['note'];
      record.projectName = projectName;
      record.projectId = projectId;

      await isar.expenseRecords.put(record);
    });
  }

  Future<void> syncRemoteProjectToLocal(Map<String, dynamic> data) async {
    final remoteId = data['id'] as int;
    final remoteSyncId = data['sync_id'] as String?;
    final remoteVersion = (data['version'] as num?)?.toInt() ?? 0;
    final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);
    final remoteDeletedAt = data['deleted_at'] == null
        ? null
        : DateTime.parse(data['deleted_at'] as String);

    await isar.writeTxn(() async {
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
      project.name = data['name'] as String? ?? 'Untitled';
      final statusStr = data['status'] as String? ?? ProjectStatus.active.name;
      project.status = ProjectStatus.values.firstWhere(
        (value) => value.name == statusStr,
        orElse: () => ProjectStatus.active,
      );
      project.createdAt = data['created_at'] == null
          ? remoteUpdatedAt
          : DateTime.parse(data['created_at'] as String);
      project.updatedAt = data['updated_at'] == null
          ? remoteUpdatedAt
          : DateTime.parse(data['updated_at'] as String);

      await isar.projects.put(project);
    });
  }
}
