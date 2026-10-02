import 'package:isar_community/isar.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

/// The five versioned cloud entities. Photos deliberately have no codec here.
final class ConflictEntity {
  final String name;
  final Object value;

  const ConflictEntity(this.name, this.value);

  dynamic get row => value;

  String get table => switch (name) {
    'work_log' => 'work_logs',
    'subscription' => 'subscriptions',
    'project' => 'projects',
    'expense_record' => 'expense_records',
    'evidence' => 'expense_evidence',
    _ => throw StateError('此记录类型暂不支持冲突处理'),
  };

  static Future<ConflictEntity?> find(Isar isar, String name, int id) async {
    final Object? value = switch (name) {
      'work_log' => await isar.workLogs.get(id),
      'subscription' => await isar.subscriptions.get(id),
      'project' => await isar.projects.get(id),
      'expense_record' => await isar.expenseRecords.get(id),
      'evidence' => await isar.expenseEvidences.get(id),
      _ => null,
    };
    return value == null ? null : ConflictEntity(name, value);
  }

  Future<int> put(Isar isar) => switch (value) {
    WorkLog item => isar.workLogs.put(item),
    Subscription item => isar.subscriptions.put(item),
    Project item => isar.projects.put(item),
    ExpenseRecord item => isar.expenseRecords.put(item),
    ExpenseEvidence item => isar.expenseEvidences.put(item),
    _ => throw StateError('Unsupported conflict entity'),
  };

  ConflictEntity snapshot() => ConflictEntity(name, switch (value) {
    WorkLog item => DbService.snapshotWorkLog(item),
    Subscription item => DbService.snapshotSubscription(item),
    Project item => DbService.snapshotProject(item),
    ExpenseRecord item => DbService.snapshotExpenseRecord(item),
    ExpenseEvidence item => DbService.snapshotEvidence(item),
    _ => throw StateError('Unsupported conflict entity'),
  });

  bool unchangedSince(ConflictEntity previous) {
    final a = row;
    final b = previous.row;
    if (a.id != b.id ||
        a.ownerUserId != b.ownerUserId ||
        a.syncId != b.syncId ||
        a.remoteId != b.remoteId ||
        a.remoteVersion != b.remoteVersion ||
        a.isDirty != b.isDirty ||
        a.deletedAt != b.deletedAt ||
        a.pendingDelete != b.pendingDelete) {
      return false;
    }
    return switch (value) {
      WorkLog item =>
        item.updatedAt == (previous.value as WorkLog).updatedAt &&
            !item.hasBusinessChangesComparedTo(previous.value as WorkLog),
      Subscription item => !item.hasBusinessChangesComparedTo(
        previous.value as Subscription,
      ),
      Project item =>
        item.updatedAt == (previous.value as Project).updatedAt &&
            item.localCoverPath == (previous.value as Project).localCoverPath &&
            item.coverImagePath == (previous.value as Project).coverImagePath &&
            !item.hasBusinessChangesComparedTo(previous.value as Project),
      ExpenseRecord item =>
        item.updatedAt == (previous.value as ExpenseRecord).updatedAt &&
            !item.hasBusinessChangesComparedTo(previous.value as ExpenseRecord),
      ExpenseEvidence item =>
        item.updatedAt == (previous.value as ExpenseEvidence).updatedAt &&
            item.remoteStoragePath ==
                (previous.value as ExpenseEvidence).remoteStoragePath &&
            !item.hasBusinessChangesComparedTo(
              previous.value as ExpenseEvidence,
            ),
      _ => false,
    };
  }

  DateTime? get updatedAt => switch (value) {
    WorkLog item => item.updatedAt,
    Project item => item.updatedAt,
    ExpenseRecord item => item.updatedAt,
    ExpenseEvidence item => item.updatedAt,
    _ => null,
  };

  void applyRemote(Map<String, dynamic> data) {
    switch (value) {
      case WorkLog item:
        item
          ..date = _day(data['date'])
          ..type = _enum(LogType.values, data['type'], LogType.work)
          ..overtimeHours = _number(data['duration'])
          ..location = data['type'] == LogType.businessTrip.name
              ? data['project_name'] as String?
              : null
          ..transport = data['transport'] as String?
          ..expenses = _number(data['expenses'])
          ..isReimbursed = data['is_reimbursed'] == true
          ..note = data['notes'] as String?
          ..projectName = data['linked_project_name'] as String?
          ..projectSyncId = data['project_sync_id'] as String?
          ..projectStageName = data['project_stage_name'] as String?
          ..updatedAt = _time(data['updated_at']);
      case Subscription item:
        item
          ..name = _requiredString(data['name'])
          ..price = _number(data['price'])
          ..currency = data['currency'] as String? ?? 'CNY'
          ..cycle = _enum(
            SubscriptionCycle.values,
            data['cycle'],
            SubscriptionCycle.monthly,
          )
          ..nextPaymentDate = _day(data['next_due_date'] ?? data['start_date'])
          ..anchorDate = data['anchor_date'] == null
              ? null
              : _day(data['anchor_date'])
          ..endDate = data['end_date'] == null ? null : _day(data['end_date'])
          ..status = _enum(
            SubscriptionRecordStatus.values,
            data['status'],
            SubscriptionRecordStatus.active,
          )
          ..reminderDays = _integer(data['reminder_days']) ?? 1
          ..note = data['description'] as String?
          ..sortIndex = _integer(data['sort_index']);
      case Project item:
        item
          ..name = _requiredString(data['name'])
          ..status = _enum(
            ProjectStatus.values,
            data['status'],
            ProjectStatus.active,
          )
          ..stageNames = (data['stage_names'] as List? ?? const [])
              .cast<String>()
              .toList()
          ..createdAt = _time(data['created_at'] ?? data['updated_at'])
          ..updatedAt = _time(data['updated_at']);
      case ExpenseRecord item:
        item
          ..expenseDate = _day(data['expense_date'])
          ..amount = _number(data['amount']) ?? 0
          ..currency = data['currency'] as String? ?? 'CNY'
          ..category = _enum(
            ExpenseCategory.values,
            data['category'],
            ExpenseCategory.other,
          )
          ..merchant = data['merchant'] as String?
          ..note = data['note'] as String?
          ..projectName = data['project_name'] as String?
          ..projectSyncId = data['project_sync_id'] as String?
          ..projectStageName = data['project_stage_name'] as String?
          ..tripWorkLogSyncId = data['trip_work_log_sync_id'] as String?
          ..updatedAt = _time(data['updated_at']);
      case ExpenseEvidence item:
        // A remote device's private filesystem path is never adopted locally.
        final sameFile = item.remoteStoragePath == data['remote_storage_path'];
        item
          ..projectName = data['project_name'] as String? ?? 'DefaultProject'
          ..projectSyncId = data['project_sync_id'] as String?
          ..projectStageName = data['project_stage_name'] as String?
          ..evidenceDate = _day(data['evidence_date'])
          ..amount = _number(data['amount'])
          ..currency = data['currency'] as String? ?? 'CNY'
          ..category = _enum(
            EvidenceCategory.values,
            data['category'],
            EvidenceCategory.invoice,
          )
          ..status = _enum(
            EvidenceStatus.values,
            data['status'],
            EvidenceStatus.pending,
          )
          ..merchant = data['merchant'] as String?
          ..note = data['note'] as String?
          ..localFilePath = sameFile ? item.localFilePath : null
          ..remoteStoragePath = data['remote_storage_path'] as String?
          ..fileName = data['file_name'] as String?
          ..mimeType = data['mime_type'] as String?
          ..uploadedAt = data['uploaded_at'] == null
              ? null
              : _time(data['uploaded_at'])
          ..tripDate = data['trip_date'] == null
              ? null
              : _day(data['trip_date'])
          ..updatedAt = _time(data['updated_at']);
      default:
        throw StateError('Unsupported conflict entity');
    }
  }

  void resetAsCopy(String syncId, DateTime now) {
    row
      ..id = Isar.autoIncrement
      ..syncId = syncId
      ..remoteId = null
      ..remoteVersion = 0
      ..remoteUpdatedAt = null
      ..syncedAt = null
      ..isDirty = true
      ..deletedAt = null
      ..pendingDelete = false;
    switch (value) {
      case WorkLog item:
        item
          ..createdAt = now
          ..updatedAt = now;
      case Project item:
        item
          ..name = '${item.name}（副本）'
          ..createdAt = now
          ..updatedAt = now
          ..localCoverPath = null
          ..coverImagePath = null;
      case ExpenseRecord item:
        item
          ..createdAt = now
          ..updatedAt = now;
      case ExpenseEvidence item:
        item
          ..createdAt = now
          ..updatedAt = now
          ..remoteStoragePath = null
          ..uploadedAt = null;
      default:
        break;
    }
  }
}

int? conflictRemoteInt(dynamic value) => _integer(value);

int? _integer(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return value is String ? int.tryParse(value) : null;
}

double? _number(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final number = double.tryParse(value.toString());
  if (number == null) throw StateError('远端金额或时长无效');
  return number;
}

DateTime _time(dynamic value) {
  final parsed = value is DateTime
      ? value
      : DateTime.tryParse(value.toString());
  if (parsed == null) throw StateError('远端日期无效');
  return parsed.toUtc();
}

DateTime _day(dynamic value) {
  final parsed = _time(value).toLocal();
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _requiredString(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    throw StateError('远端名称无效');
  }
  return value;
}

T _enum<T extends Enum>(List<T> values, dynamic name, T fallback) {
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw StateError('远端记录类型无效');
}
