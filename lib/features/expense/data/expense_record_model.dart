import 'package:isar/isar.dart';

import 'package:life_log/common/utils/date_utils.dart';

part 'expense_record_model.g.dart';

@collection
class ExpenseRecord {
  Id id = Isar.autoIncrement;

  // Sync fields
  String? ownerUserId;
  int? remoteId;
  String? syncId;
  int remoteVersion = 0;
  DateTime? remoteUpdatedAt;
  DateTime? syncedAt;
  bool isDirty = false;
  @Index()
  DateTime? deletedAt;
  bool pendingDelete = false;

  DateTime? createdAt;
  DateTime? updatedAt;

  @Index()
  late DateTime expenseDate;

  late double amount;
  String currency = 'CNY';

  @enumerated
  ExpenseCategory category = ExpenseCategory.other;

  String? merchant;
  String? note;

  @Index()
  int? projectId;

  @Index(caseSensitive: false)
  String? projectSyncId;

  @Index(caseSensitive: false)
  String? projectName;
}

enum ExpenseCategory { meal, transport, shopping, travel, office, other }

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.meal:
        return '餐饮';
      case ExpenseCategory.transport:
        return '交通';
      case ExpenseCategory.shopping:
        return '购物';
      case ExpenseCategory.travel:
        return '出差';
      case ExpenseCategory.office:
        return '办公';
      case ExpenseCategory.other:
        return '其他';
    }
  }
}

extension ExpenseRecordBusinessChanges on ExpenseRecord {
  bool hasBusinessChangesComparedTo(ExpenseRecord other) {
    return expenseDate != other.expenseDate ||
        amount != other.amount ||
        currency != other.currency ||
        category != other.category ||
        merchant != other.merchant ||
        note != other.note ||
        projectId != other.projectId ||
        projectSyncId != other.projectSyncId ||
        projectName != other.projectName;
  }
}

extension ExpenseRecordListDomainLogic on Iterable<ExpenseRecord> {
  Iterable<ExpenseRecord> inMonth(DateTime monthYear) {
    final localMonth = dateOnlyLocal(monthYear);
    return where(
      (item) =>
          dateOnlyLocal(item.expenseDate).year == localMonth.year &&
          dateOnlyLocal(item.expenseDate).month == localMonth.month,
    );
  }

  double get totalAmount => fold(0.0, (sum, item) => sum + item.amount);
}
