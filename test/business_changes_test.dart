import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';
import 'package:life_log/modules/expense/expense_record_model.dart';
import 'package:life_log/modules/project/project_model.dart';
import 'package:life_log/modules/subscription/subscription_model.dart';
import 'package:life_log/modules/work_log/work_log_model.dart';

void main() {
  WorkLog workLog() {
    return WorkLog()
      ..date = DateTime(2026, 5, 6)
      ..type = LogType.work
      ..overtimeHours = 1
      ..note = 'note';
  }

  Subscription subscription() {
    return Subscription()
      ..name = 'Service'
      ..price = 10
      ..cycle = SubscriptionCycle.monthly
      ..nextPaymentDate = DateTime(2026, 5, 6)
      ..reminderDays = 1
      ..sortIndex = 0;
  }

  test('WorkLog business change detection ignores sync metadata', () {
    final original = workLog()..remoteVersion = 1;
    final next = workLog()..remoteVersion = 2;

    expect(next.hasBusinessChangesComparedTo(original), isFalse);

    next.overtimeHours = 2;
    expect(next.hasBusinessChangesComparedTo(original), isTrue);
  });

  test('Subscription business change detection ignores sync metadata', () {
    final original = subscription()..remoteVersion = 1;
    final next = subscription()..remoteVersion = 2;

    expect(next.hasBusinessChangesComparedTo(original), isFalse);

    next.price = 12;
    expect(next.hasBusinessChangesComparedTo(original), isTrue);
  });

  test('ExpenseRecord business change detection ignores sync metadata', () {
    ExpenseRecord record() {
      return ExpenseRecord()
        ..expenseDate = DateTime(2026, 5, 6)
        ..amount = 20
        ..currency = 'CNY'
        ..category = ExpenseCategory.meal
        ..merchant = 'Cafe';
    }

    final original = record()..remoteVersion = 1;
    final next = record()..remoteVersion = 2;

    expect(next.hasBusinessChangesComparedTo(original), isFalse);

    next.amount = 25;
    expect(next.hasBusinessChangesComparedTo(original), isTrue);
  });

  test('ExpenseEvidence business change detection ignores sync metadata', () {
    ExpenseEvidence evidence() {
      return ExpenseEvidence()
        ..projectName = 'Trip'
        ..evidenceDate = DateTime(2026, 5, 6)
        ..amount = 20
        ..currency = 'CNY'
        ..category = EvidenceCategory.invoice
        ..status = EvidenceStatus.pending;
    }

    final original = evidence()..remoteVersion = 1;
    final next = evidence()..remoteVersion = 2;

    expect(next.hasBusinessChangesComparedTo(original), isFalse);

    next.status = EvidenceStatus.reimbursed;
    expect(next.hasBusinessChangesComparedTo(original), isTrue);
  });

  test('Project business change detection ignores sync metadata', () {
    Project project() {
      return Project()
        ..name = 'Trip'
        ..status = ProjectStatus.active
        ..createdAt = DateTime(2026, 5, 6)
        ..updatedAt = DateTime(2026, 5, 6);
    }

    final original = project()..remoteVersion = 1;
    final next = project()..remoteVersion = 2;

    expect(next.hasBusinessChangesComparedTo(original), isFalse);

    next.status = ProjectStatus.archived;
    expect(next.hasBusinessChangesComparedTo(original), isTrue);
  });
}
