import 'package:get/get.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // 纯全局服务目前都在 main.dart 中通过 Get.put 初始化
    // 未来如果需要全局的懒加载服务，可以在此处注册
  }
}
