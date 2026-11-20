-- NEVER run this in the real project. ISOLATED TEST DATABASE ONLY.
-- Run with psql -v ON_ERROR_STOP=1 -f supabase/tests/coach_quota_test.sql
-- after schema.sql. The migration commits, so failures may leave fixtures.
\set ON_ERROR_STOP on
\ir ../coach_quota.sql

insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-4000-8000-00000000c101', '{}'),
 ('00000000-0000-4000-8000-00000000c102', '{}');

create function pg_temp.assert_coach(ok boolean, message text)
returns void language plpgsql as $$
begin
  if ok is distinct from true then raise exception 'Test failed: %', message; end if;
end
$$;

select pg_temp.assert_coach(
 not has_table_privilege('authenticated', 'public.coach_usage', 'select')
 and not has_table_privilege('anon', 'public.coach_usage', 'select')
 and not has_function_privilege('authenticated', 'public.coach_consume_quota(uuid,integer)', 'execute')
 and not has_function_privilege('anon', 'public.coach_consume_quota(uuid,integer)', 'execute')
 and has_function_privilege('service_role', 'public.coach_consume_quota(uuid,integer)', 'execute')
 and (select relrowsecurity from pg_class where oid = 'public.coach_usage'::regclass)
 and not exists (select 1 from pg_policy where polrelid = 'public.coach_usage'::regclass),
 'quota is service-only with RLS and no policies');

set role service_role;
select pg_temp.assert_coach(allowed and remaining = 1
 and reset_at = (((clock_timestamp() at time zone 'UTC')::date + 1)::timestamp at time zone 'UTC'),
 'first request allowed and reset at next UTC midnight')
from public.coach_consume_quota('00000000-0000-4000-8000-00000000c101', 2);
select pg_temp.assert_coach(allowed and remaining = 0, 'second request allowed')
from public.coach_consume_quota('00000000-0000-4000-8000-00000000c101', 2);
select pg_temp.assert_coach(not allowed and remaining = 0, 'third request denied')
from public.coach_consume_quota('00000000-0000-4000-8000-00000000c101', 2);
select pg_temp.assert_coach(allowed and remaining = 1, 'other user has separate quota')
from public.coach_consume_quota('00000000-0000-4000-8000-00000000c102', 2);
select pg_temp.assert_coach(
 (select request_count = 2 from public.coach_usage
  where user_id = '00000000-0000-4000-8000-00000000c101'
  and usage_date = (clock_timestamp() at time zone 'UTC')::date),
 'denied request does not increment');
do $$ begin
 begin
  perform public.coach_consume_quota('00000000-0000-4000-8000-00000000c101', 0);
  raise exception 'Invalid limit accepted';
 exception when raise_exception then
  if sqlerrm = 'Invalid limit accepted' then raise; end if;
 end;
end $$;
reset role;

create temporary table coach_rows_before as select * from public.coach_usage;
\ir ../coach_quota.sql
select pg_temp.assert_coach(
 not exists ((select * from coach_rows_before except all select * from public.coach_usage)
 union all (select * from public.coach_usage except all select * from coach_rows_before)),
 'second migration preserves usage');
select pg_temp.assert_coach(
 not exists (select 1 from pg_policy where polrelid = 'public.coach_usage'::regclass)
 and not has_function_privilege('authenticated', 'public.coach_consume_quota(uuid,integer)', 'execute')
 and has_function_privilege('service_role', 'public.coach_consume_quota(uuid,integer)', 'execute'),
 'second migration preserves access restrictions');

delete from auth.users where id in
 ('00000000-0000-4000-8000-00000000c101', '00000000-0000-4000-8000-00000000c102');
