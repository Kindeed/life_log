# LifeLog UI Contract

LifeLog primary information architecture is **Today / Records / Projects**.
UI work must preserve that shape unless a new architecture decision updates it.

## UI Models May Edit

UI models may edit presentation-only files and shared UI primitives:

- `lib/features/*/presentation/`
- `lib/common/widgets/`
- `lib/common/theme/`
- `docs/ui/`
- mock state and scenario fixtures under `presentation/fixtures/`
- widget, source-boundary, geometry, and Golden tests that do not require data
  or sync changes

## UI Models Must Not Edit

UI models must not edit storage, sync, domain, application, migration, or native
runtime files:

- `lib/common/db/`
- `lib/common/services/`
- `lib/core/sync/`
- `lib/features/*/data/`
- `lib/features/*/domain/`
- `lib/features/*/application/`
- `supabase/migrations/`
- Android or iOS native configuration

UI changes must not call `DbService`, `SyncService`, Supabase clients, or
repositories directly. UI code talks to a ViewState exposed by a Cubit,
ChangeNotifier, launcher, or use-case boundary that already exists.

## State Contract

Each screen should describe its `ViewState` before layout work starts:

- `status`: loading, ready, empty, failure, or saving when relevant
- `primarySummary`: the most important reader-facing fact on the screen
- `quickActions`: stable action ids, labels, icons, and enabled state
- `pendingTasks`: user-visible reminders, sync issues, or follow-up work
- `recentItems`: compact rows with type, title, subtitle, timestamp, and status
- `failureMessage`: localized copy shown only in failure states

Mock state must live in `presentation/fixtures/` and must not depend on live
databases, repositories, cloud accounts, or device files.

## Operation Contract

Buttons and gestures trigger existing Cubit methods, presentation launchers, or
application commands. A UI model may rename labels, change layout, or compose
widgets, but it must not invent new persistence or sync behavior.

## Photo Rule

Photos are local-only. Do not add photo cloud sync, remote photo metadata,
photo conflict UI, or sync fields such as `syncId`, `remoteId`, `isDirty`,
`remoteVersion`, `deletedAt`, or `pendingDelete`.

## Review Contract

Confirmed UI layout, token, motion, accessibility, information-density, and
visual consistency issues must be recorded in `BUG_TRACKER.md`. Use source
tests and widget smoke/geometry tests first. Golden tests may be added later
only after a deliberate dependency and asset policy decision.
