# LifeLog Modernization Execution Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring LifeLog into conformance with the 2026-06-21 architecture review while preserving Flutter/Dart and the repository's local-only photo constraint.

**Architecture:** Modernization is incremental. `DbService` remains a compatibility facade while DAOs, repositories, and sync adapters move behind feature/core boundaries; `SyncService` is replaced one entity at a time by `SyncEngine + SyncAdapter`.

**Tech Stack:** Flutter/Dart, Isar, Supabase, GetIt, GoRouter, Cubit/ChangeNotifier, GitHub Actions, Android Gradle.

---

## Hard Constraints

- `PhotoItem`, photo files, and photo metadata remain local-only.
- No cloud sync fields may be added to `PhotoItem`.
- Every newly confirmed bug, data risk, sync risk, release risk, or UI consistency issue must be recorded in `BUG_TRACKER.md`.
- Every behavior change must follow red-green verification.
- Release builds must fail without release signing config.

## Phase 0: Baseline And Guardrails

- [x] Add ADR for the modernization direction.
- [x] Update README and architecture docs to the current GoRouter/GetIt/Cubit runtime.
- [x] Enforce local and CI gates: format check, fatal analyzer, tests before APK builds.
- [x] Make Android release builds fail when signing config is missing.
- [x] Reformat generated Isar files so the full-repo format gate is actionable.

## Phase 1: Core Database Boundary

- [x] Add `core/db/isar_database.dart`.
- [x] Register `IsarDatabase` in mobile startup.
- [x] Make `DbService` open Isar through `IsarDatabase`.
- [x] Add first entity DAO: `WorkLogDao`.
- [x] Add DAO coverage for Subscription, Project, ExpenseRecord, ExpenseEvidence.
- [x] Move owner/deleted/dirty filtering into DAO-level query helpers where generated Isar filters support it.

## Phase 2: Sync Safety And Engine

- [x] Add `core/sync/SyncAdapter`, `SyncCursorStore`, and `SyncEngine` skeleton.
- [x] Stop login/startup sync from automatically claiming anonymous local records.
- [x] Replace direct cloud inserts with idempotent upsert by `(user_id, sync_id)`.
- [x] Add per-table `(updated_at, id)` cursor storage.
- [x] Migrate WorkLog to `SyncAdapter`.
- [x] Migrate Subscription, Project, ExpenseRecord, and ExpenseEvidence to `SyncAdapter`.
- [x] Add local conflict records and surface conflict counts.
- [x] Add retry/backoff queue and cancellation/pause hooks.

## Phase 3: Explicit Anonymous Data Migration

- [x] Count unowned local records after login.
- [x] Add migration decision state and UI.
- [x] Export database backup before claim.
- [x] Add local migration batch record.
- [x] Claim only after explicit user confirmation.

## Phase 4: Evidence Attachment Queue

- [x] Add `EvidenceAttachment` local model.
- [x] Add upload states: pending, uploading, uploaded, failed, deleted.
- [x] Store content hash, size, MIME type, original filename, local path, and remote storage path.
- [x] Upload Storage object before remote attachment row.
- [x] Delay Storage deletion until remote row delete is confirmed.
- [x] Keep photos out of this queue.

## Phase 5: Business Model Corrections

- [x] Replace `projectName` relationships with `projectSyncId` relationships and migration.
- [x] Redesign Subscription billing cycle with anchor date, next due date, status, end date, and reminder days.
- [x] Replace one-record-per-day WorkLog normalization with explicit day summary versus entries.

## Phase 6: UI, Logging, Package, Release Hardening

- [x] Expand design tokens and page templates.
- [x] Remove repeated private UI components where shared widgets exist.
- [x] Disable release debug logs and add log redaction coverage.
- [x] Trim unused ML Kit OCR language packages or make OCR flavor-gated.
- [x] Add package size reporting to CI.
- [x] Add release metadata for schema version, sync protocol version, and minimum supported app version.

## Verification Loop

After each completed task group, run:

```powershell
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
git diff --check
```

When Android build behavior changes, also run:

```powershell
flutter build apk --debug --no-pub
```

Release APK verification requires real signing secrets and is not substituted by debug build output.
