# Migration conventions

- New migrations should wrap related DDL/DML in `BEGIN;` and `COMMIT;`.
- Prefer idempotent statements where Supabase/Postgres supports them.
- Do not rewrite already-applied migration files; add a corrective migration instead.
- Migration versions must be unique. When multiple historical migrations were created
  on the same day, keep their SQL unchanged but use distinct full timestamps so the
  Supabase migration history can register every file exactly once.
