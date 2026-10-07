import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_tab_header.dart';
import 'package:life_log/common/widgets/app_page_route.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_load_failure.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/photo/presentation/create_project_sheet.dart';
import 'package:life_log/features/project/presentation/project_detail_view.dart';

class PhotoView extends StatefulWidget {
  const PhotoView({super.key});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  late final EvidenceCubit evidenceCubit;
  late final ExpenseRecordCubit expenseCubit;
  late final ProjectCubit projectCubit;
  late final PhotoCubit photoCubit;

  @override
  void initState() {
    super.initState();
    evidenceCubit = serviceLocator<EvidenceCubit>()..start();
    expenseCubit = serviceLocator<ExpenseRecordCubit>()..start();
    projectCubit = serviceLocator<ProjectCubit>()..start();
    photoCubit = serviceLocator<PhotoCubit>()..start();
  }

  @override
  void dispose() {
    evidenceCubit.close();
    expenseCubit.close();
    projectCubit.close();
    photoCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ConstrainedPage(
              child: AppTabHeader(
                title: '项目',
                eyebrow: '现场资料与进展',
                action: AppTabAction(
                  label: '创建项目',
                  icon: Icons.create_new_folder_rounded,
                  onPressed: _openCreateProjectSheet,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<ProjectCubit, ProjectState>(
                bloc: projectCubit,
                builder: (context, projectState) {
                  return BlocBuilder<PhotoCubit, PhotoState>(
                    bloc: photoCubit,
                    builder: (context, photoState) {
                      return BlocBuilder<EvidenceCubit, EvidenceState>(
                        bloc: evidenceCubit,
                        builder: (context, evidenceState) {
                          return BlocBuilder<
                            ExpenseRecordCubit,
                            ExpenseRecordState
                          >(
                            bloc: expenseCubit,
                            builder: (context, expenseState) {
                              final isLoading =
                                  (photoState.status == PhotoStatus.loading &&
                                      photoState.entries.isEmpty) ||
                                  (projectState.status ==
                                          ProjectReadStatus.loading &&
                                      projectState.entries.isEmpty) ||
                                  (evidenceState.status ==
                                          EvidenceStatus.loading &&
                                      evidenceState.entries.isEmpty) ||
                                  (expenseState.status ==
                                          ExpenseRecordStatus.loading &&
                                      expenseState.entries.isEmpty);
                              final hasFailure =
                                  projectState.failure != null ||
                                  photoState.failure != null ||
                                  evidenceState.failure != null ||
                                  expenseState.failure != null;
                              final expenseRecords = expenseState.entries;
                              final projectCount =
                                  projectState.totalProjectCount;

                              if (isLoading) {
                                return const AppLoading(label: "正在加载项目");
                              }

                              final projects = _projectSummaries(
                                projects: projectState.entries,
                                photoSummaries: photoState.projectSummaries,
                                evidence: evidenceState.entries,
                                expenses: expenseRecords,
                                query: photoState.searchQuery,
                                sortMode: photoState.sortMode,
                              );

                              if (projectCount == 0 &&
                                  projects.isEmpty &&
                                  hasFailure) {
                                return AppLoadFailure(
                                  message: '暂时无法读取项目，请重试。',
                                  onRetry: _reloadProjectOverview,
                                );
                              }
                              if (projectCount == 0 && projects.isEmpty) {
                                return const AppEmptyState(
                                  icon: Icons.folder_open_rounded,
                                  title: "还没有项目",
                                  message: "使用上方「创建项目」建立项目，再添加照片和凭证。",
                                );
                              }

                              return RefreshIndicator(
                                onRefresh: _refreshProjectOverview,
                                child: CustomScrollView(
                                  key: const PageStorageKey('project-scroll'),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    if (hasFailure)
                                      SliverToBoxAdapter(
                                        child: ConstrainedPage(
                                          child: AppLoadFailure(
                                            compact: true,
                                            message: '部分数据未能刷新，项目汇总可能不完整。',
                                            onRetry: _reloadProjectOverview,
                                          ),
                                        ),
                                      ),
                                    SliverToBoxAdapter(
                                      child: ConstrainedPage(
                                        child: _ProjectOverview(
                                          photoCount:
                                              photoState.totalPhotoCount,
                                          projectCount: projectCount,
                                          expenseRecords: expenseRecords,
                                          semantic: semantic,
                                          textSecondary: textSecondary,
                                          sortMode: photoState.sortMode,
                                          onSearchChanged:
                                              photoCubit.updateSearch,
                                          onSortModeChanged:
                                              photoCubit.setSortMode,
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
                                        padding: const EdgeInsets.fromLTRB(
                                          22,
                                          10,
                                          22,
                                          28,
                                        ),
                                        sliver: SliverList.separated(
                                          itemCount: projects.length,
                                          separatorBuilder: (_, _) =>
                                              SizedBox(height: 12.h),
                                          itemBuilder: (context, index) {
                                            final project = projects[index];
                                            return ConstrainedPage(
                                              child: _ProjectCard(
                                                summary: project,
                                                evidenceItems: evidenceState
                                                    .entriesForProject(
                                                      project.name,
                                                    ),
                                                pendingAmount: evidenceState
                                                    .pendingAmountForProject(
                                                      project.name,
                                                    ),
                                                expenseTotal:
                                                    _expenseTotalForProject(
                                                      expenseRecords,
                                                      project.name,
                                                    ),
                                                isDark: isDark,
                                                semantic: semantic,
                                                textSecondary: textSecondary,
                                                onTap: () =>
                                                    _openProjectGallery(
                                                      project.name,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshProjectOverview() async {
    await Future.wait([
      photoCubit.loadEntries(),
      projectCubit.loadEntries(),
      evidenceCubit.loadEntries(),
      expenseCubit.loadEntries(),
    ]);
  }

  void _reloadProjectOverview() {
    photoCubit.loadEntries();
    projectCubit.loadEntries();
    evidenceCubit.loadEntries();
    expenseCubit.loadEntries();
  }

  double _expenseTotalForProject(
    List<ExpenseRecordEntry> records,
    String project,
  ) {
    return records
        .where((record) => record.projectName == project)
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  void _openCreateProjectSheet() {
    showCreateProjectSheet(
      context,
      onCreated: (project) async {
        await photoCubit.loadEntries();
        await projectCubit.loadEntries();
        await evidenceCubit.loadEntries();
        await expenseCubit.loadEntries();
        if (!mounted) return;
        await _openProjectGallery(project.name);
      },
    );
  }

  Future<void> _openProjectGallery(String projectName) {
    return Navigator.of(context).push<void>(
      appPageRoute<void>(
        context,
        ProjectDetailView(
          projectName: projectName,
          projectId: projectCubit.state.entryNamed(projectName)?.id,
          projectCubit: projectCubit,
          photoCubit: photoCubit,
          evidenceCubit: evidenceCubit,
          expenseCubit: expenseCubit,
        ),
      ),
    );
  }

  List<PhotoProjectSummary> _projectSummaries({
    required List<ProjectEntry> projects,
    required List<PhotoProjectSummary> photoSummaries,
    required List<EvidenceEntry> evidence,
    required List<ExpenseRecordEntry> expenses,
    required String query,
    required PhotoProjectSortMode sortMode,
  }) {
    final names = <String>{};
    names.addAll(projects.map((project) => project.name));
    final summariesByName = <String, PhotoProjectSummary>{};
    for (final summary in photoSummaries) {
      // PhotoState's fallback Default group can contain legacy unassigned
      // photos. Keep this overview's explicit project relationship unchanged.
      if (summary.name != 'Default' ||
          !summary.photos.any((photo) => photo.projectName == null)) {
        summariesByName[summary.name] = summary;
        continue;
      }
      final assigned = summary.photos
          .where((photo) => photo.projectName == summary.name)
          .toList();
      if (assigned.isEmpty) continue;
      summariesByName[summary.name] = PhotoProjectSummary(
        name: summary.name,
        photos: assigned,
        latestPhoto: assigned.first,
        deviceCount: assigned
            .map((photo) => photo.deviceName)
            .whereType<String>()
            .where((name) => name.trim().isNotEmpty)
            .toSet()
            .length,
        untitledCount: assigned
            .where((photo) => photo.description?.trim().isNotEmpty != true)
            .length,
      );
    }
    names.addAll(summariesByName.keys);
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
          return summariesByName[name] ??
              PhotoProjectSummary(
                name: name,
                photos: const [],
                latestPhoto: null,
                deviceCount: 0,
                untitledCount: 0,
              );
        })
        .toList();

    switch (sortMode) {
      case PhotoProjectSortMode.recent:
        summaries.sort(
          (a, b) => (b.latestPhoto?.createdAt ?? DateTime(0)).compareTo(
            a.latestPhoto?.createdAt ?? DateTime(0),
          ),
        );
        break;
      case PhotoProjectSortMode.count:
        summaries.sort((a, b) {
          final countCompare = b.photoCount.compareTo(a.photoCount);
          if (countCompare != 0) return countCompare;
          return a.name.compareTo(b.name);
        });
        break;
      case PhotoProjectSortMode.name:
        summaries.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return summaries;
  }
}

class _ProjectOverview extends StatelessWidget {
  final int projectCount;
  final int photoCount;
  final List<ExpenseRecordEntry> expenseRecords;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final PhotoProjectSortMode sortMode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PhotoProjectSortMode> onSortModeChanged;

  const _ProjectOverview({
    required this.projectCount,
    required this.photoCount,
    required this.expenseRecords,
    required this.semantic,
    required this.textSecondary,
    required this.sortMode,
    required this.onSearchChanged,
    required this.onSortModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '项目支出',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  formatMoney(
                    expenseRecords.fold(0.0, (sum, item) => sum + item.amount),
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Text(
                      '$projectCount 个项目',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '$photoCount 张照片',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          AppTextField(
            onChanged: onSearchChanged,
            hintText: "搜索项目",
            prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
          ),
          SizedBox(height: 10.h),
          AppFilterChipBar<PhotoProjectSortMode>(
            value: sortMode,
            columns: 3,
            onChanged: onSortModeChanged,
            items: const [
              AppFilterChipItem(
                value: PhotoProjectSortMode.recent,
                label: "最近",
                icon: Icons.schedule_rounded,
              ),
              AppFilterChipItem(
                value: PhotoProjectSortMode.count,
                label: "数量",
                icon: Icons.photo_library_rounded,
              ),
              AppFilterChipItem(
                value: PhotoProjectSortMode.name,
                label: "名称",
                icon: Icons.sort_by_alpha_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final PhotoProjectSummary summary;
  final List<EvidenceEntry> evidenceItems;
  final double pendingAmount;
  final double expenseTotal;
  final bool isDark;
  final AppSemanticColors semantic;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.summary,
    required this.evidenceItems,
    required this.pendingAmount,
    required this.expenseTotal,
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
  final PhotoProjectSummary summary;
  final bool isDark;

  const _ProjectCover({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final photos = summary.photos.take(4).toList();
    final physicalWidth = (98.w * MediaQuery.devicePixelRatioOf(context))
        .ceil();

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
                cacheWidth: physicalWidth,
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
                    cacheWidth: (physicalWidth / 2).ceil(),
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
