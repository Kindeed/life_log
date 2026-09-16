import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Supabase migration versions are unique', () {
    final migrationDirectory = Directory('supabase/migrations');
    final migrationFiles = migrationDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.sql'))
        .toList();

    expect(migrationFiles, isNotEmpty);

    final versions = migrationFiles
        .map((file) => file.uri.pathSegments.last.split('_').first)
        .toList();
    expect(
      versions.toSet().length,
      versions.length,
      reason: 'Each Supabase migration filename must have a unique version.',
    );
  });
}
