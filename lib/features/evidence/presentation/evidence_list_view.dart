import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_metric_grid.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/presentation/evidence_add_action_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_attachment_preview.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/evidence/presentation/evidence_detail_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_legacy_view_adapter.dart';
import 'package:life_log/features/evidence/presentation/evidence_summary_utils.dart';

class EvidenceListView extends StatefulWidget {
  const EvidenceListView({super.key});

  @override
  State<EvidenceListView> createState() => _EvidenceListViewState();
}

class _EvidenceListViewState extends State<EvidenceListView> {
  late final EvidenceCubit evidenceCubit;

  @override
  void initState() {
    super.initState();
    evidenceCubit = serviceLocator<EvidenceCubit>()..start();
  }

  @override
  void dispose() {
    evidenceCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return BlocProvider<EvidenceCubit>.value(
      value: evidenceCubit,
      child: BlocBuilder<EvidenceCubit, EvidenceState>(
        builder: (context, state) {
          if (state.status == EvidenceStatus.loading && state.entries.isEmpty) {
            return const AppLoading(label: '正在加载凭证');
          }

          if (state.entries.isEmpty) {
            return AppEmptyState(
              icon: Icons.receipt_long_rounded,
              title: '暂无凭证',
              message: '发票、付款截图和购买记录会在这里按项目归档',
              actionLabel: '添加凭证',
              onAction: () => showEvidenceAddActions(context),
            );
          }

          final summaries = state.filteredProjectSummaries;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ConstrainedPage(
                      child: _EvidenceOverview(
                        state: state,
                        onSearchChanged: evidenceCubit.updateSearch,
                        onSortModeChanged: evidenceCubit.setSortMode,
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
                        itemCount: summaries.length,
                        separatorBuilder: (_, _) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final summary = summaries[index];
                          return ConstrainedPage(
                            child: _EvidenceProjectCard(
                              summary: summary,
                              semantic: semantic,
                              textSecondary: textSecondary,
                              onTap: () =>
                                  _showProjectEvidence(context, summary),
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
                    heroTag: 'evidence_list_add_fab',
                    backgroundColor: semantic.warning,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    highlightElevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('添加凭证'),
                    onPressed: () => showEvidenceAddActions(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProjectEvidence(
    BuildContext context,
    EvidenceProjectSummary summary,
  ) {
    final theme = Theme.of(context);
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
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
                      Navigator.of(sheetContext).pop();
                      showEvidenceAddActions(
                        context,
                        initialProject: summary.projectName,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.of(sheetContext).pop(),
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
                      onTap: () => showEvidenceDetailSheet(
                        context,
                        legacyEvidenceFromEntry(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenceOverview extends StatelessWidget {
  final EvidenceState state;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<EvidenceSortMode> onSortModeChanged;
  final AppSemanticColors semantic;
  final Color textSecondary;

  const _EvidenceOverview({
    required this.state,
    required this.onSearchChanged,
    required this.onSortModeChanged,
    required this.semantic,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Column(
        children: [
          AppMetricGrid(
            children: [
              AppMetricTile(
                label: '凭证',
                value: state.totalEvidenceCount.toString(),
                icon: Icons.receipt_long_rounded,
                color: semantic.warning,
              ),
              AppMetricTile(
                label: '待报销',
                value: formatMoney(state.totalPendingAmount),
                icon: Icons.pending_actions_rounded,
                color: semantic.expense,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AppTextField(
            onChanged: onSearchChanged,
            hintText: '搜索项目',
            prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
          ),
          SizedBox(height: 10.h),
          AppFilterChipBar<EvidenceSortMode>(
            value: state.sortMode,
            onChanged: onSortModeChanged,
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
    final latest = legacyEvidenceFromEntry(summary.latest);
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(10.w),
      child: Row(
        children: [
          EvidenceAttachmentPreview(item: latest, width: 86.w, height: 86.w),
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
                  evidenceContentSummary(latest) ??
                      '最近 ${_formatDate(summary.latest.evidenceDate)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
  final EvidenceEntry item;
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
    final legacyItem = legacyEvidenceFromEntry(item);
    final statusColor = item.status == EvidenceEntryStatus.reimbursed
        ? Colors.green
        : item.status == EvidenceEntryStatus.submitted
        ? Colors.blue
        : Colors.orange;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(10.w),
      child: Row(
        children: [
          EvidenceAttachmentPreview(
            item: legacyItem,
            width: 58.w,
            height: 58.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidenceDisplayTitle(legacyItem),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  evidenceDisplaySubtitle(legacyItem),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
