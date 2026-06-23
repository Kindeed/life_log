import 'package:equatable/equatable.dart';

enum ExpenseRecordEntryCategory {
  meal,
  transport,
  shopping,
  travel,
  office,
  other,
}

extension ExpenseRecordEntryCategoryLabel on ExpenseRecordEntryCategory {
  String get label {
    return switch (this) {
      ExpenseRecordEntryCategory.meal => '餐饮',
      ExpenseRecordEntryCategory.transport => '交通',
      ExpenseRecordEntryCategory.shopping => '购物',
      ExpenseRecordEntryCategory.travel => '出差',
      ExpenseRecordEntryCategory.office => '办公',
      ExpenseRecordEntryCategory.other => '其他',
    };
  }
}

final class ExpenseRecordEntry extends Equatable {
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime expenseDate;
  final double amount;
  final String currency;
  final ExpenseRecordEntryCategory category;
  final String? merchant;
  final String? note;
  final int? projectId;
  final String? projectSyncId;
  final String? projectName;
  final int? tripWorkLogId;
  final String? tripWorkLogSyncId;

  const ExpenseRecordEntry({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.expenseDate,
    required this.amount,
    this.currency = 'CNY',
    this.category = ExpenseRecordEntryCategory.other,
    this.merchant,
    this.note,
    this.projectId,
    this.projectSyncId,
    this.projectName,
    this.tripWorkLogId,
    this.tripWorkLogSyncId,
  });

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    expenseDate,
    amount,
    currency,
    category,
    merchant,
    note,
    projectId,
    projectSyncId,
    projectName,
    tripWorkLogId,
    tripWorkLogSyncId,
  ];
}
