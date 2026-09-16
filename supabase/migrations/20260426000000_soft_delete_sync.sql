-- Phase 1 sync hardening:
-- Keep deleted rows as tombstones so other devices can learn about deletes.

alter table if exists public.work_logs
  add column if not exists deleted_at timestamptz;

alter table if exists public.subscriptions
  add column if not exists deleted_at timestamptz;

create index if not exists idx_work_logs_user_updated_at
  on public.work_logs(user_id, updated_at);

create index if not exists idx_subscriptions_user_updated_at
  on public.subscriptions(user_id, updated_at);

create index if not exists idx_work_logs_deleted_at
  on public.work_logs(deleted_at)
  where deleted_at is not null;

create index if not exists idx_subscriptions_deleted_at
  on public.subscriptions(deleted_at)
  where deleted_at is not null;
