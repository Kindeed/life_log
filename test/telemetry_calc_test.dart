import 'package:flutter_test/flutter_test.dart';
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
}
