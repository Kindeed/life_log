part of 'telemetry_calc_view.dart';

class _Header extends StatelessWidget {
  final AppSemanticColors semantic;

  const _Header({required this.semantic});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: semantic.stats.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.settings_input_antenna_rounded,
              color: semantic.stats,
              size: 28.sp,
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '工程计算工具箱',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  '${TelemetryCalculatorRegistry.formulaCatalogEntryCount} 条公式 / ${TelemetryCalculatorRegistry.definitions.length} 个工作台',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13.sp,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTemplates extends StatelessWidget {
  final List<TelemetryTemplate> templates;
  final ValueChanged<TelemetryTemplate> onTap;
  final ValueChanged<TelemetryTemplate> onLongPress;

  const _RecentTemplates({
    required this.templates,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '最近模板'),
        SizedBox(height: AppSpacing.md.h),
        SizedBox(
          height: 86.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
            itemBuilder: (context, index) {
              final template = templates[index];
              final definition = TelemetryCalculatorRegistry.byId(
                template.calculatorId,
              );
              return SizedBox(
                width: 220.w,
                child: GestureDetector(
                  onLongPress: () => onLongPress(template),
                  child: AppCard(
                    onTap: () => onTap(template),
                    padding: EdgeInsets.all(AppSpacing.md.w),
                    child: Row(
                      children: [
                        Icon(_categoryIcon(definition.category), size: 24.sp),
                        SizedBox(width: AppSpacing.md.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                template.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xs.h),
                              Text(
                                definition.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FormulaDomainChips extends StatelessWidget {
  final List<FormulaDomainSummary> summaries;
  final FormulaDomain value;
  final ValueChanged<FormulaDomain> onChanged;

  const _FormulaDomainChips({
    required this.summaries,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm.w,
      runSpacing: AppSpacing.sm.h,
      children: [
        for (final summary in summaries)
          ChoiceChip(
            selected: summary.domain == value,
            label: Text('${summary.domain.label} ${summary.count}'),
            avatar: Icon(
              _formulaDomainIcon(summary.domain),
              size: 16.sp,
              color: summary.domain == value
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (_) => onChanged(summary.domain),
          ),
      ],
    );
  }
}

class _FormulaLibraryCard extends StatelessWidget {
  final FormulaLibraryEntry entry;
  final VoidCallback onTap;

  const _FormulaLibraryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    return AppCard(
      key: const ValueKey('formulaDirectoryCard'),
      onTap: onTap,
      padding: EdgeInsets.all(AppSpacing.lg.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: semantic.stats.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(
              _formulaDomainIcon(entry.domain),
              color: semantic.stats,
              size: 22.sp,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm.w,
                  runSpacing: AppSpacing.xs.h,
                  children: [
                    AppPill(
                      label: entry.id,
                      icon: Icons.article_outlined,
                      color: semantic.stats,
                    ),
                    AppPill(
                      label: entry.status.label,
                      color: entry.status == FormulaStatus.implemented
                          ? semantic.success
                          : semantic.warning,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  entry.explanation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  entry.domain.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22.sp,
          ),
        ],
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final TelemetryCalculatorDefinition definition;
  final Color color;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.definition,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(AppSpacing.lg.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(_categoryIcon(definition.category), color: color),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Text(
                  definition.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            definition.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
              height: 1.3,
            ),
          ),
          const Spacer(),
          Text(
            definition.standards,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
