import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../modules/work_log/work_log_model.dart';
import '../../modules/subscription/subscription_model.dart';
import '../../modules/photo/photo_model.dart'; // Import PhotoModel
import '../services/sync_service.dart';

class DbService extends GetxService {
  // 单例模式：确保整个App只有一个仓库管理员
  static DbService get to => Get.find();

  late Isar isar; // 数据库实例

  // --- 1. 初始化数据库 (开门) ---
  Future<DbService> init() async {
    // 获取手机里专门存文档的路径
    final dir = await getApplicationDocumentsDirectory();

    // 打开数据库
    isar = await Isar.open([
      WorkLogSchema,
      SubscriptionSchema,
      PhotoItemSchema,
    ], directory: dir.path);

    return this;
  }

  // --- 2. 增加一条日志 (入库) ---
  Future<void> addLog(WorkLog log) async {
    await isar.writeTxn(() async {
      await isar.workLogs.put(log);
    });
    // Trigger Sync (Fire and forget)
    try {
      SyncService.to.pushWorkLog(log);
    } catch (_) {}
  }

  // --- 3. 查询某个月的日志 (盘点) ---
  Future<List<WorkLog>> getLogsByMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return await isar.workLogs
        .filter()
        .dateGreaterThan(start, include: true)
        .and()
        .dateLessThan(end, include: false)
        .sortByDate()
        .findAll();
  }

  // --- 【新增】4. 获取所有日志 (供日历初始化使用) ---
  Future<List<WorkLog>> getAllLogs() async {
    return await isar.workLogs
        .where()
        .sortByDate() // 按日期排序，保证日历加载顺序
        .findAll();
  }

  // --- 5. 删除日志 (出库) ---
  Future<void> deleteLog(int id) async {
    // 先查询 remoteId，以便同步删除
    final log = await isar.workLogs.get(id);
    final remoteId = log?.remoteId;

    await isar.writeTxn(() async {
      await isar.workLogs.delete(id);
    });

    // 同步删除到云端
    if (remoteId != null) {
      try {
        SyncService.to.deleteWorkLog(remoteId);
      } catch (_) {}
    }
  }

  // --- 订阅管理相关 ---

  // 1. 获取所有订阅 (按下次付款时间排序)
  Future<List<Subscription>> getAllSubscriptions() async {
    return await isar.subscriptions.where().sortByNextPaymentDate().findAll();
  }

  // 2. 添加/修改订阅
  Future<void> addSubscription(Subscription sub) async {
    await isar.writeTxn(() async {
      await isar.subscriptions.put(sub);
    });
    // Trigger Sync (Fire and forget)
    try {
      SyncService.to.pushSubscription(sub);
    } catch (_) {}
  }

  // 3. 删除订阅
  Future<void> deleteSubscription(int id) async {
    // 先查询 remoteId，以便同步删除
    final sub = await isar.subscriptions.get(id);
    final remoteId = sub?.remoteId;

    await isar.writeTxn(() async {
      await isar.subscriptions.delete(id);
    });

    // 同步删除到云端
    if (remoteId != null) {
      try {
        SyncService.to.deleteSubscription(remoteId);
      } catch (_) {}
    }
  }

  // 4. Update Subscription Order
  Future<void> reorderSubscriptions(List<Subscription> subs) async {
    await isar.writeTxn(() async {
      for (int i = 0; i < subs.length; i++) {
        subs[i].sortIndex = i;
        await isar.subscriptions.put(subs[i]);
      }
    });
  }

  // --- 照片系统 Photo ---

  Future<List<PhotoItem>> getAllPhotos() async {
    return await isar.photoItems.where().sortByCreatedAtDesc().findAll();
  }

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
    final localId = data['local_id'] as int?; // Optional mapping

    await isar.writeTxn(() async {
      // 1. Try find by Remote ID
      WorkLog? log = await isar.workLogs
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();

      // 2. If not found, try find by Local ID (Linkage recovery)
      if (log == null && localId != null) {
        log = await isar.workLogs.get(localId);
      }

      // 3. Create new if still null
      log ??= WorkLog();

      // 冲突检测：如果本地数据处于脏标记，优先保留本地修改等待 Push，防止被旧数据覆盖
      if (log.isDirty) {
        if (log.remoteId != remoteId) {
          log.remoteId = remoteId;
          await isar.workLogs.put(log); // 只修补 remoteId
        }
        return;
      }

      // 4. Update fields
      log.remoteId = remoteId;
      log.syncedAt = DateTime.parse(data['updated_at']);
      log.isDirty = false;
      log.date = DateTime.parse(data['date']);

      // Parse Type
      final typeStr = data['type'] as String;
      log.type = LogType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => LogType.work,
      );

      log.overtimeHours = (data['duration'] as num?)?.toDouble();
      log.note = data['notes'];

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
    // ... logic similar to WorkLog
    await isar.writeTxn(() async {
      Subscription? sub = await isar.subscriptions
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
      sub ??= Subscription();

      // 冲突检测：如果本地数据处于脏标记，优先保留本地修改等待 Push
      if (sub.isDirty) {
        if (sub.remoteId != remoteId) {
          sub.remoteId = remoteId;
          await isar.subscriptions.put(sub);
        }
        return;
      }

      sub.remoteId = remoteId;
      sub.syncedAt = DateTime.parse(data['updated_at']);
      sub.isDirty = false;
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
}
