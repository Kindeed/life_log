import 'package:get/get.dart';
import '../../common/services/auth_service.dart';
import '../../common/services/cloud_config_service.dart';
import '../../common/services/log_service.dart';
import '../../common/services/sync_service.dart';

/// Profile 模块控制器
/// 管理"我的"页面状态
class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  AuthService? get authService =>
      Get.isRegistered<AuthService>() ? AuthService.to : null;
  CloudConfigService get cloudConfig => CloudConfigService.to;

  // 用户登录状态
  final isLoggedIn = false.obs;
  final userName = '本地模式'.obs;
  final isCloudConfigured = false.obs;
  final userAvatar = ''.obs;

  @override
  void onInit() {
    super.onInit();
    isCloudConfigured.value = cloudConfig.isConfigured.value;
    _syncAuthState(authService?.currentUser.value);

    if (authService != null) {
      ever(authService!.currentUser, _syncAuthState);
    }
  }

  void _syncAuthState(dynamic user) {
    isLoggedIn.value = user != null;
    if (!isCloudConfigured.value) {
      userName.value = '本地模式';
    } else {
      userName.value = user?.email ?? '未登录';
    }
  }

  Future<void> logout() async {
    try {
      await authService?.signOut();
      if (Get.currentRoute != '/login') {
        Get.offAllNamed('/login');
      }
    } catch (e, stackTrace) {
      LogService.to.error('Profile', '退出登录失败: $e', stackTrace);
      rethrow;
    }
  }

  Future<bool> syncData() async {
    if (!Get.isRegistered<SyncService>()) return false;
    return await SyncService.to.syncAll(
      reason: 'manual',
      forceFullRefresh: true,
    );
  }
}
