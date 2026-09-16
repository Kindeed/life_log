-- Optional project links for work logs.
-- Existing work_logs.project_name is the trip location column in current app sync.

alter table if exists public.work_logs
  add column if not exists linked_project_name text,
  add column if not exists project_sync_id uuid;

create index if not exists idx_work_logs_user_project_sync_id
  on public.work_logs(user_id, project_sync_id);
