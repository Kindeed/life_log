import 'package:flutter/foundation.dart';
import 'package:life_log/core/di/service_locator.dart';

class CloudConfigService extends ChangeNotifier {
  static CloudConfigService get to => serviceLocator<CloudConfigService>();

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  bool isConfigured = false;

  String get supabaseUrl => _supabaseUrl;
  String get supabaseAnonKey => _supabaseAnonKey;
  String get maskedSupabaseUrl => maskSupabaseUrl(_supabaseUrl);

  CloudConfigService init() {
    final configured =
        _supabaseUrl.trim().isNotEmpty && _supabaseAnonKey.trim().isNotEmpty;
    if (isConfigured != configured) {
      isConfigured = configured;
      notifyListeners();
    }
    return this;
  }

  String get statusLabel => isConfigured ? '已配置' : '未配置';

  static String maskSupabaseUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.host.isEmpty) return '未配置';
    final hostParts = parsed.host.split('.');
    final maskedHost = hostParts.isEmpty
        ? '***'
        : [
            hostParts.first.length <= 6
                ? '***'
                : '${hostParts.first.substring(0, 3)}***',
            ...hostParts.skip(1),
          ].join('.');
    return '${parsed.scheme}://$maskedHost';
  }
}
