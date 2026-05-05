import 'package:get/get.dart';

class CloudConfigService extends GetxService {
  static CloudConfigService get to => Get.find();

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  final isConfigured = false.obs;

  String get supabaseUrl => _supabaseUrl;
  String get supabaseAnonKey => _supabaseAnonKey;

  CloudConfigService init() {
    isConfigured.value =
        _supabaseUrl.trim().isNotEmpty && _supabaseAnonKey.trim().isNotEmpty;
    return this;
  }

  String get statusLabel => isConfigured.value ? '已配置' : '未配置';
}
