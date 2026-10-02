import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:isar_community/isar.dart';

/// Uses the native core shipped by the locked Flutter package, without fetching
/// a different Isar release at test time. Missing or incompatible cores fail
/// tests instead of silently removing database coverage.
Future<void> initializeTestIsar() async {
  final libraryPath = await locateTestIsarLibrary();
  await Isar.initializeIsarCore(
    libraries: {Abi.current(): libraryPath},
    download: false,
  );
}

Future<String> locateTestIsarLibrary({
  Map<String, String>? environment,
  Uri? packageLibraryUri,
  Abi? abi,
}) async {
  final values = environment ?? Platform.environment;
  for (final variable in ['ISAR_LIBRARY_PATH', 'ISAR_DLL_PATH']) {
    final override = values[variable]?.trim();
    if (override == null || override.isEmpty) continue;
    final library = File(override);
    if (!library.existsSync()) {
      throw StateError('$variable points to a missing Isar core: $override');
    }
    return library.absolute.path;
  }

  final currentAbi = abi ?? Abi.current();
  final relativePath = switch (currentAbi) {
    Abi.linuxX64 => '../linux/libisar.so',
    Abi.windowsX64 => '../windows/libisar.dll',
    Abi.macosX64 || Abi.macosArm64 => '../macos/libisar.dylib',
    _ => throw UnsupportedError(
      'The locked Isar test package does not provide a core for $currentAbi. '
      'Set ISAR_LIBRARY_PATH to a matching isar_community core.',
    ),
  };
  final packageUri = packageLibraryUri ?? await _resolvePackageLibraryUri();
  if (packageUri != null && packageUri.scheme == 'file') {
    final library = File.fromUri(packageUri.resolve(relativePath));
    if (library.existsSync()) return library.absolute.path;
  }
  throw StateError(
    'The native Isar core for $currentAbi is missing from the locked '
    'isar_community_flutter_libs package. Run flutter pub get --enforce-lockfile '
    'or set ISAR_LIBRARY_PATH to a matching core. Database tests are required.',
  );
}

Future<Uri?> _resolvePackageLibraryUri() async {
  try {
    return await Isolate.resolvePackageUri(
      Uri.parse('package:isar_community_flutter_libs/isar_flutter_libs.dart'),
    );
  } on UnsupportedError {
    // Flutter's test VM cannot resolve package URIs. Ask the normal Dart
    // loader to resolve the same locked package instead of guessing a pub
    // cache path or silently removing database coverage.
    final result = await Process.run('dart', [
      'run',
      'tool/isar_test_runtime.dart',
      '--print-package-library-uri',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'Dart could not resolve the required Isar test core: ${result.stderr}',
      );
    }
    final output = result.stdout.toString().trim();
    final uri = Uri.tryParse(output.split('\n').last);
    if (uri == null || uri.scheme != 'file') {
      throw StateError('Dart returned an invalid Isar package URI: $output');
    }
    return uri;
  }
}

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--print-package-library-uri')) {
    final uri = await Isolate.resolvePackageUri(
      Uri.parse('package:isar_community_flutter_libs/isar_flutter_libs.dart'),
    );
    if (uri == null) throw StateError('Locked Isar package is unavailable.');
    stdout.writeln(uri);
    return;
  }
  await initializeTestIsar();
  stdout.writeln('Native Isar test runtime verified for ${Abi.current()}.');
}
