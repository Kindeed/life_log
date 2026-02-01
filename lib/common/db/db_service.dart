import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../modules/work_log/log_model.dart';
import '../../modules/subscription/subscription_model.dart';
import '../../modules/photo/photo_model.dart'; // Import PhotoModel

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
    await isar.writeTxn(() async {
      await isar.workLogs.delete(id);
    });
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
  }

  // 3. 删除订阅
  Future<void> deleteSubscription(int id) async {
    await isar.writeTxn(() async {
      await isar.subscriptions.delete(id);
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
}
