import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/timeline/domain/timeline_record.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class TimelineSourceResult {
  final TimelineFilter source;
  final List<TimelineRecord> records;
  final AppFailure? failure;

  const TimelineSourceResult({
    required this.source,
    this.records = const [],
    this.failure,
  });
}

/// Composes domain repositories, never other features' presentation state.
/// The existing read ports preserve current-owner + unowned local visibility.
/// These are full source reads; display pagination does not limit DB reads.
final class TimelineQuery {
  static const sources = {
    TimelineFilter.work,
    TimelineFilter.expense,
    TimelineFilter.evidence,
    TimelineFilter.subscription,
  };

  final WorkLogRepositoryPort workLogs;
  final ExpenseRecordRepositoryPort expenses;
  final EvidenceRepositoryPort evidence;
  final SubscriptionRepositoryPort subscriptions;
  final Stream<void> Function()? watchScope;

  const TimelineQuery({
    required this.workLogs,
    required this.expenses,
    required this.evidence,
    required this.subscriptions,
    this.watchScope,
  });

  Stream<void> watch(TimelineFilter source) => switch (source) {
    TimelineFilter.work => workLogs.watchEntries(),
    TimelineFilter.expense => expenses.watchEntries(),
    TimelineFilter.evidence => evidence.watchEntries(),
    TimelineFilter.subscription => subscriptions.watchEntries(),
    TimelineFilter.all => throw ArgumentError('全部不是一个数据源'),
  };

  Future<List<TimelineSourceResult>> load(
    Set<TimelineFilter> requested, {
    void Function(TimelineSourceResult)? onLoaded,
  }) {
    return Future.wait([
      for (final source in sources)
        if (requested.contains(source))
          _loadSource(source).then((result) {
            onLoaded?.call(result);
            return result;
          }),
    ]);
  }

  Future<TimelineSourceResult> _loadSource(TimelineFilter source) async {
    try {
      final List<TimelineRecord> records = switch (source) {
        TimelineFilter.work => [
          for (final entry in await workLogs.getAllEntries())
            TimelineWorkRecord(entry),
        ],
        TimelineFilter.expense => [
          for (final entry in await expenses.getAllEntries())
            TimelineExpenseRecord(entry),
        ],
        TimelineFilter.evidence => [
          for (final entry in await evidence.getAllEntries())
            TimelineEvidenceRecord(entry),
        ],
        TimelineFilter.subscription => [
          for (final entry in await subscriptions.getAllEntries())
            TimelineSubscriptionRecord(entry),
        ],
        TimelineFilter.all => throw ArgumentError('全部不是一个数据源'),
      };
      return TimelineSourceResult(
        source: source,
        records: List.unmodifiable(records),
      );
    } catch (error, stackTrace) {
      return TimelineSourceResult(
        source: source,
        failure: AppFailure(
          code: 'timeline/load-${source.name}',
          message: '${source.label}记录读取失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  List<TimelineRecord> merge(Iterable<List<TimelineRecord>> sources) {
    final records = sources.expand((entries) => entries).toList();
    records.sort((left, right) {
      final date = right.date.compareTo(left.date);
      if (date != 0) return date;
      final type = left.type.index.compareTo(right.type.index);
      if (type != 0) return type;
      return right.id.compareTo(left.id);
    });
    return List.unmodifiable(records);
  }

  List<TimelineRecord> select(
    List<TimelineRecord> sortedRecords, {
    required TimelineFilter filter,
    TimelineDateRange? range,
  }) {
    return List.unmodifiable(
      sortedRecords.where(
        (record) =>
            (filter == TimelineFilter.all || record.type == filter) &&
            (range == null || range.contains(record.date)),
      ),
    );
  }

  List<TimelineRow> rows(List<TimelineRecord> records, {required int limit}) {
    final result = <TimelineRow>[];
    DateTime? previousDate;
    for (final record in records.take(limit)) {
      final date = dateOnlyLocal(record.date);
      if (date != previousDate) {
        result.add(TimelineDateRow(date));
        previousDate = date;
      }
      result.add(TimelineRecordRow(record));
    }
    return List.unmodifiable(result);
  }
}
