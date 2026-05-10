# Migration conventions

- New migrations should wrap related DDL/DML in `BEGIN;` and `COMMIT;`.
- Prefer idempotent statements where Supabase/Postgres supports them.
- Do not rewrite already-applied migration files; add a corrective migration instead.
