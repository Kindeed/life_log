import 'package:get/get.dart';

class TabsController extends GetxController {
  static TabsController get to => Get.find();

  // 0=工时, 1=财务, 2=项目, 3=我的
  final currentIndex = 0.obs;

  void changePage(int index) {
    if (index == currentIndex.value) return;
    currentIndex.value = index;
  }
}
