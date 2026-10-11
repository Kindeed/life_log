# LifeLog UI Contract

LifeLog primary information architecture is **工时 / 项目 / 更多**, as approved
in ADR 0002. Work logs are the default destination. A calendar day presents one
primary work status; existing multiple entries remain available in day details.
Do not delete or normalize historical entries to simplify presentation.

## Visual baseline (2026-10-02)

Use one shared Material 3 theme builder for both brightness modes. Preserve
paired dynamic foreground/background colors. Pages use surfaceContainerLowest,
cards use surface, and inputs use the semantic muted surface. Avoid per-screen
primary blue overrides. Use AppTypography roles, AppSpacing and AppRadius.
Page titles are left aligned; form-sheet titles retain their explicit layout.
Keep compact engineering input/output layouts and local-only photo semantics.
Interactive controls should retain at least 48 logical pixels of touch height;
large text should reflow rather than be globally clamped. Loading, failure,
empty and partial-data states must remain distinguishable.

The primary tabs share `AppTabHeader`, optional 48px actions and surface insets.
More has a single account card and no duplicate account action in its header.
Use the warm neutral / green palette and paired light/dark roles, 30px cards,
28px groups, 22px controls, pill actions and a 36px sheet contour. Calendar cells
keep date, lunar/festival/solar-term metadata and work status in separate layers.
The calendar rebuild predicate must include asynchronously loaded day metadata.
System text scaling remains enabled; short or narrow cells use responsive gaps
and bounded multi-entry markers with full labels in semantics/tooltips.

Tab changes preserve page/search/scroll state and move the existing navigation
indicator. Local calendar changes update selected content without replaying the
whole page entrance. Use `AppMotion.duration` for transitions and reset pressed
state when a control becomes disabled during a gesture.

## Consistency additions (2026-10-11)

Core save/delete feedback uses `AppFeedback.capture` before closing an editor.
Short confirmations have measured compact width; long messages wrap within the
screen. Success/info use 2 seconds, errors 4 seconds, with native SnackBar
semantics and placement. Replace pending confirmations rather than queueing
stale results. Recoverable form errors stay inline. Evidence-detail actions use
local `AppFormFeedback` while the sheet remains open; evidence recognition and
save failures stay in the editor. Closing success uses the parent feedback handle.

Display badges use `AppPill` and `AppStatusColors` as an opaque container/foreground
pair with at least 4.5:1 small-text contrast. Subscription lifecycle and next
billing date are separate; ended items must not also say enabled. Amounts show
their original currency/precision and totals group currencies. CNY conversions
are labelled estimates; missing rates remain explicit. Tiny nonzero estimates
display a bound rather than zero. Do not round persisted original amounts.

Settings use `AppSettingsGroup`/`AppSettingsTile`: 40dp icon containers, minimum
64dp rows, wrapping text and merged labelled switch semantics. More orders its
single account entry, record/analysis group, app settings and professional tools.
Diagnostics live under About; backup copy states database-only scope.

Ordinary Navigator pages use `appPageRoute` with inherited Material platform
transitions, including predictive back: enter 240ms, reverse 200ms. Sheets use
`showAppBottomSheet`: 300ms/240ms, preserving dismissal/focus/controller policy.
Both honour reduced motion. GoRouter root/login pages retain Material defaults.
Tab foregrounds follow page progress; work-type transitions affect only the
changing region and preserve input controllers. Reduced motion bypasses
AnimatedSize where zero duration is not layout-safe.

All-record browsing consumes an independent timeline snapshot: common date/type
filters, full historical work logs, source failures and stable lazy rows with
40-row display pages. Subscription rows represent the next billing snapshot,
not payment history. Repositories still read complete visible collections;
display pagination is not database pagination or measured device performance.

## Project channel workflow (2026-10-11)

Projects own an ordered list of stages. Stages scope records; they are not a
completion percentage or an inferred current stage. A project detail opens one
continuous record channel, without persistent activity/photo/ledger tabs.
Project lifecycle is secondary text below the title. The compact stage selector
scopes the channel; photo browsing and accounting are optional toolbar tools.
Tools keep the same stage and return to the channel with its filter and scroll
position preserved. Photo selection is cancelled by the first toolbar/system
back; the next back returns to the channel. Lists use the same project status
badge and show actual configured stage counts only for persisted projects.
Historical name-only groups must not invent a status.

The activity stream has a collapsible month/day directory using local calendar
dates. Stage and type filters compose with that directory; counts describe only
the current projection. After the first complete nonempty load, only the latest
month and day open automatically. Later source updates do not open new dates or
reopen an explicitly collapsed group. Month collapse retains its day flags;
expand/collapse-all affects only dates in the current projection. Date flags
survive filter changes and tool return, while each stage/type scope retains its
own scroll position. A new scope starts at the top; an account boundary clears
all flags and scroll storage. Only expanded records enter the lazy row list.
Date headings reflow counts below the date at large text sizes, expose expansion
semantics and honour reduced motion for their arrows.

Within each day, the activity stream orders records by event time, breaking
ties with creation time and a stable identity. Text records, photo descriptions,
trip remarks and
accounting notes are readable across the card width. The channel and ledger
use compact 12dp surface corners without decorative borders or large icon
containers. Photos use bounded decoding and wide previews; rows remain lazily
built. Full photo descriptions are readable in the preview without editing.
Stage summaries omit empty record categories. The stage bar counts the current
section/type only and uses measured text width to reflow at larger text sizes.
The quiet channel composer opens a protected text editor or the add menu.
Creation inherits the selected project/stage; 全部阶段 creates
an unassigned record unless the user selects a stage in the editor. Historical
and unassigned stages remain reachable. Large text reflows and action sheets
scroll within the screen.

Text records are stored on this device and included in local database backups.
Editors explain this scope, preserve failed drafts and reject saves/deletes
after their owner/session/database context changes. An account change hides
the entire old detail until all sources have been read successfully; retry
must not reveal previous-account rows. A local archive retained after a remote
deletion allows text/photo additions and shows old accounting/trip rows read-only.

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
