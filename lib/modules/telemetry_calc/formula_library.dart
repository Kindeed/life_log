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
    final symbol = row['symbol'] as String? ?? '';
    final fieldId = row['fieldId'] as String? ?? '';
    final rawMeaning = row['meaning'] as String? ?? '';
    final rawConcept = row['concept'] as String? ?? '';
    return FormulaVariableInfo(
      symbol: symbol,
      fieldId: fieldId,
      meaning: localizedVariableMeaning(
        symbol: symbol,
        fieldId: fieldId,
        rawMeaning: rawMeaning,
      ),
      concept: localizedVariableConcept(
        symbol: symbol,
        fieldId: fieldId,
        rawConcept: rawConcept,
        rawMeaning: rawMeaning,
      ),
      units: row['units'] as String? ?? '',
      dimension: row['dimension'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
    );
  }

  String get displaySymbol => formulaDisplaySymbol(symbol);
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
          explanation: localizedFormulaExplanation(
            id: row['id'] as String? ?? '',
            domain: FormulaDomain.fromKey(row['domain'] as String? ?? ''),
            rawExplanation: row['explanation'] as String? ?? '',
          ),
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
              meaning: localizedVariableMeaning(
                symbol: rawSymbol.toString(),
                fieldId: '',
                rawMeaning: _fallbackMeaning(rawSymbol.toString(), row),
              ),
              concept: localizedVariableConcept(
                symbol: rawSymbol.toString(),
                fieldId: '',
                rawConcept: _fallbackMeaning(rawSymbol.toString(), row),
                rawMeaning: _fallbackMeaning(rawSymbol.toString(), row),
              ),
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

String formulaDisplaySymbol(String symbol) {
  const exact = {
    'lambda': 'λ',
    'pi': 'π',
    'theta': 'θ',
    'phi': 'φ',
    'eta': 'η',
    'sigma': 'σ',
    'gamma': 'γ',
    'rho': 'ρ',
    'alpha': 'α',
    'beta': 'β',
    'Omega': 'Ω',
  };
  var display = exact[symbol] ?? symbol;
  for (final entry in exact.entries) {
    display = display.replaceAllMapped(
      RegExp('(^|[^A-Za-z])${RegExp.escape(entry.key)}([^A-Za-z]|\$)'),
      (match) => '${match.group(1)}${entry.value}${match.group(2)}',
    );
  }
  return display;
}

String localizedVariableMeaning({
  required String symbol,
  required String fieldId,
  required String rawMeaning,
}) {
  final exact = _exactVariableMeaning(symbol);
  if (exact != null) return exact;

  final fromField = _localizedFromIdentifier(fieldId);
  if (fromField.isNotEmpty) return fromField;

  final translated = _translateCommonEngineeringPhrase(rawMeaning);
  if (_isUsableChineseMeaning(translated)) return translated;

  return '公式参数';
}

String localizedVariableConcept({
  required String symbol,
  required String fieldId,
  required String rawConcept,
  required String rawMeaning,
}) {
  final meaning = localizedVariableMeaning(
    symbol: symbol,
    fieldId: fieldId,
    rawMeaning: rawMeaning,
  );
  final translated = _translateCommonEngineeringPhrase(rawConcept);
  if (_isUsableChineseMeaning(translated)) return translated;
  return '用于公式中的$meaning。';
}

String localizedFormulaExplanation({
  required String id,
  required FormulaDomain domain,
  required String rawExplanation,
}) {
  final exact = _exactFormulaExplanation(id);
  if (exact != null) return exact;
  final translated = _translateCommonEngineeringPhrase(rawExplanation);
  if (_isUsableChineseMeaning(translated)) return translated;
  return '用于${_formulaDomainChineseName(domain)}工程计算，变量按下方参数说明取值。';
}

String _formulaDomainChineseName(FormulaDomain domain) {
  return switch (domain) {
    FormulaDomain.rfAntennaReceiver => '射频天线接收',
    FormulaDomain.propagationLink => '传播链路',
    FormulaDomain.baseband => '调制基带',
    FormulaDomain.telemetryFrames => '遥测帧协议',
    FormulaDomain.telecommand => '遥控上行',
    FormulaDomain.rangingTracking => '测距跟踪',
    FormulaDomain.system => '系统工程',
    FormulaDomain.optical => '光链路',
    FormulaDomain.orbitContact => '轨道接触',
    FormulaDomain.compression => '数据压缩',
    FormulaDomain.protocol => '协议安全',
    FormulaDomain.measurement => '测量单位',
  };
}

String? _exactFormulaExplanation(String id) {
  const exact = {
    'RF-001': '将射频载波频率换算为波长，供天线增益、孔径和自由空间损耗计算使用。',
    'RF-022': '按表面误差关系估算反射面均方根误差造成的孔径效率损失，适用于反射面精度评估。',
  };
  return exact[id];
}

String? _exactVariableMeaning(String symbol) {
  const exact = {
    'c': '真空光速',
    'k': '玻尔兹曼常数',
    'T0': '标准噪声温度',
    'h': '普朗克常数',
    'pi': '圆周率',
    'f': '载波频率',
    'f_c': '载波频率',
    'lambda': '波长',
    'D': '天线口径',
    'eta': '效率系数',
    'A': '物理孔径面积',
    'A_p': '几何孔径面积',
    'A_e': '有效接收孔径',
    'G': '线性天线增益',
    'G/T': '接收系统品质因数',
    'EIRP': '等效全向辐射功率',
    'ERP': '等效偶极子辐射功率',
    'VSWR': '电压驻波比',
    'Gamma': '反射系数幅度',
    'R': '距离',
    'r': '距离',
    'd': '距离',
    'P': '功率',
    'P_r': '接收功率',
    'P_t': '发射功率',
    'L': '损耗',
    'T': '温度',
    'N': '数量',
    'M': '调制阶数',
    'B': '带宽',
    'R_b': '信息比特率',
    'C/N0': '载噪密度比',
    'Eb/N0': '比特能量噪声密度比',
    'K_surf': '表面误差几何系数',
    'sigma_surface': '表面均方根误差',
  };
  return exact[symbol];
}

String _localizedFromIdentifier(String fieldId) {
  if (fieldId.trim().isEmpty) return '';
  final tokens = fieldId
      .split(RegExp(r'[_\s]+'))
      .map((token) => token.trim().toLowerCase())
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
  final words = <String>[];
  for (final token in tokens) {
    final translated = _identifierTokenZh[token];
    if (translated != null && translated.isNotEmpty) {
      words.add(translated);
    }
  }
  if (words.isEmpty) return '';
  return _dedupeAdjacent(words).join('');
}

List<String> _dedupeAdjacent(List<String> words) {
  final result = <String>[];
  for (final word in words) {
    if (result.isEmpty || result.last != word) result.add(word);
  }
  return result;
}

String _translateCommonEngineeringPhrase(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return '';
  final replacements = <String, String>{
    'speed of light in vacuum': '真空光速',
    'speed of light': '光速',
    'Boltzmann constant': '玻尔兹曼常数',
    'standard noise temperature': '标准噪声温度',
    'Planck constant': '普朗克常数',
    'circle constant': '圆周率',
    'carrier frequency': '载波频率',
    'wavelength': '波长',
    'frequency': '频率',
    'antenna gain': '天线增益',
    'linear gain': '线性增益',
    'gain': '增益',
    'temperature': '温度',
    'power': '功率',
    'range': '距离',
    'distance': '距离',
    'ratio': '比值',
    'length': '长度',
    'angle': '角度',
    'error': '误差',
    'number': '数量',
    'time': '时间',
    'rate': '速率',
    'bandwidth': '带宽',
    'efficiency': '效率',
    'loss': '损耗',
    'margin': '余量',
    'duration': '持续时间',
    'period': '周期',
    'area': '面积',
    'diameter': '直径',
    'aperture': '孔径',
    'noise': '噪声',
    'phase': '相位',
    'bit': '比特',
    'symbol': '符号',
    'frame': '帧',
    'packet': '包',
    'field': '字段',
    'payload': '载荷',
    'header': '头部',
    'trailer': '尾部',
    'sample': '采样',
    'component': '分量',
    'maximum': '最大',
    'minimum': '最小',
    'mean': '平均',
    'RMS': '均方根',
  };
  for (final entry in replacements.entries) {
    text = text.replaceAll(
      RegExp(RegExp.escape(entry.key), caseSensitive: false),
      entry.value,
    );
  }
  if (_isUsableChineseMeaning(text)) return text;
  return '';
}

bool _isUsableChineseMeaning(String value) {
  if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(value)) return false;
  return !RegExp(r'[A-Za-z]{2,}').hasMatch(value);
}

const _identifierTokenZh = {
  'acknowledgement': '确认',
  'active': '有源',
  'allocation': '分配',
  'allan': '阿伦',
  'allowed': '允许',
  'amplitude': '幅度',
  'angle': '角度',
  'antenna': '天线',
  'aperture': '孔径',
  'array': '阵列',
  'astigmatism': '像散',
  'atmos': '大气',
  'average': '平均',
  'backoff': '回退',
  'bandwidth': '带宽',
  'baseband': '基带',
  'beam': '波束',
  'beamwidth': '波束宽度',
  'bit': '比特',
  'block': '块',
  'blockage': '遮挡',
  'boresight': '轴向',
  'bound': '边界',
  'branch': '分支',
  'brightness': '亮温',
  'capacity': '容量',
  'carrier': '载波',
  'cascade': '级联',
  'channel': '信道',
  'clock': '时钟',
  'code': '编码',
  'coded': '编码后',
  'coherent': '相干',
  'complete': '完整',
  'cone': '锥角',
  'constant': '常数',
  'contact': '接触',
  'control': '控制',
  'count': '数量',
  'coupling': '耦合',
  'cross': '交叉',
  'current': '当前',
  'data': '数据',
  'db': '分贝',
  'decibel': '分贝',
  'delay': '时延',
  'density': '密度',
  'depth': '深度',
  'deviation': '偏差',
  'diameter': '直径',
  'dimension': '尺寸',
  'directivity': '方向性',
  'distance': '距离',
  'doppler': '多普勒',
  'duration': '持续时间',
  'efficiency': '效率',
  'effective': '有效',
  'element': '阵元',
  'ellipse': '椭圆',
  'equivalent': '等效',
  'error': '误差',
  'factor': '因子',
  'feed': '馈源',
  'field': '字段',
  'frame': '帧',
  'fraction': '比例',
  'frequency': '频率',
  'gain': '增益',
  'geometrical': '几何',
  'global': '全局',
  'guard': '保护',
  'header': '头部',
  'holdover': '守时',
  'illumination': '照明',
  'incident': '入射',
  'index': '序号',
  'information': '信息',
  'input': '输入',
  'interval': '间隔',
  'jitter': '抖动',
  'lateral': '横向',
  'leakage': '泄漏',
  'length': '长度',
  'linear': '线性',
  'link': '链路',
  'loss': '损耗',
  'margin': '余量',
  'maximum': '最大',
  'mean': '平均',
  'measured': '测量',
  'minimum': '最小',
  'noise': '噪声',
  'nominal': '标称',
  'normalized': '归一化',
  'offset': '偏移',
  'orbital': '轨道',
  'output': '输出',
  'packet': '包',
  'pattern': '方向图',
  'payload': '载荷',
  'peak': '峰值',
  'period': '周期',
  'phase': '相位',
  'physical': '物理',
  'pointing': '指向',
  'polarization': '极化',
  'port': '端口',
  'power': '功率',
  'primary': '主',
  'probability': '概率',
  'projected': '投影',
  'pulse': '脉冲',
  'quantization': '量化',
  'radiated': '辐射',
  'radiation': '辐射',
  'random': '随机',
  'range': '距离',
  'rate': '速率',
  'ratio': '比值',
  'reference': '参考',
  'reflector': '反射面',
  'relative': '相对',
  'repetition': '重复',
  'required': '所需',
  'resolution': '分辨率',
  'rms': '均方根',
  'sample': '采样',
  'scan': '扫描',
  'scattering': '散射',
  'selected': '选定',
  'sequence': '序列',
  'service': '业务',
  'sidelobe': '旁瓣',
  'signal': '信号',
  'size': '大小',
  'sky': '天空',
  'solid': '立体',
  'spacing': '间距',
  'spectral': '谱',
  'spillover': '溢出',
  'stability': '稳定度',
  'standard': '标准',
  'strut': '支撑杆',
  'surface': '表面',
  'symbol': '符号',
  'system': '系统',
  'taper': '锥削',
  'temperature': '温度',
  'time': '时间',
  'total': '总',
  'trailer': '尾部',
  'transfer': '传输',
  'transmitter': '发射机',
  'uncertainty': '不确定度',
  'usable': '可用',
  'user': '用户',
  'value': '值',
  'virtual': '虚拟',
  'voltage': '电压',
  'wave': '波',
  'wavelength': '波长',
  'width': '宽度',
};
