import 'dart:async';

import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_edit_draft.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/timeline/application/timeline_query.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

class TimelineTestSources {
  final work = TimelineTestWorkRepository();
  final expense = TimelineTestExpenseRepository();
  final evidence = TimelineTestEvidenceRepository();
  final subscription = TimelineTestSubscriptionRepository();
  final scope = StreamController<void>.broadcast(sync: true);

  TimelineQuery get query => TimelineQuery(
    workLogs: work,
    expenses: expense,
    evidence: evidence,
    subscriptions: subscription,
    watchScope: () => scope.stream,
  );

  Future<void> close() async {
    await Future.wait([
      work.changes.close(),
      expense.changes.close(),
      evidence.changes.close(),
      subscription.changes.close(),
      scope.close(),
    ]);
  }
}

class TimelineTestRepository<T> {
  List<T> entries = [];
  Object? error;
  Future<List<T>> Function()? read;
  int reads = 0;
  final changes = StreamController<void>.broadcast(sync: true);

  Future<List<T>> getAllEntries() async {
    reads++;
    if (read != null) return read!();
    if (error != null) throw error!;
    return List.of(entries);
  }

  Stream<void> watchEntries() => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TimelineTestWorkRepository extends TimelineTestRepository<WorkLogEntry>
    implements WorkLogRepositoryPort {
  int monthReads = 0;
  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async {
    monthReads++;
    throw StateError('Timeline must read full history, not a calendar month');
  }
}

class TimelineTestExpenseRepository
    extends TimelineTestRepository<ExpenseRecordEntry>
    implements ExpenseRecordRepositoryPort {
  @override
  Future<ExpenseRecordEditDraft?> getEditDraft(int id) async {
    for (final entry in entries) {
      if (entry.id == id) return ExpenseRecordEditDraft(entry: entry);
    }
    return null;
  }

  @override
  Future<void> saveEntry(
    ExpenseRecordEntry entry, {
    required bool markDirty,
  }) async {
    entries = [
      for (final stored in entries)
        if (stored.id != entry.id) stored,
      entry,
    ];
    changes.add(null);
  }

  @override
  Future<void> deleteEntry(int id) async {
    entries = entries.where((entry) => entry.id != id).toList();
    changes.add(null);
  }
}

class TimelineTestEvidenceRepository
    extends TimelineTestRepository<EvidenceEntry>
    implements EvidenceRepositoryPort {}

class TimelineTestSubscriptionRepository
    extends TimelineTestRepository<SubscriptionEntry>
    implements SubscriptionRepositoryPort {}

WorkLogEntry timelineWork(
  int id,
  DateTime date, {
  WorkLogEntryType type = WorkLogEntryType.work,
}) => WorkLogEntry(id: id, date: date, type: type, note: '工时 $id');

ExpenseRecordEntry timelineExpense(
  int id,
  DateTime date, {
  String currency = 'CNY',
}) => ExpenseRecordEntry(
  id: id,
  expenseDate: date,
  amount: 100,
  currency: currency,
  merchant: '支出 $id',
);

EvidenceEntry timelineEvidence(int id, DateTime date) => EvidenceEntry(
  id: id,
  projectName: '项目 A',
  evidenceDate: date,
  amount: 30,
  currency: 'EUR',
  merchant: '凭证 $id',
);

SubscriptionEntry timelineSubscription(int id, DateTime date) =>
    SubscriptionEntry(
      id: id,
      name: '订阅 $id',
      price: 20,
      cycle: SubscriptionBillingCycle.monthly,
      nextPaymentDate: date,
    );
