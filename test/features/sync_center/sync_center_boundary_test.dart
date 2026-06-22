import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sync center boundary', () {
    test('exposes a presentation-only sync status and conflict center', () {
      final view = File(
        'lib/features/sync_center/presentation/sync_center_view.dart',
      );
      final di = File('lib/features/sync_center/sync_center_feature_di.dart');
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();

      expect(view.existsSync(), isTrue);
      expect(di.existsSync(), isTrue);
      expect(appEntry, contains('configureSyncCenterFeatureDependencies'));

      final source = view.readAsStringSync();
      expect(source, contains('class SyncCenterView'));
      expect(source, contains('LoadSyncCenterSnapshot'));
      expect(source, contains('pendingQueueEntries'));
      expect(source, contains('unresolvedConflicts'));
      expect(source, contains('保留本地'));
      expect(source, contains('采用远端'));
      expect(source, contains('复制为新记录'));
      expect(source, contains('稍后处理'));
      expect(source, isNot(contains('DbService')));
      expect(source, isNot(contains('SyncService')));
      expect(source, isNot(contains('PhotoItem')));
    });

    test('makes sync center reachable from Profile settings', () {
      final profile = File(
        'lib/features/profile/presentation/profile_view.dart',
      ).readAsStringSync();

      expect(profile, contains('SyncCenterView'));
      expect(profile, contains("title: '同步状态'"));
      expect(profile, contains('冲突、失败任务、附件同步状态'));
    });
  });
}
