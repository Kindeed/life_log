import 'date_utils.dart';

String normalizeCurrencyCode(String currency) {
  final code = currency.trim().toUpperCase();
  return code.isEmpty ? 'CNY' : code;
}

/// Editable decimal text retains the source amount and omits integer '.0'.
String formatMoneyInput(double value) =>
    _expandedDecimal(value).replaceFirst(RegExp(r'\.0+$'), '');

/// Displays original amounts without rounding away historical fractional values.
/// CNY retains its familiar symbol; foreign currencies use unambiguous ISO codes.
String formatMoney(double value, {String currency = 'CNY'}) {
  final code = normalizeCurrencyCode(currency);
  final prefix = code == 'CNY' ? '¥' : '$code ';
  if (!value.isFinite) return '$prefix—';
  final places = switch (code) {
    'JPY' ||
    'KRW' ||
    'VND' ||
    'CLP' ||
    'XAF' ||
    'XOF' ||
    'XPF' ||
    'BIF' ||
    'DJF' ||
    'GNF' ||
    'KMF' ||
    'PYG' ||
    'RWF' ||
    'UGX' ||
    'VUV' => 0,
    'BHD' || 'IQD' || 'JOD' || 'KWD' || 'LYD' || 'OMR' || 'TND' => 3,
    'CLF' || 'UYW' => 4,
    _ => 2,
  };
  final decimal = _expandedDecimal(value == 0 ? 0.0 : value);
  final parts = decimal.split('.');
  final fraction = parts.length == 2 ? parts[1] : '';
  final digits = fraction.replaceFirst(RegExp(r'0+$'), '');
  final padded = digits.padRight(places, '0');
  return '$prefix${parts[0]}${padded.isEmpty ? '' : '.$padded'}';
}

String formatMoneyTotals(
  Map<String, double> totals, {
  String separator = ' · ',
}) {
  if (totals.isEmpty) return formatMoney(0);
  final codes = totals.keys.toList()..sort();
  return codes
      .map((code) => formatMoney(totals[code]!, currency: code))
      .join(separator);
}

/// Rounded presentation for derived CNY estimates, not stored original amounts.
String formatCnyEstimate(double value) {
  if (!value.isFinite) return '¥—';
  if (value != 0 && value.abs() < 0.005) {
    return value < 0 ? '>−¥0.01' : '<¥0.01';
  }
  return '¥${value == 0 ? '0.00' : value.toStringAsFixed(2)}';
}

/// Accumulates persisted decimal values without introducing binary sum tails.
double sumMoneyValues(Iterable<double> values) {
  var coefficient = BigInt.zero;
  var scale = 0;
  for (final value in values) {
    if (!value.isFinite) return value;
    final parts = _expandedDecimal(value).split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    final valueScale = fraction.length;
    if (valueScale > scale) {
      coefficient *= BigInt.from(10).pow(valueScale - scale);
      scale = valueScale;
    }
    coefficient +=
        BigInt.parse('${parts[0]}$fraction') *
        BigInt.from(10).pow(scale - valueScale);
  }
  if (scale == 0) return coefficient.toDouble();
  final negative = coefficient.isNegative;
  final digits = coefficient.abs().toString().padLeft(scale + 1, '0');
  final point = digits.length - scale;
  return double.parse(
    '${negative ? '-' : ''}${digits.substring(0, point)}.${digits.substring(point)}',
  );
}

String _expandedDecimal(double value) {
  final raw = value.toString();
  if (!raw.contains('e')) return raw;
  final pieces = raw.split('e');
  final negative = pieces[0].startsWith('-');
  final mantissa = negative ? pieces[0].substring(1) : pieces[0];
  final point = mantissa.indexOf('.');
  final digits = mantissa.replaceAll('.', '');
  final decimalIndex =
      (point < 0 ? mantissa.length : point) + int.parse(pieces[1]);
  final sign = negative ? '-' : '';
  if (decimalIndex <= 0) {
    return '${sign}0.${'0' * -decimalIndex}$digits';
  }
  if (decimalIndex >= digits.length) {
    return '$sign$digits${'0' * (decimalIndex - digits.length)}';
  }
  return '$sign${digits.substring(0, decimalIndex)}.${digits.substring(decimalIndex)}';
}

String formatDateYmd(DateTime date) {
  final localDate = dateOnlyLocal(date);
  return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
}
