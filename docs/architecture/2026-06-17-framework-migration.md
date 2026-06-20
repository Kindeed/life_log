# LifeLog Framework Migration Decision

Date: 2026-06-17
Last updated: 2026-06-18
Status: current architecture snapshot

## Decision

LifeLog stays on Flutter. The migration target is no longer "run the old app
while adding seams"; the current production runtime is feature-oriented and
GetIt-owned.

No production GetX runtime APIs remain in `lib`. The app shell uses
`MaterialApp.router` with GoRouter, feature/core services are registered through
GetIt, and UI state is owned by Cubits or Flutter listenables.

## Runtime Boundaries

Current runtime ownership:

- Routing: `lib/core/routing` with GoRouter.
- Dependency injection: `lib/core/di/service_locator.dart` with GetIt.
- Feature state: Cubit for feature workflows, `ChangeNotifier` for small app
  services and shell/theme/statistics surfaces.
- Local database: Isar through `DbService`.
- Optional cloud sync: Supabase through `SyncService` for cloud-eligible
  records only.
- Logging: `LogService`, with stack traces for startup, sync, repository,
  backup/restore, and data-management failure paths.

## Feature Shape

New and migrated code should stay in this shape:

```text
lib/
  core/
    di/
    errors/
    result/
    routing/
  features/
    <feature>/
      presentation/
      application/
      domain/
      data/
```

The old `lib/modules` feature tree is retired for migrated production code.
Boundary tests keep the removed module paths from returning.

## Data And Sync Rules

- Isar remains the local source of truth.
- Supabase remains optional and only covers cloud-eligible records.
- Photos remain local-only.
- `PhotoItem`, photo files, and photo metadata must not enter Supabase
  pull/push/merge flows.
- Do not add cloud-sync fields to `PhotoItem`, including `syncId`, `remoteId`,
  `isDirty`, `remoteVersion`, `deletedAt`, or `pendingDelete`.
- `SyncService` and `DbService` cloud-sync protocol paths must not be extended
  to cover photos.

## Current Feature Status

- WorkLog, Subscription, Expense, Evidence, Project, Photo, Profile, Shell,
  Today, Statistics, and Telemetry calculator production entry points live under
  `lib/features`.
- Feature repositories and adapters are registered through GetIt.
- Feature local data sources resolve `DbService` through GetIt.
- Feature sync gateways resolve `SyncService` through GetIt.
- `AuthService`, `SyncService`, and `DbService` use explicit lifecycle methods
  and are no longer GetX services.
- Evidence add/detail/editor paths use local Navigator, dialog, sheet, and
  ScaffoldMessenger lifecycles.
- UI helper files that owned global GetX dialog/action-sheet/binding behavior
  have been removed.

## UI And AI Design Handoff

Gemini, Claude, or another UI design tool may propose UI changes, but their
output is design input only.

AI UI prompts must include these boundaries:

- Do not change storage, sync, schema, Supabase table, or service contracts.
- Do not add photo cloud sync or remote photo metadata.
- Reuse existing Material 3 theme tokens and common widgets.
- Include loading, empty, error, disabled, accessibility, and narrow-screen
  states.
- Treat UI consistency issues as defects that must be recorded in
  `BUG_TRACKER.md`.

Implementation must be translated manually into this Flutter codebase and
covered by widget/source tests before merge or release.

## Defect Ledger Rule

`BUG_TRACKER.md` is the active defect ledger. Newly found regressions, data
risks, sync risks, UI consistency issues, stale architecture records, and test
coverage problems must be recorded there and updated when fixed, deferred, or
invalidated.

## Verification Gates

Use these gates for architecture-affecting changes:

- Targeted tests for the touched feature or boundary.
- `flutter test`
- `flutter analyze`
- `git diff --check`
- Production source scans for forbidden framework or sync-boundary regressions.
- `flutter build apk --debug` when preparing a test APK.

Current local limitation: real-device smoke checks still require an available
ADB installation and connected Android device. Without ADB, those validation
items stay open instead of being marked fixed.
