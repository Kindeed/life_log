import 'dart:math' as math;

import 'telemetry_formula_engine.dart';
import 'telemetry_units.dart';

enum TelemetryCalculatorCategory {
  link,
  antenna,
  rate,
  frame,
  coding,
  command,
  ranging,
  frequency,
  system,
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
            continue;
          }
          final comparableNumber = UnitCatalog.convert(
            number,
            value.unitId,
            input.defaultUnit,
          );
          if (input.min != null && comparableNumber < input.min!) {
            errors.add('${input.label} 不能小于 ${input.min}');
          }
          if (input.max != null && comparableNumber > input.max!) {
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
  static const int formulaCatalogEntryCount = 1205;
  static const int integratedSystemFormulaCount = 85;
  static const double _speedOfLight = 299792458;
  static const _commonFrequencyUnits = ['Hz', 'kHz', 'MHz', 'GHz'];
  static const _commonRateUnits = ['bps', 'kbps', 'Mbps', 'Gbps'];
  static const _commonDistanceUnits = ['m', 'km'];

  static final List<TelemetryCalculatorDefinition> definitions = [
    _linkBudget,
    _antennaReceiver,
    _rateBandwidth,
    _pcmFrame,
    _channelCoding,
    _telecommand,
    _ranging,
    _doppler,
    _spacecraftPower,
    _spacecraftThermal,
    _missionClosure,
    _customFormula,
  ];

  static TelemetryCalculatorDefinition byId(String id) {
    return definitions.firstWhere((definition) => definition.id == id);
  }

  static int countByCategory(TelemetryCalculatorCategory category) {
    return definitions
        .where((definition) => definition.category == category)
        .length;
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

  static const _antennaReceiver = TelemetryCalculatorDefinition(
    id: 'antenna_receiver',
    category: TelemetryCalculatorCategory.antenna,
    title: '天线与接收机',
    subtitle: '抛物面增益、有效孔径、G/T、远场与噪声温度',
    standards: 'Balanis / DESCANSO / DSN 810-005 / Maral',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'frequency',
        label: '载波频率',
        dimension: QuantityDimension.frequency,
        units: _commonFrequencyUnits,
        defaultUnit: 'GHz',
        defaultValue: 8.4,
        min: 0.001,
        helper: '用于波长、口径增益和有效孔径计算的射频中心频率。',
      ),
      TelemetryInputDefinition.number(
        id: 'reflector_diameter',
        label: '口径直径',
        dimension: QuantityDimension.distance,
        units: ['m'],
        defaultUnit: 'm',
        defaultValue: 1.2,
        min: 0.001,
        helper: '圆形抛物面或等效圆口径的物理直径。',
      ),
      TelemetryInputDefinition.number(
        id: 'aperture_efficiency',
        label: '口径效率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 65,
        min: 0.001,
        max: 100,
        helper: '综合照明、溢出、表面、阻挡等损失后的总口径效率。',
      ),
      TelemetryInputDefinition.number(
        id: 'system_temp',
        label: '系统噪声温度',
        dimension: QuantityDimension.temperature,
        units: ['K', 'dBK'],
        defaultUnit: 'K',
        defaultValue: 150,
        min: 0.001,
        helper: '馈源、接收机、天空和环境噪声折算到接收参考面的系统温度。',
      ),
      TelemetryInputDefinition.number(
        id: 'measurement_range',
        label: '测量距离',
        dimension: QuantityDimension.distance,
        units: _commonDistanceUnits,
        defaultUnit: 'm',
        defaultValue: 1000,
        min: 0.001,
        helper: '用于判断测量或链路几何是否超过 Fraunhofer 远场距离。',
      ),
      TelemetryInputDefinition.number(
        id: 'noise_figure',
        label: '接收机噪声系数',
        dimension: QuantityDimension.gain,
        units: ['dB'],
        defaultUnit: 'dB',
        defaultValue: 2,
        min: 0,
        advanced: true,
        helper: '按 T0=290 K 折算为接收机等效噪声温度。',
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'wavelength',
        label: '波长',
        unitId: 'm',
        precision: 5,
        helper: '光速除以载波频率得到的射频波长。',
      ),
      TelemetryOutputDefinition(
        id: 'aperture_area',
        label: '口径面积',
        unitId: 'm2',
        precision: 4,
        helper: '圆口径物理面积，用于增益和有效孔径核算。',
      ),
      TelemetryOutputDefinition(
        id: 'antenna_gain',
        label: '天线增益',
        unitId: 'dBi',
        helper: '由口径、波长和口径效率估算的抛物面天线增益。',
      ),
      TelemetryOutputDefinition(
        id: 'effective_aperture',
        label: '有效孔径',
        unitId: 'm2',
        precision: 4,
        helper: '天线接收等效面积，等价于增益与波长平方的关系。',
      ),
      TelemetryOutputDefinition(
        id: 'g_over_t',
        label: 'G/T',
        unitId: 'dB_K',
        helper: '接收增益与系统噪声温度的品质因数。',
      ),
      TelemetryOutputDefinition(
        id: 'receiver_noise_temp',
        label: '接收机等效噪温',
        unitId: 'K',
        helper: '由噪声系数折算的接收机等效输入噪声温度。',
      ),
      TelemetryOutputDefinition(
        id: 'far_field_distance',
        label: '远场距离',
        unitId: 'm',
        helper: 'Fraunhofer 远场距离，天线方向图测量和链路假设的基本边界。',
      ),
      TelemetryOutputDefinition(
        id: 'far_field_margin',
        label: '远场余量',
        unitId: 'm',
        helper: '测量距离减去远场距离；负值表示仍处于近场。',
      ),
    ],
    formulas: [
      FormulaReference(
        title: '波长',
        expression: 'lambda = c / f',
        source: 'ITU-R P.525 / Balanis',
      ),
      FormulaReference(
        title: '抛物面口径增益',
        expression: 'G = eta (pi D / lambda)^2',
        source: 'Balanis / DESCANSO',
      ),
      FormulaReference(
        title: '有效孔径',
        expression: 'A_e = G lambda^2 / (4 pi)',
        source: 'Balanis / DESCANSO',
      ),
      FormulaReference(
        title: '接收品质因数',
        expression: 'G/T = G_dBi - 10log10(T_sys)',
        source: 'DSN 810-005 / Maral',
      ),
      FormulaReference(
        title: '接收机等效噪温',
        expression: 'T_e = T0 (10^(NF_dB/10) - 1)',
        source: 'Maral / Sklar',
      ),
      FormulaReference(
        title: 'Fraunhofer 远场距离',
        expression: 'R_ff >= 2D^2 / lambda',
        source: 'Balanis',
      ),
    ],
    runner: _runAntennaReceiver,
  );

  static TelemetryCalculationResult _runAntennaReceiver(
    TelemetryCalculationContext context,
  ) {
    final frequencyHz = context.number('frequency', 'Hz');
    final diameter = context.number('reflector_diameter', 'm');
    final efficiency = context.number('aperture_efficiency', 'ratio');
    final systemTemp = context.number('system_temp', 'K');
    final measurementRange = context.number('measurement_range', 'm');
    final noiseFigure = context.number('noise_figure', 'dB');

    final wavelength = _speedOfLight / frequencyHz;
    final diameterSquared = diameter * diameter;
    final apertureArea = math.pi * diameterSquared / 4;
    final apertureRatio = math.pi * diameter / wavelength;
    final gainLinear = efficiency * apertureRatio * apertureRatio;
    final gainDbi = 10 * math.log(gainLinear) / math.ln10;
    final effectiveAperture =
        gainLinear * wavelength * wavelength / (4 * math.pi);
    final gOverT = gainDbi - 10 * math.log(systemTemp) / math.ln10;
    final receiverNoiseTemp =
        290 * (math.pow(10, noiseFigure / 10).toDouble() - 1);
    final farFieldDistance = 2 * diameterSquared / wavelength;
    final farFieldMargin = measurementRange - farFieldDistance;

    return _withWarnings(
      [
        context.output('wavelength', wavelength),
        context.output('aperture_area', apertureArea),
        context.output('antenna_gain', gainDbi),
        context.output('effective_aperture', effectiveAperture),
        context.output('g_over_t', gOverT),
        context.output('receiver_noise_temp', receiverNoiseTemp),
        context.output('far_field_distance', farFieldDistance),
        context.output('far_field_margin', farFieldMargin),
      ],
      [
        if (farFieldMargin < 0) '测量距离未达到 Fraunhofer 远场边界，方向图或链路假设可能不成立。',
        if (gOverT < 0) 'G/T 为负，需检查天线增益、噪声温度或接收机前端假设。',
      ],
    );
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
        units: ['K', 'dBK'],
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

  static const _spacecraftPower = TelemetryCalculatorDefinition(
    id: 'spacecraft_power',
    category: TelemetryCalculatorCategory.system,
    title: '电源与蓄电池',
    subtitle: '太阳阵 EOL、蓄电池容量、DOD 与轨道能量余量',
    standards: 'NASA SmallSat SOTA / SMAD',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'solar_constant',
        label: '设计太阳辐照度',
        dimension: QuantityDimension.irradiance,
        units: ['W_m2'],
        defaultUnit: 'W_m2',
        defaultValue: 1000,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'array_area',
        label: '太阳阵面积',
        dimension: QuantityDimension.area,
        units: ['m2'],
        defaultUnit: 'm2',
        defaultValue: 1,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'cell_efficiency',
        label: '电池片效率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 30,
        min: 0,
        max: 100,
      ),
      TelemetryInputDefinition.number(
        id: 'pack_efficiency',
        label: '封装/布板效率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 70,
        min: 0,
        max: 100,
      ),
      TelemetryInputDefinition.number(
        id: 'sun_angle',
        label: '太阳入射角',
        dimension: QuantityDimension.angle,
        units: ['deg', 'rad'],
        defaultUnit: 'deg',
        defaultValue: 0,
        min: 0,
        max: 90,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'pointing_factor',
        label: '指向/姿态效率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 100,
        min: 0,
        max: 100,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'eol_degradation',
        label: '寿命末期衰减',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 20,
        min: 0,
        max: 95,
      ),
      TelemetryInputDefinition.number(
        id: 'pcu_efficiency',
        label: '电源调节效率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 100,
        min: 0,
        max: 100,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'sunlit_duration',
        label: '光照时长',
        dimension: QuantityDimension.time,
        units: ['s', 'h'],
        defaultUnit: 'h',
        defaultValue: 0.5,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'sunlit_load',
        label: '光照负载功率',
        dimension: QuantityDimension.power,
        units: ['W'],
        defaultUnit: 'W',
        defaultValue: 60,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'eclipse_load',
        label: '阴影负载功率',
        dimension: QuantityDimension.power,
        units: ['W'],
        defaultUnit: 'W',
        defaultValue: 50,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'eclipse_duration',
        label: '阴影时长',
        dimension: QuantityDimension.time,
        units: ['s', 'h'],
        defaultUnit: 'h',
        defaultValue: 0.2,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'contingency_energy',
        label: '应急能量',
        dimension: QuantityDimension.energy,
        units: ['Wh', 'J'],
        defaultUnit: 'Wh',
        defaultValue: 4.9,
        min: 0,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'reserve_energy',
        label: '保留能量',
        dimension: QuantityDimension.energy,
        units: ['Wh', 'J'],
        defaultUnit: 'Wh',
        defaultValue: 27,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'charge_efficiency',
        label: '充电效率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 92,
        min: 0.001,
        max: 100,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'discharge_efficiency',
        label: '放电效率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 95,
        min: 0.001,
        max: 100,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'allowed_dod',
        label: '允许 DOD',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 60,
        min: 0.001,
        max: 100,
      ),
      TelemetryInputDefinition.number(
        id: 'installed_battery_energy',
        label: '装机蓄电池能量',
        dimension: QuantityDimension.energy,
        units: ['Wh', 'J'],
        defaultUnit: 'Wh',
        defaultValue: 55,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'bus_voltage',
        label: '母线电压',
        dimension: QuantityDimension.dimensionless,
        units: ['unit'],
        defaultUnit: 'unit',
        defaultValue: 24,
        min: 0.001,
        helper: '单位 V，用于 Wh 到 Ah 的容量换算。',
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'array_power_bol',
        label: 'BOL 阵功率',
        unitId: 'W',
      ),
      TelemetryOutputDefinition(
        id: 'array_power_eol',
        label: 'EOL 阵功率',
        unitId: 'W',
      ),
      TelemetryOutputDefinition(
        id: 'sunlit_energy',
        label: '光照发电量',
        unitId: 'Wh',
      ),
      TelemetryOutputDefinition(
        id: 'battery_required_energy',
        label: '所需蓄电池能量',
        unitId: 'Wh',
      ),
      TelemetryOutputDefinition(
        id: 'battery_capacity_ah',
        label: '所需容量',
        unitId: 'Ah',
      ),
      TelemetryOutputDefinition(
        id: 'charge_time_required',
        label: '回充时间',
        unitId: 's',
      ),
      TelemetryOutputDefinition(
        id: 'orbit_energy_margin',
        label: '轨道能量余量',
        unitId: 'Wh',
      ),
      TelemetryOutputDefinition(
        id: 'dod_margin',
        label: 'DOD 余量',
        unitId: 'ratio',
      ),
    ],
    formulas: [
      FormulaReference(
        title: '太阳阵 EOL 功率',
        expression:
            'P_EOL=S*A*eta_cell*eta_pack*cos(theta)*eta_pointing*(1-degradation)',
        source: 'NASA SmallSat SOTA Power / SMAD EPS sizing',
      ),
      FormulaReference(
        title: '蓄电池能量',
        expression:
            'E_bat=(E_eclipse+E_contingency)/(eta_discharge*DOD_allowed)',
        source: 'SMAD spacecraft power budget',
      ),
      FormulaReference(
        title: '轨道能量平衡',
        expression:
            'Margin=P_EOL*T_sunlit*eta_pcu-E_sunlit-E_eclipse-E_reserve',
        source: 'NASA Systems Engineering margin practice',
      ),
    ],
    runner: _runSpacecraftPower,
  );

  static TelemetryCalculationResult _runSpacecraftPower(
    TelemetryCalculationContext context,
  ) {
    final solar = context.number('solar_constant', 'W_m2');
    final area = context.number('array_area', 'm2');
    final cellEfficiency = context.number('cell_efficiency', 'ratio');
    final packEfficiency = context.number('pack_efficiency', 'ratio');
    final sunAngle = context.number('sun_angle', 'rad');
    final pointing = context.number('pointing_factor', 'ratio');
    final degradation = context.number('eol_degradation', 'ratio');
    final pcuEfficiency = context.number('pcu_efficiency', 'ratio');
    final sunlitHours = context.number('sunlit_duration', 'h');
    final sunlitLoad = context.number('sunlit_load', 'W');
    final eclipseLoad = context.number('eclipse_load', 'W');
    final eclipseHours = context.number('eclipse_duration', 'h');
    final contingency = context.number('contingency_energy', 'Wh');
    final reserve = context.number('reserve_energy', 'Wh');
    final chargeEfficiency = context.number('charge_efficiency', 'ratio');
    final dischargeEfficiency = context.number('discharge_efficiency', 'ratio');
    final allowedDod = context.number('allowed_dod', 'ratio');
    final installedBattery = context.number('installed_battery_energy', 'Wh');
    final busVoltage = context.number('bus_voltage', 'unit');

    final angleFactor = math.max(0, math.cos(sunAngle));
    final bolPower =
        solar * area * cellEfficiency * packEfficiency * angleFactor * pointing;
    final eolPower = bolPower * (1 - degradation);
    final sunlitEnergy = eolPower * sunlitHours * pcuEfficiency;
    final sunlitLoadEnergy = sunlitLoad * sunlitHours;
    final eclipseEnergy = eclipseLoad * eclipseHours;
    final batteryRequired =
        (eclipseEnergy + contingency) / (dischargeEfficiency * allowedDod);
    final batteryCapacityAh = batteryRequired / busVoltage;
    final rechargeEnergy =
        eclipseEnergy / (chargeEfficiency * dischargeEfficiency);
    final excessSunlitPower = eolPower - sunlitLoad;
    final chargeTimeHours = excessSunlitPower <= 0
        ? double.infinity
        : rechargeEnergy / excessSunlitPower;
    final orbitMargin =
        sunlitEnergy - sunlitLoadEnergy - eclipseEnergy - reserve;
    final cycleDod = eclipseEnergy / installedBattery;
    final dodMargin = allowedDod - cycleDod;

    return _withWarnings(
      [
        context.output('array_power_bol', bolPower),
        context.output('array_power_eol', eolPower),
        context.output('sunlit_energy', sunlitEnergy),
        context.output('battery_required_energy', batteryRequired),
        context.output('battery_capacity_ah', batteryCapacityAh),
        context.output(
          'charge_time_required',
          chargeTimeHours * 3600,
          unitId: 'h',
        ),
        context.output('orbit_energy_margin', orbitMargin),
        context.output('dod_margin', dodMargin, unitId: 'percent'),
      ],
      [
        if (orbitMargin < 0) '轨道能量余量为负，需增大太阳阵、降低负载或减少保留能量。',
        if (dodMargin < 0) '蓄电池循环 DOD 超限，需增加容量或缩短阴影负载。',
        if (!chargeTimeHours.isFinite) '光照剩余功率不足，无法完成蓄电池回充。',
      ],
    );
  }

  static const _spacecraftThermal = TelemetryCalculatorDefinition(
    id: 'spacecraft_thermal',
    category: TelemetryCalculatorCategory.system,
    title: '热控与散热器',
    subtitle: '外热流、内部发热、辐射散热、加热器占空比',
    standards: 'NASA SmallSat SOTA / SMAD',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'solar_constant',
        label: '太阳辐照度',
        dimension: QuantityDimension.irradiance,
        units: ['W_m2'],
        defaultUnit: 'W_m2',
        defaultValue: 1000,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'solar_absorptivity',
        label: '太阳吸收率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 50,
        min: 0,
        max: 100,
      ),
      TelemetryInputDefinition.number(
        id: 'sun_area',
        label: '直射受照面积',
        dimension: QuantityDimension.area,
        units: ['m2'],
        defaultUnit: 'm2',
        defaultValue: 0.08,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'sun_view_factor',
        label: '太阳视因子',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 100,
        min: 0,
        max: 100,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'albedo',
        label: '反照率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 30,
        min: 0,
        max: 100,
      ),
      TelemetryInputDefinition.number(
        id: 'albedo_area',
        label: '反照受照面积',
        dimension: QuantityDimension.area,
        units: ['m2'],
        defaultUnit: 'm2',
        defaultValue: 0.05,
        min: 0,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'albedo_view_factor',
        label: '反照视因子',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 90,
        min: 0,
        max: 100,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'planet_ir',
        label: '行星红外通量',
        dimension: QuantityDimension.irradiance,
        units: ['W_m2'],
        defaultUnit: 'W_m2',
        defaultValue: 237,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'ir_emissivity',
        label: '红外吸收率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 80,
        min: 0,
        max: 100,
      ),
      TelemetryInputDefinition.number(
        id: 'planet_area',
        label: '红外受照面积',
        dimension: QuantityDimension.area,
        units: ['m2'],
        defaultUnit: 'm2',
        defaultValue: 0.04,
        min: 0,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'planet_view_factor',
        label: '行星视因子',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 50,
        min: 0,
        max: 100,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'internal_heat',
        label: '内部发热',
        dimension: QuantityDimension.power,
        units: ['W'],
        defaultUnit: 'W',
        defaultValue: 10,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'radiator_emissivity',
        label: '散热面发射率',
        dimension: QuantityDimension.dimensionless,
        units: ['percent', 'ratio'],
        defaultUnit: 'percent',
        defaultValue: 85,
        min: 0.001,
        max: 100,
      ),
      TelemetryInputDefinition.number(
        id: 'radiator_area',
        label: '散热器面积',
        dimension: QuantityDimension.area,
        units: ['m2'],
        defaultUnit: 'm2',
        defaultValue: 0.2384,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'radiator_temp',
        label: '散热器温度',
        dimension: QuantityDimension.temperature,
        units: ['K', 'dBK'],
        defaultUnit: 'K',
        defaultValue: 300,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'space_temp',
        label: '空间背景温度',
        dimension: QuantityDimension.temperature,
        units: ['K', 'dBK'],
        defaultUnit: 'K',
        defaultValue: 3,
        min: 0,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'heat_to_reject',
        label: '需排散热量',
        dimension: QuantityDimension.power,
        units: ['W'],
        defaultUnit: 'W',
        defaultValue: 65,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'required_heater_heat',
        label: '冷况所需热量',
        dimension: QuantityDimension.power,
        units: ['W'],
        defaultUnit: 'W',
        defaultValue: 20,
        min: 0,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'heater_power',
        label: '加热器功率',
        dimension: QuantityDimension.power,
        units: ['W'],
        defaultUnit: 'W',
        defaultValue: 40,
        min: 0.001,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'hot_limit',
        label: '热限温度',
        dimension: QuantityDimension.temperature,
        units: ['K', 'dBK'],
        defaultUnit: 'K',
        defaultValue: 320,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'hot_case',
        label: '热况温度',
        dimension: QuantityDimension.temperature,
        units: ['K', 'dBK'],
        defaultUnit: 'K',
        defaultValue: 300,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'cold_case',
        label: '冷况温度',
        dimension: QuantityDimension.temperature,
        units: ['K', 'dBK'],
        defaultUnit: 'K',
        defaultValue: 270,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'cold_limit',
        label: '冷限温度',
        dimension: QuantityDimension.temperature,
        units: ['K', 'dBK'],
        defaultUnit: 'K',
        defaultValue: 250,
        min: 0,
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'heat_absorbed',
        label: '外部吸热',
        unitId: 'W',
      ),
      TelemetryOutputDefinition(
        id: 'radiator_heat_rejected',
        label: '散热能力',
        unitId: 'W',
      ),
      TelemetryOutputDefinition(
        id: 'radiator_area_required',
        label: '所需散热面积',
        unitId: 'm2',
      ),
      TelemetryOutputDefinition(
        id: 'radiator_margin',
        label: '散热余量',
        unitId: 'W',
      ),
      TelemetryOutputDefinition(
        id: 'heater_duty_cycle',
        label: '加热器占空比',
        unitId: 'ratio',
      ),
      TelemetryOutputDefinition(
        id: 'thermal_limit_margin',
        label: '热控限值余量',
        unitId: 'K',
      ),
    ],
    formulas: [
      FormulaReference(
        title: '外部热流',
        expression:
            'Q_abs=alpha*S*A_sun+alpha*Albedo*S*A_albedo+epsilon*IR*A_planet',
        source: 'NASA SmallSat SOTA Thermal Control',
      ),
      FormulaReference(
        title: '辐射散热',
        expression: 'Q_rad=epsilon*sigma*A*(T_rad^4-T_space^4)',
        source: 'SMAD thermal control sizing',
      ),
      FormulaReference(
        title: '热控限值余量',
        expression:
            'Margin=min(T_hot_limit-T_hot_case,T_cold_case-T_cold_limit)',
        source: 'NASA Systems Engineering margin practice',
      ),
    ],
    runner: _runSpacecraftThermal,
  );

  static TelemetryCalculationResult _runSpacecraftThermal(
    TelemetryCalculationContext context,
  ) {
    const sigma = 5.670374419e-8;
    final solar = context.number('solar_constant', 'W_m2');
    final alpha = context.number('solar_absorptivity', 'ratio');
    final sunArea = context.number('sun_area', 'm2');
    final sunView = context.number('sun_view_factor', 'ratio');
    final albedo = context.number('albedo', 'ratio');
    final albedoArea = context.number('albedo_area', 'm2');
    final albedoView = context.number('albedo_view_factor', 'ratio');
    final planetIr = context.number('planet_ir', 'W_m2');
    final irEmissivity = context.number('ir_emissivity', 'ratio');
    final planetArea = context.number('planet_area', 'm2');
    final planetView = context.number('planet_view_factor', 'ratio');
    final internalHeat = context.number('internal_heat', 'W');
    final radiatorEmissivity = context.number('radiator_emissivity', 'ratio');
    final radiatorArea = context.number('radiator_area', 'm2');
    final radiatorTemp = context.number('radiator_temp', 'K');
    final spaceTemp = context.number('space_temp', 'K');
    final heatToReject = context.number('heat_to_reject', 'W');
    final requiredHeaterHeat = context.number('required_heater_heat', 'W');
    final heaterPower = context.number('heater_power', 'W');
    final hotLimit = context.number('hot_limit', 'K');
    final hotCase = context.number('hot_case', 'K');
    final coldCase = context.number('cold_case', 'K');
    final coldLimit = context.number('cold_limit', 'K');

    final solarHeat = alpha * solar * sunArea * sunView;
    final albedoHeat = alpha * albedo * solar * albedoArea * albedoView;
    final planetHeat = irEmissivity * planetIr * planetArea * planetView;
    final heatAbsorbed = solarHeat + albedoHeat + planetHeat;
    final radiatorDenominator =
        radiatorEmissivity *
        sigma *
        (math.pow(radiatorTemp, 4) - math.pow(spaceTemp, 4));
    if (radiatorTemp <= spaceTemp || radiatorDenominator <= 0) {
      throw const TelemetryCalculationException('散热器温度必须高于空间背景温度');
    }
    final radiatorRejected = radiatorDenominator * radiatorArea;
    final areaRequired = heatToReject / radiatorDenominator;
    final radiatorMargin = radiatorRejected - heatToReject;
    final heaterDuty = ((requiredHeaterHeat - internalHeat) / heaterPower)
        .clamp(0.0, 1.0);
    final thermalLimitMargin = math.min(
      hotLimit - hotCase,
      coldCase - coldLimit,
    );

    return _withWarnings(
      [
        context.output('heat_absorbed', heatAbsorbed),
        context.output('radiator_heat_rejected', radiatorRejected),
        context.output('radiator_area_required', areaRequired),
        context.output('radiator_margin', radiatorMargin),
        context.output('heater_duty_cycle', heaterDuty, unitId: 'percent'),
        context.output('thermal_limit_margin', thermalLimitMargin),
      ],
      [
        if (radiatorMargin < 0) '散热器能力不足，需增加面积、提高允许温度或降低热耗。',
        if (thermalLimitMargin < 0) '热控限值余量为负，热况或冷况超出允许温度。',
      ],
    );
  }

  static const _missionClosure = TelemetryCalculatorDefinition(
    id: 'mission_closure',
    category: TelemetryCalculatorCategory.system,
    title: '任务资源闭合',
    subtitle: '数据、接触窗口、存储、功率与延迟的综合闭合',
    standards: 'NASA SE Handbook / SMAD',
    inputs: [
      TelemetryInputDefinition.number(
        id: 'source_rate',
        label: '源数据率',
        dimension: QuantityDimension.dataRate,
        units: _commonRateUnits,
        defaultUnit: 'Mbps',
        defaultValue: 2,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'generation_duration',
        label: '产数时长',
        dimension: QuantityDimension.time,
        units: ['s', 'h'],
        defaultUnit: 'h',
        defaultValue: 1,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'net_downlink_rate',
        label: '净下行率',
        dimension: QuantityDimension.dataRate,
        units: _commonRateUnits,
        defaultUnit: 'Mbps',
        defaultValue: 5,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'scheduled_contact',
        label: '计划接触时长',
        dimension: QuantityDimension.time,
        units: ['s', 'h'],
        defaultUnit: 'h',
        defaultValue: 1,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'contact_overhead',
        label: '建链/切换开销',
        dimension: QuantityDimension.time,
        units: ['s', 'h'],
        defaultUnit: 's',
        defaultValue: 360,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'storage_start',
        label: '初始存储占用',
        dimension: QuantityDimension.dataVolume,
        units: ['bit', 'Mbit', 'Gbit'],
        defaultUnit: 'Gbit',
        defaultValue: 48.8,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'storage_capacity',
        label: '存储容量',
        dimension: QuantityDimension.dataVolume,
        units: ['bit', 'Mbit', 'Gbit'],
        defaultUnit: 'Gbit',
        defaultValue: 200,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'power_available',
        label: '可用功率',
        dimension: QuantityDimension.power,
        units: ['W'],
        defaultUnit: 'W',
        defaultValue: 151.5,
        min: 0,
      ),
      TelemetryInputDefinition.number(
        id: 'power_required',
        label: '需求功率',
        dimension: QuantityDimension.power,
        units: ['W'],
        defaultUnit: 'W',
        defaultValue: 120,
        min: 0.001,
      ),
      TelemetryInputDefinition.number(
        id: 'latency_requirement',
        label: '延迟要求',
        dimension: QuantityDimension.time,
        units: ['s', 'h'],
        defaultUnit: 'h',
        defaultValue: 24,
        min: 0.001,
        advanced: true,
      ),
      TelemetryInputDefinition.number(
        id: 'max_latency',
        label: '最大数据延迟',
        dimension: QuantityDimension.time,
        units: ['s', 'h'],
        defaultUnit: 'h',
        defaultValue: 8,
        min: 0,
        advanced: true,
      ),
    ],
    outputs: [
      TelemetryOutputDefinition(
        id: 'generated_bits',
        label: '生成数据量',
        unitId: 'bit',
      ),
      TelemetryOutputDefinition(
        id: 'usable_contact_time',
        label: '可用接触时长',
        unitId: 's',
      ),
      TelemetryOutputDefinition(
        id: 'pass_capacity_bits',
        label: '单次下行容量',
        unitId: 'bit',
      ),
      TelemetryOutputDefinition(
        id: 'storage_end_bits',
        label: '期末存储占用',
        unitId: 'bit',
      ),
      TelemetryOutputDefinition(
        id: 'storage_margin',
        label: '存储余量',
        unitId: 'bit',
      ),
      TelemetryOutputDefinition(
        id: 'power_margin_percent',
        label: '功率余量',
        unitId: 'ratio',
      ),
      TelemetryOutputDefinition(
        id: 'latency_margin_percent',
        label: '延迟余量',
        unitId: 'ratio',
      ),
      TelemetryOutputDefinition(
        id: 'closure_score',
        label: '闭合短板',
        unitId: 'ratio',
      ),
    ],
    formulas: [
      FormulaReference(
        title: '生成数据量',
        expression: 'GeneratedBits=SourceRate*Duration',
        source: 'SMAD operations budget',
      ),
      FormulaReference(
        title: '接触容量',
        expression:
            'PassCapacity=NetDownlinkRate*max(0,ScheduledContact-Overhead)',
        source: 'NASA SmallSat communications operations',
      ),
      FormulaReference(
        title: '闭合短板',
        expression:
            'Score=min(storage_margin/storage_capacity,power_margin/power_required,latency_margin/latency_requirement)',
        source: 'NASA Systems Engineering margin practice',
      ),
    ],
    runner: _runMissionClosure,
  );

  static TelemetryCalculationResult _runMissionClosure(
    TelemetryCalculationContext context,
  ) {
    final sourceRate = context.number('source_rate', 'bps');
    final generationDuration = context.number('generation_duration', 's');
    final netDownlinkRate = context.number('net_downlink_rate', 'bps');
    final scheduledContact = context.number('scheduled_contact', 's');
    final contactOverhead = context.number('contact_overhead', 's');
    final storageStart = context.number('storage_start', 'bit');
    final storageCapacity = context.number('storage_capacity', 'bit');
    final powerAvailable = context.number('power_available', 'W');
    final powerRequired = context.number('power_required', 'W');
    final latencyRequirement = context.number('latency_requirement', 's');
    final maxLatency = context.number('max_latency', 's');

    final generated = sourceRate * generationDuration;
    final usableContact = math
        .max(0, scheduledContact - contactOverhead)
        .toDouble();
    final passCapacity = netDownlinkRate * usableContact;
    final storageEnd = math
        .max(0, storageStart + generated - passCapacity)
        .toDouble();
    final storageMargin = storageCapacity - storageEnd;
    final powerMarginPercent = (powerAvailable - powerRequired) / powerRequired;
    final latencyMarginPercent =
        (latencyRequirement - maxLatency) / latencyRequirement;
    final closureScore = [
      storageMargin / storageCapacity,
      powerMarginPercent,
      latencyMarginPercent,
    ].reduce(math.min);

    return _withWarnings(
      [
        context.output('generated_bits', generated, unitId: 'Gbit'),
        context.output('usable_contact_time', usableContact, unitId: 'h'),
        context.output('pass_capacity_bits', passCapacity, unitId: 'Gbit'),
        context.output('storage_end_bits', storageEnd, unitId: 'Gbit'),
        context.output('storage_margin', storageMargin, unitId: 'Gbit'),
        context.output(
          'power_margin_percent',
          powerMarginPercent,
          unitId: 'percent',
        ),
        context.output(
          'latency_margin_percent',
          latencyMarginPercent,
          unitId: 'percent',
        ),
        context.output('closure_score', closureScore, unitId: 'percent'),
      ],
      [
        if (storageMargin < 0) '存储余量为负，需增加下行容量或降低产数。',
        if (powerMarginPercent < 0) '功率余量为负，需调整负载或电源配置。',
        if (latencyMarginPercent < 0) '延迟余量为负，需缩短数据回传周期。',
      ],
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
