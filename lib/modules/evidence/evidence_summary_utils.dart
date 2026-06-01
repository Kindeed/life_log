import 'evidence_model.dart';

String evidenceDisplayTitle(ExpenseEvidence item) {
  final parsed = _parseContentSummary(item);
  if (parsed?.title case final title? when title.isNotEmpty) return title;

  final merchant = item.merchant?.trim();
  if (merchant != null && merchant.isNotEmpty) return merchant;
  return item.category.label;
}

String evidenceDisplaySubtitle(ExpenseEvidence item) {
  final parsed = _parseContentSummary(item);
  final parts = [
    if (parsed?.dateTime case final dateTime? when dateTime.isNotEmpty)
      dateTime,
    item.category.label,
  ];
  return parts.join(' · ');
}

String? evidenceContentSummary(ExpenseEvidence item) {
  final note = item.note?.trim();
  if (note == null || note.isEmpty) return null;

  final lines = note
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  for (final line in lines) {
    if (line.startsWith('消费内容：')) {
      final value = line.replaceFirst('消费内容：', '').trim();
      return value.isEmpty ? null : value;
    }
  }

  for (final line in lines) {
    if (line.startsWith('购买方：') ||
        line.startsWith('纳税号：') ||
        line.startsWith('发票号：')) {
      continue;
    }
    return line;
  }
  return null;
}

_EvidenceContentParts? _parseContentSummary(ExpenseEvidence item) {
  final summary = evidenceContentSummary(item);
  if (summary == null || summary.isEmpty) return null;

  final match = RegExp(
    r'^(.*?)(?:\s+(\d{4}-\d{2}-\d{2})(?:\s+(\d{1,2}:\d{2}))?)$',
  ).firstMatch(summary);
  if (match == null) return _EvidenceContentParts(title: summary);

  final title = match.group(1)?.trim();
  final date = match.group(2)?.trim();
  final time = match.group(3)?.trim();
  if (title == null || title.isEmpty || date == null || date.isEmpty) {
    return _EvidenceContentParts(title: summary);
  }

  return _EvidenceContentParts(
    title: title,
    dateTime: time == null || time.isEmpty ? date : '$date $time',
  );
}

class _EvidenceContentParts {
  const _EvidenceContentParts({required this.title, this.dateTime});

  final String title;
  final String? dateTime;
}
