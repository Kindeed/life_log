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
