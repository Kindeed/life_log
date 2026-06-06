import 'dart:math' as math;

import 'telemetry_formula_engine.dart';
import 'telemetry_units.dart';

enum TelemetryCalculatorCategory {
  link,
  rate,
  frame,
  coding,
  command,
  ranging,
  frequency,
  custom,
}

enum TelemetryInputKind { number, select, expression }

class TelemetryInputDefinition {
  final String id;
  final String label;
  final TelemetryInputKind kind;
  final QuantityDimension dimension;
  final List<String> units;
  final String defaultUnit;
  final double? defaultValue;
  final double? min;
  final double? max;
  final bool advanced;
  final String helper;
  final List<TelemetryOption> options;
  final String? defaultOptionId;
  final String? defaultText;

  const TelemetryInputDefinition.number({
    required this.id,
    required this.label,
    required this.dimension,
    required this.units,
    required this.defaultUnit,
    required this.defaultValue,
    this.min,
    this.max,
    this.advanced = false,
    this.helper = '',
  }) : kind = TelemetryInputKind.number,
       options = const [],
       defaultOptionId = null,
       defaultText = null;

  const TelemetryInputDefinition.select({
    required this.id,
    required this.label,
    required this.options,
    required this.defaultOptionId,
    this.advanced = false,
    this.helper = '',
  }) : kind = TelemetryInputKind.select,
       dimension = QuantityDimension.dimensionless,
       units = const ['unit'],
       defaultUnit = 'unit',
       defaultValue = null,
       min = null,
       max = null,
       defaultText = null;

  const TelemetryInputDefinition.expression({
    required this.id,
    required this.label,
    required this.defaultText,
    this.advanced = false,
    this.helper = '',
  }) : kind = TelemetryInputKind.expression,
       dimension = QuantityDimension.dimensionless,
       units = const ['unit'],
       defaultUnit = 'unit',
       defaultValue = null,
       min = null,
       max = null,
       options = const [],
       defaultOptionId = null;
}

class TelemetryOption {
  final String id;
  final String label;
  final double value;

  const TelemetryOption({
    required this.id,
    required this.label,
    required this.value,
  });
}

class TelemetryOutputDefinition {
  final String id;
  final String label;
  final String unitId;
  final int precision;
  final String helper;

  const TelemetryOutputDefinition({
    required this.id,
    required this.label,
    required this.unitId,
    this.precision = 2,
    this.helper = '',
  });
}

class FormulaReference {
  final String title;
  final String expression;
  final String source;
  final String note;

  const FormulaReference({
    required this.title,
    required this.expression,
    required this.source,
    this.note = '',
  });
}

typedef TelemetryCalculatorRunner =
    TelemetryCalculationResult Function(TelemetryCalculationContext context);

class TelemetryCalculatorDefinition {
  final String id;
  final TelemetryCalculatorCategory category;
  final String title;
  final String subtitle;
  final String standards;
  final List<TelemetryInputDefinition> inputs;
  final List<TelemetryOutputDefinition> outputs;
  final List<FormulaReference> formulas;
  final TelemetryCalculatorRunner runner;

  const TelemetryCalculatorDefinition({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.standards,
    required this.inputs,
    required this.outputs,
    required this.formulas,
    required this.runner,
  });
}

class TelemetryInputValue {
  final double? value;
  final String unitId;
  final String? optionId;
  final String? text;

  const TelemetryInputValue({
    this.value,
    required this.unitId,
    this.optionId,
    this.text,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'unitId': unitId,
    'optionId': optionId,
    'text': text,
  };

  factory TelemetryInputValue.fromJson(Map<String, dynamic> json) {
    return TelemetryInputValue(
      value: (json['value'] as num?)?.toDouble(),
      unitId: json['unitId'] as String? ?? 'unit',
      optionId: json['optionId'] as String?,
      text: json['text'] as String?,
    );
  }
}

class TelemetryCalculationOutput {
  final String id;
  final String label;
  final double value;
  final String unitId;
  final int precision;
  final String helper;

  const TelemetryCalculationOutput({
    required this.id,
    required this.label,
    required this.value,
    required this.unitId,
    required this.precision,
    required this.helper,
  });

  String get displayValue {
    if (value.abs() >= 100000 || value.abs() < 0.001 && value != 0) {
      return value.toStringAsExponential(precision);
    }
    return value.toStringAsFixed(precision);
  }

  String get unitLabel => UnitCatalog.unit(unitId).label;
}

class TelemetryCalculationResult {
  final List<TelemetryCalculationOutput> outputs;
  final List<String> warnings;
  final List<String> errors;

  const TelemetryCalculationResult({
    this.outputs = const [],
    this.warnings = const [],
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
}

class TelemetryCalculationContext {
  final TelemetryCalculatorDefinition definition;
  final Map<String, TelemetryInputValue> values;

  const TelemetryCalculationContext({
    required this.definition,
    required this.values,
  });

  double number(String id, String unitId) {
    final value = values[id];
    if (value == null || value.value == null) {
      throw TelemetryCalculationException('缺少参数: $id');
    }
    return UnitCatalog.convert(value.value!, value.unitId, unitId);
  }

  double optionValue(String id) {
    final field = definition.inputs.firstWhere((field) => field.id == id);
    final selected = values[id]?.optionId ?? field.defaultOptionId;
    final option = field.options.firstWhere((option) => option.id == selected);
    return option.value;
  }

  String text(String id) {
    final field = definition.inputs.firstWhere((field) => field.id == id);
    return values[id]?.text ?? field.defaultText ?? '';
  }

  TelemetryCalculationOutput output(String id, double value, {String? unitId}) {
    final definition = this.definition.outputs.firstWhere(
      (output) => output.id == id,
    );
    final targetUnit = unitId ?? definition.unitId;
    return TelemetryCalculationOutput(
      id: id,
      label: definition.label,
      value: UnitCatalog.convert(value, definition.unitId, targetUnit),
      unitId: targetUnit,
      precision: definition.precision,
      helper: definition.helper,
    );
  }
}

class TelemetryCalculationException implements Exception {
  final String message;

  const TelemetryCalculationException(this.message);

  @override
  String toString() => message;
}

class TelemetryCalculatorEngine {
  static TelemetryCalculationResult calculate(
    TelemetryCalculatorDefinition definition,
    Map<String, TelemetryInputValue> values,
  ) {
    final errors = validate(definition, values);
    if (errors.isNotEmpty) {
      return TelemetryCalculationResult(errors: errors);
    }

    try {
      return definition.runner(
        TelemetryCalculationContext(definition: definition, values: values),
      );
    } on TelemetryCalculationException catch (error) {
      return TelemetryCalculationResult(errors: [error.message]);
    } on FormulaEvaluationException catch (error) {
      return TelemetryCalculationResult(errors: [error.message]);
    } on Object catch (error) {
      return TelemetryCalculationResult(errors: ['计算失败: $error']);
    }
  }

  static List<String> validate(
    TelemetryCalculatorDefinition definition,
    Map<String, TelemetryInputValue> values,
  ) {
    final errors = <String>[];
    for (final input in definition.inputs) {
      final value = values[input.id];
      switch (input.kind) {
        case TelemetryInputKind.number:
          final number = value?.value;
          if (number == null || !number.isFinite) {
            errors.add('${input.label} 需要输入有效数字');
            continue;
          }
          if (!input.units.contains(value!.unitId)) {
            errors.add('${input.label} 单位不兼容');
          }
          if (input.min != null && number < input.min!) {
            errors.add('${input.label} 不能小于 ${input.min}');
          }
          if (input.max != null && number > input.max!) {
            errors.add('${input.label} 不能大于 ${input.max}');
          }
        case TelemetryInputKind.select:
          final optionId = value?.optionId ?? input.defaultOptionId;
          if (optionId == null ||
              !input.options.any((option) => option.id == optionId)) {
            errors.add('${input.label} 需要选择有效选项');
          }
        case TelemetryInputKind.expression:
          final text = value?.text ?? input.defaultText ?? '';
          if (text.trim().isEmpty) {
            errors.add('${input.label} 不能为空');
          }
      }
    }
    return errors;
  }
}

class TelemetryCalculatorRegistry {
  static const _commonFrequencyUnits = ['Hz', 'kHz', 'MHz', 'GHz'];
  static const _commonRateUnits = ['bps', 'kbps', 'Mbps', 'Gbps'];
  static const _commonDistanceUnits = ['m', 'km'];

  static final List<TelemetryCalculatorDefinition> definitions = [
    _linkBudget,
    _rateBandwidth,
    _pcmFrame,
    _channelCoding,
    _telecommand,
    _ranging,
    _doppler,
    _customFormula,
  ];

  static TelemetryCalculatorDefinition byId(String id) {
    return definitions.firstWhere((definition) => definition.id == id);
  }

  static Map<String, TelemetryInputValue> defaultValues(
    TelemetryCalculatorDefinition definition,
  ) {
    return {
      for (final input in definition.inputs)
        input.id: TelemetryInputValue(
          value: input.defaultValue,
          unitId: input.defaultUnit,
          optionId: input.defaultOptionId,
          text: input.defaultText,
        ),
    };
  }

  static TelemetryCalculationResult _withWarnings(
    List<TelemetryCalculationOutput> outputs,
    List<String> warnings,
  ) {
    return TelemetryCalculationResult(outputs: outputs, warnings: warnings);
  }

  static const _linkBudget = TelemetryCalculatorDefinition(
    id: 'link_budget',
    category: TelemetryCalculatorCategory.link,
    title: '链路预算',
    subtitle: 'EIRP、FSPL、C/N0、Eb/N0 与链路余量',
    standards: 'IRIG 106 / CCSDS SLS / Friis 工程通用',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'tx_power',
        label: '发射机输出功率',
        dimension: QuantityDimension.power,
        units: ['dBW', 'dBm'],
        defaultUnit: 'dBW',
        defaultValue: 10,
        helper: '功放输出端功率。',
      ),
      TelemetryInputDefinition.number(
        id: 'tx_loss',
        label: '发射馈线损耗',
        dimension: QuantityDimension.gain,
        units: ['dB'],
        defaultUnit: 'dB',
        defaultValue: 1,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'tx_gain',
        label: '发射天线增益',
        dimension: QuantityDimension.gain,
        units: ['dBi'],
        defaultUnit: 'dBi',
        defaultValue: 20,
      ),
      TelemetryInputDefinition.number(
        id: 'distance',
        label: '链路距离',
        dimension: QuantityDimension.distance,
        units: _commonDistanceUnits,
        defaultUnit: 'km',
        defaultValue: 1000,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'frequency',
        label: '载波频率',
        dimension: QuantityDimension.frequency,
        units: _commonFrequencyUnits,
        defaultUnit: 'GHz',
        defaultValue: 2.2,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'rx_gain',
        label: '接收天线增益',
        dimension: QuantityDimension.gain,
        units: ['dBi'],
        defaultUnit: 'dBi',
        defaultValue: 32,
      ),
      TelemetryInputDefinition.number(
        id: 'system_temp',
        label: '系统噪声温度',
        dimension: QuantityDimension.temperature,
        units: ['K'],
        defaultUnit: 'K',
        defaultValue: 500,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'data_rate',
        label: '数据率',
        dimension: QuantityDimension.dataRate,
        units: _commonRateUnits,
        defaultUnit: 'Mbps',
        defaultValue: 1,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'required_ebn0',
        label: '所需 Eb/N0',
        dimension: QuantityDimension.gain,
        units: ['dB'],
        defaultUnit: 'dB',
        defaultValue: 4,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'extra_loss',
        label: '其他损耗',
        dimension: QuantityDimension.gain,
        units: ['dB'],
        defaultUnit: 'dB',
        defaultValue: 2,
        min: 0,
        advanced: true,
        helper: '大气、极化、指向、实现损耗等合并项。',
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(id: 'eirp', label: 'EIRP', unitId: 'dBW'),
      TelemetryOutputDefinition(id: 'fspl', label: '自由空间损耗', unitId: 'dB'),
      TelemetryOutputDefinition(id: 'rx_power', label: '接收功率', unitId: 'dBW'),
      TelemetryOutputDefinition(id: 'g_over_t', label: 'G/T', unitId: 'dB'),
      TelemetryOutputDefinition(id: 'cn0', label: 'C/N0', unitId: 'dBHz'),
      TelemetryOutputDefinition(id: 'ebn0', label: 'Eb/N0', unitId: 'dB'),
      TelemetryOutputDefinition(id: 'margin', label: '链路余量', unitId: 'dB'),
    ],
    formulas: [
      FormulaReference(
        title: 'Friis / FSPL',
        expression: 'FSPL(dB)=92.45+20log10(d_km)+20log10(f_GHz)',
        source: 'IRIG 106 / CCSDS SLS / SpaceLink path model',
      ),
      FormulaReference(
        title: '载噪密度比',
        expression: 'C/N0=EIRP+G/T-FSPL-Loss+228.6',
        source: '工程链路预算通用形式',
      ),
    ],
    runner: _runLinkBudget,
  );

  static TelemetryCalculationResult _runLinkBudget(
    TelemetryCalculationContext context,
  ) {
    final txPower = context.number('tx_power', 'dBW');
    final txLoss = context.number('tx_loss', 'dB');
    final txGain = context.number('tx_gain', 'dBi');
    final distanceKm = context.number('distance', 'km');
    final frequencyGHz = context.number('frequency', 'GHz');
    final rxGain = context.number('rx_gain', 'dBi');
    final systemTemp = context.number('system_temp', 'K');
    final dataRate = context.number('data_rate', 'bps');
    final required = context.number('required_ebn0', 'dB');
    final extraLoss = context.number('extra_loss', 'dB');

    final eirp = txPower - txLoss + txGain;
    final fspl = 92.45 + 20 * _log10(distanceKm) + 20 * _log10(frequencyGHz);
    final rxPower = eirp + rxGain - fspl - extraLoss;
    final gOverT = rxGain - 10 * _log10(systemTemp);
    final cn0 = eirp + gOverT - fspl - extraLoss + 228.6;
    final ebn0 = cn0 - 10 * _log10(dataRate);
    final margin = ebn0 - required;

    return _withWarnings(
      [
        context.output('eirp', eirp),
        context.output('fspl', fspl),
        context.output('rx_power', rxPower),
        context.output('g_over_t', gOverT),
        context.output('cn0', cn0),
        context.output('ebn0', ebn0),
        context.output('margin', margin),
      ],
      [
        if (margin < 0) '链路余量为负，需提高 EIRP、降低码率或减少损耗。',
        if (extraLoss == 0) '其他损耗为 0，确认是否已计入大气、极化和实现损耗。',
      ],
    );
  }

  static const _rateBandwidth = TelemetryCalculatorDefinition(
    id: 'rate_bandwidth',
    category: TelemetryCalculatorCategory.rate,
    title: '码率与带宽',
    subtitle: '净荷率、编码率、调制阶数、滚降带宽',
    standards: 'IRIG 106 / CCSDS 同步与信道编码 / 工程通用',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'payload_rate',
        label: '净荷数据率',
        dimension: QuantityDimension.dataRate,
        units: _commonRateUnits,
        defaultUnit: 'Mbps',
        defaultValue: 2,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'coding_rate',
        label: '编码率',
        dimension: QuantityDimension.dimensionless,
        units: ['ratio'],
        defaultUnit: 'ratio',
        defaultValue: 0.5,
        min: 0.01,
        max: 1,
      ),
      TelemetryInputDefinition.select(
        id: 'modulation',
        label: '调制方式',
        defaultOptionId: 'qpsk',
        options: [
          TelemetryOption(id: 'bpsk', label: 'BPSK', value: 1),
          TelemetryOption(id: 'qpsk', label: 'QPSK', value: 2),
          TelemetryOption(id: '8psk', label: '8PSK', value: 3),
          TelemetryOption(id: '16qam', label: '16QAM', value: 4),
        ],
      ),
      TelemetryInputDefinition.number(
        id: 'rolloff',
        label: '滚降系数',
        dimension: QuantityDimension.dimensionless,
        units: ['ratio'],
        defaultUnit: 'ratio',
        defaultValue: 0.35,
        min: 0,
        max: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'overhead',
        label: '帧/协议开销',
        dimension: QuantityDimension.percent,
        units: ['percent'],
        defaultUnit: 'percent',
        defaultValue: 5,
        min: 0,
        max: 95,
        advanced: true,
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'coded_rate',
        label: '编码后码率',
        unitId: 'bps',
      ),
      TelemetryOutputDefinition(id: 'symbol_rate', label: '符号率', unitId: 'Hz'),
      TelemetryOutputDefinition(
        id: 'occupied_bandwidth',
        label: '占用带宽',
        unitId: 'Hz',
      ),
      TelemetryOutputDefinition(
        id: 'spectral_efficiency',
        label: '频谱效率',
        unitId: 'ratio',
      ),
    ],
    formulas: [
      FormulaReference(
        title: '符号率',
        expression: 'Rs=R_payload/(coding_rate*(1-overhead)*bits_per_symbol)',
        source: '数字通信工程通用',
      ),
    ],
    runner: _runRateBandwidth,
  );

  static TelemetryCalculationResult _runRateBandwidth(
    TelemetryCalculationContext context,
  ) {
    final payloadRate = context.number('payload_rate', 'bps');
    final codingRate = context.number('coding_rate', 'ratio');
    final bitsPerSymbol = context.optionValue('modulation');
    final rolloff = context.number('rolloff', 'ratio');
    final overhead = context.number('overhead', 'ratio');

    final codedRate = payloadRate / codingRate / (1 - overhead);
    final symbolRate = codedRate / bitsPerSymbol;
    final occupiedBandwidth = symbolRate * (1 + rolloff);
    final spectralEfficiency = payloadRate / occupiedBandwidth;

    return TelemetryCalculationResult(
      outputs: [
        context.output('coded_rate', codedRate, unitId: 'Mbps'),
        context.output('symbol_rate', symbolRate, unitId: 'Msps'),
        context.output('occupied_bandwidth', occupiedBandwidth, unitId: 'MHz'),
        context.output('spectral_efficiency', spectralEfficiency),
      ],
      warnings: [if (overhead > 0.2) '协议开销超过 20%，建议复核帧格式或封装层级。'],
    );
  }

  static const _pcmFrame = TelemetryCalculatorDefinition(
    id: 'pcm_frame',
    category: TelemetryCalculatorCategory.frame,
    title: 'PCM 帧格式',
    subtitle: '帧长、主帧周期、同步开销和参数采样率',
    standards: 'IRIG 106 Chapter 4 / GJB 21 系列公开目录',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'word_length',
        label: '字长',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 16,
        min: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'words_per_minor',
        label: '每小帧字数',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 256,
        min: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'minor_rate',
        label: '小帧速率',
        dimension: QuantityDimension.frequency,
        units: ['Hz', 'kHz'],
        defaultUnit: 'Hz',
        defaultValue: 100,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'minor_per_major',
        label: '每主帧小帧数',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 64,
        min: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'sync_bits',
        label: '同步字长度',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 32,
        min: 0,
        advanced: true,
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'minor_bits',
        label: '小帧长度',
        unitId: 'unit',
        precision: 0,
      ),
      TelemetryOutputDefinition(
        id: 'bit_rate',
        label: '总码率',
        unitId: 'bps',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'major_period',
        label: '主帧周期',
        unitId: 's',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'frame_efficiency',
        label: '帧效率',
        unitId: 'ratio',
        precision: 1,
      ),
      TelemetryOutputDefinition(
        id: 'parameter_sample_rate',
        label: '主帧参数采样率',
        unitId: 'Hz',
        precision: 3,
      ),
    ],
    formulas: [
      FormulaReference(
        title: 'PCM 帧码率',
        expression:
            'R=(word_length*words_per_minor+sync_bits)*minor_frame_rate',
        source: 'IRIG 106 Chapter 4 工程化计算',
      ),
    ],
    runner: _runPcmFrame,
  );

  static TelemetryCalculationResult _runPcmFrame(
    TelemetryCalculationContext context,
  ) {
    final wordLength = context.number('word_length', 'unit');
    final wordsPerMinor = context.number('words_per_minor', 'unit');
    final minorRate = context.number('minor_rate', 'Hz');
    final minorPerMajor = context.number('minor_per_major', 'unit');
    final syncBits = context.number('sync_bits', 'unit');

    final payloadBits = wordLength * wordsPerMinor;
    final minorBits = payloadBits + syncBits;
    final bitRate = minorBits * minorRate;
    final majorPeriod = minorPerMajor / minorRate;
    final efficiency = payloadBits / minorBits;
    final parameterSampleRate = 1 / majorPeriod;

    return TelemetryCalculationResult(
      outputs: [
        context.output('minor_bits', minorBits),
        context.output('bit_rate', bitRate, unitId: 'Mbps'),
        context.output('major_period', majorPeriod),
        context.output('frame_efficiency', efficiency, unitId: 'percent'),
        context.output('parameter_sample_rate', parameterSampleRate),
      ],
    );
  }

  static const _channelCoding = TelemetryCalculatorDefinition(
    id: 'channel_coding',
    category: TelemetryCalculatorCategory.coding,
    title: '信道编码开销',
    subtitle: '编码率、冗余、交织深度和链路延迟',
    standards: 'CCSDS 131/231 / IRIG 106 编码工程通用',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'input_rate',
        label: '输入信息率',
        dimension: QuantityDimension.dataRate,
        units: _commonRateUnits,
        defaultUnit: 'Mbps',
        defaultValue: 1,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'coding_rate',
        label: '编码率',
        dimension: QuantityDimension.dimensionless,
        units: ['ratio'],
        defaultUnit: 'ratio',
        defaultValue: 0.5,
        min: 0.01,
        max: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'frame_bits',
        label: '码块/帧长度',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 1024,
        min: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'interleaver_depth',
        label: '交织深度',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 4,
        min: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'extra_overhead_bits',
        label: '额外开销比特',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 0,
        min: 0,
        advanced: true,
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'coded_rate',
        label: '输出码率',
        unitId: 'bps',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'redundancy_rate',
        label: '冗余码率',
        unitId: 'bps',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'overhead_percent',
        label: '总开销比例',
        unitId: 'ratio',
        precision: 1,
      ),
      TelemetryOutputDefinition(
        id: 'latency',
        label: '交织估算延迟',
        unitId: 's',
        precision: 3,
      ),
    ],
    formulas: [
      FormulaReference(
        title: '编码输出码率',
        expression: 'R_coded=R_input/coding_rate*(1+extra_overhead/frame_bits)',
        source: 'CCSDS/IRIG 编码链路工程估算',
      ),
    ],
    runner: _runChannelCoding,
  );

  static TelemetryCalculationResult _runChannelCoding(
    TelemetryCalculationContext context,
  ) {
    final inputRate = context.number('input_rate', 'bps');
    final codingRate = context.number('coding_rate', 'ratio');
    final frameBits = context.number('frame_bits', 'unit');
    final interleaverDepth = context.number('interleaver_depth', 'unit');
    final extraOverheadBits = context.number('extra_overhead_bits', 'unit');

    final codedRate =
        inputRate / codingRate * (1 + extraOverheadBits / frameBits);
    final redundancy = codedRate - inputRate;
    final overheadPercent = redundancy / codedRate;
    final latency = interleaverDepth * frameBits / inputRate;

    return TelemetryCalculationResult(
      outputs: [
        context.output('coded_rate', codedRate, unitId: 'Mbps'),
        context.output('redundancy_rate', redundancy, unitId: 'Mbps'),
        context.output('overhead_percent', overheadPercent, unitId: 'percent'),
        context.output('latency', latency, unitId: 'ms'),
      ],
    );
  }

  static const _telecommand = TelemetryCalculatorDefinition(
    id: 'telecommand',
    category: TelemetryCalculatorCategory.command,
    title: '遥控指令吞吐',
    subtitle: '指令帧长度、重复发送和有效吞吐',
    standards: 'CCSDS TC / GJB 1198A 公开目录 / 工程通用',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'command_bits',
        label: '有效指令比特',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 256,
        min: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'header_bits',
        label: '帧头比特',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 64,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'crc_bits',
        label: '校验比特',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 16,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'security_bits',
        label: '安全/认证开销',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 0,
        min: 0,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'repeat_count',
        label: '重复发送次数',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 3,
        min: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'uplink_rate',
        label: '上行码率',
        dimension: QuantityDimension.dataRate,
        units: _commonRateUnits,
        defaultUnit: 'kbps',
        defaultValue: 8,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'guard_time',
        label: '帧间保护时间',
        dimension: QuantityDimension.time,
        units: ['ms', 's'],
        defaultUnit: 'ms',
        defaultValue: 20,
        min: 0,
        advanced: true,
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'frame_bits',
        label: '单帧长度',
        unitId: 'unit',
        precision: 0,
      ),
      TelemetryOutputDefinition(
        id: 'total_time',
        label: '总发送时间',
        unitId: 's',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'effective_rate',
        label: '有效指令吞吐',
        unitId: 'bps',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'overhead_percent',
        label: '开销比例',
        unitId: 'ratio',
        precision: 1,
      ),
    ],
    formulas: [
      FormulaReference(
        title: '遥控帧吞吐',
        expression: 'throughput=command_bits/(repeat*frame_time+guard)',
        source: 'CCSDS TC / 工程通用估算',
      ),
    ],
    runner: _runTelecommand,
  );

  static TelemetryCalculationResult _runTelecommand(
    TelemetryCalculationContext context,
  ) {
    final commandBits = context.number('command_bits', 'unit');
    final headerBits = context.number('header_bits', 'unit');
    final crcBits = context.number('crc_bits', 'unit');
    final securityBits = context.number('security_bits', 'unit');
    final repeatCount = context.number('repeat_count', 'unit');
    final uplinkRate = context.number('uplink_rate', 'bps');
    final guardTime = context.number('guard_time', 's');

    final frameBits = commandBits + headerBits + crcBits + securityBits;
    final totalTime =
        repeatCount * frameBits / uplinkRate +
        math.max(0, repeatCount - 1) * guardTime;
    final effectiveRate = commandBits / totalTime;
    final overheadPercent = 1 - commandBits / frameBits;

    return TelemetryCalculationResult(
      outputs: [
        context.output('frame_bits', frameBits),
        context.output('total_time', totalTime, unitId: 'ms'),
        context.output('effective_rate', effectiveRate, unitId: 'kbps'),
        context.output('overhead_percent', overheadPercent, unitId: 'percent'),
      ],
    );
  }

  static const _ranging = TelemetryCalculatorDefinition(
    id: 'ranging',
    category: TelemetryCalculatorCategory.ranging,
    title: '测距与时延',
    subtitle: '传播时延、距离分辨率和无模糊距离',
    standards: 'CCSDS PN Ranging / SpaceLink ranging model',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'distance',
        label: '目标距离',
        dimension: QuantityDimension.distance,
        units: _commonDistanceUnits,
        defaultUnit: 'km',
        defaultValue: 1000,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'chip_rate',
        label: '测距码片率',
        dimension: QuantityDimension.frequency,
        units: ['Hz', 'kHz', 'MHz'],
        defaultUnit: 'MHz',
        defaultValue: 1,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'code_length',
        label: '码序列长度',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 1009470,
        min: 1,
        advanced: true,
        helper: 'CCSDS/DSN PN 测距常见完整序列长度。',
      ),
      TelemetryInputDefinition.number(
        id: 'timing_error',
        label: '定时误差',
        dimension: QuantityDimension.time,
        units: ['ns', 'us', 'ms'],
        defaultUnit: 'ns',
        defaultValue: 10,
        min: 0,
        advanced: true,
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'one_way_delay',
        label: '单程时延',
        unitId: 's',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'round_trip_delay',
        label: '双程时延',
        unitId: 's',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'range_resolution',
        label: '距离分辨率',
        unitId: 'm',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'ambiguity_distance',
        label: '最大无模糊距离',
        unitId: 'm',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'range_error',
        label: '定时误差等效距离',
        unitId: 'm',
        precision: 3,
      ),
    ],
    formulas: [
      FormulaReference(
        title: '传播时延',
        expression: 't=d/c',
        source: 'CCSDS SLS / SpaceLink ranging model',
      ),
      FormulaReference(
        title: '测距分辨率',
        expression: 'resolution=c/(2*chip_rate)',
        source: 'PN/双程测距工程估算',
      ),
    ],
    runner: _runRanging,
  );

  static TelemetryCalculationResult _runRanging(
    TelemetryCalculationContext context,
  ) {
    const c = 299792458.0;
    final distance = context.number('distance', 'm');
    final chipRate = context.number('chip_rate', 'Hz');
    final codeLength = context.number('code_length', 'unit');
    final timingError = context.number('timing_error', 's');

    final oneWay = distance / c;
    final roundTrip = oneWay * 2;
    final resolution = c / (2 * chipRate);
    final ambiguity = c * codeLength / (2 * chipRate);
    final rangeError = c * timingError / 2;

    return TelemetryCalculationResult(
      outputs: [
        context.output('one_way_delay', oneWay, unitId: 'ms'),
        context.output('round_trip_delay', roundTrip, unitId: 'ms'),
        context.output('range_resolution', resolution),
        context.output('ambiguity_distance', ambiguity, unitId: 'km'),
        context.output('range_error', rangeError),
      ],
    );
  }

  static const _doppler = TelemetryCalculatorDefinition(
    id: 'doppler',
    category: TelemetryCalculatorCategory.frequency,
    title: '频率与 Doppler',
    subtitle: '相对速度频移、振荡器误差和保护间隔',
    standards: 'CCSDS RF & Modulation / 工程通用',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'carrier_frequency',
        label: '载波频率',
        dimension: QuantityDimension.frequency,
        units: _commonFrequencyUnits,
        defaultUnit: 'GHz',
        defaultValue: 2.2,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'relative_velocity',
        label: '径向相对速度',
        dimension: QuantityDimension.velocity,
        units: ['mps', 'kmps'],
        defaultUnit: 'kmps',
        defaultValue: 7.5,
      ),
      TelemetryInputDefinition.number(
        id: 'oscillator_tolerance',
        label: '频率源容差',
        dimension: QuantityDimension.dimensionless,
        units: ['ppm'],
        defaultUnit: 'ppm',
        defaultValue: 1,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'protection_band',
        label: '保护间隔',
        dimension: QuantityDimension.frequency,
        units: ['Hz', 'kHz', 'MHz'],
        defaultUnit: 'kHz',
        defaultValue: 100,
        min: 0,
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'doppler_shift',
        label: 'Doppler 频移',
        unitId: 'Hz',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'oscillator_error',
        label: '频率源误差',
        unitId: 'Hz',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'total_error',
        label: '总频偏估算',
        unitId: 'Hz',
        precision: 3,
      ),
      TelemetryOutputDefinition(
        id: 'guard_margin',
        label: '保护间隔余量',
        unitId: 'Hz',
        precision: 3,
      ),
    ],
    formulas: [
      FormulaReference(
        title: 'Doppler 频移',
        expression: 'df=f*v/c',
        source: 'CCSDS RF & Modulation / 工程通用',
      ),
    ],
    runner: _runDoppler,
  );

  static TelemetryCalculationResult _runDoppler(
    TelemetryCalculationContext context,
  ) {
    const c = 299792458.0;
    final frequency = context.number('carrier_frequency', 'Hz');
    final velocity = context.number('relative_velocity', 'mps');
    final tolerance = context.number('oscillator_tolerance', 'ratio');
    final protection = context.number('protection_band', 'Hz');

    final doppler = frequency * velocity / c;
    final oscillator = frequency * tolerance;
    final total = doppler.abs() + oscillator.abs();
    final margin = protection - total;

    return TelemetryCalculationResult(
      outputs: [
        context.output('doppler_shift', doppler, unitId: 'kHz'),
        context.output('oscillator_error', oscillator, unitId: 'kHz'),
        context.output('total_error', total, unitId: 'kHz'),
        context.output('guard_margin', margin, unitId: 'kHz'),
      ],
      warnings: [if (margin < 0) '保护间隔不足，可能导致频谱/接收机捕获风险。'],
    );
  }

  static const _customFormula = TelemetryCalculatorDefinition(
    id: 'custom_formula',
    category: TelemetryCalculatorCategory.custom,
    title: '自定义公式',
    subtitle: '用 A/B/C/D 快速扩展本地计算',
    standards: '本地自定义 / GJB 项目公式承接',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'a',
        label: '变量 A',
        dimension: QuantityDimension.dimensionless,
        units: ['ratio'],
        defaultUnit: 'ratio',
        defaultValue: 1,
      ),
      TelemetryInputDefinition.number(
        id: 'b',
        label: '变量 B',
        dimension: QuantityDimension.dimensionless,
        units: ['ratio'],
        defaultUnit: 'ratio',
        defaultValue: 2,
      ),
      TelemetryInputDefinition.number(
        id: 'c',
        label: '变量 C',
        dimension: QuantityDimension.dimensionless,
        units: ['ratio'],
        defaultUnit: 'ratio',
        defaultValue: 3,
      ),
      TelemetryInputDefinition.number(
        id: 'd',
        label: '变量 D',
        dimension: QuantityDimension.dimensionless,
        units: ['ratio'],
        defaultUnit: 'ratio',
        defaultValue: 4,
      ),
      TelemetryInputDefinition.expression(
        id: 'expression',
        label: '公式',
        defaultText: '10*log10(a+b+c+d)',
        helper: '支持 + - * / ^、括号、log10、sqrt、sin、cos、tan、abs。',
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'result',
        label: '计算结果',
        unitId: 'ratio',
        precision: 6,
      ),
    ],
    formulas: [
      FormulaReference(
        title: '安全表达式',
        expression: 'result=f(a,b,c,d)',
        source: '本地公式引擎，不执行代码、不访问文件或网络。',
      ),
    ],
    runner: _runCustomFormula,
  );

  static TelemetryCalculationResult _runCustomFormula(
    TelemetryCalculationContext context,
  ) {
    final variables = {
      'a': context.number('a', 'ratio'),
      'b': context.number('b', 'ratio'),
      'c': context.number('c', 'ratio'),
      'd': context.number('d', 'ratio'),
    };
    final result = FormulaEngine().evaluate(
      context.text('expression'),
      variables,
    );
    return TelemetryCalculationResult(
      outputs: [context.output('result', result)],
    );
  }

  static double _log10(double value) {
    if (value <= 0 || !value.isFinite) {
      throw const TelemetryCalculationException('对数参数必须大于 0');
    }
    return math.log(value) / math.ln10;
  }
}
