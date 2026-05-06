import 'package:isar/isar.dart';

part 'evidence_model.g.dart';

@collection
class ExpenseEvidence {
  Id id = Isar.autoIncrement;

  // Sync fields
  String? ownerUserId;
  int? remoteId;
  String? syncId;
  int remoteVersion = 0;
  DateTime? remoteUpdatedAt;
  DateTime? syncedAt;
  bool isDirty = false;
  DateTime? deletedAt;
  bool pendingDelete = false;

  @Index(caseSensitive: false)
  late String projectName;

  @Index()
  int? projectId;

  @Index()
  late DateTime evidenceDate;

  double? amount;
  String currency = 'CNY';

  @enumerated
  EvidenceCategory category = EvidenceCategory.invoice;

  @enumerated
  EvidenceStatus status = EvidenceStatus.pending;

  String? merchant;
  String? note;

  String? localFilePath;
  String? remoteStoragePath;
  String? fileName;
  String? mimeType;
  DateTime? uploadedAt;

  DateTime? tripDate;
}

enum EvidenceCategory {
  invoice,
  payment,
  purchase,
  travel,
  meal,
  accommodation,
  other,
}

enum EvidenceStatus { pending, submitted, reimbursed }

extension EvidenceCategoryLabel on EvidenceCategory {
  String get label {
    switch (this) {
      case EvidenceCategory.invoice:
        return '发票';
      case EvidenceCategory.payment:
        return '付款截图';
      case EvidenceCategory.purchase:
        return '购买记录';
      case EvidenceCategory.travel:
        return '交通';
      case EvidenceCategory.meal:
        return '餐饮';
      case EvidenceCategory.accommodation:
        return '住宿';
      case EvidenceCategory.other:
        return '其他';
    }
  }
}

extension EvidenceStatusLabel on EvidenceStatus {
  String get label {
    switch (this) {
      case EvidenceStatus.pending:
        return '待报销';
      case EvidenceStatus.submitted:
        return '已提交';
      case EvidenceStatus.reimbursed:
        return '已报销';
    }
  }
}

extension ExpenseEvidenceListDomainLogic on Iterable<ExpenseEvidence> {
  Iterable<ExpenseEvidence> inMonth(DateTime monthYear) {
    return where(
      (item) =>
          item.evidenceDate.year == monthYear.year &&
          item.evidenceDate.month == monthYear.month,
    );
  }

  double get totalPendingAmount {
    return where(
      (item) => item.status != EvidenceStatus.reimbursed,
    ).fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));
  }

  double get totalReimbursedAmount {
    return where(
      (item) => item.status == EvidenceStatus.reimbursed,
    ).fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));
  }
}
