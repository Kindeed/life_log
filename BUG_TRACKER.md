# LifeLog BUG Tracker

**Last updated**: 2026-05-10  
**Status values**: `open`, `in_progress`, `fixed`, `deferred`, `invalidated`

This is the active defect ledger. `REVIEW_REPORT.md` is historical context only. Photo sync findings from older reports are superseded by `AGENTS.md`: photos remain local-only and must not enter Supabase sync.

## Data / Sync

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| D1 | High | fixed | `Project` sync | `Project` has cloud fields and remote schema, but client pull/push is incomplete. | Fixed: project pull/push/delete exists, and sync is limited to cloud-eligible projects or projects referenced by synced expense/evidence records. |
| D2 | High | fixed | owner claim | `claimUnownedRecordsForCurrentUser()` omits projects. | Fixed: unowned projects are claimed locally; only sync-eligible projects become dirty. |
| D3 | Medium | fixed | dirty marking | Save paths rely on UI to set `isDirty`. | Fixed: DB save paths mark dirty from business-field changes even if UI forgets. |
| D4 | Medium | fixed | backup | Backup exports Isar DB only, not photo/evidence files. | Fixed: UI and share text explicitly say database-only and warn that media files are not included. |
| D5 | Low | fixed | diagnostics | Diagnostic export includes the full Supabase URL. | Fixed: diagnostic/log exports mask the Supabase URL. |

## UI / Design System

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| U1 | Medium | fixed | `AppSheetScaffold` | Keyboard inset changes jump without transition. | Fixed: scroll content uses tokenized animated padding; header/grabber remain stable. |
| U2 | Low | open | `AddLogSheet` | Cross-field focus switch can flicker the bottom bar. | Focus state is coalesced so only final focus state rebuilds. |
| U3 | Low | fixed | `AppSkeleton` | Skeleton color uses raw `Colors.white10`. | Fixed: color comes from theme color scheme. |
| U4 | Low | open | `AppEmptyState` | 74x74 icon container is hard-coded. | Size comes from design token. |
| U5 | Low | open | `AppMetricTile` | 38x38 icon container is hard-coded. | Size comes from design token. |
| U6 | Low | fixed | `AppLoading` | Loading label gap uses raw `12`. | Fixed: uses `AppSpacing.md`. |
| U7 | Low | fixed | `AppSafeBottomBar` | Shadow blur uses raw `24`. | Fixed: uses elevation/shadow token. |
| U8 | Low | fixed | `AppMotion` | Uses both `Easing.*` and raw `Curves.easeInOutCubic`. | Fixed: motion constants use tokenized `Easing.*`. |
| U9 | Low | fixed | `AppTheme` | Text styles force `letterSpacing: 0`; dialog theme is missing. | Fixed: app-theme text styles no longer force letter spacing and dialog theme exists. |
| U10 | Low | open | `DayCell` | Holiday badge can overlap double-digit dates. | Badge/content layout no longer overlaps. |
| U11 | Low | open | `StatisticsView` | Overtime text may become too small in calendar cells. | Calendar cell text uses stable sizing, not whole-cell `FittedBox`. |

## Tooling / Validation

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| T1 | Medium | fixed | Flutter/Dart CLI | `flutter`/`dart` commands timed out inside the sandbox because the CLI could not write normal analytics/tool-state files under `C:\Users\WZH\AppData\Roaming`. | Fixed: reran with approved Flutter/Dart permissions; `flutter --version`, `dart --version`, `flutter analyze`, and `flutter test` complete successfully. |
| T2 | Low | fixed | GitHub Actions | GitHub Actions warned that Node.js 20 action runtime is deprecated and will default to Node.js 24 on 2026-06-02. | Fixed: opted both APK workflows into Node.js 24 action runtime with `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`. |

## Maintenance / Cleanup

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| C1 | Low | fixed | project cache | Regenerable Flutter project caches were present after prior local builds. | Fixed: ran `flutter clean`, restored dependency metadata with `flutter pub get`, verified the project, then removed test-regenerated `build` cache while keeping required `.dart_tool` metadata. |

## Invalidated Historical Findings

| ID | Status | Finding | Reason |
| --- | --- | --- | --- |
| H1 | invalidated | Add `syncId`/`remoteId`/`isDirty` etc. to `PhotoItem`. | Violates current hard constraint: photos are local-only. |
| H2 | invalidated | Add photo pull/push/merge paths to `SyncService`/`DbService`. | Violates current hard constraint: photos must not enter cloud sync. |
