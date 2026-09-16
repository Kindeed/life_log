-- Extend subscription billing state without breaking the legacy start_date field.

alter table public.subscriptions
  add column if not exists anchor_date timestamptz,
  add column if not exists next_due_date timestamptz,
  add column if not exists end_date timestamptz,
  add column if not exists status text not null default 'active',
  add column if not exists reminder_days integer not null default 1;

update public.subscriptions
set anchor_date = coalesce(anchor_date, start_date),
    next_due_date = coalesce(next_due_date, start_date),
    status = coalesce(nullif(status, ''), 'active'),
    reminder_days = greatest(coalesce(reminder_days, 1), 0);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'subscriptions_status_check'
      and conrelid = 'public.subscriptions'::regclass
  ) then
    alter table public.subscriptions
      add constraint subscriptions_status_check
      check (status in ('active', 'paused', 'canceled', 'archived'))
      not valid;
  end if;
end $$;

alter table public.subscriptions
  validate constraint subscriptions_status_check;

create index if not exists idx_subscriptions_user_status_due
  on public.subscriptions(user_id, status, next_due_date);

notify pgrst, 'reload schema';
