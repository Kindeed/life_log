import 'dart:io';

import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';
import 'package:life_log/modules/expense/expense_record_controller.dart';
import 'package:life_log/modules/expense/expense_record_model.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:life_log/modules/photo/views/create_project_sheet.dart';
import 'package:life_log/modules/photo/views/project_gallery_view.dart';
import 'package:life_log/modules/project/project_controller.dart';
import 'package:life_log/modules/project/project_model.dart';

class PhotoView extends StatefulWidget {
  const PhotoView({super.key});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  late final PhotoController controller;
  late final EvidenceController evidenceController;
  late final ExpenseRecordController expenseController;
  late final ProjectController projectController;
  late final Worker _messageWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PhotoController>();
    evidenceController = Get.find<EvidenceController>();
    expenseController = Get.find<ExpenseRecordController>();
    projectController = Get.find<ProjectController>();
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
    final semantic = theme.semanticColors;
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
      ),
      body: Obx(() {
        final isLoading =
            controller.isLoading.value || projectController.isLoading.value;
        final expenseRecords = expenseController.records.toList();
        final projectCount = projectController.projects.length;

        if (isLoading) {
          return const AppLoading(label: "正在加载项目");
        }

        final projects = _projectSummaries(
          projects: projectController.projects,
          photos: controller.photos,
          evidence: evidenceController.evidence,
          expenses: expenseRecords,
          query: controller.projectSearchQuery.value,
          sortMode: controller.projectSortMode.value,
        );

        if (projectCount == 0 && projects.isEmpty) {
          return AppEmptyState(
            icon: Icons.folder_open_rounded,
            title: "还没有项目",
            message: "先创建第一个项目，再添加照片和凭证。",
            actionLabel: "创建项目",
            onAction: () => showCreateProjectSheet(
              onCreated: (project) async {
                await controller.loadPhotos();
                await evidenceController.loadEvidence();
                await expenseController.loadRecords();
                if (!mounted) return;
                await Get.to(
                  () => ProjectGalleryView(projectName: project.name),
                );
              },
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ConstrainedPage(
                child: _ProjectOverview(
                  controller: controller,
                  projectCount: projectCount,
                  expenseRecords: expenseRecords,
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
                    style: TextStyle(color: textSecondary, fontSize: 14.sp),
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
                        expenseTotal: _expenseTotalForProject(
                          expenseRecords,
                          project.name,
                        ),
                        isDark: isDark,
                        semantic: semantic,
                        textSecondary: textSecondary,
                        onTap: () => Get.to(
                          () => ProjectGalleryView(projectName: project.name),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }

  double _expenseTotalForProject(List<ExpenseRecord> records, String project) {
    return records
        .where((record) => record.projectName == project)
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  List<ProjectSummary> _projectSummaries({
    required List<Project> projects,
    required List<PhotoItem> photos,
    required List<ExpenseEvidence> evidence,
    required List<ExpenseRecord> expenses,
    required String query,
    required ProjectSortMode sortMode,
  }) {
    final names = <String>{};
    names.addAll(projects.map((project) => project.name));
    names.addAll(photos.map((photo) => photo.projectName).whereType<String>());
    names.addAll(evidence.map((item) => item.projectName));
    names.addAll(
      expenses
          .map((record) => record.projectName)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty),
    );

    final lowerQuery = query.trim().toLowerCase();
    final summaries = names
        .where(
          (name) =>
              lowerQuery.isEmpty || name.toLowerCase().contains(lowerQuery),
        )
        .map((name) {
          final projectPhotos =
              photos.where((photo) => photo.projectName == name).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final deviceNames = projectPhotos
              .map((photo) => photo.deviceName)
              .whereType<String>()
              .where((name) => name.trim().isNotEmpty)
              .toSet();
          final untitledCount = projectPhotos
              .where((photo) => photo.description?.trim().isNotEmpty != true)
              .length;

          return ProjectSummary(
            name: name,
            photos: projectPhotos,
            latestPhoto: projectPhotos.isEmpty ? null : projectPhotos.first,
            deviceCount: deviceNames.length,
            untitledCount: untitledCount,
          );
        })
        .toList();

    switch (sortMode) {
      case ProjectSortMode.recent:
        summaries.sort(
          (a, b) => (b.latestPhoto?.createdAt ?? DateTime(0)).compareTo(
            a.latestPhoto?.createdAt ?? DateTime(0),
          ),
        );
        break;
      case ProjectSortMode.count:
        summaries.sort((a, b) {
          final countCompare = b.photoCount.compareTo(a.photoCount);
          if (countCompare != 0) return countCompare;
          return a.name.compareTo(b.name);
        });
        break;
      case ProjectSortMode.name:
        summaries.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return summaries;
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
}

class _ProjectOverview extends StatelessWidget {
  final PhotoController controller;
  final int projectCount;
  final List<ExpenseRecord> expenseRecords;
  final AppSemanticColors semantic;
  final Color textSecondary;

  const _ProjectOverview({
    required this.controller,
    required this.projectCount,
    required this.expenseRecords,
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
                  value: projectCount.toString(),
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
          SizedBox(height: 10.h),
          AppMetricTile(
            label: "项目支出",
            value: formatMoney(
              expenseRecords.fold(0.0, (sum, item) => sum + item.amount),
            ),
            icon: Icons.payments_rounded,
            color: semantic.expense,
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
  final double expenseTotal;
  final bool isDark;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.summary,
    required this.expenseTotal,
    required this.isDark,
    required this.semantic,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final evidenceController = Get.find<EvidenceController>();
    final evidenceItems =
        evidenceController.groupedEvidence[summary.name] ?? const [];
    final pendingAmount = evidenceItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.status == EvidenceStatus.reimbursed ? 0 : (item.amount ?? 0)),
    );
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
                            ?.copyWith(fontWeight: FontWeight.w700),
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
                  summary.latestPhoto == null
                      ? "等待添加资料"
                      : "最近 ${_formatDate(summary.latestPhoto!.createdAt)}",
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
                      icon: Icons.receipt_long_rounded,
                      label: "${evidenceItems.length} 份",
                      color: semantic.expense,
                    ),
                    if (pendingAmount > 0)
                      AppPill(
                        icon: Icons.payments_rounded,
                        label: formatMoney(pendingAmount),
                        color: semantic.warning,
                      ),
                    if (expenseTotal > 0)
                      AppPill(
                        icon: Icons.account_balance_wallet_rounded,
                        label: formatMoney(expenseTotal),
                        color: semantic.expense,
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
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: photos.isEmpty
            ? Container(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                child: Icon(
                  Icons.folder_open_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey,
                  size: 32.sp,
                ),
              )
            : photos.length == 1
            ? Image.file(
                File(photos.first.filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: isDark ? Colors.grey[600] : Colors.grey,
                  ),
                ),
              )
            : GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
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
