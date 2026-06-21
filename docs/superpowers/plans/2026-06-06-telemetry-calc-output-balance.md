# Telemetry Calc Output Balance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strengthen the telemetry calculator output pane so calculators with many inputs and few outputs still look visually balanced.

**Architecture:** Keep the existing `TelemetryCalcDetailView` workbench and calculation flow. Add a derived interpretation/status block inside `_CompactResultPanel`, using only `TelemetryCalculationOutput` values already produced by `TelemetryCalculatorEngine`.

**Tech Stack:** Flutter, Dart widget tests, existing LifeLog app widgets and semantic colors.

---

## File Structure

- Modify: `test/telemetry_calc_test.dart`
  - Add widget assertions that valid calculator detail pages render a status/interpretation block in the output pane.
- Modify: `lib/modules/telemetry_calc/telemetry_calc_view.dart`
  - Add `_ResultInsight`, `_OutputInsightPanel`, and a small helper to derive insight content from output ids.
  - Slightly strengthen `_WorkbenchPane` when it is used for output.
- Modify: `BUG_TRACKER.md`
  - Mark `U73` fixed after verification.

### Task 1: Widget Test For Output Interpretation

**Files:**
- Modify: `test/telemetry_calc_test.dart`

- [x] **Step 1: Write the failing test**

Add an assertion to the existing telemetry detail widget tests:

```dart
expect(find.text('工程判断'), findsWidgets);
```

Use the existing valid default calculator pump path so the test exercises real output rendering.

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/telemetry_calc_test.dart`

Expected: FAIL because no widget currently renders `工程判断`.

### Task 2: Output Pane Decision Block

**Files:**
- Modify: `lib/modules/telemetry_calc/telemetry_calc_view.dart`

- [x] **Step 1: Add implementation**

Update `_CompactResultPanel` to render `_OutputInsightPanel` after secondary result rows. Add helper logic:

- `margin` or `guard_margin` >= 0: pass state, success color.
- `margin` or `guard_margin` < 0: warning state, error color.
- fallback: neutral "实时计算完成" state using the primary output label.

- [x] **Step 2: Run focused widget test**

Run: `flutter test test/telemetry_calc_test.dart`

Expected: PASS.

### Task 3: Tracker And Full Verification

**Files:**
- Modify: `BUG_TRACKER.md`

- [x] **Step 1: Mark U73 fixed**

Update the `U73` row with a concise fixed note describing the output interpretation block.

- [x] **Step 2: Run validation**

Run:

```powershell
flutter test test/telemetry_calc_test.dart
flutter analyze
git diff --check
```

Expected: all commands exit 0.
