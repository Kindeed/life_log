import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';
import 'package:life_log/modules/evidence/evidence_summary_utils.dart';

void main() {
  ExpenseEvidence evidence({
    required EvidenceCategory category,
    required DateTime evidenceDate,
    required String note,
  }) {
    return ExpenseEvidence()
      ..projectName = 'ww'
      ..category = category
      ..evidenceDate = evidenceDate
      ..note = note;
  }

  test(
    'rail ticket list title omits travel date and subtitle uses travel date',
    () {
      final item = evidence(
        category: EvidenceCategory.invoice,
        evidenceDate: DateTime(2026, 6, 1),
        note: '消费内容：广州 → 阳江北 2026-05-21 12:08',
      );

      expect(evidenceDisplayTitle(item), '广州 → 阳江北');
      expect(evidenceDisplaySubtitle(item), '2026-05-21 12:08 · 发票');
    },
  );

  test(
    'meal list subtitle uses parsed consumption date, not evidence date',
    () {
      final item = evidence(
        category: EvidenceCategory.meal,
        evidenceDate: DateTime(2026, 6, 1),
        note: '消费内容：餐饮服务 2026-05-28',
      );

      expect(evidenceDisplayTitle(item), '餐饮服务');
      expect(evidenceDisplaySubtitle(item), '2026-05-28 · 餐饮');
    },
  );

  test('list subtitle does not fall back to imported evidence date', () {
    final item = evidence(
      category: EvidenceCategory.invoice,
      evidenceDate: DateTime(2026, 6, 1),
      note: '消费内容：住宿费',
    );

    expect(evidenceDisplayTitle(item), '住宿费');
    expect(evidenceDisplaySubtitle(item), '发票');
  });
}
