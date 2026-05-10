import 'dart:async';

import 'package:get/get.dart';
import 'package:life_log/common/services/log_service.dart';

import 'expense_record_model.dart';
import 'expense_record_repository.dart';

class ExpenseRecordController extends GetxController {
  static ExpenseRecordController get to => Get.find();

  final records = <ExpenseRecord>[].obs;
  final isLoading = false.obs;

  StreamSubscription? _dbSub;

  @override
  void onInit() {
    super.onInit();
    loadRecords();
    _dbSub = ExpenseRecordRepository.to.watchExpenseRecords().listen((_) {
      loadRecords();
    });
  }

  @override
  void onClose() {
    _dbSub?.cancel();
    super.onClose();
  }

  Future<void> loadRecords() async {
    isLoading.value = true;
    try {
      records.assignAll(
        await ExpenseRecordRepository.to.getAllExpenseRecords(),
      );
    } catch (e, stackTrace) {
      LogService.to.error('ExpenseRecord', '加载一次性消费失败: $e', stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveRecord(ExpenseRecord record) async {
    try {
      await ExpenseRecordRepository.to.saveExpenseRecord(record);
      LogService.to.info('ExpenseRecord', '保存一次性消费: ${record.amount}');
    } catch (e, stackTrace) {
      LogService.to.error('ExpenseRecord', '保存一次性消费失败: $e', stackTrace);
      Get.snackbar('保存失败', e.toString());
      rethrow;
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await ExpenseRecordRepository.to.deleteExpenseRecord(id);
      LogService.to.info('ExpenseRecord', '删除一次性消费 ID: $id');
    } catch (e, stackTrace) {
      LogService.to.error('ExpenseRecord', '删除一次性消费失败: $e', stackTrace);
      Get.snackbar('删除失败', e.toString());
      rethrow;
    }
  }

  double totalForMonth(DateTime month) {
    return records
        .where(
          (item) =>
              item.expenseDate.year == month.year &&
              item.expenseDate.month == month.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }
}
