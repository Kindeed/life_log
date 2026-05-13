import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_action_sheet.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/views/create_project_sheet.dart';
import 'package:life_log/modules/photo/views/project_gallery_view.dart';
import 'package:life_log/modules/project/project_controller.dart';
import 'package:life_log/modules/subscription/views/subscription_edit_view.dart';
import 'package:life_log/modules/work_log/views/log_edit_view.dart';
import 'package:life_log/modules/work_log/work_log_controller.dart';
import 'package:life_log/modules/work_log/work_log_model.dart';

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
    if (index == controller.currentIndex.value) return;
    controller.changePage(index);
    pageController.animateToPage(
      index,
      duration: AppMotion.normal,
      curve: AppMotion.emphasizedDecelerate,
    );
  }

  void _showQuickAdd(int index) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedWorkDay = Get.isRegistered<WorkLogController>()
        ? WorkLogController.to.selectedDay.value
        : today;
    final existingWorkLog = Get.isRegistered<WorkLogController>()
        ? WorkLogController.to.getLogForDay(selectedWorkDay)
        : null;

    switch (index) {
      case 0:
        AppActionSheet.show(
          title: '添加工时',
          actions: [
            AppActionSheetItem(
              icon: Icons.work_history_rounded,
              title: '工时',
              subtitle: '记录工作、出差、请假或休息',
              onTap: () => Get.to(
                () => LogEditView(
                  selectedDate: selectedWorkDay,
                  existingLog: existingWorkLog,
                  initialType: LogType.work,
                ),
              ),
            ),
            AppActionSheetItem(
              icon: Icons.flight_takeoff_rounded,
              title: '出差',
              subtitle: '快速记录地点、交通和垫付',
              onTap: () => Get.to(
                () => LogEditView(
                  selectedDate: selectedWorkDay,
                  existingLog: existingWorkLog,
                  initialType: LogType.businessTrip,
                ),
              ),
            ),
            AppActionSheetItem(
              icon: Icons.event_busy_rounded,
              title: '请假',
              subtitle: '直接进入请假类型表单',
              onTap: () => Get.to(
                () => LogEditView(
                  selectedDate: selectedWorkDay,
                  existingLog: existingWorkLog,
                  initialType: LogType.leave,
                ),
              ),
            ),
            AppActionSheetItem(
              icon: Icons.hotel_rounded,
              title: '休息',
              subtitle: '补一条休息记录',
              onTap: () => Get.to(
                () => LogEditView(
                  selectedDate: selectedWorkDay,
                  existingLog: existingWorkLog,
                  initialType: LogType.rest,
                ),
              ),
            ),
          ],
        );
        return;
      case 1:
        AppActionSheet.show(
          title: '添加支出',
          actions: [
            AppActionSheetItem(
              icon: Icons.subscriptions_rounded,
              title: '固定支出',
              subtitle: '订阅、房租、月度开销',
              onTap: () => Get.to(() => const SubscriptionEditView()),
            ),
          ],
        );
        return;
      case 2:
        final hasProjects =
            Get.isRegistered<ProjectController>() &&
            !ProjectController.to.isLoading.value &&
            ProjectController.to.projects.isNotEmpty;
        if (!hasProjects) {
          showCreateProjectSheet(
            onCreated: (project) async {
              await Get.to(() => ProjectGalleryView(projectName: project.name));
            },
          );
          return;
        }
        AppActionSheet.show(
          title: '添加资料',
          actions: [
            AppActionSheetItem(
              icon: Icons.camera_alt_rounded,
              title: '照片',
              subtitle: '拍摄或导入项目图片',
              onTap: () => PhotoController.to.captureWithSystemCamera(),
            ),
            AppActionSheetItem(
              icon: Icons.receipt_long_rounded,
              title: '凭证',
              subtitle: '发票、收据、付款截图',
              onTap: () => EvidenceController.to.captureEvidence(),
            ),
            AppActionSheetItem(
              icon: Icons.photo_library_rounded,
              title: '导入截图',
              subtitle: '从相册导入付款截图',
              onTap: () => EvidenceController.to.importEvidence(),
            ),
            AppActionSheetItem(
              icon: Icons.upload_file_rounded,
              title: '导入文件',
              subtitle: '发票 PDF 或图片文件',
              onTap: () => EvidenceController.to.importEvidenceFile(),
            ),
            AppActionSheetItem(
              icon: Icons.edit_note_rounded,
              title: '手动记录',
              subtitle: '没有图片时先记录金额和状态',
              onTap: () => EvidenceController.to.createManualEvidence(),
            ),
          ],
        );
        return;
      default:
        AppActionSheet.show(
          title: '快捷添加',
          actions: [
            AppActionSheetItem(
              icon: Icons.work_history_rounded,
              title: '工时',
              onTap: () => Get.to(
                () => LogEditView(
                  selectedDate: selectedWorkDay,
                  initialType: LogType.work,
                ),
              ),
            ),
            AppActionSheetItem(
              icon: Icons.camera_alt_rounded,
              title: '照片',
              onTap: () => PhotoController.to.captureWithSystemCamera(),
            ),
          ],
        );
    }
  }
}

class _AppleTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ValueChanged<int> onAdd;

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

  static const _quickActions = [
    _QuickActionSpec(Icons.edit_calendar_rounded, '记工时'),
    _QuickActionSpec(Icons.payments_rounded, '添加支出'),
    _QuickActionSpec(Icons.add_photo_alternate_rounded, '添加资料'),
    _QuickActionSpec(Icons.bolt_rounded, '快捷添加'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        height: 76.h,
        padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 8.h),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(
              color: semantic.border.withValues(alpha: isDark ? 0.7 : 0.85),
              width: 1,
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
            _AddTabButton(
              spec: _quickActions[currentIndex],
              onTap: () => onAdd(currentIndex),
            ),
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
  final _QuickActionSpec spec;
  final VoidCallback onTap;

  const _AddTabButton({required this.spec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;

    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: spec.label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: onTap,
              child: AnimatedContainer(
                duration: AppMotion.normal,
                curve: AppMotion.standardDecelerate,
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: semantic.border.withValues(alpha: 0.75),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  switchInCurve: AppMotion.standardDecelerate,
                  switchOutCurve: AppMotion.standardDecelerate,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey(spec.label),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        spec.icon,
                        color: theme.colorScheme.primary,
                        size: 20.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        spec.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
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
            duration: AppMotion.normal,
            curve: AppMotion.standardDecelerate,
            margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
            padding: EdgeInsets.symmetric(vertical: 6.h),
            decoration: BoxDecoration(
              color: selected
                  ? selectedColor.withValues(
                      alpha: isDark(context) ? 0.14 : 0.1,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: AnimatedScale(
              scale: selected ? 1.04 : 1,
              duration: AppMotion.normal,
              curve: AppMotion.standardDecelerate,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    spec.icon,
                    size: selected ? 23.sp : 22.sp,
                    color: selected ? selectedColor : muted,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    spec.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5.sp,
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
      ),
    );
  }

  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

class _TabSpec {
  final IconData icon;
  final String label;

  const _TabSpec(this.icon, this.label);
}

class _QuickActionSpec {
  final IconData icon;
  final String label;

  const _QuickActionSpec(this.icon, this.label);
}
