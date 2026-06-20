import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/presentation/subscription_view.dart';
import 'package:life_log/features/today/presentation/today_view.dart';
import 'package:life_log/features/work_log/presentation/work_log_view.dart';

import 'package:life_log/features/photo/presentation/photo_view.dart';
import 'package:life_log/features/profile/presentation/profile_view.dart';
import 'tabs_controller.dart';

class TabsView extends StatefulWidget {
  const TabsView({super.key});

  @override
  State<TabsView> createState() => _TabsViewState();
}

class _TabsViewState extends State<TabsView> {
  late final TabsController controller;
  late final PageController pageController;

  static const _destinations = [
    _TabDestination(
      label: '今天',
      selectedIcon: Icons.today_rounded,
      icon: Icons.today_outlined,
    ),
    _TabDestination(
      label: '工时',
      selectedIcon: Icons.calendar_today_rounded,
      icon: Icons.calendar_today_outlined,
    ),
    _TabDestination(
      label: '财务',
      selectedIcon: Icons.account_balance_wallet_rounded,
      icon: Icons.account_balance_wallet_outlined,
    ),
    _TabDestination(
      label: '项目',
      selectedIcon: Icons.folder_rounded,
      icon: Icons.folder_outlined,
    ),
    _TabDestination(
      label: '我的',
      selectedIcon: Icons.person_rounded,
      icon: Icons.person_outline_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    controller = serviceLocator<TabsController>();
    pageController = PageController(initialPage: controller.currentIndex);
    controller.addListener(_syncPage);
  }

  @override
  void dispose() {
    controller.removeListener(_syncPage);
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabsScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final useRail = constraints.maxWidth >= 700;
              return Scaffold(
                body: Row(
                  children: [
                    if (useRail)
                      NavigationRail(
                        selectedIndex: controller.currentIndex,
                        onDestinationSelected: _goToPage,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final destination in _destinations)
                            NavigationRailDestination(
                              selectedIcon: Icon(destination.selectedIcon),
                              icon: Icon(destination.icon),
                              label: Text(destination.label),
                            ),
                        ],
                      ),
                    Expanded(
                      child: PageView(
                        controller: pageController,
                        onPageChanged: controller.changePage,
                        children: const [
                          _KeepAliveTabPage(child: TodayView()),
                          _KeepAliveTabPage(child: WorkLogView()),
                          _KeepAliveTabPage(child: SubscriptionView()),
                          _KeepAliveTabPage(child: PhotoView()),
                          _KeepAliveTabPage(child: ProfileView()),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: useRail
                    ? null
                    : NavigationBar(
                        selectedIndex: controller.currentIndex,
                        onDestinationSelected: _goToPage,
                        destinations: [
                          for (final destination in _destinations)
                            NavigationDestination(
                              selectedIcon: Icon(destination.selectedIcon),
                              icon: Icon(destination.icon),
                              label: destination.label,
                            ),
                        ],
                      ),
              );
            },
          );
        },
      ),
    );
  }

  void _goToPage(int index) {
    controller.changePage(index);
  }

  void _syncPage() {
    final index = controller.currentIndex;
    if (!pageController.hasClients) return;
    final page = pageController.page?.round() ?? pageController.initialPage;
    if (page == index) return;
    pageController.animateToPage(
      index,
      duration: AppMotion.normal,
      curve: AppMotion.emphasizedDecelerate,
    );
  }
}

class _KeepAliveTabPage extends StatefulWidget {
  final Widget child;

  const _KeepAliveTabPage({required this.child});

  @override
  State<_KeepAliveTabPage> createState() => _KeepAliveTabPageState();
}

class _KeepAliveTabPageState extends State<_KeepAliveTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _TabDestination {
  final String label;
  final IconData selectedIcon;
  final IconData icon;

  const _TabDestination({
    required this.label,
    required this.selectedIcon,
    required this.icon,
  });
}
