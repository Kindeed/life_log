alter table public.projects
  add column if not exists stage_names text[] not null default '{}';

alter table public.work_logs
  add column if not exists project_stage_name text;

alter table public.expense_evidence
  add column if not exists project_stage_name text;

alter table public.expense_records
  add column if not exists project_stage_name text;

create index if not exists idx_work_logs_user_project_stage_name
  on public.work_logs(user_id, project_stage_name)
  where deleted_at is null;

create index if not exists idx_expense_evidence_user_project_stage_name
  on public.expense_evidence(user_id, project_stage_name)
  where deleted_at is null;

create index if not exists idx_expense_records_user_project_stage_name
  on public.expense_records(user_id, project_stage_name)
  where deleted_at is null;
