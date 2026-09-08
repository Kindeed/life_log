# AGENTS.md

## Core Data Sync Rule (Hard Constraint)

- Photos are **local-only** in this repository and must not enter any cloud sync pipeline.
- `PhotoItem`, photo files, and photo metadata must not be included in Supabase pull/push/merge flows.
- Do not add cloud-sync fields to `PhotoItem`, including (but not limited to):
  - `syncId`
  - `remoteId`
  - `isDirty`
  - `remoteVersion`
  - `deletedAt`
  - `pendingDelete`
- Do not extend `SyncService` / `DbService` cloud-sync protocol paths to cover photos.

## Device Data Safety (Hard Constraint)

- Never use `flutter install` for upgrade verification on a device containing LifeLog data; it may uninstall the existing package before installing a missing or mismatched artifact.
- Before any device install, verify the target package with `adb shell pm list packages` and `adb shell pm path com.wzh.lifelog`.
- Preserve application data by using only `adb install -r <apk>` after confirming the APK application ID and signing compatibility; never use `pm clear`, uninstall, or a clean install as an upgrade test.
- Before installation, confirm a current cloud sync and/or local backup exists; if the target package is absent, stop and report that an in-place upgrade cannot be performed.
- Treat output containing `Uninstalling`, `clear data`, `delete data`, or `reset` as a hard stop. Do not continue automatically.
- Build/debug artifact path, package name, version code, and signature must be checked before touching a connected device.

## Change Control

- If product direction changes and photos must become syncable, implementation must be gated by an explicit architecture decision document that includes:
  - migration plan
  - rollback plan
  - data consistency and conflict strategy

## Bug Tracking Rule (Hard Constraint)

- Any newly discovered bug, regression, data-risk, sync-risk, or UI consistency issue must be recorded in `BUG_TRACKER.md`.
- Bug records must be updated when fixes are implemented, deferred, invalidated, or superseded by a stronger architecture constraint.
- UI token, motion, layout, accessibility, and visual consistency issues count as bugs for tracking purposes.
- If an older review finding conflicts with current hard constraints, correct the bug record before implementing code.
- Do not leave defect findings only in chat history, screenshots, or temporary notes.
- Historical reviews and plans are context, not current implementation contracts.

## Build / run / test

LifeLog targets Android. The repository uses Flutter 3.38.5 and Dart SDK
`^3.10.4`; dependency and app versions are maintained in `pubspec.yaml` and
`pubspec.lock`, not here.

```bash
flutter pub get --enforce-lockfile
# Only after changing Isar models:
dart run build_runner build --delete-conflicting-outputs
# Read-only source formatting check:
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter run
flutter build apk --debug
flutter build apk --release --split-per-abi
```

Run focused tests for changes and `flutter test` before shipping behavior
changes. Release builds require local signing configuration or CI secrets and
must not fall back to debug signing. Do not publish or push without explicit
authorization. `tool/quality_gate.ps1` also regenerates/formats sources; it is
not a read-only audit command.

## Current architecture

- Startup: `lib/main.dart` delegates to `lib/app/lifelog_mobile_entry.dart`.
- Routing: GoRouter in `lib/core/routing`, using `MaterialApp.router`.
- Dependency injection: GetIt in `lib/core/di/service_locator.dart` and feature
  `*_feature_di.dart` registrations.
- State: flutter_bloc/Cubit for feature workflows; ChangeNotifier/listenables
  for shell, theme, statistics and lightweight services. No production GetX
  runtime APIs remain; GetStorage is persistence, not GetX state/routing.
- Three tabs in `lib/features/shell/presentation/tabs_view.dart`: 工时、项目、更多.
  Other feature files existing on disk do not imply a top-level navigation tab.
- Feature code lives in `lib/features/<feature>/{presentation,application,domain,data}`;
  cloud-eligible features also have `sync/`. Do not recreate `lib/modules`.
- Views use feature presentation/application/domain boundaries, not direct
  DbService or SyncService operations. Repositories coordinate local data and
  sync gateways; remaining legacy-named adapters are active compatibility
  boundaries, not automatically safe deletion candidates.

See `docs/architecture/2026-06-17-framework-migration.md` for the architecture
snapshot and `docs/adr/0001-architecture-modernization-roadmap.md` for historical
modernization decisions. `docs/adr/0002-worklog-first-reconstruction.md` is the
approved reconstruction direction and supersedes ADR 0001's one-work-log-per-day
rule and any fixed navigation/layer-count requirement. Multiple same-day
work-log types are intentional; preserve existing multi-entry records.
The target three tabs are 工时 / 项目 / 更多; this target is implemented in the shell.
Do not change code back to old navigation to satisfy
historical documentation. ADR 0002 does not supersede the local-only photo rule.
Known inconsistencies and incomplete guarantees remain in `BUG_TRACKER.md`;
do not interpret a roadmap as proof of completed behavior.

## Local data and cloud sync

- Isar is the local source of truth. `DbService.schemas` is the authoritative
  collection inventory; feature DAOs/local data sources mediate access.
- Logged-in visible lists can include current-owner and unowned local records;
  cloud work must stay restricted to the authenticated owner. Do not conflate
  local visibility with eligibility to upload.
- Supabase is optional. No cloud configuration means local mode.
- `SyncService` orchestrates `SyncScheduler`, `SyncEngine`, feature adapters,
  persisted cursors, retry queues and conflicts under `lib/core/sync`.
- Cloud entities cover work logs, subscriptions, projects, expense records,
  evidence and evidence attachments. Evidence Storage is distinct from
  local-only project photos.
- Read `docs/sync-protocol.md` and current implementation before changing
  identity, version, tombstone, retry or owner semantics. Open tracker findings
  mean concurrency and data-safety guarantees must still be verified.
- `BackupService` manages local export/import; preserve photo locality and
  validate filesystem/account boundaries when changing backup behavior.
- Follow `supabase/migrations/README.md`: add corrective migrations instead of
  rewriting applied migrations. Do not execute cloud migrations during audits.

## UI and maintenance

Chinese UI; date formatting initializes `zh_CN`. Reuse tokens from
`lib/common/theme/`, shared UI from `lib/common/widgets/`, and the contracts in
`docs/ui/`. Track layout, motion, accessibility and visual inconsistencies as
bugs. Regenerate `.g.dart` only for related model changes; never hand-edit it.

CI definitions are in `.github/workflows/`: `build.yml` (tag release),
`test-apk.yml` (manual test APK), `ci-main-apk.yml` (main/manual test APK).
See `README.md` and the workflows for required cloud and signing secrets.

## Local workspace files

- `.claude/`, `.idea/`, `*.iml`, `.dart_tool/`, `build/`, platform `ephemeral/`,
  `android/.gradle/`, and `android/build/` are local/generated workspace state.
  Do not inspect, edit, stage, or commit them during normal repo work.
- `android/local.properties`, `android/key.properties`, and
  `android/app/upload-keystore.jks` are local machine or signing files. Never
  commit them or print their contents.
- Preserve user edits, prototype artifacts and historical evidence. Cleanup
  uses an explicit file whitelist, checks real paths/reparse points, and keeps
  uncertain files. Do not delete whole cache or agent directories implicitly.
