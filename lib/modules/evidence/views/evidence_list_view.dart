import 'dart:io';

import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_action_sheet.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';

class EvidenceListView extends StatelessWidget {
  const EvidenceListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EvidenceController>();
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Obx(() {
      if (controller.isLoading.value && controller.evidence.isEmpty) {
        return const AppLoading(label: '正在加载凭证');
      }

      if (controller.evidence.isEmpty) {
        return Stack(
          children: [
            AppEmptyState(
              icon: Icons.receipt_long_rounded,
              title: '暂无凭证',
              message: '发票、付款截图和购买记录会在这里按项目归档',
              actionLabel: '添加凭证',
              onAction: () => _showAddActions(context, controller),
            ),
          ],
        );
      }

      final summaries = controller.filteredProjectSummaries;
      return Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ConstrainedPage(
                  child: _EvidenceOverview(
                    controller: controller,
                    semantic: semantic,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
              if (summaries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      '没有匹配的凭证',
                      style: TextStyle(color: textSecondary, fontSize: 14.sp),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 92.h),
                  sliver: SliverList.separated(
                    itemCount: summaries.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      return ConstrainedPage(
                        child: _EvidenceProjectCard(
                          summary: summary,
                          semantic: semantic,
                          textSecondary: textSecondary,
                          onTap: () => _showProjectEvidence(
                            context,
                            controller,
                            summary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 18.h,
            child: Center(
              child: FloatingActionButton.extended(
                backgroundColor: semantic.warning,
                foregroundColor: Colors.white,
                elevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('添加凭证'),
                onPressed: () => _showAddActions(context, controller),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showAddActions(BuildContext context, EvidenceController controller) {
    AppActionSheet.show(
      title: '添加凭证',
      actions: [
        AppActionSheetItem(
          icon: Icons.camera_alt_rounded,
          title: '拍摄凭证',
          onTap: controller.captureEvidence,
        ),
        AppActionSheetItem(
          icon: Icons.photo_library_rounded,
          title: '从相册导入',
          onTap: controller.importEvidence,
        ),
        AppActionSheetItem(
          icon: Icons.upload_file_rounded,
          title: '导入文件',
          subtitle: '发票、PDF 或截图文件',
          onTap: controller.importEvidenceFile,
        ),
        AppActionSheetItem(
          icon: Icons.edit_note_rounded,
          title: '手动记录',
          subtitle: '没有截图时先记录金额和状态',
          onTap: controller.createManualEvidence,
        ),
      ],
    );
  }

  void _showProjectEvidence(
    BuildContext context,
    EvidenceController controller,
    EvidenceProjectSummary summary,
  ) {
    final theme = Theme.of(context);
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: 0.82.sh),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.projectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    tooltip: '添加凭证',
                    onPressed: () {
                      Get.back();
                      _showProjectAddActions(controller, summary.projectName);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: Get.back,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: ListView.separated(
                  itemCount: summary.items.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final item = summary.items[index];
                    return _EvidenceItemCard(
                      item: item,
                      textSecondary: textSecondary,
                      onTap: () =>
                          _showEvidenceDetail(context, controller, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showProjectAddActions(
    EvidenceController controller,
    String projectName,
  ) {
    AppActionSheet.show(
      title: '添加到 $projectName',
      actions: [
        AppActionSheetItem(
          icon: Icons.camera_alt_rounded,
          title: '拍摄凭证',
          onTap: () => controller.captureEvidence(initialProject: projectName),
        ),
        AppActionSheetItem(
          icon: Icons.photo_library_rounded,
          title: '从相册导入',
          onTap: () => controller.importEvidence(initialProject: projectName),
        ),
        AppActionSheetItem(
          icon: Icons.upload_file_rounded,
          title: '导入文件',
          subtitle: '发票、PDF 或截图文件',
          onTap: () =>
              controller.importEvidenceFile(initialProject: projectName),
        ),
        AppActionSheetItem(
          icon: Icons.edit_note_rounded,
          title: '手动记录',
          onTap: () =>
              controller.createManualEvidence(initialProject: projectName),
        ),
      ],
    );
  }

  void _showEvidenceDetail(
    BuildContext context,
    EvidenceController controller,
    ExpenseEvidence item,
  ) {
    final theme = Theme.of(context);
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.merchant?.isNotEmpty == true
                            ? item.merchant!
                            : item.category.label,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: Get.back,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _EvidencePreview(item: item, height: 220.h),
                SizedBox(height: 16.h),
                _InfoRow(label: '项目', value: item.projectName),
                _InfoRow(label: '日期', value: _formatDate(item.evidenceDate)),
                _InfoRow(label: '金额', value: formatMoney(item.amount ?? 0)),
                _InfoRow(label: '类型', value: item.category.label),
                _InfoRow(label: '状态', value: item.status.label),
                if (item.tripDate != null)
                  _InfoRow(label: '出差日期', value: _formatDate(item.tripDate!)),
                if (item.note?.isNotEmpty == true)
                  _InfoRow(label: '备注', value: item.note!),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.exportEvidenceFile(item),
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('导出'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Get.back();
                          controller.editEvidence(item);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('编辑'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String _formatDate(DateTime date) {
    return formatDateYmd(date);
  }
}

class _EvidenceOverview extends StatelessWidget {
  final EvidenceController controller;
  final AppSemanticColors semantic;
  final Color textSecondary;

  const _EvidenceOverview({
    required this.controller,
    required this.semantic,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: '凭证',
                  value: controller.totalEvidenceCount.toString(),
                  icon: Icons.receipt_long_rounded,
                  color: semantic.warning,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppMetricTile(
                  label: '待报销',
                  value: formatMoney(controller.totalPendingAmount),
                  icon: Icons.pending_actions_rounded,
                  color: semantic.expense,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AppTextField(
            onChanged: controller.updateSearch,
            hintText: '搜索项目',
            prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
          ),
          SizedBox(height: 10.h),
          Obx(
            () => AppFilterChipBar<EvidenceSortMode>(
              value: controller.sortMode.value,
              onChanged: controller.setSortMode,
              items: const [
                AppFilterChipItem(
                  value: EvidenceSortMode.recent,
                  label: '最近',
                  icon: Icons.schedule_rounded,
                ),
                AppFilterChipItem(
                  value: EvidenceSortMode.amount,
                  label: '金额',
                  icon: Icons.payments_rounded,
                ),
                AppFilterChipItem(
                  value: EvidenceSortMode.project,
                  label: '项目',
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

class _EvidenceProjectCard extends StatelessWidget {
  final EvidenceProjectSummary summary;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final VoidCallback onTap;

  const _EvidenceProjectCard({
    required this.summary,
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
          _EvidencePreview(item: summary.latest, width: 86.w, height: 86.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.projectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: textSecondary),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '最近 ${_formatDate(summary.latest.evidenceDate)}',
                  style: TextStyle(color: textSecondary, fontSize: 12.sp),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _MetaPill(
                      icon: Icons.receipt_long_rounded,
                      label: '${summary.count} 条',
                      color: semantic.warning,
                    ),
                    _MetaPill(
                      icon: Icons.pending_actions_rounded,
                      label: formatMoney(summary.pendingAmount),
                      color: semantic.expense,
                    ),
                    if (summary.reimbursedAmount > 0)
                      _MetaPill(
                        icon: Icons.verified_rounded,
                        label: formatMoney(summary.reimbursedAmount),
                        color: semantic.success,
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
    return '${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
  }
}

class _EvidenceItemCard extends StatelessWidget {
  final ExpenseEvidence item;
  final Color textSecondary;
  final VoidCallback onTap;

  const _EvidenceItemCard({
    required this.item,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = item.status == EvidenceStatus.reimbursed
        ? Colors.green
        : item.status == EvidenceStatus.submitted
        ? Colors.blue
        : Colors.orange;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(10.w),
      child: Row(
        children: [
          _EvidencePreview(item: item, width: 58.w, height: 58.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.merchant?.isNotEmpty == true
                      ? item.merchant!
                      : item.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  '${_formatDate(item.evidenceDate)} · ${item.category.label}',
                  style: TextStyle(color: textSecondary, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(item.amount ?? 0),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 6.h),
              _MetaPill(
                icon: Icons.circle,
                label: item.status.label,
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
  }
}

class _EvidencePreview extends StatelessWidget {
  final ExpenseEvidence item;
  final double? width;
  final double height;

  const _EvidencePreview({
    required this.item,
    this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final path = item.localFilePath;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        color: theme.colorScheme.surfaceContainerHighest,
        child: path != null && File(path).existsSync() && _isImagePath(path)
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(theme),
              )
            : _placeholder(theme),
      ),
    );
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.heic');
  }

  Widget _placeholder(ThemeData theme) {
    return Icon(
      Icons.receipt_long_rounded,
      color: theme.colorScheme.onSurfaceVariant,
      size: 28.sp,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78.w,
            child: Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 13.sp),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: color),
          ),
        ],
      ),
    );
  }
}
