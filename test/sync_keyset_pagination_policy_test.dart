import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sync keyset pagination policy', () {
    test('feature sync adapters avoid offset range pagination', () {
      final adapterFiles = Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_sync_adapter.dart'))
          .toList();

      expect(adapterFiles, isNotEmpty);
      for (final file in adapterFiles) {
        final source = file.readAsStringSync();
        expect(source, isNot(contains('.range(start')), reason: file.path);
        expect(source, isNot(contains('start += pageSize')), reason: file.path);
        expect(
          source,
          contains('SyncPullPage'),
          reason: '${file.path} should use shared keyset guardrails',
        );
      }
    });

    test('shared pull page helper documents keyset upper-bound semantics', () {
      final helper = File('lib/core/sync/sync_pull_page.dart');

      expect(helper.existsSync(), isTrue);
      final source = helper.readAsStringSync();
      expect(source, contains('class SyncPullPage'));
      expect(source, contains('updated_at'));
      expect(source, contains('id'));
      expect(source, contains('upperBound'));
      expect(source, contains('isAfterCursor'));
    });
  });
}
