# LifeLog UI IA Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce the primary shell to Today / Records / Projects and add a UI Contract Pack that lets another model work safely in presentation-only code.

**Architecture:** Keep this iteration in Flutter presentation, docs, and tests. The shell owns only three primary destinations; Profile moves to a secondary app-bar action, and financial surfaces become record filters instead of a bottom tab.

**Tech Stack:** Flutter, Material 3, GetIt, Cubit/ChangeNotifier, source-boundary tests.

---

### Task 1: Shell IA Boundary

**Files:**
- Modify: `test/features/shell/shell_presentation_boundary_test.dart`
- Modify: `lib/features/shell/presentation/tabs_controller.dart`
- Modify: `lib/features/shell/presentation/tabs_view.dart`
- Create: `lib/features/shell/presentation/profile_action_button.dart`

- [ ] Write a failing shell boundary test that requires exactly `today`, `records`, and `project`.
- [ ] Run `flutter test test/features/shell/shell_presentation_boundary_test.dart` and verify it fails on the old five-tab shell.
- [ ] Update `TabsDestination`, tab labels, PageView children, and Profile secondary action.
- [ ] Re-run the shell boundary test and verify it passes.

### Task 2: Records Timeline Entry

**Files:**
- Create: `lib/features/timeline/presentation/timeline_view.dart`
- Create: `test/features/timeline/timeline_presentation_boundary_test.dart`

- [ ] Write a failing timeline boundary test requiring record filters for all, work, expense, evidence, and subscription.
- [ ] Run the timeline test and verify the file is missing.
- [ ] Add a presentation-only `TimelineView` that uses existing feature surfaces and filter chips.
- [ ] Re-run the timeline test and shell test.

### Task 3: Today Density Follow-up

**Files:**
- Modify: `test/features/today/today_presentation_boundary_test.dart`
- Modify: `lib/features/today/presentation/today_view.dart`

- [ ] Add a failing test that recent records are capped at three and “view all” routes to records.
- [ ] Update Today copy/navigation and add the Profile secondary action.
- [ ] Re-run the Today and shell tests.

### Task 4: UI Contract Pack

**Files:**
- Create: `docs/ui/ui-contract.md`
- Create: `docs/ui/component-catalog.md`
- Create: `lib/features/today/presentation/fixtures/today_mock_state.dart`
- Create: `test/ui_contract_pack_test.dart`
- Modify: `docs/ui_ai_handoff.md`

- [ ] Write a failing contract-pack source test for docs, fixtures, state contracts, operation contracts, and forbidden code boundaries.
- [ ] Add the UI contract docs and fixture state.
- [ ] Re-run contract-pack and architecture documentation tests.

### Task 5: Tracker and Verification

**Files:**
- Modify: `BUG_TRACKER.md`

- [ ] Record the shell IA/UI handoff findings and fixed status.
- [ ] Run `dart format --set-exit-if-changed .`.
- [ ] Run `flutter analyze --fatal-infos --fatal-warnings`.
- [ ] Run `flutter test`.
- [ ] Run source scans for photo local-only and tab regressions.
