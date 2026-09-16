begin;

-- Preserve the user's original subscription currency. CNY is the legacy default.
alter table public.subscriptions
  add column if not exists currency text not null default 'CNY';

update public.subscriptions
set currency = case
  when upper(trim(currency)) in ('CNY', 'USD', 'EUR', 'JPY', 'HKD')
    then upper(trim(currency))
  else 'CNY'
end;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'subscriptions_currency_check'
      and conrelid = 'public.subscriptions'::regclass
  ) then
    alter table public.subscriptions
      add constraint subscriptions_currency_check
      check (currency in ('CNY', 'USD', 'EUR', 'JPY', 'HKD'));
  end if;
end $$;

notify pgrst, 'reload schema';

commit;
