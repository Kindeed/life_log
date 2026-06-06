# Telemetry Calc Output Balance Design

## Context

`TelemetryCalcDetailView` already uses a linked workbench: inputs on the left and outputs on the right. New calculators can still feel visually unbalanced when the input count is much larger than the output count. The chosen direction is option A from the visual mockup: keep the left-input/right-output model, but strengthen the output pane so sparse results still read as a complete engineering decision area.

This work is tracked as `U73` in `BUG_TRACKER.md`.

## Scope

- Preserve local-only calculation behavior.
- Do not change formulas, units, default values, template storage, or sync behavior.
- Do not add any cloud-sync fields or paths, especially not for photos.
- Update only the telemetry calculator detail UI and focused widget coverage.

## Design

The output pane remains on the right side of `_CalculationWorkbench`. `_CompactResultPanel` should become a stronger decision panel:

1. Keep the primary result card as the visual anchor.
2. Keep up to four secondary result rows for numeric review.
3. Add a compact status or interpretation block below sparse outputs. The block should use existing output metadata and known output ids to communicate engineering state, for example margin pass/fail, guard margin pass/fail, or "实时计算完成" when no domain-specific judgement applies.
4. Give the output pane slightly stronger surface treatment than the input pane through existing semantic colors, borders, and spacing, without introducing a new visual theme.

Input tiles stay compact. Dense input lists may still use the existing advanced toggle, but this design does not introduce new calculator-specific input grouping yet.

## Data Flow

The calculation flow does not change:

`_values` -> `TelemetryCalculatorEngine.calculate()` -> `TelemetryCalculationResult` -> `_CompactResultPanel`.

The new status block derives display text from `TelemetryCalculationOutput` values already present in the result. It should not store state, mutate inputs, or affect saved templates.

## Error Handling

If `result.hasErrors` is true, the current error status panel remains the only output content. The new interpretation block renders only for valid results.

If a calculator has one output, it still shows the primary result plus the status block. If it has many outputs, it shows the primary result, the existing bounded secondary rows, and the status block.

## Testing

Update widget tests for telemetry calculator detail pages to assert:

- input remains left of output;
- formula support remains below the input/output workbench;
- the output pane contains an interpretation/status element for valid calculations;
- all default calculators still render output without errors.

