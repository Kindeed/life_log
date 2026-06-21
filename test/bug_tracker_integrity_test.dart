import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BUG_TRACKER integrity', () {
    test('table IDs are unique and statuses are valid', () {
      final source = File('BUG_TRACKER.md').readAsStringSync();
      final idPattern = RegExp(r'^\| ([A-Z]+[0-9]+(?:-[0-9]+)?) \|(.+)$');
      const validStatuses = {
        'open',
        'in_progress',
        'fixed',
        'deferred',
        'invalidated',
      };
      final seen = <String>{};
      final duplicates = <String>[];
      final missingStatuses = <String>[];

      for (final line in source.splitLines()) {
        final match = idPattern.firstMatch(line);
        if (match == null) continue;

        final id = match.group(1)!;
        final cells = match
            .group(2)!
            .split('|')
            .map((cell) => cell.trim())
            .where((cell) => cell.isNotEmpty)
            .toList();

        if (!seen.add(id)) {
          duplicates.add(id);
        }
        if (!cells.any(validStatuses.contains)) {
          missingStatuses.add(id);
        }
      }

      expect(duplicates, isEmpty, reason: 'BUG_TRACKER IDs must stay unique.');
      expect(
        missingStatuses,
        isEmpty,
        reason: 'Every BUG_TRACKER table row must carry a known status.',
      );
      expect(seen.length, greaterThan(0));
    });

    test('historical photo sync findings stay invalidated', () {
      final source = File('BUG_TRACKER.md').readAsStringSync();

      expect(
        source,
        contains('| H1 | invalidated | Add `syncId`/`remoteId`/`isDirty`'),
      );
      expect(
        source,
        contains('| H2 | invalidated | Add photo pull/push/merge paths'),
      );
      expect(
        source,
        contains('photos remain local-only and must not enter Supabase sync'),
      );
    });

    test('audit summary IDs exist in table with matching status', () {
      final source = File('BUG_TRACKER.md').readAsStringSync();
      final tableStatuses = _tableStatuses(source);
      final summaryPattern = RegExp(
        r'^- Newly discovered and (fixed|open|in progress|deferred|invalidated): ([A-Z]+[0-9]+(?:-[0-9]+)?)\.',
      );
      final missingRows = <String>[];
      final mismatchedStatuses = <String>[];

      for (final line in source.splitLines()) {
        final match = summaryPattern.firstMatch(line);
        if (match == null) continue;

        final expectedStatus = _normalizeSummaryStatus(match.group(1)!);
        final id = match.group(2)!;
        final actualStatus = tableStatuses[id];
        if (actualStatus == null) {
          missingRows.add(id);
        } else if (actualStatus != expectedStatus) {
          mismatchedStatuses.add(
            '$id summary=$expectedStatus table=$actualStatus',
          );
        }
      }

      expect(
        missingRows,
        isEmpty,
        reason: 'Every newly discovered summary bullet needs a table row.',
      );
      expect(
        mismatchedStatuses,
        isEmpty,
        reason: 'Summary bullet status must match the table status.',
      );
    });
  });
}

Map<String, String> _tableStatuses(String source) {
  final idPattern = RegExp(r'^\| ([A-Z]+[0-9]+(?:-[0-9]+)?) \|(.+)$');
  const validStatuses = {
    'open',
    'in_progress',
    'fixed',
    'deferred',
    'invalidated',
  };
  final statuses = <String, String>{};

  for (final line in source.splitLines()) {
    final match = idPattern.firstMatch(line);
    if (match == null) continue;

    final cells = match
        .group(2)!
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty);
    String? status;
    for (final cell in cells) {
      if (validStatuses.contains(cell)) {
        status = cell;
        break;
      }
    }
    if (status != null) {
      statuses[match.group(1)!] = status;
    }
  }

  return statuses;
}

String _normalizeSummaryStatus(String status) {
  return switch (status) {
    'in progress' => 'in_progress',
    _ => status,
  };
}

extension on String {
  List<String> splitLines() => split(RegExp(r'\r?\n'));
}
