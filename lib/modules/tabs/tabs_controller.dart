import 'package:get/get.dart';

class TabsController extends GetxController {
  // 1. 这是一个“可观察”的整数，代表当前选中的是第几个 Tab (0=日历, 1=会员)
  final currentIndex = 0.obs;
  // 记录已经访问过的 Tab，用于懒加载优化性能
  final visitedTabs = <int>{0}.obs;

  // 2. 切换页面的方法
  void changePage(int index) {
    currentIndex.value = index;
  }
}
