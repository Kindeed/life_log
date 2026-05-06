String formatMoney(double value) {
  return "¥${value.toStringAsFixed(2)}";
}

String formatDateYmd(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
