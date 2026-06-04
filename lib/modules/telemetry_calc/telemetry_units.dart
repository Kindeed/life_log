import 'dart:math' as math;

enum QuantityDimension {
  dimensionless,
  percent,
  frequency,
  dataRate,
  distance,
  time,
  power,
  gain,
  temperature,
  angle,
  velocity,
}

class EngineeringUnit {
  final String id;
  final String label;
  final QuantityDimension dimension;
  final double Function(double value) toBase;
  final double Function(double value) fromBase;

  const EngineeringUnit({
    required this.id,
    required this.label,
    required this.dimension,
    required this.toBase,
    required this.fromBase,
  });
}

double _identity(double value) => value;
double _scale(double value, double factor) => value * factor;
double _unscale(double value, double factor) => value / factor;

class UnitCatalog {
  static final Map<String, EngineeringUnit> _units = {
    'unit': const EngineeringUnit(
      id: 'unit',
      label: '-',
      dimension: QuantityDimension.dimensionless,
      toBase: _identity,
      fromBase: _identity,
    ),
    'ratio': const EngineeringUnit(
      id: 'ratio',
      label: 'ratio',
      dimension: QuantityDimension.dimensionless,
      toBase: _identity,
      fromBase: _identity,
    ),
    'percent': EngineeringUnit(
      id: 'percent',
      label: '%',
      dimension: QuantityDimension.dimensionless,
      toBase: (value) => value / 100,
      fromBase: (value) => value * 100,
    ),
    'Hz': const EngineeringUnit(
      id: 'Hz',
      label: 'Hz',
      dimension: QuantityDimension.frequency,
      toBase: _identity,
      fromBase: _identity,
    ),
    'kHz': EngineeringUnit(
      id: 'kHz',
      label: 'kHz',
      dimension: QuantityDimension.frequency,
      toBase: (value) => _scale(value, 1e3),
      fromBase: (value) => _unscale(value, 1e3),
    ),
    'MHz': EngineeringUnit(
      id: 'MHz',
      label: 'MHz',
      dimension: QuantityDimension.frequency,
      toBase: (value) => _scale(value, 1e6),
      fromBase: (value) => _unscale(value, 1e6),
    ),
    'Msps': EngineeringUnit(
      id: 'Msps',
      label: 'Msps',
      dimension: QuantityDimension.frequency,
      toBase: (value) => _scale(value, 1e6),
      fromBase: (value) => _unscale(value, 1e6),
    ),
    'GHz': EngineeringUnit(
      id: 'GHz',
      label: 'GHz',
      dimension: QuantityDimension.frequency,
      toBase: (value) => _scale(value, 1e9),
      fromBase: (value) => _unscale(value, 1e9),
    ),
    'bps': const EngineeringUnit(
      id: 'bps',
      label: 'bps',
      dimension: QuantityDimension.dataRate,
      toBase: _identity,
      fromBase: _identity,
    ),
    'kbps': EngineeringUnit(
      id: 'kbps',
      label: 'kbps',
      dimension: QuantityDimension.dataRate,
      toBase: (value) => _scale(value, 1e3),
      fromBase: (value) => _unscale(value, 1e3),
    ),
    'Mbps': EngineeringUnit(
      id: 'Mbps',
      label: 'Mbps',
      dimension: QuantityDimension.dataRate,
      toBase: (value) => _scale(value, 1e6),
      fromBase: (value) => _unscale(value, 1e6),
    ),
    'Gbps': EngineeringUnit(
      id: 'Gbps',
      label: 'Gbps',
      dimension: QuantityDimension.dataRate,
      toBase: (value) => _scale(value, 1e9),
      fromBase: (value) => _unscale(value, 1e9),
    ),
    'm': const EngineeringUnit(
      id: 'm',
      label: 'm',
      dimension: QuantityDimension.distance,
      toBase: _identity,
      fromBase: _identity,
    ),
    'km': EngineeringUnit(
      id: 'km',
      label: 'km',
      dimension: QuantityDimension.distance,
      toBase: (value) => _scale(value, 1e3),
      fromBase: (value) => _unscale(value, 1e3),
    ),
    's': const EngineeringUnit(
      id: 's',
      label: 's',
      dimension: QuantityDimension.time,
      toBase: _identity,
      fromBase: _identity,
    ),
    'ms': EngineeringUnit(
      id: 'ms',
      label: 'ms',
      dimension: QuantityDimension.time,
      toBase: (value) => _scale(value, 1e-3),
      fromBase: (value) => _unscale(value, 1e-3),
    ),
    'us': EngineeringUnit(
      id: 'us',
      label: 'us',
      dimension: QuantityDimension.time,
      toBase: (value) => _scale(value, 1e-6),
      fromBase: (value) => _unscale(value, 1e-6),
    ),
    'ns': EngineeringUnit(
      id: 'ns',
      label: 'ns',
      dimension: QuantityDimension.time,
      toBase: (value) => _scale(value, 1e-9),
      fromBase: (value) => _unscale(value, 1e-9),
    ),
    'dBW': const EngineeringUnit(
      id: 'dBW',
      label: 'dBW',
      dimension: QuantityDimension.power,
      toBase: _identity,
      fromBase: _identity,
    ),
    'dBm': EngineeringUnit(
      id: 'dBm',
      label: 'dBm',
      dimension: QuantityDimension.power,
      toBase: (value) => value - 30,
      fromBase: (value) => value + 30,
    ),
    'dB': const EngineeringUnit(
      id: 'dB',
      label: 'dB',
      dimension: QuantityDimension.gain,
      toBase: _identity,
      fromBase: _identity,
    ),
    'dBi': const EngineeringUnit(
      id: 'dBi',
      label: 'dBi',
      dimension: QuantityDimension.gain,
      toBase: _identity,
      fromBase: _identity,
    ),
    'dBHz': const EngineeringUnit(
      id: 'dBHz',
      label: 'dB-Hz',
      dimension: QuantityDimension.gain,
      toBase: _identity,
      fromBase: _identity,
    ),
    'K': const EngineeringUnit(
      id: 'K',
      label: 'K',
      dimension: QuantityDimension.temperature,
      toBase: _identity,
      fromBase: _identity,
    ),
    'deg': EngineeringUnit(
      id: 'deg',
      label: 'deg',
      dimension: QuantityDimension.angle,
      toBase: (value) => value * math.pi / 180,
      fromBase: (value) => value * 180 / math.pi,
    ),
    'rad': const EngineeringUnit(
      id: 'rad',
      label: 'rad',
      dimension: QuantityDimension.angle,
      toBase: _identity,
      fromBase: _identity,
    ),
    'mps': const EngineeringUnit(
      id: 'mps',
      label: 'm/s',
      dimension: QuantityDimension.velocity,
      toBase: _identity,
      fromBase: _identity,
    ),
    'kmps': EngineeringUnit(
      id: 'kmps',
      label: 'km/s',
      dimension: QuantityDimension.velocity,
      toBase: (value) => _scale(value, 1e3),
      fromBase: (value) => _unscale(value, 1e3),
    ),
    'ppm': EngineeringUnit(
      id: 'ppm',
      label: 'ppm',
      dimension: QuantityDimension.dimensionless,
      toBase: (value) => value * 1e-6,
      fromBase: (value) => value / 1e-6,
    ),
  };

  static EngineeringUnit unit(String id) {
    final unit = _units[id];
    if (unit == null) {
      throw ArgumentError.value(id, 'id', 'Unknown engineering unit');
    }
    return unit;
  }

  static double convert(double value, String fromUnitId, String toUnitId) {
    final from = unit(fromUnitId);
    final to = unit(toUnitId);
    if (from.dimension != to.dimension) {
      throw ArgumentError('Incompatible units: ${from.label} -> ${to.label}');
    }
    return to.fromBase(from.toBase(value));
  }

  static List<EngineeringUnit> unitsFor(QuantityDimension dimension) {
    return _units.values
        .where((unit) => unit.dimension == dimension)
        .toList(growable: false);
  }
}

class EngineeringQuantity {
  final double value;
  final String unitId;

  const EngineeringQuantity(this.value, this.unitId);

  double as(String targetUnitId) {
    return UnitCatalog.convert(value, unitId, targetUnitId);
  }

  EngineeringQuantity to(String targetUnitId) {
    return EngineeringQuantity(as(targetUnitId), targetUnitId);
  }
}
