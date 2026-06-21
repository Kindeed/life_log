-- Use project sync_id as the stable cross-device relationship key.
-- Photo remains local-only and is intentionally not represented here.

alter table public.expense_evidence
  add column if not exists project_sync_id uuid;

alter table public.expense_records
  add column if not exists project_sync_id uuid;

update public.expense_evidence evidence
set project_sync_id = project.sync_id
from public.projects project
where evidence.project_sync_id is null
  and evidence.user_id = project.user_id
  and lower(trim(evidence.project_name)) = lower(trim(project.name));

update public.expense_records record
set project_sync_id = project.sync_id
from public.projects project
where record.project_sync_id is null
  and record.project_name is not null
  and record.user_id = project.user_id
  and lower(trim(record.project_name)) = lower(trim(project.name));

create index if not exists idx_expense_evidence_user_project_sync_id
  on public.expense_evidence(user_id, project_sync_id);

create index if not exists idx_expense_records_user_project_sync_id
  on public.expense_records(user_id, project_sync_id);

notify pgrst, 'reload schema';
