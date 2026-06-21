import 'package:life_log/features/work_log/application/normalize_work_log_entries.dart';

final class InitializeWorkLogFeature {
  final NormalizeWorkLogEntries _normalizeEntries;
  Future<void>? _activeInitialization;
  var _hasInitialized = false;

  InitializeWorkLogFeature({required NormalizeWorkLogEntries normalizeEntries})
    : _normalizeEntries = normalizeEntries;

  Future<void> call() {
    if (_hasInitialized) return Future.value();

    final activeInitialization = _activeInitialization;
    if (activeInitialization != null) return activeInitialization;

    final initialization = _normalizeEntries().then((_) {
      _hasInitialized = true;
    });
    _activeInitialization = initialization.whenComplete(() {
      if (identical(_activeInitialization, initialization)) {
        _activeInitialization = null;
      }
    });
    return _activeInitialization!;
  }
}
