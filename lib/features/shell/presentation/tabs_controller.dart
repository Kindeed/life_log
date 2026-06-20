import 'package:flutter/widgets.dart';

enum TabsDestination { today, work, finance, project, profile }

class TabsController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changePage(int index) {
    index = index.clamp(0, TabsDestination.values.length - 1).toInt();
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }

  void goTo(TabsDestination destination) {
    changePage(destination.index);
  }
}

class TabsScope extends InheritedNotifier<TabsController> {
  const TabsScope({
    super.key,
    required TabsController controller,
    required super.child,
  }) : super(notifier: controller);

  static TabsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TabsScope>();
    assert(scope != null, 'TabsScope is not available in this context.');
    return scope!.notifier!;
  }
}
