import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Telemetry calculator feature boundary', () {
    test('keeps telemetry files under feature data/domain/presentation', () {
      final featurePaths = [
        'lib/features/telemetry_calc/data/formula_library_data.dart',
        'lib/features/telemetry_calc/data/telemetry_template_store.dart',
        'lib/features/telemetry_calc/domain/formula_library.dart',
        'lib/features/telemetry_calc/domain/telemetry_calculators.dart',
        'lib/features/telemetry_calc/domain/telemetry_formula_engine.dart',
        'lib/features/telemetry_calc/domain/telemetry_units.dart',
        'lib/features/telemetry_calc/presentation/telemetry_calc_view.dart',
      ];
      final legacyPaths = [
        'lib/modules/telemetry_calc/formula_library_data.dart',
        'lib/modules/telemetry_calc/formula_library.dart',
        'lib/modules/telemetry_calc/telemetry_calculators.dart',
        'lib/modules/telemetry_calc/telemetry_calc_view.dart',
        'lib/modules/telemetry_calc/telemetry_formula_engine.dart',
        'lib/modules/telemetry_calc/telemetry_template_store.dart',
        'lib/modules/telemetry_calc/telemetry_units.dart',
      ];

      for (final path in featurePaths) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
      for (final path in legacyPaths) {
        expect(File(path).existsSync(), isFalse, reason: '$path is retired');
      }
    });

    test('blocks profile entry and tests from importing module telemetry', () {
      final profileView = File(
        'lib/features/profile/presentation/profile_view.dart',
      ).readAsStringSync();
      final telemetryTest = File(
        'test/telemetry_calc_test.dart',
      ).readAsStringSync();

      for (final source in [profileView, telemetryTest]) {
        expect(
          source,
          isNot(contains('package:life_log/modules/telemetry_calc/')),
        );
      }
      expect(
        profileView,
        contains(
          'package:life_log/features/telemetry_calc/presentation/telemetry_calc_view.dart',
        ),
      );
    });

    test('splits formula presentation widgets out of the main view file', () {
      final view = File(
        'lib/features/telemetry_calc/presentation/telemetry_calc_view.dart',
      );
      final formulaWidgets = File(
        'lib/features/telemetry_calc/presentation/telemetry_formula_widgets.dart',
      );
      final homeWidgets = File(
        'lib/features/telemetry_calc/presentation/telemetry_home_widgets.dart',
      );

      expect(formulaWidgets.existsSync(), isTrue);
      expect(homeWidgets.existsSync(), isTrue);
      final viewSource = view.readAsStringSync();
      final formulaSource = formulaWidgets.readAsStringSync();
      final homeSource = homeWidgets.readAsStringSync();

      expect(viewSource, contains("part 'telemetry_formula_widgets.dart';"));
      expect(viewSource, contains("part 'telemetry_home_widgets.dart';"));
      expect(viewSource, isNot(contains('class _FormulaPanel')));
      expect(viewSource, isNot(contains('class _FormulaMathBlock')));
      expect(viewSource, isNot(contains('class _Header')));
      expect(formulaSource, contains("part of 'telemetry_calc_view.dart';"));
      expect(formulaSource, contains('class FormulaLibraryDetailView'));
      expect(formulaSource, contains('class _FormulaPanel'));
      expect(formulaSource, contains('class _FormulaMathBlock'));
      expect(homeSource, contains("part of 'telemetry_calc_view.dart';"));
      expect(homeSource, contains('class _Header'));
      expect(homeSource, contains('class _CalculatorCard'));
      expect(view.readAsLinesSync().length, lessThanOrEqualTo(2300));
    });
  });
}
