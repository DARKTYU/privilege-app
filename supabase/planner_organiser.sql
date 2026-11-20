-- Run manually in the Supabase SQL Editor after schema.sql.
begin;

create table if not exists public.planner_splits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references public.profiles(id) on delete cascade,
  name text not null
    check (char_length(btrim(name)) >= 1 and char_length(name) <= 100),
  kind text not null check (kind in ('workout', 'rest')),
  default_duration_minutes integer,
  default_effort_percent integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (kind = 'rest'
      and default_duration_minutes is null
      and default_effort_percent is null)
    or
    (kind = 'workout'
      and default_duration_minutes is not null
      and default_duration_minutes between 1 and 600
      and default_effort_percent is not null
      and default_effort_percent between 0 and 100)
  )
);

create index if not exists planner_splits_user_idx
  on public.planner_splits (user_id, name);

create table if not exists public.planner_days (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references public.profiles(id) on delete cascade,
  planned_date date not null,
  source_split_id uuid,
  name text not null
    check (char_length(btrim(name)) >= 1 and char_length(name) <= 100),
  kind text not null check (kind in ('workout', 'rest')),
  duration_minutes integer,
  effort_percent integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, planned_date),
  check (
    (kind = 'rest'
      and duration_minutes is null
      and effort_percent is null)
    or
    (kind = 'workout'
      and duration_minutes is not null
      and duration_minutes between 1 and 600
      and effort_percent is not null
      and effort_percent between 0 and 100)
  )
);

alter table public.planner_splits enable row level security;
alter table public.planner_days enable row level security;

revoke all on public.planner_splits, public.planner_days
  from public, anon, authenticated;
grant select, insert, update, delete
  on public.planner_splits, public.planner_days to authenticated;
grant all on public.planner_splits, public.planner_days to service_role;

drop policy if exists planner_splits_owner on public.planner_splits;
create policy planner_splits_owner on public.planner_splits
  for all to authenticated
  using (public.is_registered_user() and user_id = auth.uid())
  with check (public.is_registered_user() and user_id = auth.uid());

drop policy if exists planner_days_owner on public.planner_days;
create policy planner_days_owner on public.planner_days
  for all to authenticated
  using (public.is_registered_user() and user_id = auth.uid())
  with check (public.is_registered_user() and user_id = auth.uid());

drop trigger if exists planner_splits_updated_at on public.planner_splits;
create trigger planner_splits_updated_at before update on public.planner_splits
  for each row execute function public.touch_updated_at();

drop trigger if exists planner_days_updated_at on public.planner_days;
create trigger planner_days_updated_at before update on public.planner_days
  for each row execute function public.touch_updated_at();

commit;
