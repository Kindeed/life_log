# ADR 0002: Work-log-first reconstruction

Date: 2026-09-07
Status: accepted direction; implementation in progress

## Authority and baseline

The user approved a systemic, incremental reconstruction after choosing daily
work logs as the primary workflow and retaining lower-frequency features under
secondary navigation. This supersedes ADR 0001's one-work-log-per-day rule and
any fixed navigation/layer-count requirement, not the local-only photo rule.

Baseline commit: `9d704ac` (1.4.26+32). Existing uncommitted audit changes,
AGENTS consolidation, Android template removal, tests and prototype HTML must
be preserved. No automatic commit, publication, production cloud operation or
user database deletion is authorized by this decision.

Pre-reconstruction evidence: strict analysis and 510 tests passed; the audit
cleanup subsequently passed focused tests and a Debug APK build. These are
historical baselines, not validation of this reconstruction. No connected
Android device was found during the audit.

## Product decisions

- Main destinations: 工时 / 项目 / 更多, defaulting to 工时.
- More retains subscriptions, global expenses, statistics, telemetry tools,
  settings, account and sync access. Do not drop features or their data.
- Work logs intentionally permit multiple same-day types. Creating ordinary
  work on a date with existing ordinary work defaults to editing that work;
  preserve existing multi-entry records rather than destructive normalization.
- Aggregate all applicable records with explicit type rules; deleting one entry
  does not delete the date group. Regression fixtures must cover work, trip,
  leave and reimbursement together and reconcile totals across surfaces.
- Project detail moves out of the photo feature and is addressed by local
  project identity, not mutable display name. Proposed sections: records,
  photos, expenses; summary collapsible, stages as filters/metadata.
- Expenses are monetary facts; evidence is supporting material. Never silently
  double count, merge by name/amount, or discard historical unlinked evidence.
  Introduce optional explicit evidence-to-expense association in a verified
  additive migration; pending evidence amounts remain separately visible.

## Ownership and interfaces

- App composition owns routing, dependency construction and account scope.
  Repositories receive dependencies; avoid hidden mutable service-locator reads.
- Page Cubits belong to their route. They consume query models/commands, not
  other feature Cubits. Project overview/timeline queries compose repositories
  outside widgets, with owner/project/date/pagination scope.
- Keep useful domain/application boundaries; retire pass-through wrappers and
  legacy adapters only after replacing their callers and preserving mappings.
- A local command returns local commit identity/status independently of network
  completion. Eligible mutations and outbox entries commit together locally.
- Sync owns immutable run owner/generation, stable retry identity, version base,
  independent transfer retry and concrete tombstone acknowledgement.
- Isar remains initially. New persistence requires generator compatibility,
  migration fixtures and verified rollback; do not switch databases implicitly.

## Capture and file protocol

One coordinator owns the external picker and lost-data retrieval. Its local
capture draft includes task identity, owner/generation, purpose, project local
identity, existing edit target, necessary draft values, staged paths and state.

States: prepared -> pickerActive -> staged -> editing -> committing -> committed;
cancelled and recoverableFailure are explicit alternatives. Record intent before
launch, stage results before presentation, and clear only after durable commit or
explicit abandonment. Missing UI context must not discard a recovered result.

Photo and evidence share device acquisition, not cloud identity or upload
eligibility. Drafts and project photos remain local-only. Restore old evidence
as an edit of the same identity; stale owner/deleted targets must not silently
become new records. Keep gallery originals by default; deleting originals is a
separate explicit action after successful import.

Files and DB cannot share a physical transaction: use staging, durable operation
records, idempotent completion and compensation. Remote tombstones cannot erase
unfinished Storage cleanup obligations. Recover abandoned upload leases.

## Sequence and gates

1. Baseline, interfaces, key-screen interaction samples and defect mapping.
2. Reliable capture/local commit/account/sync foundation, one complete project
   capture-to-restart-recovery slice before broad UI replacement.
3. Work-log-first shell and reliable work-log read/write path.
4. Project queries, stable identity, expenses/evidence and recoverable deletion.
5. Remaining features under More and consistent states/components.
6. Remove verified unused old paths; migration, regression and performance gates.

The lead owns shared entrypoints, schema, migrations, AGENTS and BUG_TRACKER.
Initially at most two independent implementation lines; freeze interfaces before
parallel edits. Independent review follows implementation. Failed agents are not
completed reviews. Available ordinary subagent calls do not guarantee different
models; verify actual provider/model availability before claiming multi-model work.

## Verification contract

- Preserve local-only photos and account separation in every persistence test.
- Inject out-of-order reads, duplicate submit/callback, closed editor, network
  failure, DB/file failure, interrupted upload and pending-delete pull.
- Migration fixtures: legacy versions, empty/unowned rows, duplicate names,
  missing files, orphan relationships; reruns are idempotent. Verify counts,
  amounts, relationships and file samples against a restorable local snapshot.
- Never downgrade a changed DB blindly. After new writes, preserve/export the
  delta before restoring a previous snapshot.
- Key UI samples: work log, project list/detail, acquisition/editor. Compact
  summaries, lazy lists, appropriately decoded thumbnails, 48dp primary hit
  targets, 360dp width, enlarged fonts, dark mode and keyboard accessibility.
- Path goals: one tap to work-log input; at most two from project detail to
  camera; one tap to photo preview.
- Performance targets (not measured results): same-device profile/release,
  10k work logs / 100 projects / 5k photos / 5k expense-evidence metadata;
  non-file local save p95 <=300ms, project first content p95 <=500ms,
  cold interactive startup <=2s, <1% over-budget frames on 60Hz scrolling.
  Record sample count, device, data size, image sizes and cold/warm cache.
- Relevant behavior tests, strict analysis, format and generated consistency;
  Debug build and eventual Release/device gates. String-based architecture
  tests do not establish runtime correctness.
- Actual Android recovery, TalkBack, frame-time and camera gates remain unverified
  without a device; do not represent host tests as device acceptance.

## Tracking

Use BUG_TRACKER as the defect ledger and its reconstruction section for current
execution status. Known priorities include D29, D43-D46, D53, D57-D58, U223,
U266, U282-U285, U289-U290. Record newly verified gaps before implementation.
