-- Phase 2 sync identity and optimistic-lock metadata.
-- Existing rows receive sync_id automatically; clients keep remoteId only as a
-- migration bridge and use sync_id for stable cross-device identity.

create extension if not exists pgcrypto;

alter table if exists public.work_logs
  add column if not exists sync_id uuid default gen_random_uuid(),
  add column if not exists version integer not null default 1;

alter table if exists public.subscriptions
  add column if not exists sync_id uuid default gen_random_uuid(),
  add column if not exists version integer not null default 1;

update public.work_logs
set sync_id = gen_random_uuid()
where sync_id is null;

update public.subscriptions
set sync_id = gen_random_uuid()
where sync_id is null;

alter table if exists public.work_logs
  alter column sync_id set not null;

alter table if exists public.subscriptions
  alter column sync_id set not null;

create unique index if not exists uq_work_logs_user_sync_id
  on public.work_logs(user_id, sync_id);

create unique index if not exists uq_subscriptions_user_sync_id
  on public.subscriptions(user_id, sync_id);

create or replace function public.bump_sync_metadata()
returns trigger as $$
begin
  new.updated_at := now();

  if tg_op = 'UPDATE' then
    new.version := old.version + 1;
  elsif new.version is null then
    new.version := 1;
  end if;

  if new.sync_id is null then
    new.sync_id := gen_random_uuid();
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_work_logs_bump_sync_metadata on public.work_logs;
create trigger trg_work_logs_bump_sync_metadata
before insert or update on public.work_logs
for each row execute function public.bump_sync_metadata();

drop trigger if exists trg_subscriptions_bump_sync_metadata on public.subscriptions;
create trigger trg_subscriptions_bump_sync_metadata
before insert or update on public.subscriptions
for each row execute function public.bump_sync_metadata();
