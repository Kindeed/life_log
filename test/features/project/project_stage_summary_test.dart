import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/presentation/project_stage_summary.dart';

void main() {
  test('stage totals preserve decimal precision and original currencies', () {
    final summaries = projectStageSummaries(
      definitions: ['勘查', '生产'],
      photos: [],
      expenses: [
        _expense(1, .1, 'CNY'),
        _expense(2, .2, 'CNY'),
        _expense(3, 1.2345, 'USD'),
        _expense(4, .0001, 'USD'),
      ],
      evidence: [],
      trips: [],
    );
    expect(summaries.map((s) => s.name), ['勘查', '生产', '']);
    expect(summaries.first.totals, {'CNY': .3, 'USD': 1.2346});
    expect(formatMoney(summaries.first.totals['CNY']!), '¥0.30');
    expect(summaries[1].totals, isEmpty);
  });
  test(
    'text records retain unknown stages and unassigned history without inferring progress',
    () {
      final date = DateTime(2026, 10, 11);
      final summaries = projectStageSummaries(
        definitions: ['勘查', '生产'],
        photos: [],
        expenses: [],
        evidence: [],
        trips: [],
        notes: [
          for (final stage in ['勘查', '旧节点', null])
            ProjectNoteEntry(
              projectId: 1,
              projectName: '项目',
              projectStageName: stage,
              content: '记录',
              date: date,
              createdAt: date,
              updatedAt: date,
            ),
        ],
      );
      expect(summaries.map((s) => s.name), ['勘查', '生产', '旧节点', '']);
      expect(summaries.map((s) => s.notes), [1, 0, 1, 1]);
    },
  );
}

ExpenseRecordEntry _expense(int id, double amount, String currency) =>
    ExpenseRecordEntry(
      id: id,
      expenseDate: DateTime(2026, 10, 11),
      amount: amount,
      currency: currency,
      category: ExpenseRecordEntryCategory.office,
      projectName: '项目',
      projectStageName: '勘查',
    );
