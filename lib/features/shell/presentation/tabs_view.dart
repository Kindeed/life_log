import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/more/presentation/more_view.dart';
import 'package:life_log/features/photo/presentation/photo_view.dart';
import 'package:life_log/features/work_log/presentation/work_log_view.dart';
import 'tabs_controller.dart';

// Note: Secondary tabs such as SubscriptionView() (historical label: '订阅')
// are now accessible under MoreView.

class TabsView extends StatefulWidget {
  const TabsView({super.key});

  @override
  State<TabsView> createState() => _TabsViewState();
}

class _TabsViewState extends State<TabsView> {
  late final TabsController controller;
  late final PageController pageController;
  int? _requestedPage;
  int _transitionId = 0;

  static const _destinations = [
    _TabDestination(
      label: '工时',
      selectedIcon: Icons.work_history_rounded,
      icon: Icons.work_history_outlined,
    ),
    _TabDestination(
      label: '项目',
      selectedIcon: Icons.folder_rounded,
      icon: Icons.folder_outlined,
    ),
    _TabDestination(
      label: '更多',
      selectedIcon: Icons.more_horiz_rounded,
      icon: Icons.more_horiz_outlined,
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
                        onPageChanged: (index) {
                          if (_requestedPage == null) {
                            controller.changePage(index);
                          }
                        },
                        children: const [
                          _KeepAliveTabPage(child: WorkLogView()),
                          _KeepAliveTabPage(child: PhotoView()),
                          _KeepAliveTabPage(child: MoreView()),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: useRail
                    ? null
                    : _SlidingTabBar(
                        pageController: pageController,
                        selectedIndex: controller.currentIndex,
                        onSelected: _goToPage,
                        destinations: _destinations,
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
    if (page == index && _requestedPage == null) return;
    final transitionId = ++_transitionId;
    if (MediaQuery.disableAnimationsOf(context)) {
      _requestedPage = null;
      pageController.jumpToPage(index);
      return;
    }
    _requestedPage = index;
    pageController
        .animateToPage(
          index,
          duration: AppMotion.normal,
          curve: AppMotion.emphasizedDecelerate,
        )
        .whenComplete(() {
          if (!mounted || transitionId != _transitionId) return;
          _requestedPage = null;
          final settledPage = pageController.page?.round();
          if (settledPage != null) controller.changePage(settledPage);
        });
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

class _SlidingTabBar extends StatelessWidget {
  final PageController pageController;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_TabDestination> destinations;

  const _SlidingTabBar({
    required this.pageController,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / destinations.length;
              final height =
                  64 *
                  (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(
                    1.0,
                    1.5,
                  );
              return SizedBox(
                height: height,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: pageController,
                      builder: (context, _) {
                        final page = pageController.hasClients
                            ? pageController.page ?? selectedIndex.toDouble()
                            : selectedIndex.toDouble();
                        return Positioned(
                          left:
                              slot * page.clamp(0, destinations.length - 1) + 6,
                          top: 0,
                          bottom: 0,
                          width: slot - 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        for (
                          var index = 0;
                          index < destinations.length;
                          index++
                        )
                          Expanded(
                            child: Semantics(
                              selected: selectedIndex == index,
                              button: true,
                              label: destinations[index].label,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                onTap: () => onSelected(index),
                                child: ExcludeSemantics(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        selectedIndex == index
                                            ? destinations[index].selectedIcon
                                            : destinations[index].icon,
                                        color: selectedIndex == index
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        destinations[index].label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: selectedIndex == index
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selectedIndex == index
                                              ? scheme.onPrimaryContainer
                                              : scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
