alter table public.expense_records
  add column if not exists trip_work_log_sync_id uuid;

create index if not exists idx_expense_records_user_trip_work_log_sync_id
  on public.expense_records(user_id, trip_work_log_sync_id);
