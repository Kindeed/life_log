import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_section_header.dart';

import 'telemetry_calculators.dart';
import 'telemetry_template_store.dart';
import 'telemetry_units.dart';

class TelemetryCalcView extends StatefulWidget {
  const TelemetryCalcView({super.key});

  @override
  State<TelemetryCalcView> createState() => _TelemetryCalcViewState();
}

class _TelemetryCalcViewState extends State<TelemetryCalcView> {
  final _store = TelemetryTemplateStore();
  var _category = TelemetryCalculatorCategory.link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final definitions = TelemetryCalculatorRegistry.definitions
        .where((definition) => definition.category == _category)
        .toList(growable: false);
    final recent = _store.loadRecent();

    return Scaffold(
      appBar: AppBar(title: const Text('遥测遥控计算')),
      body: SafeArea(
        child: ConstrainedPage(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(semantic: semantic),
                      if (recent.isNotEmpty) ...[
                        SizedBox(height: 18.h),
                        _RecentTemplates(
                          templates: recent,
                          onTap: _openTemplate,
                        ),
                      ],
                      SizedBox(height: 18.h),
                      const AppSectionHeader(title: '计算分类'),
                      SizedBox(height: 10.h),
                      AppFilterChipBar<TelemetryCalculatorCategory>(
                        value: _category,
                        onChanged: (value) => setState(() => _category = value),
                        items: [
                          for (final category
                              in TelemetryCalculatorCategory.values)
                            AppFilterChipItem(
                              value: category,
                              label: _categoryLabel(category),
                              icon: _categoryIcon(category),
                            ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 30.h),
                sliver: SliverGrid.builder(
                  itemCount: definitions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width >= 720
                        ? 2
                        : 1,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    mainAxisExtent: 132.h,
                  ),
                  itemBuilder: (context, index) {
                    final definition = definitions[index];
                    return _CalculatorCard(
                      definition: definition,
                      color: _categoryColor(definition.category, semantic),
                      onTap: () => Get.to(
                        () => TelemetryCalcDetailView(definition: definition),
                      )?.then((_) => setState(() {})),
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

  void _openTemplate(TelemetryTemplate template) {
    final definition = TelemetryCalculatorRegistry.byId(template.calculatorId);
    Get.to(
      () => TelemetryCalcDetailView(
        definition: definition,
        initialValues: template.values,
      ),
    )?.then((_) => setState(() {}));
  }
}

class TelemetryCalcDetailView extends StatefulWidget {
  final TelemetryCalculatorDefinition definition;
  final Map<String, TelemetryInputValue>? initialValues;

  const TelemetryCalcDetailView({
    super.key,
    required this.definition,
    this.initialValues,
  });

  @override
  State<TelemetryCalcDetailView> createState() =>
      _TelemetryCalcDetailViewState();
}

class _TelemetryCalcDetailViewState extends State<TelemetryCalcDetailView> {
  final _store = TelemetryTemplateStore();
  final _controllers = <String, TextEditingController>{};
  late Map<String, TelemetryInputValue> _values;
  late TelemetryCalculationResult _result;
  var _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _values = {
      ...TelemetryCalculatorRegistry.defaultValues(widget.definition),
      ...?widget.initialValues,
    };
    for (final input in widget.definition.inputs) {
      final value = _values[input.id];
      final text = input.kind == TelemetryInputKind.expression
          ? value?.text ?? input.defaultText ?? ''
          : _formatInputNumber(value?.value ?? input.defaultValue);
      _controllers[input.id] = TextEditingController(text: text);
    }
    _result = TelemetryCalculatorEngine.calculate(widget.definition, _values);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final color = _categoryColor(widget.definition.category, semantic);
    final primaryInputs = widget.definition.inputs
        .where((input) => !input.advanced)
        .toList(growable: false);
    final advancedInputs = widget.definition.inputs
        .where((input) => input.advanced)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_detailTitle(widget.definition)),
        actions: [
          IconButton(
            tooltip: '载入模板',
            onPressed: _showTemplates,
            icon: const Icon(Icons.folder_open_rounded),
          ),
          IconButton(
            tooltip: '恢复默认',
            onPressed: _resetDefaults,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: '保存模板',
            onPressed: _saveTemplate,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ConstrainedPage(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 28.h),
            children: [
              _DetailHeader(definition: widget.definition, color: color),
              SizedBox(height: 12.h),
              AppCard(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CalculationWorkbench(
                      result: _result,
                      color: color,
                      primaryInputs: primaryInputs
                          .map(_buildCompactInput)
                          .toList(growable: false),
                      advancedInputs: advancedInputs
                          .map(_buildCompactInput)
                          .toList(growable: false),
                      showAdvanced: _showAdvanced,
                      onToggleAdvanced: () =>
                          setState(() => _showAdvanced = !_showAdvanced),
                    ),
                    SizedBox(height: 12.h),
                    _FormulaPanel(definition: widget.definition, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInput(TelemetryInputDefinition input) {
    return switch (input.kind) {
      TelemetryInputKind.number => _CompactNumberInput(
        input: input,
        value: _values[input.id]!,
        controller: _controllers[input.id]!,
        onChanged: _updateNumber,
        onUnitChanged: _updateUnit,
      ),
      TelemetryInputKind.select => _CompactSelectInput(
        input: input,
        selectedId: _values[input.id]!.optionId ?? input.defaultOptionId ?? '',
        onChanged: _updateOption,
      ),
      TelemetryInputKind.expression => _CompactExpressionInput(
        input: input,
        controller: _controllers[input.id]!,
        onChanged: _updateExpression,
      ),
    };
  }

  void _updateNumber(String id, String text) {
    final old = _values[id]!;
    _values = {
      ..._values,
      id: TelemetryInputValue(
        value: double.tryParse(text.trim()),
        unitId: old.unitId,
        optionId: old.optionId,
        text: old.text,
      ),
    };
    _recalculate();
  }

  void _updateUnit(String id, String unitId) {
    final old = _values[id]!;
    _values = {
      ..._values,
      id: TelemetryInputValue(
        value: old.value,
        unitId: unitId,
        optionId: old.optionId,
        text: old.text,
      ),
    };
    _recalculate();
  }

  void _updateOption(String id, String optionId) {
    final old = _values[id]!;
    _values = {
      ..._values,
      id: TelemetryInputValue(
        value: old.value,
        unitId: old.unitId,
        optionId: optionId,
        text: old.text,
      ),
    };
    _recalculate();
  }

  void _updateExpression(String id, String text) {
    final old = _values[id]!;
    _values = {
      ..._values,
      id: TelemetryInputValue(
        value: old.value,
        unitId: old.unitId,
        optionId: old.optionId,
        text: text,
      ),
    };
    _recalculate();
  }

  void _recalculate() {
    setState(() {
      _result = TelemetryCalculatorEngine.calculate(widget.definition, _values);
    });
  }

  void _resetDefaults() {
    setState(() {
      _values = TelemetryCalculatorRegistry.defaultValues(widget.definition);
      for (final input in widget.definition.inputs) {
        final value = _values[input.id];
        _controllers[input.id]?.text =
            input.kind == TelemetryInputKind.expression
            ? value?.text ?? ''
            : _formatInputNumber(value?.value);
      }
      _result = TelemetryCalculatorEngine.calculate(widget.definition, _values);
    });
  }

  Future<void> _saveTemplate() async {
    final controller = TextEditingController(
      text: '${widget.definition.title}模板',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存模板'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '模板名称'),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
          FilledButton(
            onPressed: () => Get.back(result: controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await _store.saveTemplate(widget.definition.id, name, _values);
    if (mounted) {
      Get.snackbar('模板已保存', name.trim().isEmpty ? '未命名模板' : name.trim());
    }
  }

  void _showTemplates() {
    final templates = _store.loadTemplates(widget.definition.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (templates.isEmpty) {
          return const SizedBox(
            height: 260,
            child: AppEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: '暂无模板',
              message: '保存常用参数后可以从这里快速载入。',
            ),
          );
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: templates.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: Text(template.name),
                subtitle: Text(_formatDateTime(template.updatedAt)),
                trailing: IconButton(
                  tooltip: '删除模板',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    await _store.deleteTemplate(template.id);
                    if (mounted) {
                      Get.back();
                      _showTemplates();
                    }
                  },
                ),
                onTap: () {
                  setState(() {
                    _values = {
                      ...TelemetryCalculatorRegistry.defaultValues(
                        widget.definition,
                      ),
                      ...template.values,
                    };
                    for (final input in widget.definition.inputs) {
                      final value = _values[input.id];
                      _controllers[input.id]?.text =
                          input.kind == TelemetryInputKind.expression
                          ? value?.text ?? ''
                          : _formatInputNumber(value?.value);
                    }
                    _result = TelemetryCalculatorEngine.calculate(
                      widget.definition,
                      _values,
                    );
                  });
                  Get.back();
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final AppSemanticColors semantic;

  const _Header({required this.semantic});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: semantic.stats.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.settings_input_antenna_rounded,
              color: semantic.stats,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '工程计算工具箱',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '链路、码率、帧格式、测距和自定义公式均在本地计算。',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                    height: 1.35,
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

  const _RecentTemplates({required this.templates, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '最近模板'),
        SizedBox(height: 10.h),
        SizedBox(
          height: 86.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final template = templates[index];
              final definition = TelemetryCalculatorRegistry.byId(
                template.calculatorId,
              );
              return SizedBox(
                width: 220.w,
                child: AppCard(
                  onTap: () => onTap(template),
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Icon(_categoryIcon(definition.category), size: 24.sp),
                      SizedBox(width: 10.w),
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
                            SizedBox(height: 4.h),
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
              );
            },
          ),
        ),
      ],
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
      padding: EdgeInsets.all(14.w),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_categoryIcon(definition.category), color: color),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  definition.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          SizedBox(height: 10.h),
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

class _DetailHeader extends StatelessWidget {
  final TelemetryCalculatorDefinition definition;
  final Color color;

  const _DetailHeader({required this.definition, required this.color});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.fromLTRB(2.w, 4.h, 2.w, 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_categoryIcon(definition.category), color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detailTitle(definition),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  definition.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 7.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _InfoPill(
                      label: _categoryLabel(definition.category),
                      color: color,
                    ),
                    _InfoPill(
                      label: '本地计算',
                      color: Theme.of(context).semanticColors.success,
                    ),
                    _InfoPill(label: definition.standards, color: color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 220.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

class _CalculationWorkbench extends StatelessWidget {
  final TelemetryCalculationResult result;
  final Color color;
  final List<Widget> primaryInputs;
  final List<Widget> advancedInputs;
  final bool showAdvanced;
  final VoidCallback onToggleAdvanced;

  const _CalculationWorkbench({
    required this.result,
    required this.color,
    required this.primaryInputs,
    required this.advancedInputs,
    required this.showAdvanced,
    required this.onToggleAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    final outputPane = _WorkbenchPane(
      title: '输出',
      subtitle: '含工程判断',
      icon: Icons.analytics_outlined,
      color: color,
      emphasized: true,
      child: _CompactResultPanel(result: result, color: color),
    );
    final inputPane = _WorkbenchPane(
      title: '输入',
      subtitle: '实时刷新输出',
      icon: Icons.tune_rounded,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < primaryInputs.length; i++) ...[
            primaryInputs[i],
            if (i < primaryInputs.length - 1) SizedBox(height: 10.h),
          ],
          if (advancedInputs.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _AdvancedToggle(expanded: showAdvanced, onTap: onToggleAdvanced),
            if (showAdvanced) ...[
              SizedBox(height: 10.h),
              for (var i = 0; i < advancedInputs.length; i++) ...[
                advancedInputs[i],
                if (i < advancedInputs.length - 1) SizedBox(height: 10.h),
              ],
            ],
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: inputPane),
            SizedBox(width: 10.w),
            Expanded(flex: 10, child: outputPane),
          ],
        );
      },
    );
  }
}

class _CompactResultPanel extends StatelessWidget {
  final TelemetryCalculationResult result;
  final Color color;

  const _CompactResultPanel({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (result.hasErrors) {
      return _StatusPanel(
        icon: Icons.error_outline_rounded,
        color: theme.colorScheme.error,
        title: '等待有效输入',
        message: result.errors.join('\n'),
      );
    }
    final primary = _primaryOutput(result.outputs);
    final secondary = _secondaryOutput(result.outputs, primary);
    final rest = result.outputs
        .where((output) => output.id != primary.id)
        .take(4)
        .toList(growable: false);
    final insight = _resultInsight(context, result.outputs, primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5.h),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    primary.displayValue,
                    maxLines: 1,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: _outputStatusColor(context, primary, color),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto',
                      height: 1,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                primary.unitLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (secondary != null) ...[
                SizedBox(height: 5.h),
                Text(
                  _compactOutputSummary(secondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 8.h),
        for (var i = 0; i < rest.length; i++) ...[
          _CompactResultRow(output: rest[i], color: color),
          if (i < rest.length - 1) SizedBox(height: 6.h),
        ],
        if (rest.isNotEmpty) SizedBox(height: 8.h),
        _OutputInsightPanel(insight: insight),
      ],
    );
  }
}

class _CompactResultRow extends StatelessWidget {
  final TelemetryCalculationOutput output;
  final Color color;

  const _CompactResultRow({required this.output, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: theme.semanticColors.mutedSurface.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.semanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            output.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${output.displayValue} ${output.unitLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchPane extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final bool emphasized;

  const _WorkbenchPane({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: emphasized
            ? color.withValues(alpha: 0.06)
            : theme.semanticColors.mutedSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: emphasized
              ? color.withValues(alpha: 0.24)
              : theme.semanticColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 17.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3.h),
                Text(
                  message,
                  style: TextStyle(color: color, fontSize: 12.sp, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultInsight {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _ResultInsight({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

class _OutputInsightPanel extends StatelessWidget {
  final _ResultInsight insight;

  const _OutputInsightPanel({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: insight.color, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '工程判断',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: insight.color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  insight.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  insight.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
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

Color _outputStatusColor(
  BuildContext context,
  TelemetryCalculationOutput output,
  Color fallback,
) {
  if ((output.id == 'margin' || output.id == 'guard_margin') &&
      output.value < 0) {
    return Theme.of(context).colorScheme.error;
  }
  if (output.id == 'margin' || output.id == 'guard_margin') {
    return Theme.of(context).semanticColors.success;
  }
  return fallback;
}

_ResultInsight _resultInsight(
  BuildContext context,
  List<TelemetryCalculationOutput> outputs,
  TelemetryCalculationOutput primary,
) {
  final theme = Theme.of(context);
  final margin = _findOutput(outputs, 'margin');
  if (margin != null) {
    return _marginInsight(
      margin,
      passTitle: '链路余量满足要求',
      failTitle: '链路余量不足',
      passColor: theme.semanticColors.success,
      failColor: theme.colorScheme.error,
    );
  }

  final guardMargin = _findOutput(outputs, 'guard_margin');
  if (guardMargin != null) {
    final passed = guardMargin.value >= 0;
    final value = _outputValueLabel(guardMargin, absolute: !passed);
    return _ResultInsight(
      icon: passed
          ? Icons.check_circle_outline_rounded
          : Icons.warning_amber_rounded,
      color: passed ? theme.semanticColors.success : theme.colorScheme.error,
      title: passed ? '保护带覆盖误差' : '保护带不足',
      message: passed ? '余量 $value，覆盖误差。' : '缺口 $value，需加保护带。',
    );
  }

  return _ResultInsight(
    icon: Icons.check_circle_outline_rounded,
    color: theme.semanticColors.success,
    title: '实时计算完成',
    message: '结果已更新，可继续调参。',
  );
}

String _compactOutputSummary(TelemetryCalculationOutput output) {
  final label = switch (output.id) {
    'total_error' => '总频偏',
    'oscillator_error' => '频源误差',
    'guard_margin' => '保护余量',
    _ => output.label,
  };
  return '$label ${_outputValueLabel(output)}';
}

_ResultInsight _marginInsight(
  TelemetryCalculationOutput output, {
  required String passTitle,
  required String failTitle,
  required Color passColor,
  required Color failColor,
}) {
  final passed = output.value >= 0;
  final value = _outputValueLabel(output);
  final message = passed ? '余量 $value，配置可用。' : '余量 $value，需调整预算。';
  return _ResultInsight(
    icon: passed
        ? Icons.check_circle_outline_rounded
        : Icons.warning_amber_rounded,
    color: passed ? passColor : failColor,
    title: passed ? passTitle : failTitle,
    message: message,
  );
}

String _outputValueLabel(
  TelemetryCalculationOutput output, {
  bool absolute = false,
}) {
  final value = absolute ? output.value.abs() : output.value;
  final displayValue = _formatOutputValue(value, output.precision);
  return '$displayValue ${output.unitLabel}'.trim();
}

String _formatOutputValue(double value, int precision) {
  if (value.abs() >= 100000 || value.abs() < 0.001 && value != 0) {
    return value.toStringAsExponential(precision);
  }
  return value.toStringAsFixed(precision);
}

TelemetryCalculationOutput? _findOutput(
  List<TelemetryCalculationOutput> outputs,
  String id,
) {
  for (final output in outputs) {
    if (output.id == id) return output;
  }
  return null;
}

TelemetryCalculationOutput _primaryOutput(
  List<TelemetryCalculationOutput> outputs,
) {
  const priority = [
    'margin',
    'guard_margin',
    'occupied_bandwidth',
    'bit_rate',
    'coded_rate',
    'range_resolution',
    'total_time',
    'effective_rate',
    'doppler_shift',
    'result',
    'ebn0',
    'cn0',
  ];
  for (final id in priority) {
    final matched = outputs.where((output) => output.id == id);
    if (matched.isNotEmpty) return matched.first;
  }
  return outputs.first;
}

TelemetryCalculationOutput? _secondaryOutput(
  List<TelemetryCalculationOutput> outputs,
  TelemetryCalculationOutput primary,
) {
  const priority = [
    'ebn0',
    'cn0',
    'symbol_rate',
    'frame_efficiency',
    'total_error',
    'effective_rate',
    'round_trip_delay',
    'occupied_bandwidth',
  ];
  for (final id in priority) {
    final matched = outputs.where(
      (output) => output.id == id && output.id != primary.id,
    );
    if (matched.isNotEmpty) return matched.first;
  }
  final rest = outputs.where((output) => output.id != primary.id);
  return rest.isEmpty ? null : rest.first;
}

class _CompactNumberInput extends StatelessWidget {
  final TelemetryInputDefinition input;
  final TelemetryInputValue value;
  final TextEditingController controller;
  final void Function(String id, String text) onChanged;
  final void Function(String id, String unitId) onUnitChanged;

  const _CompactNumberInput({
    required this.input,
    required this.value,
    required this.controller,
    required this.onChanged,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invalid =
        controller.text.trim().isEmpty ||
        double.tryParse(controller.text.trim()) == null;
    return _CompactInputShell(
      label: input.label,
      helper: input.helper,
      invalid: invalid,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final valueField = TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: (text) => onChanged(input.id, text),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: 'Roboto',
              height: 1,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          );
          final unitButton = _UnitMenuButton(
            value: value.unitId,
            units: input.units,
            onChanged: (unitId) => onUnitChanged(input.id, unitId),
            compact: true,
          );
          if (constraints.maxWidth < 128.w) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                valueField,
                SizedBox(height: 6.h),
                Align(alignment: Alignment.centerRight, child: unitButton),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: valueField),
              SizedBox(width: 6.w),
              unitButton,
            ],
          );
        },
      ),
    );
  }
}

class _CompactSelectInput extends StatelessWidget {
  final TelemetryInputDefinition input;
  final String selectedId;
  final void Function(String id, String optionId) onChanged;

  const _CompactSelectInput({
    required this.input,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = input.options.firstWhere(
      (option) => option.id == selectedId,
      orElse: () => input.options.first,
    );
    return _CompactInputShell(
      label: input.label,
      helper: input.helper,
      child: _OptionMenuButton(
        selected: selected,
        options: input.options,
        onChanged: (optionId) => onChanged(input.id, optionId),
      ),
    );
  }
}

class _CompactExpressionInput extends StatelessWidget {
  final TelemetryInputDefinition input;
  final TextEditingController controller;
  final void Function(String id, String text) onChanged;

  const _CompactExpressionInput({
    required this.input,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CompactInputShell(
      label: input.label,
      helper: input.helper,
      child: TextField(
        controller: controller,
        maxLines: 2,
        minLines: 1,
        keyboardType: TextInputType.text,
        onChanged: (text) => onChanged(input.id, text),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'Roboto',
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _CompactInputShell extends StatelessWidget {
  final String label;
  final String helper;
  final bool invalid;
  final Widget child;

  const _CompactInputShell({
    required this.label,
    required this.helper,
    required this.child,
    this.invalid = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 9.h),
      decoration: BoxDecoration(
        color: theme.semanticColors.mutedSurface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: invalid
              ? theme.colorScheme.error
              : theme.semanticColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (helper.isNotEmpty)
                Tooltip(
                  message: helper,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          SizedBox(height: 5.h),
          child,
        ],
      ),
    );
  }
}

class _UnitMenuButton extends StatelessWidget {
  final String value;
  final List<String> units;
  final ValueChanged<String> onChanged;
  final bool compact;

  const _UnitMenuButton({
    required this.value,
    required this.units,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: '选择单位',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final unitId in units)
          PopupMenuItem(
            value: unitId,
            child: Text(UnitCatalog.unit(unitId).label),
          ),
      ],
      child: Container(
        constraints: BoxConstraints(minWidth: compact ? 48.w : 70.w),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5.w : 10.w,
          vertical: compact ? 6.h : 7.h,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.semanticColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                UnitCatalog.unit(value).label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: compact ? 2.w : 4.w),
            Icon(Icons.expand_more_rounded, size: compact ? 14.sp : 16.sp),
          ],
        ),
      ),
    );
  }
}

class _OptionMenuButton extends StatelessWidget {
  final TelemetryOption selected;
  final List<TelemetryOption> options;
  final ValueChanged<String> onChanged;

  const _OptionMenuButton({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: '选择参数',
      initialValue: selected.id,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(value: option.id, child: Text(option.label)),
      ],
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.semanticColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, size: 16.sp),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                selected.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 16.sp),
          ],
        ),
      ),
    );
  }
}

class _AdvancedToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _AdvancedToggle({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            const Expanded(child: AppSectionHeader(title: '高级参数')),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
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
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions_rounded, color: color, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '依据',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
          SizedBox(height: 8.h),
          for (var i = 0; i < formulas.length; i++) ...[
            _FormulaCompactRow(formula: formulas[i], color: color),
            if (i < formulas.length - 1) SizedBox(height: 8.h),
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
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: theme.semanticColors.mutedSurface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: '复制公式',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: formula.expression));
                  Get.snackbar('已复制', formula.title);
                },
                icon: const Icon(Icons.copy_rounded),
                style: IconButton.styleFrom(
                  minimumSize: Size(32.w, 32.w),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          _FormulaExpression(expression: formula.expression, color: color),
          SizedBox(height: 6.h),
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: SelectableText.rich(
        TextSpan(children: _formulaSpans(context, expression, color)),
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13.sp,
          height: 1.35,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

List<TextSpan> _formulaSpans(
  BuildContext context,
  String expression,
  Color color,
) {
  final theme = Theme.of(context);
  final secondary = theme.colorScheme.onSurfaceVariant;
  final spans = <TextSpan>[];
  final buffer = StringBuffer();

  void flushBuffer() {
    if (buffer.isEmpty) return;
    final text = buffer.toString();
    buffer.clear();
    final isNumber = double.tryParse(text) != null;
    spans.add(
      TextSpan(
        text: text,
        style: TextStyle(
          color: isNumber ? color : theme.colorScheme.onSurface,
          fontWeight: isNumber ? FontWeight.w800 : FontWeight.w700,
          fontStyle: isNumber ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }

  for (final rune in expression.runes) {
    final char = String.fromCharCode(rune);
    if ('+-*/=^(),'.contains(char)) {
      flushBuffer();
      spans.add(
        TextSpan(
          text: ' $char ',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      );
    } else if (char == '_') {
      flushBuffer();
      spans.add(
        TextSpan(
          text: '_',
          style: TextStyle(color: secondary, fontWeight: FontWeight.w600),
        ),
      );
    } else {
      buffer.write(char);
    }
  }
  flushBuffer();
  return spans;
}

String _categoryLabel(TelemetryCalculatorCategory category) {
  return switch (category) {
    TelemetryCalculatorCategory.link => '链路',
    TelemetryCalculatorCategory.rate => '码率',
    TelemetryCalculatorCategory.frame => 'PCM',
    TelemetryCalculatorCategory.coding => '编码',
    TelemetryCalculatorCategory.command => '遥控',
    TelemetryCalculatorCategory.ranging => '测距',
    TelemetryCalculatorCategory.frequency => '频率',
    TelemetryCalculatorCategory.custom => '公式',
  };
}

String _detailTitle(TelemetryCalculatorDefinition definition) {
  return switch (definition.id) {
    'link_budget' => '链路预算',
    'rate_bandwidth' => '带宽计算',
    'pcm_frame' => 'PCM 计算',
    'channel_coding' => '编码开销',
    'telecommand' => '遥控吞吐',
    'ranging' => '测距时延',
    'doppler' => '频率校核',
    'custom_formula' => '自定义公式',
    _ => definition.title,
  };
}

IconData _categoryIcon(TelemetryCalculatorCategory category) {
  return switch (category) {
    TelemetryCalculatorCategory.link => Icons.settings_input_antenna_rounded,
    TelemetryCalculatorCategory.rate => Icons.speed_rounded,
    TelemetryCalculatorCategory.frame => Icons.view_timeline_rounded,
    TelemetryCalculatorCategory.coding => Icons.memory_rounded,
    TelemetryCalculatorCategory.command => Icons.keyboard_command_key_rounded,
    TelemetryCalculatorCategory.ranging => Icons.social_distance_rounded,
    TelemetryCalculatorCategory.frequency => Icons.graphic_eq_rounded,
    TelemetryCalculatorCategory.custom => Icons.functions_rounded,
  };
}

Color _categoryColor(TelemetryCalculatorCategory category, dynamic semantic) {
  return switch (category) {
    TelemetryCalculatorCategory.link => semantic.stats,
    TelemetryCalculatorCategory.rate => semantic.work,
    TelemetryCalculatorCategory.frame => semantic.project,
    TelemetryCalculatorCategory.coding => semantic.expense,
    TelemetryCalculatorCategory.command => semantic.warning,
    TelemetryCalculatorCategory.ranging => semantic.success,
    TelemetryCalculatorCategory.frequency => semantic.stats,
    TelemetryCalculatorCategory.custom => semantic.project,
  };
}

String _formatInputNumber(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}
