-- NEVER run this in the real project. ISOLATED TEST DATABASE ONLY.
-- Run with psql -v ON_ERROR_STOP=1 -f this file after schema.sql.
-- The migration commits: a failed run may leave fixtures behind.
\set ON_ERROR_STOP on

insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-4000-8000-000000000c01', '{}'),
 ('00000000-0000-4000-8000-000000000c02', '{}');
-- Existing invalid and over-limit data must survive the migration.
insert into public.cheat_meals (id, user_id, planned_date, notes) values
 ('00000000-0000-4000-8000-000000000c91', '00000000-0000-4000-8000-000000000c01', '2025-01-01', ''),
 ('00000000-0000-4000-8000-000000000c92', '00000000-0000-4000-8000-000000000c01', '2025-01-02', 'Existing'),
 ('00000000-0000-4000-8000-000000000c93', '00000000-0000-4000-8000-000000000c01', '2025-01-03', 'Existing');
create temporary table legacy_rows as select to_jsonb(c) row_data from public.cheat_meals c;
\ir ../cheat_meals_limit_and_classified_checks.sql

create function pg_temp.assert_test(ok boolean, message text) returns void
language plpgsql as $$
begin
 if ok is distinct from true then raise exception 'Test failed: %', message; end if;
end $$;
select pg_temp.assert_test(
 not exists ((select row_data from legacy_rows except all select to_jsonb(c) from public.cheat_meals c)
 union all (select to_jsonb(c) from public.cheat_meals c except all select row_data from legacy_rows)),
 'migration preserves legacy rows');
select pg_temp.assert_test(
 (select not convalidated from pg_constraint where conrelid = 'public.cheat_meals'::regclass
  and conname = 'cheat_meals_notes_length_check'),
 'notes constraint is not validated against legacy rows');

begin;
select set_config('request.jwt.claims', '{}', true);
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000c01', true);
insert into public.cheat_meals (id, planned_date, notes) values
 ('00000000-0000-4000-8000-000000000c11', '2026-11-01', 'First'),
 ('00000000-0000-4000-8000-000000000c12', '2026-11-30', 'Second'),
 ('00000000-0000-4000-8000-000000000c13', '2026-12-01', 'Third'),
 ('00000000-0000-4000-8000-000000000c14', '2026-12-31', 'Fourth');
insert into public.classified_checks (item_key) values ('foundation_goal');
commit;

create temporary view cheat_classified_schema as
select 'column:' || c.table_name || ':' || c.column_name item,
 concat_ws('|', c.ordinal_position::text, c.data_type, c.udt_name, c.is_nullable, coalesce(c.column_default, '')) definition
from information_schema.columns c where c.table_schema = 'public' and c.table_name in ('cheat_meals', 'classified_checks')
union all
select 'constraint:' || t.relname || ':' || con.conname,
 pg_get_constraintdef(con.oid) || '|' || con.convalidated::text
from pg_constraint con join pg_class t on t.oid = con.conrelid join pg_namespace n on n.oid = t.relnamespace
where n.nspname = 'public' and t.relname in ('cheat_meals', 'classified_checks')
union all
select 'policy:' || tablename || ':' || policyname, concat_ws('|', permissive, roles::text, cmd, coalesce(qual, ''), coalesce(with_check, ''))
from pg_policies where schemaname = 'public' and tablename in ('cheat_meals', 'classified_checks')
union all
select 'index:' || tablename || ':' || indexname, indexdef from pg_indexes
where schemaname = 'public' and tablename in ('cheat_meals', 'classified_checks')
union all
select 'comment:' || c.relname, coalesce(obj_description(c.oid, 'pg_class'), '')
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('cheat_meals', 'classified_checks')
union all
select 'trigger:' || t.relname || ':' || tr.tgname, pg_get_triggerdef(tr.oid)
from pg_trigger tr join pg_class t on t.oid = tr.tgrelid join pg_namespace n on n.oid = t.relnamespace
where n.nspname = 'public' and t.relname in ('cheat_meals', 'classified_checks') and not tr.tgisinternal
union all
select 'function:limit', pg_get_functiondef('public.enforce_cheat_meal_monthly_limit()'::regprocedure)
union all
select 'rls:' || t.relname, t.relrowsecurity::text || '|' || t.relforcerowsecurity::text
from pg_class t join pg_namespace n on n.oid = t.relnamespace
where n.nspname = 'public' and t.relname in ('cheat_meals', 'classified_checks')
union all
select 'grant:' || c.relname || ':' || r.rolname || ':' || p.privilege, has_table_privilege(r.rolname, c.oid, p.privilege)::text
from pg_class c join pg_namespace n on n.oid = c.relnamespace
cross join (values ('anon'), ('authenticated'), ('service_role')) r(rolname)
cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')) p(privilege)
where n.nspname = 'public' and c.relname in ('cheat_meals', 'classified_checks');
create temporary table schema_before as select * from cheat_classified_schema;
create temporary table rows_before as
 select 'meal' kind, to_jsonb(c) row_data from public.cheat_meals c
 union all select 'check', to_jsonb(c) from public.classified_checks c;
\ir ../cheat_meals_limit_and_classified_checks.sql
select pg_temp.assert_test(
 not exists ((select * from schema_before except all select * from cheat_classified_schema)
 union all (select * from cheat_classified_schema except all select * from schema_before)),
 'second run preserves schema, RLS, triggers and grants');
select pg_temp.assert_test(
 not exists ((select * from rows_before except all
   (select 'meal', to_jsonb(c) from public.cheat_meals c union all select 'check', to_jsonb(c) from public.classified_checks c))
 union all ((select 'meal', to_jsonb(c) from public.cheat_meals c union all select 'check', to_jsonb(c) from public.classified_checks c)
   except all select * from rows_before)), 'second run preserves all rows');

begin;
select set_config('request.jwt.claims', '{}', true);
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000c01', true);
do $$ begin
 begin
  insert into public.cheat_meals(planned_date, notes) values ('2026-11-15', 'Third');
  raise exception 'Third meal unexpectedly accepted';
 exception when raise_exception then
  if position('cheat meal limit' in sqlerrm) = 0 then raise; end if;
 end;
 begin
  update public.cheat_meals set planned_date = '2026-11-15' where id = '00000000-0000-4000-8000-000000000c13';
  raise exception 'Move into full month unexpectedly accepted';
 exception when raise_exception then
  if position('cheat meal limit' in sqlerrm) = 0 then raise; end if;
 end;
 begin
  insert into public.classified_checks(item_key) values ('foundation_goal');
  raise exception 'Duplicate checklist item unexpectedly accepted';
 exception when unique_violation then null; end;
 begin
  insert into public.cheat_meals(planned_date, notes) values ('2027-01-01', '   ');
  raise exception 'Blank notes unexpectedly accepted';
 exception when check_violation then null; end;
 begin
  insert into public.cheat_meals(planned_date, notes) values ('2027-01-01', repeat('x', 201));
  raise exception 'Long notes unexpectedly accepted';
 exception when check_violation then null; end;
end $$;
update public.cheat_meals set notes = 'Edited' where id = '00000000-0000-4000-8000-000000000c11';
select pg_temp.assert_test((select notes = 'Edited' from public.cheat_meals where id = '00000000-0000-4000-8000-000000000c11'), 'notes edit succeeds at limit');
update public.cheat_meals set planned_date = '2027-01-01' where id = '00000000-0000-4000-8000-000000000c13';
select pg_temp.assert_test((select planned_date = '2027-01-01' from public.cheat_meals where id = '00000000-0000-4000-8000-000000000c13'), 'move into month with room succeeds');

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000c02', true);
select pg_temp.assert_test((select count(*) = 0 from public.cheat_meals) and
 (select count(*) = 0 from public.classified_checks), 'second user cannot read first user rows');
update public.cheat_meals set notes = 'Unauthorized' where id = '00000000-0000-4000-8000-000000000c11';
delete from public.cheat_meals where id = '00000000-0000-4000-8000-000000000c12';
delete from public.classified_checks where user_id = '00000000-0000-4000-8000-000000000c01';
do $$ begin
 begin
  insert into public.cheat_meals(user_id, planned_date, notes) values ('00000000-0000-4000-8000-000000000c01', '2027-02-01', 'Wrong owner');
  raise exception 'Wrong meal owner unexpectedly accepted';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.classified_checks(user_id, item_key) values ('00000000-0000-4000-8000-000000000c01', 'wrong_owner');
  raise exception 'Wrong checklist owner unexpectedly accepted';
 exception when insufficient_privilege then null; end;
end $$;
insert into public.cheat_meals(planned_date, notes) values ('2026-11-10', 'Other user first'), ('2026-11-11', 'Other user second');
insert into public.classified_checks(item_key) values ('foundation_goal');
delete from public.classified_checks where item_key = 'foundation_goal';
select pg_temp.assert_test((select count(*) = 2 from public.cheat_meals) and
 (select count(*) = 0 from public.classified_checks), 'other user has own limit and delete unchecks');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000c01', true);
select pg_temp.assert_test((select notes = 'Edited' from public.cheat_meals where id = '00000000-0000-4000-8000-000000000c11') and
 (select count(*) = 1 from public.cheat_meals where id = '00000000-0000-4000-8000-000000000c12') and
 (select count(*) = 1 from public.classified_checks where item_key = 'foundation_goal'), 'other user did not alter owner rows');
rollback;

-- Remove only the two test users and their cascading fixtures.
delete from auth.users where id in ('00000000-0000-4000-8000-000000000c01', '00000000-0000-4000-8000-000000000c02');
