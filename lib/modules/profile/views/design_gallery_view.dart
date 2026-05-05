import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';

import '../../../common/layout/constrained_page.dart';
import '../../../common/theme/app_radius.dart';
import '../../../common/theme/app_spacing.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/app_empty_state.dart';
import '../../../common/widgets/app_filter_chip_bar.dart';
import '../../../common/widgets/app_loading.dart';
import '../../../common/widgets/app_metric_tile.dart';
import '../../../common/widgets/app_section_header.dart';
import '../../../common/widgets/app_skeleton.dart';
import '../../../common/widgets/app_text_field.dart';

class DesignGalleryView extends StatefulWidget {
  const DesignGalleryView({super.key});

  @override
  State<DesignGalleryView> createState() => _DesignGalleryViewState();
}

class _DesignGalleryViewState extends State<DesignGalleryView> {
  String _selectedChip = 'recent';

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).semanticColors;

    return Scaffold(
      appBar: AppBar(title: const Text('UI Gallery')),
      body: ConstrainedPage(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const AppSectionHeader(title: 'Semantic Colors'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ColorSwatch(label: 'Work', color: semantic.work),
                _ColorSwatch(label: 'Expense', color: semantic.expense),
                _ColorSwatch(label: 'Project', color: semantic.project),
                _ColorSwatch(label: 'Stats', color: semantic.stats),
                _ColorSwatch(label: 'Success', color: semantic.success),
                _ColorSwatch(label: 'Warning', color: semantic.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: 'Cards & Metrics'),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppMetricTile(
                    label: '项目',
                    value: '12',
                    icon: Icons.folder_special_rounded,
                    color: semantic.project,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppMetricTile(
                    label: '待处理',
                    value: '3',
                    icon: Icons.warning_rounded,
                    color: semantic.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AppCard',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('统一圆角、边框、背景和点击区域。'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: 'Buttons'),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'Primary',
              icon: Icons.check_rounded,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: 'Secondary',
              icon: Icons.tune_rounded,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.text(label: 'Text', onPressed: () {}),
            const SizedBox(height: AppSpacing.sm),
            AppButton.destructive(
              label: 'Destructive',
              icon: Icons.delete_outline,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: 'Inputs'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(
              labelText: '服务名称',
              hintText: '如: 云存储',
              textInputAction: TextInputAction.next,
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(
              labelText: '备注',
              hintText: '支持多行输入',
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: 'Filters'),
            const SizedBox(height: AppSpacing.md),
            AppFilterChipBar<String>(
              value: _selectedChip,
              onChanged: (value) => setState(() => _selectedChip = value),
              items: const [
                AppFilterChipItem(
                  value: 'recent',
                  label: '最近',
                  icon: Icons.schedule_rounded,
                ),
                AppFilterChipItem(
                  value: 'count',
                  label: '数量',
                  icon: Icons.photo_library_rounded,
                ),
                AppFilterChipItem(
                  value: 'name',
                  label: '名称',
                  icon: Icons.sort_by_alpha_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: 'Loading & Skeleton'),
            const SizedBox(height: AppSpacing.md),
            const AppCard(child: AppLoading(label: '加载中')),
            const SizedBox(height: AppSpacing.md),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: double.infinity, height: 18),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton(width: 160, height: 14),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton(width: 220, height: 14),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 260,
              child: AppEmptyState(
                icon: Icons.inbox_outlined,
                title: '空状态',
                message: '用于列表、搜索结果和无数据页面。',
                actionLabel: '创建',
                onAction: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorSwatch({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
