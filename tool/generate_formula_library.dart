import 'dart:io';

void main() {
  final catalog = File(
    'docs/formula_knowledge/formula_catalog.md',
  ).readAsLinesSync();
  final glossary = File(
    'docs/formula_knowledge/variable_glossary.md',
  ).readAsLinesSync();

  final variables = _parseGlossary(glossary);
  final formulas = _parseCatalog(catalog);
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart run tool/generate_formula_library.dart')
    ..writeln()
    ..writeln('const formulaLibraryGeneratedAt = \'2026-06-09\';')
    ..writeln()
    ..writeln('const formulaVariableRows = <Map<String, Object?>>[');

  for (final variable in variables) {
    buffer.writeln('  {');
    for (final entry in variable.entries) {
      buffer.writeln(
        '    ${_dartString(entry.key)}: ${_dartString(entry.value)},',
      );
    }
    buffer.writeln('  },');
  }
  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('const formulaLibraryRows = <Map<String, Object?>>[');

  for (final formula in formulas) {
    buffer.writeln('  {');
    for (final entry in formula.entries) {
      buffer.writeln(
        '    ${_dartString(entry.key)}: ${_dartValue(entry.value)},',
      );
    }
    buffer.writeln('  },');
  }
  buffer.writeln('];');

  File(
    'lib/features/telemetry_calc/data/formula_library_data.dart',
  ).writeAsStringSync(buffer.toString());
  stdout.writeln(
    'Generated ${formulas.length} formulas and ${variables.length} variables.',
  );
}

List<Map<String, String>> _parseGlossary(List<String> lines) {
  final rows = <Map<String, String>>[];
  var currentSection = '';
  for (final line in lines) {
    if (line.startsWith('## ')) {
      currentSection = line.substring(3).trim();
      continue;
    }
    if (!line.startsWith('| `')) continue;
    final cells = _splitMarkdownRow(line);
    if (cells.length < 4) continue;
    if (cells.first == 'Symbol') continue;

    final symbols = RegExp(r'`([^`]+)`')
        .allMatches(cells[0])
        .map((match) => match.group(1)!.trim())
        .where((symbol) => symbol.isNotEmpty)
        .toList();
    if (symbols.isEmpty) continue;

    for (final symbol in symbols) {
      final isConstant = currentSection == 'Constants';
      rows.add({
        'symbol': symbol,
        'fieldId': isConstant
            ? ''
            : _stripBackticks(cells.length >= 2 ? cells[1] : ''),
        'meaning': isConstant
            ? _stripBackticks(cells.length >= 2 ? cells[1] : '')
            : (cells.length >= 3 ? _stripBackticks(cells[2]) : ''),
        'concept': isConstant
            ? _stripBackticks(cells.length >= 2 ? cells[1] : '')
            : (cells.length >= 3 ? _stripBackticks(cells[2]) : ''),
        'units': isConstant
            ? (cells.length >= 4 ? _stripBackticks(cells[3]) : '')
            : (cells.length >= 4 ? _stripBackticks(cells[3]) : ''),
        'dimension': currentSection,
        'notes': cells.length >= 5 ? _stripBackticks(cells[4]) : '',
      });
    }
  }
  return rows;
}

List<Map<String, Object?>> _parseCatalog(List<String> lines) {
  final rows = <Map<String, Object?>>[];
  var section = '';
  for (final line in lines) {
    if (line.startsWith('## ')) {
      section = line.substring(3).trim();
      continue;
    }
    if (!RegExp(r'^\| [A-Z]+-[0-9]+').hasMatch(line)) continue;
    final cells = _splitMarkdownRow(line);
    if (cells.length < 6) continue;
    final id = cells[0].trim();
    rows.add({
      'id': id,
      'domain': _domainKey(section, id),
      'section': section,
      'expression': _stripBackticks(cells[1]),
      'texExpression': _toTex(_stripBackticks(cells[1])),
      'variablesRaw': _stripBackticks(cells[2]),
      'variableSymbols': _extractSymbols(cells[2]),
      'explanation': _stripBackticks(cells[3]),
      'sourceFamily': _stripBackticks(cells[4]),
      'status': _statusKey(cells[5]),
    });
  }
  return rows;
}

List<String> _splitMarkdownRow(String line) {
  final trimmed = line.trim();
  final content = trimmed.substring(
    1,
    trimmed.endsWith('|') ? trimmed.length - 1 : trimmed.length,
  );
  return content.split('|').map((cell) => cell.trim()).toList();
}

String _stripBackticks(String value) => value.replaceAll('`', '').trim();

List<String> _extractSymbols(String value) {
  final symbols = <String>{};
  for (final match in RegExp(r'`([^`]+)`').allMatches(value)) {
    final raw = match.group(1)!.trim();
    for (final part in raw.split(RegExp(r'\s*/\s*|\s*,\s*|\s+or\s+'))) {
      final symbol = part.trim();
      if (symbol.isNotEmpty && symbol.length <= 40) symbols.add(symbol);
    }
  }
  return symbols.toList(growable: false);
}

String _domainKey(String section, String id) {
  if (section.contains('RF, Antenna')) return 'rfAntennaReceiver';
  if (section.contains('Propagation')) return 'propagationLink';
  if (section.contains('Modulation')) return 'baseband';
  if (section.contains('Telemetry')) return 'telemetryFrames';
  if (section.contains('Telecommand')) return 'telecommand';
  if (section.contains('Ranging')) return 'rangingTracking';
  if (section.contains('System-Level')) return 'system';
  if (section.contains('Optical')) return 'optical';
  if (section.contains('Orbit')) return 'orbitContact';
  if (section.contains('Compression')) return 'compression';
  if (section.contains('Protocol')) return 'protocol';
  if (section.contains('Measurement')) return 'measurement';
  if (id.startsWith('SYS-')) return 'system';
  return 'rfAntennaReceiver';
}

String _statusKey(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('implemented')) return 'implemented';
  if (normalized.contains('procedure')) return 'procedure';
  return 'seeded';
}

String _toTex(String expression) {
  var tex = expression;
  const greek = {
    'lambda': r'\lambda',
    'theta': r'\theta',
    'phi': r'\phi',
    'eta': r'\eta',
    'sigma': r'\sigma',
    'gamma': r'\gamma',
    'Omega': r'\Omega',
    'pi': r'\pi',
    'rho': r'\rho',
    'alpha': r'\alpha',
    'beta': r'\beta',
  };
  for (final entry in greek.entries) {
    tex = tex.replaceAllMapped(
      RegExp('(^|[^A-Za-z])${RegExp.escape(entry.key)}([^A-Za-z]|\$)'),
      (match) => '${match.group(1)}${entry.value}${match.group(2)}',
    );
  }
  tex = tex.replaceAll('~=', r'\approx');
  tex = tex.replaceAll('>=', r'\ge ');
  tex = tex.replaceAll('<=', r'\le ');
  tex = tex.replaceAll('*', r' \cdot ');
  return tex;
}

String _dartValue(Object? value) {
  if (value is List<String>) {
    return '<String>[${value.map(_dartString).join(', ')}]';
  }
  return _dartString(value?.toString() ?? '');
}

String _dartString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", "\\'")
      .replaceAll('\r', r'\r')
      .replaceAll('\n', r'\n');
  return '\'$escaped\'';
}
