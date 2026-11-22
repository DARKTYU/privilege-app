-- Proposed only. Review and apply manually in the Supabase SQL Editor.
-- Restores already-consumed quota units for a provider failure. Do not call this
-- until the provider request has conclusively failed and no retry remains.

begin;

create or replace function public.coach_refund_quota(
  p_user uuid,
  p_cost integer,
  p_usage_date date default (pg_catalog.clock_timestamp() at time zone 'UTC')::date
)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_remaining_cost integer;
begin
  if p_user is null or p_cost is null or p_cost < 1 or p_usage_date is null then
    raise exception 'A user, positive cost, and usage date are required';
  end if;

  select request_count into v_remaining_cost
  from public.coach_usage
  where user_id = p_user and usage_date = p_usage_date
  for update;

  if v_remaining_cost is null then return 0; end if;
  if v_remaining_cost <= p_cost then
    delete from public.coach_usage
    where user_id = p_user and usage_date = p_usage_date;
    return 0;
  end if;

  update public.coach_usage
  set request_count = request_count - p_cost
  where user_id = p_user and usage_date = p_usage_date
  returning request_count into v_remaining_cost;

  return v_remaining_cost;
end
$$;

revoke all on function public.coach_refund_quota(uuid, integer, date)
  from public, anon, authenticated;
grant execute on function public.coach_refund_quota(uuid, integer, date)
  to service_role;

commit;
