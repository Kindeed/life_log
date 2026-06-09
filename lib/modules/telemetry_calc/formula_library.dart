import 'formula_library_data.dart';

enum FormulaDomain {
  rfAntennaReceiver('rfAntennaReceiver', 'RF / 天线 / 接收机'),
  propagationLink('propagationLink', '传播 / 链路'),
  baseband('baseband', '调制 / 基带'),
  telemetryFrames('telemetryFrames', '遥测帧 / 协议'),
  telecommand('telecommand', '遥控 / 上行'),
  rangingTracking('rangingTracking', '测距 / 跟踪'),
  system('system', '系统工程'),
  optical('optical', '光链路'),
  orbitContact('orbitContact', '轨道 / 接触'),
  compression('compression', '数据压缩'),
  protocol('protocol', '协议 / 安全'),
  measurement('measurement', '测量 / 单位');

  final String key;
  final String label;

  const FormulaDomain(this.key, this.label);

  static FormulaDomain fromKey(String key) {
    return FormulaDomain.values.firstWhere(
      (domain) => domain.key == key,
      orElse: () => FormulaDomain.rfAntennaReceiver,
    );
  }
}

enum FormulaStatus {
  implemented('implemented', '已实现'),
  seeded('seeded', '已收录'),
  procedure('procedure', '流程/表格');

  final String key;
  final String label;

  const FormulaStatus(this.key, this.label);

  static FormulaStatus fromKey(String key) {
    return FormulaStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => FormulaStatus.seeded,
    );
  }
}

class FormulaVariableInfo {
  final String symbol;
  final String fieldId;
  final String meaning;
  final String concept;
  final String units;
  final String dimension;
  final String notes;

  const FormulaVariableInfo({
    required this.symbol,
    required this.fieldId,
    required this.meaning,
    required this.concept,
    required this.units,
    required this.dimension,
    required this.notes,
  });

  factory FormulaVariableInfo.fromRow(Map<String, Object?> row) {
    return FormulaVariableInfo(
      symbol: row['symbol'] as String? ?? '',
      fieldId: row['fieldId'] as String? ?? '',
      meaning: row['meaning'] as String? ?? '',
      concept: row['concept'] as String? ?? '',
      units: row['units'] as String? ?? '',
      dimension: row['dimension'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
    );
  }
}

class FormulaLibraryEntry {
  final String id;
  final FormulaDomain domain;
  final String section;
  final String expression;
  final String texExpression;
  final String variablesRaw;
  final List<FormulaVariableInfo> variables;
  final String explanation;
  final String sourceFamily;
  final FormulaStatus status;
  final List<String> relatedCalculatorIds;

  const FormulaLibraryEntry({
    required this.id,
    required this.domain,
    required this.section,
    required this.expression,
    required this.texExpression,
    required this.variablesRaw,
    required this.variables,
    required this.explanation,
    required this.sourceFamily,
    required this.status,
    this.relatedCalculatorIds = const [],
  });

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final fields = [
      id,
      domain.label,
      section,
      expression,
      variablesRaw,
      explanation,
      sourceFamily,
      status.label,
      for (final variable in variables) ...[
        variable.symbol,
        variable.meaning,
        variable.units,
        variable.notes,
      ],
    ];
    return fields.any((field) => field.toLowerCase().contains(normalized));
  }
}

class FormulaDomainSummary {
  final FormulaDomain domain;
  final int count;

  const FormulaDomainSummary({required this.domain, required this.count});
}

class FormulaLibraryRepository {
  late final Map<String, FormulaVariableInfo> _variablesBySymbol =
      _buildVariables();
  late final List<FormulaLibraryEntry> _entries = _buildEntries();

  List<FormulaLibraryEntry> loadAll() => List.unmodifiable(_entries);

  FormulaLibraryEntry? byId(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  List<FormulaLibraryEntry> byDomain(FormulaDomain domain) {
    return _entries
        .where((entry) => entry.domain == domain)
        .toList(growable: false);
  }

  List<FormulaLibraryEntry> search(String query) {
    return _entries
        .where((entry) => entry.matches(query))
        .toList(growable: false);
  }

  List<FormulaDomainSummary> get domainSummaries {
    return [
      for (final domain in FormulaDomain.values)
        FormulaDomainSummary(domain: domain, count: byDomain(domain).length),
    ];
  }

  Map<String, FormulaVariableInfo> _buildVariables() {
    final variables = <String, FormulaVariableInfo>{};
    for (final row in formulaVariableRows) {
      final variable = FormulaVariableInfo.fromRow(row);
      variables.putIfAbsent(variable.symbol, () => variable);
    }
    return variables;
  }

  List<FormulaLibraryEntry> _buildEntries() {
    return [
      for (final row in formulaLibraryRows)
        FormulaLibraryEntry(
          id: row['id'] as String? ?? '',
          domain: FormulaDomain.fromKey(row['domain'] as String? ?? ''),
          section: row['section'] as String? ?? '',
          expression: row['expression'] as String? ?? '',
          texExpression: row['texExpression'] as String? ?? '',
          variablesRaw: row['variablesRaw'] as String? ?? '',
          variables: _resolveVariables(row),
          explanation: row['explanation'] as String? ?? '',
          sourceFamily: row['sourceFamily'] as String? ?? '',
          status: FormulaStatus.fromKey(row['status'] as String? ?? ''),
          relatedCalculatorIds: _relatedCalculatorIds(
            row['id'] as String? ?? '',
          ),
        ),
    ];
  }

  List<FormulaVariableInfo> _resolveVariables(Map<String, Object?> row) {
    final symbols = row['variableSymbols'] as List<Object?>? ?? const [];
    return [
      for (final rawSymbol in symbols)
        _variablesBySymbol[rawSymbol.toString()] ??
            FormulaVariableInfo(
              symbol: rawSymbol.toString(),
              fieldId: '',
              meaning: _fallbackMeaning(rawSymbol.toString(), row),
              concept: _fallbackMeaning(rawSymbol.toString(), row),
              units: '',
              dimension: '',
              notes: '',
            ),
    ];
  }

  String _fallbackMeaning(String symbol, Map<String, Object?> row) {
    final variablesRaw = row['variablesRaw'] as String? ?? '';
    final match = RegExp(
      '${RegExp.escape(symbol)}:?\\s*([^;]+)',
      caseSensitive: false,
    ).firstMatch(variablesRaw);
    return match?.group(1)?.trim() ?? '公式局部变量';
  }

  List<String> _relatedCalculatorIds(String id) {
    if (id.startsWith('SYS-')) {
      return const [
        'spacecraft_power',
        'spacecraft_thermal',
        'mission_closure',
      ];
    }
    if (id.startsWith('LINK-') || id.startsWith('RF-')) {
      return const ['link_budget'];
    }
    if (id.startsWith('TC-')) return const ['telecommand'];
    if (id.startsWith('TRK-')) return const ['ranging', 'doppler'];
    return const [];
  }
}
