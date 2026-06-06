import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_calc_view.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_calculators.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_formula_engine.dart';
import 'package:life_log/modules/telemetry_calc/telemetry_units.dart';

void main() {
  group('UnitCatalog', () {
    test('converts common engineering units', () {
      expect(UnitCatalog.convert(1, 'GHz', 'MHz'), 1000);
      expect(UnitCatalog.convert(30, 'dBm', 'dBW'), 0);
      expect(UnitCatalog.convert(0.875, 'ratio', 'percent'), 87.5);
      expect(UnitCatalog.convert(100, 'percent', 'ratio'), 1);
    });

    test('rejects incompatible dimensions', () {
      expect(() => UnitCatalog.convert(1, 'km', 'MHz'), throwsArgumentError);
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

    test('validates invalid numeric input before running formulas', () {
      final definition = TelemetryCalculatorRegistry.byId('link_budget');
      final values = TelemetryCalculatorRegistry.defaultValues(definition);
      values['distance'] = const TelemetryInputValue(value: 0, unitId: 'km');

      final result = TelemetryCalculatorEngine.calculate(definition, values);

      expect(result.errors, contains(contains('链路距离')));
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

  group('TelemetryCalcDetailView', () {
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

        expect(find.text('依据'), findsOneWidget);
        expect(find.text('输出'), findsOneWidget);
        expect(find.text('输入'), findsOneWidget);
        expect(find.textContaining('Rs'), findsWidgets);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SingleChildScrollView &&
                widget.scrollDirection == Axis.horizontal,
          ),
          findsNothing,
        );

        final formulaTop = tester.getTopLeft(find.text('依据')).dy;
        final resultTop = tester.getTopLeft(find.text('输出')).dy;
        final inputTop = tester.getTopLeft(find.text('输入')).dy;
        final resultLeft = tester.getTopLeft(find.text('输出')).dx;
        final inputLeft = tester.getTopLeft(find.text('输入')).dx;

        expect(inputLeft, lessThan(resultLeft));
        expect(formulaTop, greaterThan(resultTop));
        expect(formulaTop, greaterThan(inputTop));
        expect(tester.takeException(), isNull);
      },
    );

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
      expect(
        find.ancestor(of: valueFinder.first, matching: find.byType(FittedBox)),
        findsOneWidget,
      );
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

        expect(find.text('依据'), findsWidgets, reason: definition.id);
        expect(find.text('输出'), findsWidgets, reason: definition.id);
        expect(find.text('输入'), findsWidgets, reason: definition.id);
        expect(find.text('工程判断'), findsWidgets, reason: definition.id);

        final formulaTop = tester.getTopLeft(find.text('依据').first).dy;
        final resultTop = tester.getTopLeft(find.text('输出').first).dy;
        final inputTop = tester.getTopLeft(find.text('输入').first).dy;
        final resultLeft = tester.getTopLeft(find.text('输出').first).dx;
        final inputLeft = tester.getTopLeft(find.text('输入').first).dx;

        expect(inputLeft, lessThan(resultLeft), reason: definition.id);
        expect(formulaTop, greaterThan(resultTop), reason: definition.id);
        expect(formulaTop, greaterThan(inputTop), reason: definition.id);
        expect(tester.takeException(), isNull, reason: definition.id);
      });
    }
  });
}
