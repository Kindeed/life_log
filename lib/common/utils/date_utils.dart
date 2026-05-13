DateTime dateOnlyLocal(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime dateTimeLocal(DateTime date) => date.toLocal();
