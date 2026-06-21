# ADR 0001: LifeLog Architecture Modernization Roadmap

Date: 2026-06-21
Status: accepted

## Context

LifeLog is already a feature-oriented Flutter app using GoRouter, GetIt, Cubit,
ChangeNotifier, Isar, and optional Supabase sync. The remaining high-risk
architecture debt is concentrated in `DbService` and `SyncService`: they still
mix local database access, owner assignment, remote row parsing, push/pull
protocols, attachment handling, and entity-specific merge behavior.

Photos are explicitly local-only by `AGENTS.md`. Any modernization must preserve
that boundary.

## Decision

- Keep Flutter/Dart. Do not rewrite the app in Kotlin, Swift, React Native, or
  another language to solve architecture debt.
- Keep the current GoRouter + GetIt + Cubit/ChangeNotifier runtime direction.
  Do not reintroduce GetX runtime ownership.
- Split local storage behind `IsarDatabase` and feature DAOs while keeping
  `DbService` temporarily as a compatibility facade.
- Replace the hard-coded sync service with `SyncEngine + SyncAdapter` for only
  cloud-eligible entities: WorkLog, Subscription, Project, ExpenseRecord, and
  ExpenseEvidence.
- Use per-table `(updated_at, id)` pull cursors, local conflict records, retry
  queues, and Supabase RPC/upsert by `(user_id, sync_id)` for idempotent push.
- Replace automatic anonymous-data claim with an explicit user migration flow
  that can keep data local, migrate after backup, export backup, or delete.
- Split evidence file transfer into an attachment model and upload/delete
  queue. Storage operations must be retryable and separately auditable.
- Keep photos local-only. Do not add `syncId`, `remoteId`, `isDirty`,
  `remoteVersion`, `deletedAt`, `pendingDelete`, `projectSyncId`, or any other
  cloud-sync field to `PhotoItem`.
- Keep the current one-work-log-per-day product behavior. A multi-entry work-log
  model requires a separate ADR with migration, UI, statistics, and rollback
  strategy.
- Defer hot update integration until sync protocol versioning, migration
  rollback, crash reporting, staging/prod separation, and minimum-supported-app
  policy are in place.

## Implementation Order

1. Baseline gates and release safety: format, fatal analyze, tests, signing
   failure, ADR, and bug tracker entries.
2. Local storage split: `IsarDatabase`, DAOs, repository injection, and
   `DbService` facade.
3. Sync engine slice: WorkLog adapter first, then the remaining cloud-eligible
   entities.
4. Protocol hardening: RPC/upsert, conflict table, retry queue, per-table
   cursors, and sync status UI.
5. Anonymous-data migration confirmation and backup.
6. Evidence attachment queue.
7. Project relationship hardening for cloud-synced expense/evidence records.
   Photo relationships stay local-only.
8. Subscription billing model revision.

## Consequences

- Large data and sync changes must land as small verified slices.
- Every newly confirmed data, sync, release, UI, or architecture drift issue
  must be recorded in `BUG_TRACKER.md`.
- Tests must guard the photo local-only rule, release signing behavior, and
  current runtime documentation so old review findings do not re-enter the code.
