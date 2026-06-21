part of 'telemetry_calc_view.dart';

class FormulaLibraryDetailView extends StatelessWidget {
  final FormulaLibraryEntry entry;

  const FormulaLibraryDetailView({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final color = _formulaDomainColor(entry.domain, semantic);
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.id),
        actions: [
          IconButton(
            tooltip: '复制公式',
            onPressed: () {
              _copyTelemetryText(
                context,
                text: entry.expression,
                message: '已复制：${entry.id}',
              );
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ConstrainedPage(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            children: [
              AppCard(
                padding: EdgeInsets.all(AppSpacing.lg.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm.w,
                      runSpacing: AppSpacing.xs.h,
                      children: [
                        AppPill(
                          label: entry.domain.label,
                          icon: _formulaDomainIcon(entry.domain),
                          color: color,
                        ),
                        AppPill(label: entry.status.label, color: color),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    _FormulaMathBlock(
                      expression: entry.expression,
                      texExpression: entry.texExpression,
                      color: color,
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    Text(
                      entry.explanation,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    Text(
                      entry.sourceFamily,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              const AppSectionHeader(title: '参数说明'),
              SizedBox(height: AppSpacing.md.h),
              for (final variable in entry.variables) ...[
                _FormulaVariableCard(variable: variable, color: color),
                SizedBox(height: AppSpacing.sm.h),
              ],
              if (entry.relatedCalculatorIds.isNotEmpty) ...[
                SizedBox(height: AppSpacing.lg.h),
                const AppSectionHeader(title: '关联工作台'),
                SizedBox(height: AppSpacing.md.h),
                for (final calculatorId in entry.relatedCalculatorIds)
                  _RelatedCalculatorTile(calculatorId: calculatorId),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FormulaVariableCard extends StatelessWidget {
  final FormulaVariableInfo variable;
  final Color color;

  const _FormulaVariableCard({required this.variable, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.md.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              variable.displaySymbol,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variable.meaning,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (variable.concept.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    variable.concept,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                      height: 1.35,
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  variable.units.isEmpty
                      ? '单位：按公式上下文确定'
                      : '单位：${variable.units}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
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

class _RelatedCalculatorTile extends StatelessWidget {
  final String calculatorId;

  const _RelatedCalculatorTile({required this.calculatorId});

  @override
  Widget build(BuildContext context) {
    final definition = TelemetryCalculatorRegistry.byId(calculatorId);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
      child: AppCard(
        onTap: () => _openTelemetryPage<void>(
          context,
          TelemetryCalcDetailView(definition: definition),
        ),
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Row(
          children: [
            Icon(_categoryIcon(definition.category), size: 22.sp),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Text(
                definition.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _FormulaPanel extends StatelessWidget {
  final TelemetryCalculatorDefinition definition;
  final Color color;

  const _FormulaPanel({required this.definition, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formulas = definition.formulas;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions_rounded, color: color, size: 18.sp),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Text(
                  '依据',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '公式与来源',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          for (var i = 0; i < formulas.length; i++) ...[
            _FormulaCompactRow(formula: formulas[i], color: color),
            if (i < formulas.length - 1) SizedBox(height: AppSpacing.sm.h),
          ],
        ],
      ),
    );
  }
}

class _FormulaCompactRow extends StatelessWidget {
  final FormulaReference formula;
  final Color color;

  const _FormulaCompactRow({required this.formula, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: theme.semanticColors.mutedSurface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.semanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formula.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: '复制公式',
                onPressed: () {
                  _copyTelemetryText(
                    context,
                    text: formula.expression,
                    message: '已复制：${formula.title}',
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                style: IconButton.styleFrom(
                  minimumSize: Size(32.w, 32.w),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          _FormulaExpression(expression: formula.expression, color: color),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            formula.source,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaExpression extends StatelessWidget {
  final String expression;
  final Color color;

  const _FormulaExpression({required this.expression, required this.color});

  @override
  Widget build(BuildContext context) {
    return _FormulaMathBlock(
      expression: expression,
      texExpression: expression,
      color: color,
    );
  }
}

class _FormulaMathBlock extends StatelessWidget {
  final String expression;
  final String texExpression;
  final Color color;

  const _FormulaMathBlock({
    required this.expression,
    required this.texExpression,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                texExpression,
                textStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 17.sp,
                ),
                onErrorFallback: (_) => Text(
                  _readableFormulaExpression(expression),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.sp,
                    height: 1.35,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
