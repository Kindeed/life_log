# LifeLog Sync Protocol

Last updated: 2026-06-21

## Current Versions

- Local schema version: `2026062102`
- Sync protocol version: `2`
- Minimum supported app version: `1.4.19+25`
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

Remote `evidence_attachments` rows are pulled and merged through
`EvidenceAttachmentSyncAdapter`. Evidence row file fields remain compatibility
fields, but attachment metadata is the primary cross-device file source.

## Retry Queue Policy

Failed adapter pushes record retry state in Isar-backed `SyncQueueRecord` rows.
The retry queue persists `entityName`, `entityKey`, `attemptCount`,
`nextAttemptAt`, `lastAttemptAt`, and `lastError` across app restarts.
