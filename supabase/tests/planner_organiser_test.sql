-- NEVER run this in the real project. ISOLATED TEST DATABASE ONLY.
-- Run with psql -v ON_ERROR_STOP=1 -f supabase/tests/planner_organiser_test.sql
-- after schema.sql. The migration commits, so a failed run may leave fixtures.
\set ON_ERROR_STOP on
\ir ../planner_organiser.sql

begin;
insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-4000-8000-000000000b01', '{}'),
 ('00000000-0000-4000-8000-000000000b02', '{}');
select set_config('request.jwt.claims', '{}', true);
set local role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-000000000b01', true);
insert into public.planner_splits
 (id, name, kind, default_duration_minutes, default_effort_percent)
values
 ('00000000-0000-4000-8000-000000000b11', 'Strength', 'workout', 60, 80);
insert into public.planner_days
 (id, planned_date, source_split_id, name, kind, duration_minutes, effort_percent)
values
 ('00000000-0000-4000-8000-000000000b21', '2026-11-20',
  '00000000-0000-4000-8000-000000000b11', 'Strength', 'workout', 60, 80);
commit;

-- Compare logical definitions and row data, not recreated policy/trigger OIDs.
create temporary view planner_schema_snapshot as
select 'column:' || c.table_name || ':' || c.column_name as item,
 concat_ws('|', c.ordinal_position::text, c.data_type, c.udt_name,
   c.is_nullable, coalesce(c.column_default, '')) as definition
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name in ('planner_splits', 'planner_days')
union all
select 'constraint:' || t.relname || ':' || con.conname,
 pg_get_constraintdef(con.oid)
from pg_constraint con
join pg_class t on t.oid = con.conrelid
join pg_namespace n on n.oid = t.relnamespace
where n.nspname = 'public' and t.relname in ('planner_splits', 'planner_days')
union all
select 'index:' || tablename || ':' || indexname, indexdef
from pg_indexes
where schemaname = 'public' and tablename in ('planner_splits', 'planner_days')
union all
select 'policy:' || tablename || ':' || policyname,
 concat_ws('|', permissive, roles::text, cmd, coalesce(qual, ''),
   coalesce(with_check, ''))
from pg_policies
where schemaname = 'public' and tablename in ('planner_splits', 'planner_days')
union all
select 'trigger:' || t.relname || ':' || tr.tgname, pg_get_triggerdef(tr.oid)
from pg_trigger tr
join pg_class t on t.oid = tr.tgrelid
join pg_namespace n on n.oid = t.relnamespace
where n.nspname = 'public' and t.relname in ('planner_splits', 'planner_days')
  and not tr.tgisinternal
union all
select 'rls:' || t.relname, t.relrowsecurity::text || '|' || t.relforcerowsecurity::text
from pg_class t join pg_namespace n on n.oid = t.relnamespace
where n.nspname = 'public' and t.relname in ('planner_splits', 'planner_days')
union all
select 'grant:' || c.relname || ':' || r.rolname || ':' || p.privilege,
 has_table_privilege(r.rolname, c.oid, p.privilege)::text
from pg_class c join pg_namespace n on n.oid = c.relnamespace
cross join (values ('anon'), ('authenticated'), ('service_role')) as r(rolname)
cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')) as p(privilege)
where n.nspname = 'public' and c.relname in ('planner_splits', 'planner_days');

create temporary table planner_schema_before as
 select * from planner_schema_snapshot;
create temporary table planner_rows_before as
 select 'split' as kind, to_jsonb(s) as row_data from public.planner_splits s
 union all
 select 'day', to_jsonb(d) from public.planner_days d;

\ir ../planner_organiser.sql

create function pg_temp.assert_planner(ok boolean, message text)
returns void language plpgsql as $$
begin
 if ok is distinct from true then raise exception 'Test failed: %', message; end if;
end $$;

select pg_temp.assert_planner(
 not exists (
   (select * from planner_schema_before except all select * from planner_schema_snapshot)
   union all
   (select * from planner_schema_snapshot except all select * from planner_schema_before)
 ), 'second migration run preserves definitions, policies, grants and indexes');
select pg_temp.assert_planner(
 not exists (
   (select kind, row_data from planner_rows_before
    except all
    (select 'split', to_jsonb(s) from public.planner_splits s
     union all select 'day', to_jsonb(d) from public.planner_days d))
   union all
   ((select 'split', to_jsonb(s) from public.planner_splits s
     union all select 'day', to_jsonb(d) from public.planner_days d)
    except all select kind, row_data from planner_rows_before)
 ), 'second migration run preserves all planner rows');

begin;
select set_config('request.jwt.claims', '{}', true);
set local role authenticated;
select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-000000000b01', true);
select pg_temp.assert_planner(
 (select count(*) = 1 from public.planner_splits),
 'owner can read own split');
select pg_temp.assert_planner(
 (select count(*) = 1 from public.planner_days),
 'owner can read own day');
do $$ begin
 begin
  update public.planner_splits
  set user_id = '00000000-0000-4000-8000-000000000b02'
  where id = '00000000-0000-4000-8000-000000000b11';
  raise exception 'Split owner change accepted';
 exception when insufficient_privilege then null; end;
 begin
  update public.planner_days
  set user_id = '00000000-0000-4000-8000-000000000b02'
  where id = '00000000-0000-4000-8000-000000000b21';
  raise exception 'Day owner change accepted';
 exception when insufficient_privilege then null; end;
end $$;
update public.planner_splits set name = 'Strength edited', updated_at = '2000-01-01'
 where id = '00000000-0000-4000-8000-000000000b11';
update public.planner_days set name = 'Strength edited', updated_at = '2000-01-01'
 where id = '00000000-0000-4000-8000-000000000b21';
select pg_temp.assert_planner(
 (select updated_at = now() from public.planner_splits
  where id = '00000000-0000-4000-8000-000000000b11')
 and (select updated_at = now() from public.planner_days
  where id = '00000000-0000-4000-8000-000000000b21'),
 'owner edits update timestamps');
update public.planner_splits set name = 'Strength'
 where id = '00000000-0000-4000-8000-000000000b11';
update public.planner_days set name = 'Strength'
 where id = '00000000-0000-4000-8000-000000000b21';

-- Test both tables with the same invalid names, kinds, durations and efforts.
do $$
declare
 table_name text;
 duration_column text;
 effort_column text;
 bad record;
begin
 for table_name, duration_column, effort_column in
  select * from (values
   ('planner_splits', 'default_duration_minutes', 'default_effort_percent'),
   ('planner_days', 'duration_minutes', 'effort_percent')
  ) as t(table_name, duration_column, effort_column)
 loop
  for bad in
   select * from (values
    ('', 'workout', 60, 80),
    ('   ', 'workout', 60, 80),
    (repeat('x', 101), 'workout', 60, 80),
    ('Name', 'unknown', 60, 80),
    ('Name', 'workout', 0, 80),
    ('Name', 'workout', 601, 80),
    ('Name', 'workout', null::integer, 80),
    ('Name', 'workout', 60, -1),
    ('Name', 'workout', 60, 101),
    ('Name', 'workout', 60, null::integer),
    ('Name', 'rest', 30, null::integer),
    ('Name', 'rest', null::integer, 10)
   ) as v(name, kind, duration, effort)
  loop
   begin
    if table_name = 'planner_days' then
     execute format(
      'insert into public.%I (name, kind, %I, %I, planned_date) values ($1,$2,$3,$4,$5)',
      table_name, duration_column, effort_column)
      using bad.name, bad.kind, bad.duration, bad.effort, date '2026-11-21';
    else
     execute format(
      'insert into public.%I (name, kind, %I, %I) values ($1,$2,$3,$4)',
      table_name, duration_column, effort_column)
      using bad.name, bad.kind, bad.duration, bad.effort;
    end if;
    raise exception 'Invalid values accepted by %', table_name;
   exception when check_violation then null;
   end;
  end loop;
 end loop;
end $$;

insert into public.planner_splits
 (name, kind, default_duration_minutes, default_effort_percent)
values ('Lower boundary', 'workout', 1, 0),
       (repeat('x', 100), 'workout', 600, 100),
       ('Rest', 'rest', null, null);
insert into public.planner_days
 (planned_date, name, kind, duration_minutes, effort_percent)
values ('2026-11-21', 'Lower boundary', 'workout', 1, 0),
       ('2026-11-22', repeat('x', 100), 'workout', 600, 100),
       ('2026-11-23', 'Rest', 'rest', null, null);
do $$ begin
 begin
  insert into public.planner_days
   (planned_date, name, kind, duration_minutes, effort_percent)
  values ('2026-11-20', 'Duplicate', 'workout', 30, 50);
  raise exception 'Duplicate date accepted';
 exception when unique_violation then null; end;
end $$;

select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-000000000b02', true);
select pg_temp.assert_planner(
 (select count(*) = 0 from public.planner_splits)
 and (select count(*) = 0 from public.planner_days),
 'second user cannot read first user rows');
do $$
declare affected integer;
begin
 update public.planner_splits set name = 'Changed'
 where id = '00000000-0000-4000-8000-000000000b11';
 get diagnostics affected = row_count;
 if affected <> 0 then raise exception 'Second user changed split'; end if;
 delete from public.planner_splits
 where id = '00000000-0000-4000-8000-000000000b11';
 get diagnostics affected = row_count;
 if affected <> 0 then raise exception 'Second user deleted split'; end if;
 update public.planner_days set name = 'Changed'
 where id = '00000000-0000-4000-8000-000000000b21';
 get diagnostics affected = row_count;
 if affected <> 0 then raise exception 'Second user changed day'; end if;
 delete from public.planner_days
 where id = '00000000-0000-4000-8000-000000000b21';
 get diagnostics affected = row_count;
 if affected <> 0 then raise exception 'Second user deleted day'; end if;
 begin
  insert into public.planner_splits
   (user_id, name, kind, default_duration_minutes, default_effort_percent)
  values ('00000000-0000-4000-8000-000000000b01', 'Spoof', 'workout', 60, 80);
  raise exception 'Split owner spoof accepted';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.planner_days
   (user_id, planned_date, name, kind, duration_minutes, effort_percent)
  values ('00000000-0000-4000-8000-000000000b01', '2026-11-24',
   'Spoof', 'workout', 60, 80);
  raise exception 'Day owner spoof accepted';
 exception when insufficient_privilege then null; end;
end $$;
insert into public.planner_days
 (planned_date, name, kind, duration_minutes, effort_percent)
values ('2026-11-20', 'Own day', 'workout', 30, 50);

select set_config('request.jwt.claim.sub',
 '00000000-0000-4000-8000-000000000b01', true);
select pg_temp.assert_planner(
 (select name = 'Strength' from public.planner_splits
  where id = '00000000-0000-4000-8000-000000000b11')
 and (select name = 'Strength' from public.planner_days
  where id = '00000000-0000-4000-8000-000000000b21'),
 'second user did not change or delete rows');
delete from public.planner_splits
 where id = '00000000-0000-4000-8000-000000000b11';
select pg_temp.assert_planner(
 (select name = 'Strength'
    and source_split_id = '00000000-0000-4000-8000-000000000b11'
    and duration_minutes = 60 and effort_percent = 80
  from public.planner_days
  where id = '00000000-0000-4000-8000-000000000b21'),
 'deleting split leaves its day snapshot unchanged');
rollback;

-- Cleanup the committed fixtures on success; a failure stops before cleanup.
delete from auth.users where id in
 ('00000000-0000-4000-8000-000000000b01',
  '00000000-0000-4000-8000-000000000b02');
