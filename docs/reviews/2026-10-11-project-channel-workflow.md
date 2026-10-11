# Project stages and channel workflow

Date: 2026-10-11. Baseline: `abdeab4007d0b519feba90731b2914bc31387756`
(`v1.4.39+45`). This iteration is prepared for `v1.4.41+47` following the
user's request to upgrade and push to GitHub. The development verification
batches below retain their original scopes and counts.

Release preparation adds 7 passing workflow/package checks, enforced-lockfile
validation with the CI package host, a read-only format check of 514 Dart files
with no changes, and clean diff checks. The reviewed lockfile is unchanged.
No project or application test batch was repeated for the version/notes bump.
The GitHub tag workflow remains the signed Android build and publication gate.

The first pushed candidate `v1.4.40+46` did not produce an APK: CI passed 1182
tests and failed one outdated source-policy assertion requiring the original
project cascade condition verbatim. The additive local-archive branch preserves
the remote-tombstone path for ordinary syncable projects, but the source test
did not account for that exception. Its contract is updated in `v1.4.41+47`
without removing archive protection. The original tag is retained; the new
candidate repeats the existing CI publication gates.

All 4 sync-idempotency policy tests pass after the assertion update, with strict
test-file analysis, formatting and diff checks. The correction changes no
production deletion code or dependency versions; the project tests are not
repeated locally for this test-only fix.

## Product direction

The user expects each project to contain stages or nodes, with photographs,
device-state descriptions, business trips, production arrangements, customer
communications and follow-up notes associated with that stage. Telegram's
channel reading is the interaction reference: readable chronological content
and a consistent place to add records. This does not introduce messaging,
members, comments or an inferred project completion model.

Flutter, Isar and Cubit remain suitable for this work. Changing the application
framework would not resolve missing relationships or inconsistent presentation.
No exact Flutter version pin is reintroduced; the installed stable SDK is used
for host verification.

## Current channel presentation

The second local UI revision supersedes the first revision's persistent
activity/photo/ledger tabs and large stage card. The detail now opens one
chronological channel. Photo browsing and accounting are optional toolbar tools;
all record types remain readable in the channel. Project lifecycle is secondary
text below the title, and the stage selector counts the currently displayed
type/tool. Its measured text widths trigger a vertical layout when the stage
and count cannot fit, without reducing system text scaling.

Channel messages and ledger surfaces use restrained 12dp corners, small icons
and no card borders. Text records omit redundant headings; photos have bounded
wide previews and remarks. The bottom record entry remains a quiet secondary
element. Toolbar/system back first cancel photo selection, then
return to the channel. Channel/tool scroll positions and the stage/type scope
survive switching. Reduced motion bypasses section transitions. Full photo
descriptions are available read-only in the photo preview.

At 320dp/2x the stage selector and count reflow without fragmented labels; the
composer uses concise general-purpose wording. The stage sheet uses a shorter
title and wraps individual record category counts independently. This avoids
clipping in the project scope without changing shared sheet geometry (U389).

New review images are in `project-channel-v2`, separate from the historical
`project-channel` images. The final screenshot helper waits for image completion
or error and verifies genuine missing-file placeholders before capture.

The photo preview has a scrollable read-only caption region, bounded to 30% of
its image area, with GPS shown only when the existing preference is enabled.
Remark saves are single flight, retain failures inline and cannot close a
different route after the editor is dismissed. A reported file rename refreshes
only the matching original identity through the existing owner-scoped photo
load use case, preserving the gallery order. A failed refresh reports that the
remark was saved and the image needs reopening.

## Implemented workflow behavior

- Project lists use the same theme-based status badge and truthful stage/photo
  copy; the detail hierarchy is described above.
- The activity stream includes independent text records and previews remarks
  for photos, business trips, expenses and evidence. Photos have wide previews
  with bounded decoding. Record bodies use the card width; stage summaries omit
  empty record categories. Equal-date sorting uses creation time and stable ids.
- The activity composer offers text and a shared add menu. New records inherit
  the selected stage; business trips now receive project identity and stage.
  Editing existing trips retains their own relationship. Selecting a local
  project clears an old sync identity and stage.
- Camera/gallery photo creation and recovery carry the exact local project id.
  An unavailable explicit parent never falls back to a namesake; changing the
  project name clears its previous id and stage before reselecting. Failed
  coordinated photo recovery retains its draft/source for retry instead of
  bypassing the account context boundary with a direct save.
- Text records support editing content, date and stage, deletion, failed-draft
  retention and unsaved-change protection. The shared Chinese date picker is
  used. Stage summaries include text and accumulate original-currency amounts
  without binary floating-point tails.
- Camera evidence now carries the same stage as other creation routes. Action
  sheets preserve ink feedback and scroll at 320dp with 2x text.

## Collapsible date directory

The current detail adds an outline of local-calendar months, dates and records.
Selecting a stage narrows the same outline; the type filter can narrow it again.
Each month shows its visible date and record counts, and each day shows its
visible record count. Month/day controls are independently collapsible. The
date-directory menu offers expand-all and collapse-all for the current filter.

Only the latest month/day opens after the first complete nonempty load. A later
watch refresh updates counts and the records in an open day, but keeps newly
arriving dates collapsed. Empty or failed initial sources do not initialize an
outline from a partial snapshot. Collapsing a month retains its day choices.
Date flags survive empty filters, stage/type switches, refresh and tool return.
Each stage/type scope has separate scroll storage: a new scope starts at zero,
and revisiting a scope restores its position. Account changes clear all outline
and scroll state before new-account content becomes visible. The section's
storage wrapper also uses the account reload generation as its widget key, so
even a reload completed before the next frame recreates mounted scrollables
rather than retaining the old account's current offset (U395).

The list flattens only expanded date groups into stable row descriptors, then
builds records near the viewport. This avoids constructing an entire day's
widget subtree under an ExpansionTile. It does not add database paging. Date
headers expose expanded accessibility state, retain 48dp touch targets and
reflow at 320dp/2x without reducing text scaling. Arrow motion follows AppMotion
and reduced-motion preferences; no large record-list height animation is used.

Current directory evidence is kept in `project-channel-folders`, separately
from both earlier review image directories.

## Data boundaries

Text is local-only and included in database backup/restore. Photos remain
local-only; photo files are still outside the database-only backup. No remote
table, Supabase migration or photo cloud path was added.

Text DAO reads and transactions validate owner, session and database context.
Editors capture that context at opening and reject an old draft after a scope
change. Note and trip Cubits invalidate pending reads and immediately clear
their cache at account boundaries. The entire detail hides old account rows
while refreshing, retaining the boundary on any read failure until retry.

Cleanup preserves parents of owned local notes. Manual cascade refuses
foreign-owner children atomically. A remote project deletion with local notes
retains the same parent as a durable local archive, excluded from cloud
candidates, identity preparation and direct or delayed pushes. Tombstone
replay, acknowledgements and late live pulls cannot delete or reactivate it.
Text/photos can still be added; new cloud-eligible records use another project.

## Date-directory verification

**71 focused tests pass**, counted once: 61 across the two project-detail test
files and 10 for the new date-heading component. The directory checks cover
month/day independence, filtered expand/collapse-all without repository reads,
stage/type composition, empty filters, live counts without reopening new dates,
tool return, local-calendar grouping for UTC timestamps, initially empty loads,
failed initial reads followed by retry, and stage/type scroll restoration.
Account boundaries include a still-scrollable 80-record same-day snapshot:
the old account has a nonzero offset and the new account starts at zero even
when the reload completes in the same frame. Reduced motion is covered in the
detail paths.

Strict whole-project analysis has no issues. The final account-generation key
change also passes strict source analysis. All five directory-related Dart
files format unchanged; `git diff --check` passes. Targeted helper/account reruns
are not counted as additional tests.

Four directory geometry scenarios render light/dark at 390dp and light/dark at
320dp with 2x text. Each captures default, expanded and collapsed states in
`project-channel-folders`; the current folder screenshots were visually checked.
The existing four project media geometry cases also pass with capture enabled.
After the directory deferred initial media mounting, their test helper needed
to evict the exact image provider and reassemble the fixture's widget tree in
the real async zone through the public BuildOwner API. It retains fold state
and waits for the
actual image error before asserting missing-file placeholders (U394). This does
not change the separate photo-preview capture limitation U391.

This iteration does not repeat the earlier 118-test UI batch or the 266-test
storage/workflow batch. It adds no database schema or cloud-sync changes and
does not claim real-device frame-time measurements.

```powershell
flutter test test/features/project/project_detail_ui_test.dart `
  test/features/project/project_detail_view_test.dart --reporter expanded
flutter test test/features/project/project_channel_group_header_test.dart `
  --reporter expanded
```

## Previous single-channel presentation verification

**118 focused tests pass**, counted once across the following groups:

| Group | Tests |
| --- | ---: |
| Project detail UI/navigation | 47 |
| Channel stage/composer/record widgets | 33 |
| Project note editor | 14 |
| Photo preview | 18 |
| Photo presentation boundaries | 6 |

Whole-project `flutter analyze --fatal-infos --fatal-warnings` reports no issues.
All 11 changed presentation/test Dart files format unchanged; `git diff --check`
passes. Focused reruns after visual refinements are not counted again.

Only project UI and its directly affected photo presentation paths were tested.
The verification groups are the two project detail tests, three new channel
widget tests, the existing note editor tests, photo preview widget tests and
photo presentation boundary tests. Geometry was rerendered only after relevant
layout changes. The previous storage/sync batch was not repeated.

The task's `project-channel-v2` directory contains 26 project/stage review images
and a 320dp/2x photo-preview image, rendered with CJK and Material icon fonts.
Main photo fixtures intentionally show the real missing-file fallback. The
photo-preview fixture uses the repository app icon as a safe readable image;
it is not an equipment photograph. Renamed-image UI tests supply mocked updated
snapshots; they do not exercise native database/file renaming.

The photo preview's ordinary 24-test widget/boundary run passes. Generate its
optional screenshot in an isolated `complete caption ... dark=true width=320.0`
case: enabling capture for its entire suite can time out on a cross-fake-async
pending image decode (U391). The isolated CJK capture passes; no claim is made
that the entire capture-enabled preview batch passed. Project geometry captures
pass together, including image-error completion assertions.

Reproduce the earlier single-channel UI checks (not repeated in full for the
date-directory addition):

```powershell
flutter test test/features/project/project_detail_ui_test.dart `
  test/features/project/project_detail_view_test.dart `
  test/features/project/project_channel_stage_bar_test.dart `
  test/features/project/project_channel_composer_test.dart `
  test/features/project/project_channel_record_test.dart `
  test/features/project/project_note_editor_test.dart `
  test/features/photo/photo_preview_view_test.dart `
  test/features/photo/photo_presentation_boundary_test.dart --reporter expanded
```

## Previous workflow verification

The first local workflow revision passed **266 focused tests** on Flutter
3.47.7 / Dart 3.13.5.
Strict whole-project analysis reports no issues; formatting checks 506 Dart
files without changes; `git diff --check` passes. This follows the user's
request to test the project module and directly affected paths without
repeating the whole application suite.

The batch covers `test/features/project`, project list/photo boundaries and
photo identity/camera/Cubit tests, capture commit/recovery integration,
work-log editor context, evidence add actions, native database backup/restore,
HTTP project guards, migration/relationship/photo-locality policies and
local-schema diagnostic metadata. Native Isar opens the actual released
v1.4.39 project schema, then upgrades it with the current schema; identities,
stage order, original photo paths/descriptions, trips and original-currency
amounts remain intact.

Four previous rendered widget cases passed and were visually inspected with CJK and
Material icon fonts: light/dark at 390dp, and light/dark at 320dp with 2x text.
They produce activity, photo, ledger, add-sheet and stage-selection screens.
Those images live in the task's `project-channel` visualization directory and
are superseded as evidence of the current presentation by `project-channel-v2`.
Photo regions use the actual missing-file placeholder, not a fabricated device
photo. Host rendering does not measure scrolling or frame times on a phone.

Reproduce the earlier data/workflow batch (not rerun for this UI-only revision):

```powershell
flutter test test/features/project `
  test/features/photo/project_list_ui_test.dart `
  test/features/photo/photo_presentation_boundary_test.dart `
  test/features/photo/photo_data_boundary_test.dart `
  test/features/photo/photo_project_identity_test.dart `
  test/features/photo/photo_add_action_launcher_test.dart `
  test/features/photo/photo_cubit_test.dart `
  test/features/capture/app_commit_port_test.dart `
  test/features/capture/capture_integration_test.dart `
  test/features/work_log/work_log_editor_cubit_test.dart `
  test/features/evidence/evidence_add_action_launcher_test.dart `
  test/core/db/backup_service_restore_test.dart `
  test/sync_adapter_http_cas_test.dart `
  test/local_data_migration_policy_test.dart `
  test/project_sync_id_relationship_policy_test.dart `
  test/photo_local_only_architecture_test.dart `
  test/package_release_hardening_test.dart `
  test/project_expense_model_test.dart --reporter expanded
```

## Remaining limits

Stage relationships still use ordered names. There is no dedicated stage id,
active-stage state, completion status or dependency graph. Database paging and
device frame-time measurements remain follow-up work; lazy row construction
and host tests do not establish Telegram-equivalent real-device smoothness.
Concurrent full-project snapshot edits (D102) and historical trip nonfinite
amount validation (D103) remain deferred and are not described as fixed.
Expense/evidence editors still have name-based resolution seams for duplicate
project names (D110); local archive details block those edit/create paths.
The existing photo save does not revalidate account/database context after
every file IO await (D113). Exact-id lookup rejects an unavailable or foreign
parent before IO, but is not a complete asynchronous photo-save context fence.
Other consumers of the fixed-height shared sheet title still need large-text
review (U389); this revision only shortens the project stage title. Preview
capture batching has the test-only limitation described under U391 above.
