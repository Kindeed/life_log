import 'date_utils.dart';

String formatMoney(double value) {
  return "¥${value.toStringAsFixed(2)}";
}

String formatDateYmd(DateTime date) {
  final localDate = dateOnlyLocal(date);
  return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
}
