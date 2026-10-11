import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

enum TimelineFilter { all, work, expense, evidence, subscription }

extension TimelineFilterLabel on TimelineFilter {
  String get label => switch (this) {
    TimelineFilter.all => '全部',
    TimelineFilter.work => '工时',
    TimelineFilter.expense => '支出',
    TimelineFilter.evidence => '凭证',
    TimelineFilter.subscription => '订阅',
  };
}

/// Dates are inclusive local calendar dates for every record type.
final class TimelineDateRange {
  final DateTime start;
  final DateTime end;

  TimelineDateRange(DateTime start, DateTime end)
    : start = dateOnlyLocal(start),
      end = dateOnlyLocal(end) {
    if (this.end.isBefore(this.start)) {
      throw ArgumentError('时间范围结束日期不能早于开始日期');
    }
  }

  bool contains(DateTime date) {
    final localDate = dateOnlyLocal(date);
    return !localDate.isBefore(start) && !localDate.isAfter(end);
  }

  String get key => '${start.toIso8601String()}/${end.toIso8601String()}';
}

sealed class TimelineRecord {
  const TimelineRecord();

  int get id;
  DateTime get date;
  TimelineFilter get type;
  String get key => '${type.name}:$id';
}

final class TimelineWorkRecord extends TimelineRecord {
  final WorkLogEntry entry;
  const TimelineWorkRecord(this.entry);

  @override
  int get id => entry.id;
  @override
  DateTime get date => entry.date;
  @override
  TimelineFilter get type => TimelineFilter.work;
}

final class TimelineExpenseRecord extends TimelineRecord {
  final ExpenseRecordEntry entry;
  const TimelineExpenseRecord(this.entry);

  @override
  int get id => entry.id;
  @override
  DateTime get date => entry.expenseDate;
  @override
  TimelineFilter get type => TimelineFilter.expense;
}

final class TimelineEvidenceRecord extends TimelineRecord {
  final EvidenceEntry entry;
  const TimelineEvidenceRecord(this.entry);

  @override
  int get id => entry.id;
  @override
  DateTime get date => entry.evidenceDate;
  @override
  TimelineFilter get type => TimelineFilter.evidence;
}

/// A subscription is its existing next-payment snapshot, not a fabricated
/// payment-history transaction. Keep this event date explicit in presentation.
final class TimelineSubscriptionRecord extends TimelineRecord {
  final SubscriptionEntry entry;
  const TimelineSubscriptionRecord(this.entry);

  @override
  int get id => entry.id;
  @override
  DateTime get date => entry.nextPaymentDate;
  @override
  TimelineFilter get type => TimelineFilter.subscription;
}

sealed class TimelineRow {
  const TimelineRow();
  String get key;
}

final class TimelineDateRow extends TimelineRow {
  final DateTime date;
  const TimelineDateRow(this.date);

  @override
  String get key => 'date:${date.toIso8601String()}';
}

final class TimelineRecordRow extends TimelineRow {
  final TimelineRecord record;
  const TimelineRecordRow(this.record);

  @override
  String get key => record.key;
}
