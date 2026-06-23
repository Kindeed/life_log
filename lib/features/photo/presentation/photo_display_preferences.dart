import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

final class PhotoDisplayPreferences extends ChangeNotifier {
  static const _showGpsMetadataKey = 'photo.showGpsMetadata';

  final GetStorage _storage;

  PhotoDisplayPreferences({GetStorage? storage})
    : _storage = storage ?? GetStorage();

  bool get showGpsMetadata => _storage.read(_showGpsMetadataKey) == true;

  Future<void> setShowGpsMetadata(bool value) async {
    await _storage.write(_showGpsMetadataKey, value);
    notifyListeners();
  }
}
