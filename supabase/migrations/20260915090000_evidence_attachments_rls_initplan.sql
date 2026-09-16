-- Avoid re-evaluating auth.uid() for every evidence attachment row.
-- This is a corrective migration; do not rewrite the original migration.

begin;

drop policy if exists "evidence_attachments_select_own"
  on public.evidence_attachments;
create policy "evidence_attachments_select_own"
  on public.evidence_attachments
  for select
  using ((select auth.uid()) = user_id);

drop policy if exists "evidence_attachments_insert_own"
  on public.evidence_attachments;
create policy "evidence_attachments_insert_own"
  on public.evidence_attachments
  for insert
  with check ((select auth.uid()) = user_id);

drop policy if exists "evidence_attachments_update_own"
  on public.evidence_attachments;
create policy "evidence_attachments_update_own"
  on public.evidence_attachments
  for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "evidence_attachments_delete_own"
  on public.evidence_attachments;
create policy "evidence_attachments_delete_own"
  on public.evidence_attachments
  for delete
  using ((select auth.uid()) = user_id);

commit;
