import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    final controller = Get.put(TabsController(), permanent: true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        // Pre-cache logic
        if (!controller.visitedTabs.contains(controller.currentIndex.value)) {
          controller.visitedTabs.add(controller.currentIndex.value);
        }

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
        () => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changePage,
            backgroundColor: theme.cardColor,
            elevation: 0,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_rounded),
                label: "工时",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: "支出",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_shared_rounded),
                label: "项目",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_rounded),
                label: "面板",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: "我的",
              ),
            ],
          ),
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
