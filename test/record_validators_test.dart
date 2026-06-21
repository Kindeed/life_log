import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/utils/record_validators.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

void main() {
  test('validateWorkLog rejects negative values', () {
    final log = WorkLog()
      ..date = DateTime(2026)
      ..type = LogType.work
      ..overtimeHours = -1;

    expect(() => validateWorkLog(log), throwsArgumentError);

    log
      ..overtimeHours = null
      ..expenses = -0.01;
    expect(() => validateWorkLog(log), throwsArgumentError);
  });

  test('validateWorkLog allows zero and empty expense', () {
    final log = WorkLog()
      ..date = DateTime(2026)
      ..type = LogType.businessTrip
      ..overtimeHours = 0;

    expect(() => validateWorkLog(log), returnsNormally);
  });

  test('validateSubscription rejects invalid fields', () {
    final sub = Subscription()
      ..name = ''
      ..nextPaymentDate = DateTime(2026);

    expect(() => validateSubscription(sub), throwsArgumentError);

    sub
      ..name = 'Cloud'
      ..price = -1;
    expect(() => validateSubscription(sub), throwsArgumentError);

    sub
      ..price = 1
      ..reminderDays = -1;
    expect(() => validateSubscription(sub), throwsArgumentError);
  });

  test(
    'validateExpenseEvidence rejects negative amount and defaults currency',
    () {
      final evidence = ExpenseEvidence()
        ..projectName = 'Trip'
        ..evidenceDate = DateTime(2026)
        ..amount = -1;

      expect(() => validateExpenseEvidence(evidence), throwsArgumentError);

      evidence
        ..amount = null
        ..currency = ' ';
      validateExpenseEvidence(evidence);
      expect(evidence.currency, 'CNY');
    },
  );

  test(
    'validateExpenseRecord rejects negative amount and defaults currency',
    () {
      final record = ExpenseRecord()
        ..expenseDate = DateTime(2026)
        ..amount = -1;

      expect(() => validateExpenseRecord(record), throwsArgumentError);

      record
        ..amount = 12
        ..currency = ' '
        ..projectName = ' ';
      validateExpenseRecord(record);
      expect(record.currency, 'CNY');
      expect(record.projectName, isNull);
    },
  );
}
