import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/utils/sync_id_policy.dart';

void main() {
  test('ensureSyncId preserves existing non-empty sync IDs', () {
    expect(
      ensureSyncId('existing-id', generator: () => 'new-id'),
      'existing-id',
    );
  });

  test('ensureSyncId creates IDs for missing or blank sync IDs', () {
    var counter = 0;
    String nextId() => 'new-id-${++counter}';

    expect(ensureSyncId(null, generator: nextId), 'new-id-1');
    expect(ensureSyncId('', generator: nextId), 'new-id-2');
    expect(ensureSyncId('   ', generator: nextId), 'new-id-3');
  });
}
