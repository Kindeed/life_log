import 'package:get/get.dart';

enum TabsDestination { work, finance, project, profile }

class TabsController extends GetxController {
  static TabsController get to => Get.find();

  // 0=工时, 1=财务, 2=项目, 3=我的
  final currentIndex = 0.obs;

  void changePage(int index) {
    index = index.clamp(0, TabsDestination.values.length - 1).toInt();
    if (index == currentIndex.value) return;
    currentIndex.value = index;
  }

  void goTo(TabsDestination destination) {
    changePage(destination.index);
  }
}
