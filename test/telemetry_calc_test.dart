import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_calc_view.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_calculators.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_formula_engine.dart';
import 'package:life_log/modules/telemetry_calc/formula_library.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_template_store.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_units.dart';

void main() {
  group('UnitCatalog', () {
    test('converts common engineering units', () {
      expect(UnitCatalog.convert(1, 'GHz', 'MHz'), 1000);
      expect(UnitCatalog.convert(30, 'dBm', 'dBW'), 0);
      expect(UnitCatalog.convert(0.875, 'ratio', 'percent'), 87.5);
      expect(UnitCatalog.convert(100, 'percent', 'ratio'), 1);
      expect(UnitCatalog.convert(500, 'K', 'dBK'), closeTo(26.9897, 1e-4));
      expect(UnitCatalog.convert(26.9897, 'dBK', 'K'), closeTo(500, 0.02));
    });

    test('rejects incompatible dimensions', () {
      expect(() => UnitCatalog.convert(1, 'km', 'MHz'), throwsArgumentError);
      expect(() => UnitCatalog.convert(1, 'dBK', 'dBW'), throwsArgumentError);
    });
  });

  group('FormulaEngine', () {
    test('evaluates safe expressions', () {
      final result = FormulaEngine().evaluate(
        '10*log10(a+b) + sqrt(c^2) - abs(d)',
        {'a': 8, 'b': 2, 'c': 3, 'd': -1},
      );

      expect(result, closeTo(12, 1e-9));
    });

    test('rejects unsafe or invalid expressions', () {
      expect(
        () => FormulaEngine().evaluate('log10(0)', {'a': 1}),
        throwsA(isA<FormulaEvaluationException>()),
      );
      expect(
        () => FormulaEngine().evaluate('a / 0', {'a': 1}),
        throwsA(isA<FormulaEvaluationException>()),
      );
      expect(
        () => FormulaEngine().evaluate('process.exit()', {'a': 1}),
        throwsA(isA<FormulaEvaluationException>()),
      );
    });
  });

  group('TelemetryCalculatorEngine', () {
    test('computes link budget margin and core outputs', () {
      final definition = TelemetryCalculatorRegistry.byId('link_budget');
      final result = TelemetryCalculatorEngine.calculate(
        definition,
        TelemetryCalculatorRegistry.defaultValues(definition),
      );

      expect(result.errors, isEmpty);
      final outputs = {
        for (final output in result.outputs) output.id: output.value,
      };
      expect(outputs['eirp'], closeTo(29, 1e-9));
      expect(outputs['fspl'], closeTo(159.30, 0.02));
      expect(outputs['cn0'], closeTo(101.31, 0.02));
      expect(outputs['ebn0'], closeTo(41.31, 0.02));
      expect(outputs['margin'], greaterThan(35));
    });

    test('computes PCM frame efficiency using ratio to percent conversion', () {
      final definition = TelemetryCalculatorRegistry.byId('pcm_frame');
      final result = TelemetryCalculatorEngine.calculate(
        definition,
        TelemetryCalculatorRegistry.defaultValues(definition),
      );

      expect(result.errors, isEmpty);
      final efficiency = result.outputs.firstWhere(
        (output) => output.id == 'frame_efficiency',
      );
      expect(efficiency.toString(), isNotEmpty);
      expect(efficiency.value, closeTo(99.2248, 0.001));
      expect(efficiency.unitId, 'percent');
    });

    test('computes rate bandwidth with percent overhead as a ratio', () {
      final definition = TelemetryCalculatorRegistry.byId('rate_bandwidth');
      final result = TelemetryCalculatorEngine.calculate(
        definition,
        TelemetryCalculatorRegistry.defaultValues(definition),
      );

      expect(result.errors, isEmpty);
      final outputs = {
        for (final output in result.outputs) output.id: output.value,
      };
      expect(outputs['coded_rate'], closeTo(4.2105, 0.001));
      expect(outputs['symbol_rate'], closeTo(2.1053, 0.001));
      expect(outputs['occupied_bandwidth'], closeTo(2.8421, 0.001));
      expect(outputs['spectral_efficiency'], closeTo(0.7037, 0.001));
    });

    test('computes Doppler oscillator tolerance as ppm ratio', () {
      final definition = TelemetryCalculatorRegistry.byId('doppler');
      final result = TelemetryCalculatorEngine.calculate(
        definition,
        TelemetryCalculatorRegistry.defaultValues(definition),
      );

      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      final outputs = {
        for (final output in result.outputs) output.id: output.value,
      };
      expect(outputs['doppler_shift'], closeTo(55.038, 0.001));
      expect(outputs['oscillator_error'], closeTo(2.2, 0.001));
      expect(outputs['total_error'], closeTo(57.238, 0.001));
      expect(outputs['guard_margin'], closeTo(42.762, 0.001));
    });

    test('computes spacecraft power budget outputs', () {
      final definition = TelemetryCalculatorRegistry.byId('spacecraft_power');
      final result = TelemetryCalculatorEngine.calculate(
        definition,
        TelemetryCalculatorRegistry.defaultValues(definition),
      );

      expect(result.errors, isEmpty);
      final outputs = {
        for (final output in result.outputs) output.id: output.value,
      };
      expect(outputs['array_power_eol'], closeTo(168.0, 0.01));
      expect(outputs['battery_required_energy'], closeTo(26.14, 0.01));
      expect(outputs['battery_capacity_ah'], closeTo(1.09, 0.01));
      expect(outputs['orbit_energy_margin'], closeTo(17.0, 0.01));
      expect(outputs['dod_margin'], closeTo(41.82, 0.01));
    });

    test('computes spacecraft thermal budget outputs', () {
      final definition = TelemetryCalculatorRegistry.byId('spacecraft_thermal');
      final result = TelemetryCalculatorEngine.calculate(
        definition,
        TelemetryCalculatorRegistry.defaultValues(definition),
      );

      expect(result.errors, isEmpty);
      final outputs = {
        for (final output in result.outputs) output.id: output.value,
      };
      expect(outputs['heat_absorbed'], closeTo(50.54, 0.01));
      expect(outputs['radiator_heat_rejected'], closeTo(93.07, 0.01));
      expect(outputs['radiator_area_required'], closeTo(0.17, 0.01));
      expect(outputs['heater_duty_cycle'], closeTo(25.0, 0.01));
      expect(outputs['thermal_limit_margin'], closeTo(20.0, 0.01));
    });

    test('computes mission resource closure outputs', () {
      final definition = TelemetryCalculatorRegistry.byId('mission_closure');
      final result = TelemetryCalculatorEngine.calculate(
        definition,
        TelemetryCalculatorRegistry.defaultValues(definition),
      );

      expect(result.errors, isEmpty);
      final outputs = {
        for (final output in result.outputs) output.id: output.value,
      };
      expect(outputs['generated_bits'], closeTo(7.2, 0.01));
      expect(outputs['pass_capacity_bits'], closeTo(16.2, 0.01));
      expect(outputs['storage_end_bits'], closeTo(39.8, 0.01));
      expect(outputs['storage_margin'], closeTo(160.2, 0.01));
      expect(outputs['closure_score'], closeTo(26.25, 0.01));
    });

    test('validates invalid numeric input before running formulas', () {
      final definition = TelemetryCalculatorRegistry.byId('link_budget');
      final values = TelemetryCalculatorRegistry.defaultValues(definition);
      values['distance'] = const TelemetryInputValue(value: 0, unitId: 'km');

      final result = TelemetryCalculatorEngine.calculate(definition, values);

      expect(result.errors, contains(contains('链路距离')));
      expect(result.outputs, isEmpty);
    });

    test('validates ratio inputs after unit conversion', () {
      final definition = TelemetryCalculatorRegistry.byId('spacecraft_power');
      final values = TelemetryCalculatorRegistry.defaultValues(definition);
      values['cell_efficiency'] = const TelemetryInputValue(
        value: 30,
        unitId: 'ratio',
      );

      final result = TelemetryCalculatorEngine.calculate(definition, values);

      expect(result.errors, contains(contains('电池片效率')));
      expect(result.outputs, isEmpty);
    });

    test('keeps negative thermal power margins finite', () {
      final definition = TelemetryCalculatorRegistry.byId('spacecraft_thermal');
      final values = TelemetryCalculatorRegistry.defaultValues(definition);
      values['heat_to_reject'] = const TelemetryInputValue(
        value: 200,
        unitId: 'W',
      );

      final result = TelemetryCalculatorEngine.calculate(definition, values);

      expect(result.errors, isEmpty);
      final radiatorMargin = result.outputs.firstWhere(
        (output) => output.id == 'radiator_margin',
      );
      expect(radiatorMargin.value.isFinite, isTrue);
      expect(radiatorMargin.value, lessThan(0));
    });

    test('rejects non-radiating thermal temperature boundaries', () {
      final definition = TelemetryCalculatorRegistry.byId('spacecraft_thermal');
      final values = TelemetryCalculatorRegistry.defaultValues(definition);
      values['radiator_temp'] = const TelemetryInputValue(
        value: 3,
        unitId: 'K',
      );

      final result = TelemetryCalculatorEngine.calculate(definition, values);

      expect(result.errors, contains(contains('散热器温度')));
      expect(result.outputs, isEmpty);
    });

    test('evaluates custom local formula', () {
      final definition = TelemetryCalculatorRegistry.byId('custom_formula');
      final values = TelemetryCalculatorRegistry.defaultValues(definition);
      values['expression'] = const TelemetryInputValue(
        unitId: 'unit',
        text: 'a*b + c^2 - d',
      );

      final result = TelemetryCalculatorEngine.calculate(definition, values);

      expect(result.errors, isEmpty);
      expect(result.outputs.single.value, 7);
    });

    test('registers gathered formulas as categorized system calculators', () {
      expect(TelemetryCalculatorRegistry.formulaCatalogEntryCount, 1205);
      expect(TelemetryCalculatorRegistry.integratedSystemFormulaCount, 85);

      final systemCalculators = TelemetryCalculatorRegistry.definitions
          .where(
            (definition) =>
                definition.category == TelemetryCalculatorCategory.system,
          )
          .toList();

      expect(
        systemCalculators.map((definition) => definition.id),
        containsAll([
          'spacecraft_power',
          'spacecraft_thermal',
          'mission_closure',
        ]),
      );
      for (final definition in systemCalculators) {
        expect(definition.formulas.length, greaterThanOrEqualTo(3));
        expect(definition.standards, contains('NASA'));
      }
    });

    test('counts runnable calculators by category', () {
      expect(
        TelemetryCalculatorRegistry.countByCategory(
          TelemetryCalculatorCategory.link,
        ),
        1,
      );
      expect(
        TelemetryCalculatorRegistry.countByCategory(
          TelemetryCalculatorCategory.system,
        ),
        3,
      );
      expect(
        TelemetryCalculatorRegistry.countByCategory(
          TelemetryCalculatorCategory.custom,
        ),
        1,
      );
    });

    test('offers dBK only for absolute temperature inputs', () {
      final linkBudget = TelemetryCalculatorRegistry.byId('link_budget');
      final systemTemp = linkBudget.inputs.firstWhere(
        (input) => input.id == 'system_temp',
      );
      expect(systemTemp.units, containsAll(['K', 'dBK']));

      final thermal = TelemetryCalculatorRegistry.byId('spacecraft_thermal');
      for (final id in [
        'radiator_temp',
        'space_temp',
        'hot_limit',
        'hot_case',
        'cold_case',
        'cold_limit',
      ]) {
        expect(
          thermal.inputs.firstWhere((input) => input.id == id).units,
          containsAll(['K', 'dBK']),
          reason: id,
        );
      }
      final thermalMargin = thermal.outputs.firstWhere(
        (output) => output.id == 'thermal_limit_margin',
      );
      expect(thermalMargin.unitId, 'K');
    });

    test('all default calculators produce finite outputs', () {
      for (final definition in TelemetryCalculatorRegistry.definitions) {
        final result = TelemetryCalculatorEngine.calculate(
          definition,
          TelemetryCalculatorRegistry.defaultValues(definition),
        );

        expect(result.errors, isEmpty, reason: definition.id);
        expect(result.outputs, isNotEmpty, reason: definition.id);
        for (final output in result.outputs) {
          expect(output.value.isFinite, isTrue, reason: definition.id);
        }
      }
    });
  });

  group('FormulaLibraryRepository', () {
    test('loads the full structured formula catalog', () {
      final repository = FormulaLibraryRepository();
      final entries = repository.loadAll();

      expect(entries, hasLength(1205));
      expect(entries.map((entry) => entry.id).toSet(), hasLength(1205));
      expect(repository.domainSummaries, isNotEmpty);
      expect(repository.domainSummaries.first.count, greaterThan(100));

      final rf001 = repository.byId('RF-001');
      expect(rf001, isNotNull);
      expect(rf001!.domain.label, 'RF / 天线 / 接收机');
      expect(rf001.texExpression, contains(r'\lambda'));
      expect(rf001.variables.map((variable) => variable.symbol), contains('c'));
      expect(
        rf001.variables
            .firstWhere((variable) => variable.symbol == 'c')
            .meaning,
        contains('真空光速'),
      );
      expect(
        rf001.variables.firstWhere((variable) => variable.symbol == 'c').units,
        contains('m/s'),
      );
    });

    test('localizes every formula variable explanation for display', () {
      final repository = FormulaLibraryRepository();
      final variables = [
        for (final entry in repository.loadAll())
          for (final variable in entry.variables) variable,
      ];

      expect(variables, isNotEmpty);
      expect(
        variables.where(
          (variable) => !RegExp(r'[\u4e00-\u9fff]').hasMatch(variable.meaning),
        ),
        isEmpty,
      );
      expect(
        variables.where(
          (variable) => RegExp(
            r'\b(speed|light|wavelength|frequency|gain|temperature|power|range|ratio|length|angle|error|number|time|rate)\b',
            caseSensitive: false,
          ).hasMatch(variable.meaning),
        ),
        isEmpty,
      );
    });

    test('keeps formula explanations and variable concepts Chinese-only', () {
      final repository = FormulaLibraryRepository();
      final latinWord = RegExp(r'[A-Za-z]{2,}');

      final entriesWithEnglish = repository.loadAll().where(
        (entry) => latinWord.hasMatch(entry.explanation),
      );
      final variablesWithEnglish = [
        for (final entry in repository.loadAll())
          for (final variable in entry.variables)
            if (latinWord.hasMatch(variable.meaning) ||
                latinWord.hasMatch(variable.concept))
              '${entry.id}:${variable.symbol}:${variable.meaning}:${variable.concept}',
      ];

      expect(entriesWithEnglish, isEmpty);
      expect(variablesWithEnglish, isEmpty);

      final rf022 = repository.byId('RF-022')!;
      expect(rf022.explanation, contains('表面'));
      expect(rf022.explanation, contains('误差'));
      expect(rf022.explanation, isNot(contains('Ruze-style')));
      final sigmaSurface = rf022.variables.firstWhere(
        (variable) => variable.symbol == 'sigma_surface',
      );
      expect(sigmaSurface.meaning, '表面均方根误差');
      expect(sigmaSurface.concept, contains('表面均方根误差'));
      expect(sigmaSurface.concept, isNot(contains('reflector')));
    });

    test('searches formulas and filters by domain', () {
      final repository = FormulaLibraryRepository();

      expect(
        repository.search('wavelength').map((entry) => entry.id),
        contains('RF-001'),
      );
      expect(
        repository
            .byDomain(FormulaDomain.system)
            .map((entry) => entry.id)
            .toSet(),
        containsAll(['SYS-001', 'SYS-083']),
      );
    });
  });

  group('TelemetryCalcDetailView', () {
    test('uses design tokens instead of hard-coded compact radii', () {
      final source = File(
        'lib/modules/telemetry_calc/telemetry_calc_view.dart',
      ).readAsStringSync();

      expect(source, contains('AppRadius.'));
      expect(source, isNot(contains('BorderRadius.circular(8)')));
    });

    test('keeps tiny telemetry labels below extra-bold weights', () {
      final source = File(
        'lib/modules/telemetry_calc/telemetry_calc_view.dart',
      ).readAsStringSync();
      final tinyHeavyText = RegExp(
        r'fontSize:\s*(?:10|11)\.sp,[\s\S]{0,120}?FontWeight\.w(?:800|900)',
      );

      expect(tinyHeavyText.hasMatch(source), isFalse);
    });

    test('aligns compact input shell with app text field tokens', () {
      final source = File(
        'lib/modules/telemetry_calc/telemetry_calc_view.dart',
      ).readAsStringSync();
      final compactInputShell = RegExp(
        r'class _CompactInputShell[\s\S]*?class _UnitMenuButton',
      ).firstMatch(source)!.group(0)!;

      expect(compactInputShell, contains('AppRadius.lg'));
      expect(compactInputShell, contains('semantic.mutedSurface'));
      expect(compactInputShell, contains('AppSpacing.lg'));
      expect(compactInputShell, isNot(contains('withValues(alpha: 0.62)')));
    });

    test('uses spacing tokens for telemetry gaps and padding', () {
      final source = File(
        'lib/modules/telemetry_calc/telemetry_calc_view.dart',
      ).readAsStringSync();
      final magicSizedBoxSpacing = RegExp(
        r'SizedBox\((?:height|width):\s*(?:2|3|4|5|6|7|8|10|12|14|16|18|24|28|30)\.(?:h|w)\)',
      );
      final magicEdgeInsetsSpacing = RegExp(
        r'EdgeInsets\.(?:all|symmetric|fromLTRB)\([^;\n]*\b(?:2|3|4|5|6|7|8|9|10|11|12|14|16|18|24|28|30)\.(?:h|w)',
      );

      expect(magicSizedBoxSpacing.hasMatch(source), isFalse);
      expect(magicEdgeInsetsSpacing.hasMatch(source), isFalse);
    });

    test('uses motion tokens for advanced inputs and result updates', () {
      final source = File(
        'lib/modules/telemetry_calc/telemetry_calc_view.dart',
      ).readAsStringSync();

      expect(source, contains('AppMotion.'));
      expect(source, contains('AnimatedSize'));
      expect(source, contains('AnimatedSwitcher'));
    });

    testWidgets(
      'renders compact workbench and opens unit selector without crash',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final definition = TelemetryCalculatorRegistry.byId('link_budget');
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => GetMaterialApp(
              theme: AppTheme.lightWith(null),
              home: TelemetryCalcDetailView(definition: definition),
            ),
          ),
        );

        expect(find.text('输出'), findsOneWidget);
        expect(find.text('输入'), findsOneWidget);
        expect(find.text('链路余量'), findsWidgets);

        final scrollable = find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first;
        final unitButton = find.byTooltip('选择单位').first;
        await tester.scrollUntilVisible(
          unitButton,
          120,
          scrollable: scrollable,
          maxScrolls: 12,
        );
        await tester.pumpAndSettle();

        await tester.tap(unitButton);
        await tester.pumpAndSettle();
        expect(find.text('dBm'), findsWidgets);

        await tester.tap(find.text('dBm').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders linked input output workbench before formula support',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final definition = TelemetryCalculatorRegistry.byId('rate_bandwidth');
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => GetMaterialApp(
              theme: AppTheme.lightWith(null),
              home: TelemetryCalcDetailView(definition: definition),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('公式与依据'), findsOneWidget);
        expect(find.text('依据'), findsNothing);
        expect(find.text('输出'), findsOneWidget);
        expect(find.text('输入'), findsOneWidget);
        expect(find.textContaining('Rs'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SingleChildScrollView &&
                widget.scrollDirection == Axis.horizontal,
          ),
          findsNothing,
        );

        final resultTop = tester.getTopLeft(find.text('输出')).dy;
        final inputTop = tester.getTopLeft(find.text('输入')).dy;
        final resultLeft = tester.getTopLeft(find.text('输出')).dx;
        final inputLeft = tester.getTopLeft(find.text('输入')).dx;

        expect(resultTop, lessThan(inputTop));
        expect((resultLeft - inputLeft).abs(), lessThan(1));

        await tester.tap(find.byTooltip('公式与依据'));
        await tester.pumpAndSettle();
        expect(find.text('依据'), findsOneWidget);
        expect(find.text('符号率'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('keeps two-column workbench on tablet width', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final definition = TelemetryCalculatorRegistry.byId('rate_bandwidth');
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: TelemetryCalcDetailView(definition: definition),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final resultTop = tester.getTopLeft(find.text('输出')).dy;
      final inputTop = tester.getTopLeft(find.text('输入')).dy;
      final resultLeft = tester.getTopLeft(find.text('输出')).dx;
      final inputLeft = tester.getTopLeft(find.text('输入')).dx;

      expect(inputLeft, lessThan(resultLeft));
      expect((resultTop - inputTop).abs(), lessThan(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses short title and linked input output workbench', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final definition = TelemetryCalculatorRegistry.byId('rate_bandwidth');
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: TelemetryCalcDetailView(definition: definition),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('带宽计算'), findsWidgets);
      expect(find.text('输入'), findsWidgets);
      expect(find.text('输出'), findsWidgets);
      expect(find.text('码率与带宽'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('allows judgement title to wrap in narrow output pane', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final definition = TelemetryCalculatorRegistry.byId('link_budget');
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: TelemetryCalcDetailView(definition: definition),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final judgementTitle = tester.widget<Text>(find.text('链路余量满足要求'));
      expect(judgementTitle.maxLines, greaterThanOrEqualTo(2));
      expect(find.text('含工程判断'), findsWidgets);
      expect(find.text('实时刷新输出'), findsWidgets);
      expect(find.textContaining('配置可用'), findsWidgets);
      final inputLabel = tester.widget<Text>(find.text('发射机输出功率'));
      expect(inputLabel.maxLines, greaterThanOrEqualTo(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses unified adaptive result tiles on mobile', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final definition = TelemetryCalculatorRegistry.byId('link_budget');
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: TelemetryCalcDetailView(definition: definition),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('compactPrimaryResultBar')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('compactResultChipWrap')), findsNothing);
      expect(find.byKey(const ValueKey('adaptiveResultTile')), findsWidgets);
      expect(
        find.byKey(const ValueKey('adaptiveResultTileInlineRow')),
        findsWidgets,
      );
      expect(find.byKey(const ValueKey('compactInsightBar')), findsOneWidget);
      expect(find.textContaining('Eb/N0'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scales long primary result values in the output pane', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final definition = TelemetryCalculatorRegistry.byId('custom_formula');
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: TelemetryCalcDetailView(definition: definition),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final valueFinder = find.text('10.000000');
      expect(valueFinder, findsWidgets);
      expect(find.byKey(const ValueKey('adaptiveResultTile')), findsWidgets);
      expect(find.text('结果已更新，可继续调参。'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Doppler ppm output without oversized guard margin', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final definition = TelemetryCalculatorRegistry.byId('doppler');
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: TelemetryCalcDetailView(definition: definition),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('42.762'), findsWidgets);
      expect(find.textContaining('2.200e+6'), findsNothing);
      expect(find.textContaining('保护带覆盖误差'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lists categorized system calculators on the module page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: const TelemetryCalcView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('系统 3'));
      await tester.pumpAndSettle();
      final scrollable = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('任务资源闭合'),
        120,
        scrollable: scrollable,
        maxScrolls: 8,
      );
      await tester.pumpAndSettle();

      expect(find.text('电源与蓄电池'), findsOneWidget);
      expect(find.text('热控与散热器'), findsOneWidget);
      expect(find.text('任务资源闭合'), findsOneWidget);
      expect(find.text('系统 3'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('separates formula catalog coverage from runnable cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: const TelemetryCalcView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1205 条公式 / 11 个工作台'), findsOneWidget);
      expect(find.text('公式目录 1205'), findsNothing);
      expect(find.text('系统公式 85'), findsNothing);
      expect(find.text('可运行 11'), findsNothing);
      expect(
        find.byKey(const ValueKey('telemetryModeSwitcherCenter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('telemetryCategoryFilterCenter')),
        findsOneWidget,
      );
      expect(find.text('链路 1'), findsOneWidget);

      await tester.tap(find.text('系统 3'));
      await tester.pumpAndSettle();
      final scrollable = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('任务资源闭合'),
        120,
        scrollable: scrollable,
        maxScrolls: 8,
      );
      await tester.pumpAndSettle();

      expect(find.text('系统 3'), findsOneWidget);
      expect(find.text('电源与蓄电池'), findsOneWidget);
      expect(find.text('热控与散热器'), findsOneWidget);
      expect(find.text('任务资源闭合'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filters calculator cards from the module search field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: const TelemetryCalcView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('telemetryCalcSearchField')),
        '热控',
      );
      await tester.pumpAndSettle();

      expect(find.text('热控与散热器'), findsOneWidget);
      expect(find.text('链路预算'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renames and deletes recent templates from the module page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final definition = TelemetryCalculatorRegistry.byId('link_budget');
      final store = _FakeTelemetryTemplateStore([
        TelemetryTemplate(
          id: 'recent-template',
          calculatorId: definition.id,
          name: '最近模板测试',
          updatedAt: DateTime(2026, 6, 8, 20),
          values: TelemetryCalculatorRegistry.defaultValues(definition),
        ),
      ]);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: TelemetryCalcView(templateStore: store),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('最近模板测试'), findsOneWidget);
      await tester.longPress(find.text('最近模板测试'));
      await tester.pumpAndSettle();
      expect(find.text('重命名模板'), findsOneWidget);
      expect(find.text('删除模板'), findsOneWidget);

      await tester.tap(find.text('重命名模板'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, '链路常用模板');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('链路常用模板'), findsOneWidget);
      expect(find.text('最近模板测试'), findsNothing);

      await tester.longPress(find.text('链路常用模板'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除模板'));
      await tester.pumpAndSettle();

      expect(find.text('链路常用模板'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saves templates with a local dialog lifecycle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = _FakeTelemetryTemplateStore([]);
      final definition = TelemetryCalculatorRegistry.byId('link_budget');
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: TelemetryCalcDetailView(
              definition: definition,
              templateStore: store,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('保存模板'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '链路常用参数');
      await tester.tap(find.text('保存').last);
      await tester.pumpAndSettle();

      expect(store.templates.single.name, '链路常用参数');
      expect(find.textContaining('模板已保存'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders formula library entries with variable explanations', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => GetMaterialApp(
            theme: AppTheme.lightWith(null),
            home: const TelemetryCalcView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('公式库'));
      await tester.pumpAndSettle();
      final scrollable = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('RF-001'),
        120,
        scrollable: scrollable,
        maxScrolls: 8,
      );
      await tester.pumpAndSettle();
      expect(find.text('RF-001'), findsOneWidget);
      expect(find.text('RF / 天线 / 接收机'), findsWidgets);
      expect(find.byKey(const ValueKey('formulaDirectoryCard')), findsWidgets);
      expect(find.textContaining('lambda = c / f'), findsNothing);
      expect(find.textContaining('A = pi D^2 / 4'), findsNothing);

      await tester.tap(find.text('RF-001'));
      await tester.pumpAndSettle();
      expect(find.text('参数说明'), findsOneWidget);
      expect(find.text('c'), findsWidgets);
      expect(find.textContaining('真空光速'), findsWidgets);
      expect(find.textContaining('波长'), findsWidgets);
      expect(find.textContaining('载波频率'), findsWidgets);
      expect(find.textContaining('speed of light'), findsNothing);
      expect(find.textContaining('wavelength'), findsNothing);
      expect(find.textContaining('m/s'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    for (final definition in TelemetryCalculatorRegistry.definitions) {
      testWidgets('uses unified workbench layout for ${definition.id}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => GetMaterialApp(
              theme: AppTheme.lightWith(null),
              home: TelemetryCalcDetailView(definition: definition),
            ),
          ),
        );

        expect(find.byTooltip('公式与依据'), findsWidgets, reason: definition.id);
        expect(find.text('输出'), findsWidgets, reason: definition.id);
        expect(find.text('输入'), findsWidgets, reason: definition.id);
        expect(find.text('工程判断'), findsWidgets, reason: definition.id);

        final resultTop = tester.getTopLeft(find.text('输出').first).dy;
        final inputTop = tester.getTopLeft(find.text('输入').first).dy;
        final resultLeft = tester.getTopLeft(find.text('输出').first).dx;
        final inputLeft = tester.getTopLeft(find.text('输入').first).dx;

        expect(resultTop, lessThan(inputTop), reason: definition.id);
        expect(
          (resultLeft - inputLeft).abs(),
          lessThan(1),
          reason: definition.id,
        );
        expect(tester.takeException(), isNull, reason: definition.id);
      });
    }
  });
}

class _FakeTelemetryTemplateStore extends TelemetryTemplateStore {
  final List<TelemetryTemplate> templates;

  _FakeTelemetryTemplateStore(this.templates);

  @override
  List<TelemetryTemplate> loadRecent({int limit = 3}) =>
      templates.take(limit).toList(growable: false);

  @override
  Future<void> deleteTemplate(String templateId) async {
    templates.removeWhere((template) => template.id == templateId);
  }

  @override
  Future<void> saveTemplate(
    String calculatorId,
    String name,
    Map<String, TelemetryInputValue> values,
  ) async {
    templates.removeWhere(
      (template) =>
          template.calculatorId == calculatorId &&
          template.name.trim() == name.trim(),
    );
    templates.add(
      TelemetryTemplate(
        id: '${calculatorId}_${templates.length + 1}',
        calculatorId: calculatorId,
        name: name.trim().isEmpty ? '未命名模板' : name.trim(),
        updatedAt: DateTime(2026, 6, 9, 14),
        values: Map.of(values),
      ),
    );
  }

  @override
  Future<void> renameTemplate(String templateId, String name) async {
    final index = templates.indexWhere((template) => template.id == templateId);
    if (index == -1) return;
    final template = templates[index];
    templates[index] = TelemetryTemplate(
      id: template.id,
      calculatorId: template.calculatorId,
      name: name.trim().isEmpty ? '未命名模板' : name.trim(),
      updatedAt: DateTime(2026, 6, 8, 21),
      values: template.values,
    );
  }
}
