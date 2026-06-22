# LifeLog Follow-up Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the remaining follow-up items from the architecture review: conflict center, sync status center, keyset pull guardrails, project dashboard depth, and a more useful Records timeline.

**Architecture:** Keep data/sync changes behind existing core sync and feature boundaries. UI additions stay in feature presentation, consume existing Cubits/stores, and preserve the photo local-only rule.

**Tech Stack:** Flutter, GetIt, Cubit/ChangeNotifier, Isar, SyncEngine/SyncAdapter, source-boundary tests, widget-safe presentation tests.

---

### Task 1: Sync Conflict Center

**Files:**
- Create: `lib/features/sync_center/presentation/sync_center_view.dart`
- Modify: `lib/features/shell/presentation/profile_action_button.dart`
- Create: `test/features/sync_center/sync_center_boundary_test.dart`

- [ ] Write failing source tests requiring a conflict/status center view, unresolved conflict list, and local-only presentation imports.
- [ ] Add the view with tabs/sections for sync status and conflicts.
- [ ] Route profile/shell secondary access to include the sync center entry.
- [ ] Run targeted tests.

### Task 2: Sync Status Center Data Hooks

**Files:**
- Modify: `lib/core/sync/isar_sync_queue.dart`
- Modify: `lib/core/sync/isar_sync_conflict_store.dart`
- Create: `test/core/sync/sync_center_store_test.dart`

- [ ] Write failing tests for listing pending queue entries and unresolved conflicts.
- [ ] Add read-only list/count helpers.
- [ ] Run core sync tests.

### Task 3: Keyset Pull Guardrails

**Files:**
- Create: `lib/core/sync/sync_pull_page.dart`
- Modify: feature sync adapters under `lib/features/*/sync/`
- Create: `test/sync_keyset_pagination_policy_test.dart`

- [ ] Write failing policy tests requiring adapter pulls to avoid `.range(start, ...)`.
- [ ] Add a shared keyset page helper or at least source-level guardrails.
- [ ] Update adapters to use limit-based keyset-style filtering where the Supabase query shape allows it.
- [ ] Run sync policy tests.

### Task 4: Project Dashboard Details

**Files:**
- Modify: `lib/features/photo/presentation/project_gallery_view.dart`
- Modify: `lib/features/photo/presentation/photo_view.dart`
- Create/modify: `test/features/project/project_dashboard_boundary_test.dart`

- [ ] Write failing tests for project detail tabs: overview, timeline, photos, evidence, expenses.
- [ ] Add compact detail tabs using existing Cubits and domain entries.
- [ ] Keep photos local-only.
- [ ] Run project/photo/evidence/expense presentation tests.

### Task 5: Records Timeline Depth

**Files:**
- Modify: `lib/features/timeline/presentation/timeline_view.dart`
- Modify: `test/features/timeline/timeline_presentation_boundary_test.dart`

- [ ] Write failing tests requiring a unified timeline item model and visible grouped record rows.
- [ ] Add timeline rows for work, expenses, evidence, and subscriptions using existing feature Cubits/views.
- [ ] Run timeline and shell tests.

### Task 6: Tracker and Verification

**Files:**
- Modify: `BUG_TRACKER.md`
- Modify: docs as needed

- [ ] Record all newly fixed issues.
- [ ] Run `dart format --set-exit-if-changed .`.
- [ ] Run `flutter analyze --fatal-infos --fatal-warnings`.
- [ ] Run `flutter test`.
- [ ] Run photo local-only and legacy-tab/sync scans.
