# LifeLog Sync Protocol

Last updated: 2026-10-01

## Current Versions

- Local schema version: `2026100101`
- Sync protocol version: `2`
- Minimum supported app version: `1.4.19+25`
- Minimum supported sync protocol version: `2`

The local schema identifier includes the nullable owner scope on persisted sync conflicts. This additive local field does not change the remote sync protocol or minimum supported version.

## Entity Identity

- `syncId` is the cross-device entity identity and is created locally before sync.
- Pending legacy rows receive their identity transactionally before any request;
  a persisted owner/local retry key migrates with its existing backoff.
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

## Continuation and concurrency policy

- A run captures immutable owner, session epoch and database generation. Remote
  continuations, cursor/queue writes and merges reject invalidated contexts.
- ACKs update only remote metadata on the latest stored row. Value comparisons
  and process mutation revisions preserve newer edits, edit/revert sequences and
  tombstones. Remote pulls keep a dirty record's original base version.
- Update/delete requests always compare the base version, including zero. An
  unknown zero base cannot overwrite an existing positive server version.

## Restore and conflict lifecycle

Restore drains issued sync and local writes before database replacement. The
stable IsarDatabase handle reconnects existing consumers/watchers. A separate,
flushed restore-generation file survives replacement and invalidates every
owner's incremental cursor until a successful full refresh is recorded. Failed
restore and failed rollback retain the original recovery snapshot.

Conflict actions suspend ordinary sync, drain issued requests and verify the
current remote version before atomically applying the business decision and
closing the conflict. Copy uses new identities and independent evidence files;
project photos and covers remain local. Discarded attachment jobs become cloud
tombstones while selected remote paths and local files are preserved.

Interrupted uploading attachments remain retryable on the next valid run.
Attachment ACKs compare current bytes/tombstones; a changed uploaded parent path
marks the evidence dirty and requests a serialized follow-up.
