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

        expect(find.text('计算结果'), findsOneWidget);
        expect(find.text('输入参数'), findsOneWidget);
        expect(find.text('链路余量'), findsWidgets);

        await tester.drag(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first,
          const Offset(0, -720),
        );
        await tester.pumpAndSettle();

        final unitButton = find.byTooltip('选择单位').first;
        await tester.tap(unitButton);
        await tester.pumpAndSettle();
        expect(find.text('dBm'), findsWidgets);

        await tester.tap(find.text('dBm').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders formula before results on rate bandwidth page', (
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

      expect(find.text('公式与依据'), findsOneWidget);
      expect(find.text('计算结果'), findsOneWidget);
      expect(find.text('输入参数'), findsOneWidget);
      expect(find.textContaining('Rs'), findsWidgets);

      final formulaTop = tester.getTopLeft(find.text('公式与依据')).dy;
      final resultTop = tester.getTopLeft(find.text('计算结果')).dy;
      final inputTop = tester.getTopLeft(find.text('输入参数')).dy;

      expect(formulaTop, lessThan(resultTop));
      expect(resultTop, lessThan(inputTop));
      expect(tester.takeException(), isNull);
    });
  });
}
