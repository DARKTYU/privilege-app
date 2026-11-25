-- Gives back coach quota when the AI provider failed (busy, timeout, network).
-- Apply once in the Supabase SQL Editor of the REAL project, after coach_quota.sql.
-- Safe to re-run. The coach function calls this on a best-effort basis: until
-- this is applied, nothing breaks, failed requests simply stay charged.
begin;

create or replace function public.coach_refund_quota(p_user uuid, p_cost integer)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_date date := (pg_catalog.clock_timestamp() at time zone 'UTC')::date;
begin
  if p_user is null or p_cost is null or p_cost < 1 then
    raise exception 'A user and a positive cost are required';
  end if;

  -- coach_usage.request_count must stay above zero, so a refund that would
  -- reach zero removes today's row instead.
  update public.coach_usage
     set request_count = request_count - p_cost
   where user_id = p_user and usage_date = v_date and request_count > p_cost;
  if not found then
    delete from public.coach_usage
     where user_id = p_user and usage_date = v_date and request_count <= p_cost;
  end if;
end
$$;

revoke all on function public.coach_refund_quota(uuid, integer)
  from public, anon, authenticated;
grant execute on function public.coach_refund_quota(uuid, integer)
  to service_role;

commit;
