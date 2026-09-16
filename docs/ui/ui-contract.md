# LifeLog UI Contract

LifeLog primary information architecture is **工时 / 项目 / 更多**, as approved
in ADR 0002. Work logs are the default destination. A calendar day presents one
primary work status; existing multiple entries remain available in day details.
Do not delete or normalize historical entries to simplify presentation.

## Visual baseline (2026-09-16)

Use one shared Material 3 theme builder for both brightness modes. Preserve
paired dynamic foreground/background colors. Pages use surfaceContainerLowest,
cards use surface, and inputs use the semantic muted surface. Avoid per-screen
primary blue overrides. Use AppTypography roles, AppSpacing and AppRadius.
Page titles are left aligned; form-sheet titles retain their explicit layout.
Keep compact engineering input/output layouts and local-only photo semantics.
Interactive controls should retain at least 48 logical pixels of touch height;
large text should reflow rather than be globally clamped. Loading, failure,
empty and partial-data states must remain distinguishable.

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
