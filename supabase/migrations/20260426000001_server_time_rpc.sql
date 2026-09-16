-- Server-side cursor source for incremental sync windows.

create or replace function public.get_server_time()
returns timestamptz
language sql
stable
as $$
  select now();
$$;

notify pgrst, 'reload schema';
