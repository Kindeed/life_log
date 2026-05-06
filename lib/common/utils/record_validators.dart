import '../../modules/evidence/evidence_model.dart';
import '../../modules/expense/expense_record_model.dart';
import '../../modules/subscription/subscription_model.dart';
import '../../modules/work_log/work_log_model.dart';

void validateWorkLog(WorkLog log) {
  final overtimeHours = log.overtimeHours;
  if (overtimeHours != null && overtimeHours < 0) {
    throw ArgumentError.value(overtimeHours, 'overtimeHours', '加班时长不能为负数');
  }

  final expenses = log.expenses;
  if (expenses != null && expenses < 0) {
    throw ArgumentError.value(expenses, 'expenses', '垫付金额不能为负数');
  }
}

void validateSubscription(Subscription sub) {
  if (sub.name.trim().isEmpty) {
    throw ArgumentError.value(sub.name, 'name', '订阅名称不能为空');
  }

  final price = sub.price;
  if (price != null && price < 0) {
    throw ArgumentError.value(price, 'price', '订阅价格不能为负数');
  }

  if (sub.reminderDays < 0) {
    throw ArgumentError.value(sub.reminderDays, 'reminderDays', '提醒天数不能为负数');
  }
}

void validateExpenseEvidence(ExpenseEvidence evidence) {
  if (evidence.projectName.trim().isEmpty) {
    throw ArgumentError.value(evidence.projectName, 'projectName', '项目名称不能为空');
  }

  final amount = evidence.amount;
  if (amount != null && amount < 0) {
    throw ArgumentError.value(amount, 'amount', '凭证金额不能为负数');
  }

  if (evidence.currency.trim().isEmpty) {
    evidence.currency = 'CNY';
  }
}

void validateExpenseRecord(ExpenseRecord record) {
  if (record.amount < 0) {
    throw ArgumentError.value(record.amount, 'amount', '消费金额不能为负数');
  }

  if (record.currency.trim().isEmpty) {
    record.currency = 'CNY';
  }

  final projectName = record.projectName;
  if (projectName != null && projectName.trim().isEmpty) {
    record.projectName = null;
  }
}
