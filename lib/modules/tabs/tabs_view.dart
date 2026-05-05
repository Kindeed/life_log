import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import '../work_log/work_log_view.dart';
import '../subscription/subscription_view.dart';
import '../statistics/statistics_view.dart';
import 'tabs_controller.dart';
import '../photo/views/photo_view.dart';
import '../profile/profile_view.dart';

class TabsView extends StatelessWidget {
  const TabsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TabsController>();

    return Scaffold(
      body: Obx(() {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildPage(controller.currentIndex.value),
        );
      }),
      bottomNavigationBar: Obx(
        () => _AppleTabBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changePage,
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const WorkLogView();
      case 1:
        return const SubscriptionView();
      case 2:
        return const PhotoView();
      case 3:
        return const StatisticsView();
      case 4:
        return const ProfileView();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _AppleTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppleTabBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _TabSpec(Icons.calendar_today_rounded, '工时'),
    _TabSpec(Icons.account_balance_wallet_rounded, '支出'),
    _TabSpec(Icons.folder_shared_rounded, '项目'),
    _TabSpec(Icons.analytics_rounded, '面板'),
    _TabSpec(Icons.person_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(
              color: semantic.border.withValues(alpha: isDark ? 0.7 : 0.85),
              width: 0.7,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.055),
              blurRadius: 26,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _AppleTabItem(
                  spec: _items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppleTabItem extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  const _AppleTabItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72);

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  spec.icon,
                  size: selected ? 23 : 22,
                  color: selected ? selectedColor : muted,
                ),
                const SizedBox(height: 3),
                Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.1,
                    color: selected ? selectedColor : muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final IconData icon;
  final String label;

  const _TabSpec(this.icon, this.label);
}
