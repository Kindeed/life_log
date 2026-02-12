import 'package:get/get.dart';
import '../../common/services/auth_service.dart';
import '../../common/services/sync_service.dart';

/// Profile 模块控制器
/// 管理"我的"页面状态
class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final authService = Get.find<AuthService>();

  // 用户登录状态
  late final RxBool isLoggedIn;
  late final RxString userName;
  final userAvatar = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Bind to AuthService
    isLoggedIn = RxBool(authService.isLoggedIn);
    userName = RxString(authService.currentUser.value?.email ?? '未登录');

    // Listen to changes
    ever(authService.currentUser, (user) {
      isLoggedIn.value = user != null;
      userName.value = user?.email ?? '未登录';
    });
  }

  Future<void> logout() async {
    await authService.signOut();
  }

  Future<bool> syncData() async {
    return await SyncService.to.syncAll();
  }
}
