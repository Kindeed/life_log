import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:life_log/common/widgets/app_action_sheet.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/expense/views/expense_record_edit_view.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/work_log/views/log_edit_view.dart';
import '../photo/views/photo_view.dart';
import '../profile/profile_view.dart';
import '../subscription/subscription_view.dart';
import '../work_log/work_log_view.dart';
import 'tabs_controller.dart';

class TabsView extends StatefulWidget {
  const TabsView({super.key});

  @override
  State<TabsView> createState() => _TabsViewState();
}

class _TabsViewState extends State<TabsView> {
  late final TabsController controller;
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<TabsController>();
    pageController = PageController(initialPage: controller.currentIndex.value);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: controller.changePage,
        children: const [
          WorkLogView(),
          SubscriptionView(),
          PhotoView(),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: Obx(
        () => _AppleTabBar(
          currentIndex: controller.currentIndex.value,
          onTap: _goToPage,
          onAdd: _showQuickAdd,
        ),
      ),
    );
  }

  void _goToPage(int index) {
    controller.changePage(index);
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _showQuickAdd() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    AppActionSheet.show(
      title: '快速添加',
      actions: [
        AppActionSheetItem(
          icon: Icons.work_history_rounded,
          title: '工时',
          onTap: () => Get.to(() => LogEditView(selectedDate: today)),
        ),
        AppActionSheetItem(
          icon: Icons.payments_rounded,
          title: '项目支出',
          onTap: () => Get.to(() => ExpenseRecordEditView(initialDate: today)),
        ),
        AppActionSheetItem(
          icon: Icons.camera_alt_rounded,
          title: '照片',
          onTap: () => PhotoController.to.captureWithSystemCamera(),
        ),
        AppActionSheetItem(
          icon: Icons.receipt_long_rounded,
          title: '凭证',
          onTap: () => EvidenceController.to.createManualEvidence(),
        ),
      ],
    );
  }
}

class _AppleTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  const _AppleTabBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
  });

  static const _items = [
    _TabSpec(Icons.calendar_today_rounded, '工时'),
    _TabSpec(Icons.account_balance_wallet_rounded, '财务'),
    _TabSpec(Icons.folder_shared_rounded, '项目'),
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
            for (var i = 0; i < 2; i++)
              Expanded(
                child: _AppleTabItem(
                  spec: _items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
            _AddTabButton(onTap: onAdd),
            for (var i = 2; i < _items.length; i++)
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

class _AddTabButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTabButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: '快速添加',
          child: Material(
            color: theme.colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.add_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 30,
                ),
              ),
            ),
          ),
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
