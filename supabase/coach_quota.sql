-- Run manually in the Supabase SQL Editor after schema.sql.
begin;

create table if not exists public.coach_usage (
  user_id uuid not null references public.profiles(id) on delete cascade,
  usage_date date not null,
  request_count integer not null check (request_count > 0),
  primary key (user_id, usage_date)
);

alter table public.coach_usage enable row level security;
revoke all on public.coach_usage from public, anon, authenticated;
grant select, insert, update, delete on public.coach_usage to service_role;

do $$
begin
  if exists (
    select 1 from pg_catalog.pg_policy
    where polrelid = 'public.coach_usage'::regclass
  ) then
    raise exception 'coach_usage must not have RLS policies';
  end if;
end
$$;

create or replace function public.coach_consume_quota(p_user uuid, p_limit integer)
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
  if p_user is null or p_limit is null or p_limit < 1 then
    raise exception 'A user and a positive quota limit are required';
  end if;

  insert into public.coach_usage as usage (user_id, usage_date, request_count)
  values (p_user, v_date, 1)
  on conflict (user_id, usage_date) do update
    set request_count = usage.request_count + 1
    where usage.request_count < p_limit
  returning request_count into v_count;

  return query select v_count is not null,
    case when v_count is null then 0 else p_limit - v_count end,
    (v_date + 1)::timestamp at time zone 'UTC';
end
$$;

revoke all on function public.coach_consume_quota(uuid, integer)
  from public, anon, authenticated;
grant execute on function public.coach_consume_quota(uuid, integer)
  to service_role;

commit;
