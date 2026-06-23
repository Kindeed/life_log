import 'package:equatable/equatable.dart';

enum EvidenceEntryCategory {
  invoice,
  payment,
  purchase,
  travel,
  meal,
  accommodation,
  other,
}

extension EvidenceEntryCategoryLabel on EvidenceEntryCategory {
  String get label {
    return switch (this) {
      EvidenceEntryCategory.invoice => '发票',
      EvidenceEntryCategory.payment => '付款截图',
      EvidenceEntryCategory.purchase => '购买记录',
      EvidenceEntryCategory.travel => '交通',
      EvidenceEntryCategory.meal => '餐饮',
      EvidenceEntryCategory.accommodation => '住宿',
      EvidenceEntryCategory.other => '其他',
    };
  }
}

enum EvidenceEntryStatus { pending, submitted, reimbursed }

extension EvidenceEntryStatusLabel on EvidenceEntryStatus {
  String get label {
    return switch (this) {
      EvidenceEntryStatus.pending => '待报销',
      EvidenceEntryStatus.submitted => '已提交',
      EvidenceEntryStatus.reimbursed => '已报销',
    };
  }
}

final class EvidenceEntry extends Equatable {
  final int id;
  final String projectName;
  final int? projectId;
  final String? projectSyncId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime evidenceDate;
  final double? amount;
  final String currency;
  final EvidenceEntryCategory category;
  final EvidenceEntryStatus status;
  final String? merchant;
  final String? note;
  final String? localFilePath;
  final String? remoteStoragePath;
  final String? fileName;
  final String? mimeType;
  final DateTime? uploadedAt;
  final DateTime? tripDate;

  const EvidenceEntry({
    required this.id,
    required this.projectName,
    required this.evidenceDate,
    this.projectId,
    this.projectSyncId,
    this.createdAt,
    this.updatedAt,
    this.amount,
    this.currency = 'CNY',
    this.category = EvidenceEntryCategory.invoice,
    this.status = EvidenceEntryStatus.pending,
    this.merchant,
    this.note,
    this.localFilePath,
    this.remoteStoragePath,
    this.fileName,
    this.mimeType,
    this.uploadedAt,
    this.tripDate,
  });

  @override
  List<Object?> get props => [
    id,
    projectName,
    projectId,
    projectSyncId,
    createdAt,
    updatedAt,
    evidenceDate,
    amount,
    currency,
    category,
    status,
    merchant,
    note,
    localFilePath,
    remoteStoragePath,
    fileName,
    mimeType,
    uploadedAt,
    tripDate,
  ];
}
