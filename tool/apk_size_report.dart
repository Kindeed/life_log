import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/apk_size_report.dart <apk-dir> <output-file> [--max-mb=N]',
    );
    exit(64);
  }

  final directory = Directory(args[0]);
  final output = File(args[1]);
  final maxMb = _parseMaxMb(args.skip(2));

  if (!directory.existsSync()) {
    stderr.writeln('APK directory not found: ${directory.path}');
    exit(66);
  }

  final apkFiles =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.apk'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  if (apkFiles.isEmpty) {
    stderr.writeln('No APK files found in ${directory.path}');
    exit(65);
  }

  final now = DateTime.now().toIso8601String();
  final lines = <String>[
    '# LifeLog APK Size Report',
    '',
    'Generated: $now',
    if (maxMb != null) 'Threshold: ${maxMb.toStringAsFixed(1)} MB per APK',
    '',
    '| APK | Size MB | Size Bytes |',
    '| --- | ---: | ---: |',
  ];

  final violations = <String>[];
  final maxBytes = maxMb == null ? null : (maxMb * 1024 * 1024).round();
  for (final apk in apkFiles) {
    final bytes = apk.lengthSync();
    final mb = bytes / 1024 / 1024;
    final name = apk.uri.pathSegments.last;
    lines.add('| $name | ${mb.toStringAsFixed(2)} | $bytes |');
    if (maxBytes != null && bytes > maxBytes) {
      violations.add('$name ${mb.toStringAsFixed(2)} MB > $maxMb MB');
    }
  }

  output.parent.createSync(recursive: true);
  output.writeAsStringSync('${lines.join('\n')}\n');
  stdout.write(output.readAsStringSync());

  if (violations.isNotEmpty) {
    stderr.writeln('APK size threshold exceeded: ${violations.join('; ')}');
    exit(73);
  }
}

double? _parseMaxMb(Iterable<String> args) {
  for (final arg in args) {
    if (!arg.startsWith('--max-mb=')) continue;
    final value = double.tryParse(arg.substring('--max-mb='.length));
    if (value == null || value <= 0) {
      stderr.writeln('Invalid --max-mb value: $arg');
      exit(64);
    }
    return value;
  }
  return null;
}
