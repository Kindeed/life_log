# LifeLog Sync Protocol

Last updated: 2026-06-21

## Current Versions

- Local schema version: `2026062101`
- Sync protocol version: `2`
- Minimum supported app version: `1.4.16+22`
- Minimum supported sync protocol version: `2`

## Entity Identity

- `syncId` is the cross-device entity identity and is created locally before sync.
- `remoteId` is the Supabase row identity and has no local semantic meaning.
- Isar `id` is device-local only.
- Cloud writes must be idempotent by `(user_id, sync_id)`.

## Local-Only Boundary

Photos are local-only. `PhotoItem`, photo files, and photo metadata are excluded
from Supabase pull, push, merge, attachment, and conflict pipelines.

## Cursor Policy

Each cloud table stores an independent pull cursor encoded from `(updated_at, id)`.
Pull queries must order by `updated_at, id` and must handle equal-timestamp rows by
the row id boundary.

## Attachment Policy

Evidence file synchronization runs through the `EvidenceAttachment` queue. Storage
objects are uploaded before remote attachment rows, and Storage deletion is delayed
until the remote attachment delete row is confirmed.
