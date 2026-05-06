import 'package:get/get.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // 当前服务在 main.dart/bootstrap 和模块 binding 中注册。
    // 保留此绑定作为应用级路由入口的扩展点。
  }
}
