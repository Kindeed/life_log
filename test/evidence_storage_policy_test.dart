import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/utils/evidence_storage_policy.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'remote filenames cannot write outside the evidence download folder',
    () async {
      final folder = await Directory.systemTemp.createTemp('evidence_paths_');
      final destination = Directory(p.join(folder.path, 'project'));
      await destination.create();
      try {
        for (final name in [
          '../../outside.pdf',
          r'..\..\outside.pdf',
          '/tmp/absolute.pdf',
          '票据.pdf',
        ]) {
          final path = safeEvidenceDownloadPath(
            directory: destination.path,
            remoteFileName: name,
          );
          await File(path).writeAsString('downloaded bytes');
          expect(p.isWithin(destination.path, path), isTrue);
          expect(await File(path).readAsString(), 'downloaded bytes');
        }
        expect(
          await File(p.join(folder.path, 'outside.pdf')).exists(),
          isFalse,
        );
        expect(
          () => safeEvidenceDownloadPath(
            directory: destination.path,
            remoteFileName: '..',
          ),
          throwsStateError,
        );
      } finally {
        await folder.delete(recursive: true);
      }
    },
  );

  test('storage operations reject foreign owner and traversal paths', () {
    expect(
      evidenceStoragePathBelongsToOwner('owner-a/evidence/file.pdf', 'owner-a'),
      isTrue,
    );
    for (final path in [
      'owner-b/evidence/file.pdf',
      'owner-a-fake/file.pdf',
      'owner-a/../owner-b/file.pdf',
      r'owner-a/evidence\file.pdf',
    ]) {
      expect(evidenceStoragePathBelongsToOwner(path, 'owner-a'), isFalse);
    }
  });
}
