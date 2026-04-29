import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../modules/work_log/work_log_model.dart';
import '../../modules/subscription/subscription_model.dart';
import '../../modules/photo/photo_model.dart'; // Import PhotoModel
import '../../modules/evidence/evidence_model.dart';
import '../services/auth_service.dart';
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
    ], directory: dir.path);

    return this;
  }

  // --- 2. 增加一条日志 (入库) ---
  Future<int> addLog(WorkLog log) async {
    final id = await isar.writeTxn(() async {
      _stampWorkLogOwner(log);
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
    return await isar.photoItems.where().sortByCreatedAtDesc().findAll();
  }

  Future<PhotoItem?> getPhoto(int id) async {
    return await isar.photoItems.get(id);
  }

  // 获取照片变更流
  Stream<void> watchPhotos() => isar.photoItems.watchLazy();

  Future<void> addPhoto(PhotoItem photo) async {
    await isar.writeTxn(() async {
      await isar.photoItems.put(photo);
    });
  }

  Future<void> deletePhoto(int id) async {
    await isar.writeTxn(() async {
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
}
