import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/widgets/app_action_sheet.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_floating_action_pill.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/views/evidence_list_view.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/views/project_gallery_view.dart';

enum _ProjectSection { photos, evidence }

class PhotoView extends StatefulWidget {
  const PhotoView({super.key});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  late final PhotoController controller;
  late final EvidenceController evidenceController;
  late final Worker _messageWorker;
  _ProjectSection _section = _ProjectSection.photos;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PhotoController>();
    evidenceController = Get.find<EvidenceController>();
    _messageWorker = ever<PhotoUiMessage?>(
      controller.uiMessage,
      _showUiMessage,
    );
  }

  @override
  void dispose() {
    _messageWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semantic = theme.extension<AppSemanticColors>()!;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text("项目资料"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "刷新",
            onPressed: () {
              controller.loadPhotos();
              evidenceController.loadEvidence();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(54.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
            child: _ProjectSectionSwitch(
              value: _section,
              onChanged: (value) => setState(() => _section = value),
            ),
          ),
        ),
      ),
      body: _section == _ProjectSection.evidence
          ? const EvidenceListView()
          : Obx(() {
              if (controller.isLoading.value) {
                return const AppLoading(label: "正在加载项目");
              }

              if (controller.photos.isEmpty) {
                return AppEmptyState(
                  icon: Icons.folder_open_rounded,
                  title: "暂无项目记录",
                  message: "拍摄或导入照片后会自动按项目归档",
                  actionLabel: "添加照片",
                  onAction: () => _showAddPhotoActions(context, controller),
                );
              }

              final projects = controller.filteredProjectSummaries;

              return NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  controller.onScroll(notification);
                  return true;
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: ConstrainedPage(
                        child: _ProjectOverview(
                          controller: controller,
                          semantic: semantic,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ),
                    if (projects.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            "没有匹配的项目",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 92.h),
                        sliver: SliverList.separated(
                          itemCount: projects.length,
                          separatorBuilder: (_, _) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final project = projects[index];
                            return ConstrainedPage(
                              child: _ProjectCard(
                                summary: project,
                                isDark: isDark,
                                semantic: semantic,
                                textSecondary: textSecondary,
                                onTap: () => Get.to(
                                  () => ProjectGalleryView(
                                    projectName: project.name,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        if (_section == _ProjectSection.evidence) {
          return const SizedBox.shrink();
        }
        if (controller.photos.isEmpty) return const SizedBox.shrink();

        return AppFloatingActionPill(
          label: "添加照片",
          icon: Icons.camera_alt_rounded,
          color: semantic.project,
          visible: controller.isFabVisible.value,
          onPressed: () => _showAddPhotoActions(context, controller),
        );
      }),
    );
  }

  void _showUiMessage(PhotoUiMessage? message) {
    if (message == null) return;

    final backgroundColor = switch (message.type) {
      PhotoUiMessageType.success => Colors.green.withValues(alpha: 0.8),
      PhotoUiMessageType.warning => Colors.orange.withValues(alpha: 0.9),
      PhotoUiMessageType.error => Theme.of(context).colorScheme.errorContainer,
    };
    final colorText = switch (message.type) {
      PhotoUiMessageType.success || PhotoUiMessageType.warning => Colors.white,
      PhotoUiMessageType.error => Theme.of(
        context,
      ).colorScheme.onErrorContainer,
    };

    Get.snackbar(
      message.title,
      message.message,
      snackPosition: message.showAtBottom
          ? SnackPosition.BOTTOM
          : SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: colorText,
    );
  }

  void _showAddPhotoActions(BuildContext context, PhotoController controller) {
    AppActionSheet.show(
      title: "添加照片",
      actions: [
        AppActionSheetItem(
          icon: Icons.camera_alt_rounded,
          title: "拍摄照片",
          onTap: controller.captureWithSystemCamera,
        ),
        AppActionSheetItem(
          icon: Icons.photo_library_rounded,
          title: "从相册导入",
          subtitle: "导入后请求删除系统相册原图",
          onTap: controller.importFromGallery,
        ),
      ],
    );
  }
}

class _ProjectSectionSwitch extends StatelessWidget {
  final _ProjectSection value;
  final ValueChanged<_ProjectSection> onChanged;

  const _ProjectSectionSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _item(
            context,
            '照片',
            Icons.photo_library_rounded,
            _ProjectSection.photos,
          ),
          _item(
            context,
            '凭证',
            Icons.receipt_long_rounded,
            _ProjectSection.evidence,
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String label,
    IconData icon,
    _ProjectSection section,
  ) {
    final selected = value == section;
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(section),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            color: selected ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17.sp,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectOverview extends StatelessWidget {
  final PhotoController controller;
  final AppSemanticColors semantic;
  final Color textSecondary;

  const _ProjectOverview({
    required this.controller,
    required this.semantic,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: "项目",
                  value: controller.totalProjectCount.toString(),
                  icon: Icons.folder_special_rounded,
                  color: semantic.project,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppMetricTile(
                  label: "照片",
                  value: controller.totalPhotoCount.toString(),
                  icon: Icons.photo_library_rounded,
                  color: semantic.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AppTextField(
            onChanged: controller.updateProjectSearch,
            hintText: "搜索项目",
            prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
          ),
          SizedBox(height: 10.h),
          Obx(
            () => AppFilterChipBar<ProjectSortMode>(
              value: controller.projectSortMode.value,
              onChanged: controller.setProjectSortMode,
              items: const [
                AppFilterChipItem(
                  value: ProjectSortMode.recent,
                  label: "最近",
                  icon: Icons.schedule_rounded,
                ),
                AppFilterChipItem(
                  value: ProjectSortMode.count,
                  label: "数量",
                  icon: Icons.photo_library_rounded,
                ),
                AppFilterChipItem(
                  value: ProjectSortMode.name,
                  label: "名称",
                  icon: Icons.sort_by_alpha_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectSummary summary;
  final bool isDark;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.summary,
    required this.isDark,
    required this.semantic,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(10.w),
      child: Row(
        children: [
          _ProjectCover(summary: summary, isDark: isDark),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: textSecondary,
                      size: 22.sp,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  "最近 ${_formatDate(summary.latestPhoto.createdAt)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textSecondary, fontSize: 12.sp),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    AppPill(
                      icon: Icons.photo_outlined,
                      label: "${summary.photoCount} 张",
                      color: semantic.project,
                    ),
                    AppPill(
                      icon: Icons.devices_rounded,
                      label: "${summary.deviceCount} 台",
                      color: semantic.stats,
                    ),
                    if (summary.untitledCount > 0)
                      AppPill(
                        icon: Icons.edit_note_rounded,
                        label: "${summary.untitledCount} 未命名",
                        color: semantic.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month.$day $hour:$minute';
  }
}

class _ProjectCover extends StatelessWidget {
  final ProjectSummary summary;
  final bool isDark;

  const _ProjectCover({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final photos = summary.photos.take(4).toList();

    return SizedBox(
      width: 98.w,
      height: 98.w,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: photos.length == 1 ? 1 : 4,
          itemBuilder: (context, index) {
            if (index >= photos.length) {
              return Container(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                child: Icon(
                  Icons.image_outlined,
                  size: 18.sp,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
              );
            }
            return Image.file(
              File(photos[index].filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                child: Icon(
                  Icons.broken_image_outlined,
                  color: isDark ? Colors.grey[600] : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
