-- Proposal only. Review and apply manually in the Supabase SQL Editor after
-- supabase/coach_quota.sql has already been applied. This file is not run by CI.
-- A cost of 3 gives photo requests one third the daily allowance of text requests;
-- at the default limit of 30, that permits about 10 photo requests per day.

begin;

create or replace function public.coach_consume_quota(
  p_user uuid,
  p_limit integer,
  p_cost integer
)
returns table (allowed boolean, remaining integer, reset_at timestamptz)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_now timestamptz := pg_catalog.clock_timestamp();
  v_date date := (v_now at time zone 'UTC')::date;
  v_count integer;
begin
  if p_user is null or p_limit is null or p_limit < 1
     or p_cost is null or p_cost < 1 or p_cost > p_limit then
    raise exception 'A user, positive quota limit, and valid cost are required';
  end if;

  insert into public.coach_usage as usage (user_id, usage_date, request_count)
  values (p_user, v_date, p_cost)
  on conflict (user_id, usage_date) do update
    set request_count = usage.request_count + p_cost
    where usage.request_count + p_cost <= p_limit
  returning request_count into v_count;

  return query select v_count is not null,
    case when v_count is null then 0 else p_limit - v_count end,
    (v_date + 1)::timestamp at time zone 'UTC';
end
$$;

revoke all on function public.coach_consume_quota(uuid, integer, integer)
  from public, anon, authenticated;
grant execute on function public.coach_consume_quota(uuid, integer, integer)
  to service_role;

commit;
