import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_metric_tile.dart';
import 'package:life_log/common/widgets/app_section_header.dart';
import 'package:life_log/common/widgets/app_text_field.dart';

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
        title: Text(widget.definition.title),
        actions: [
          IconButton(
            tooltip: '载入模板',
            onPressed: _showTemplates,
            icon: const Icon(Icons.folder_open_rounded),
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
              SizedBox(height: 18.h),
              _ResultPanel(result: _result, color: color),
              SizedBox(height: 18.h),
              const AppSectionHeader(title: '必要参数'),
              SizedBox(height: 10.h),
              ...primaryInputs
                  .map(_buildInput)
                  .expand((widget) => [widget, SizedBox(height: 12.h)]),
              if (advancedInputs.isNotEmpty) ...[
                _AdvancedToggle(
                  expanded: _showAdvanced,
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                ),
                if (_showAdvanced) ...[
                  SizedBox(height: 12.h),
                  ...advancedInputs
                      .map(_buildInput)
                      .expand((widget) => [widget, SizedBox(height: 12.h)]),
                ],
              ],
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: '恢复默认',
                      icon: Icons.refresh_rounded,
                      onPressed: _resetDefaults,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AppButton.primary(
                      label: '保存模板',
                      icon: Icons.bookmark_add_outlined,
                      onPressed: _saveTemplate,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              _FormulaPanel(definition: widget.definition),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TelemetryInputDefinition input) {
    return switch (input.kind) {
      TelemetryInputKind.number => _NumberInput(
        input: input,
        value: _values[input.id]!,
        controller: _controllers[input.id]!,
        onChanged: _updateNumber,
        onUnitChanged: _updateUnit,
      ),
      TelemetryInputKind.select => _SelectInput(
        input: input,
        selectedId: _values[input.id]?.optionId ?? input.defaultOptionId!,
        onChanged: _updateOption,
      ),
      TelemetryInputKind.expression => _ExpressionInput(
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
  final dynamic semantic;

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
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
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
                  definition.subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  definition.standards,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
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

class _ResultPanel extends StatelessWidget {
  final TelemetryCalculationResult result;
  final Color color;

  const _ResultPanel({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    if (result.hasErrors) {
      return AppCard(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                result.errors.join('\n'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '计算结果'),
        SizedBox(height: 10.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.outputs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                mainAxisExtent: 98.h,
              ),
              itemBuilder: (context, index) {
                final output = result.outputs[index];
                return AppMetricTile(
                  label: output.label,
                  value: '${output.displayValue} ${output.unitLabel}',
                  icon: Icons.functions_rounded,
                  color: output.id == 'margin' || output.id == 'guard_margin'
                      ? output.value < 0
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).semanticColors.success
                      : color,
                );
              },
            );
          },
        ),
        if (result.warnings.isNotEmpty) ...[
          SizedBox(height: 10.h),
          AppCard(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).semanticColors.warning,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    result.warnings.join('\n'),
                    style: TextStyle(
                      color: Theme.of(context).semanticColors.warning,
                      fontSize: 12.sp,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TelemetryInputDefinition input;
  final TelemetryInputValue value;
  final TextEditingController controller;
  final void Function(String id, String text) onChanged;
  final void Function(String id, String unitId) onUnitChanged;

  const _NumberInput({
    required this.input,
    required this.value,
    required this.controller,
    required this.onChanged,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      labelText: input.label,
      hintText: input.helper.isEmpty ? null : input.helper,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      onChanged: (text) => onChanged(input.id, text),
      suffixIcon: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.unitId,
          padding: EdgeInsets.only(right: 8.w),
          items: [
            for (final unitId in input.units)
              DropdownMenuItem(
                value: unitId,
                child: Text(UnitCatalog.unit(unitId).label),
              ),
          ],
          onChanged: (unitId) {
            if (unitId != null) onUnitChanged(input.id, unitId);
          },
        ),
      ),
    );
  }
}

class _SelectInput extends StatelessWidget {
  final TelemetryInputDefinition input;
  final String selectedId;
  final void Function(String id, String optionId) onChanged;

  const _SelectInput({
    required this.input,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            input.label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10.h),
          AppFilterChipBar<String>(
            value: selectedId,
            onChanged: (value) => onChanged(input.id, value),
            items: [
              for (final option in input.options)
                AppFilterChipItem(value: option.id, label: option.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpressionInput extends StatelessWidget {
  final TelemetryInputDefinition input;
  final TextEditingController controller;
  final void Function(String id, String text) onChanged;

  const _ExpressionInput({
    required this.input,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      labelText: input.label,
      hintText: input.helper,
      maxLines: 3,
      keyboardType: TextInputType.text,
      onChanged: (text) => onChanged(input.id, text),
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

  const _FormulaPanel({required this.definition});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '公式与依据'),
        SizedBox(height: 10.h),
        for (final formula in definition.formulas)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: AppCard(
              padding: EdgeInsets.all(14.w),
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
                          Clipboard.setData(
                            ClipboardData(text: formula.expression),
                          );
                          Get.snackbar('已复制', formula.title);
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                  SelectableText(formula.expression),
                  SizedBox(height: 8.h),
                  Text(
                    formula.source,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                    ),
                  ),
                  if (formula.note.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(formula.note),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
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
