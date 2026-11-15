-- Stage 1: persistent activity, local-day streaks, and server-awarded XP/points.
-- Apply after schema.sql, seed.sql, and auth_migration.sql. This migration
-- extends existing tables and never replaces or clears their data.

alter table public.profiles
  add column if not exists activity_timezone text,
  add column if not exists pending_activity_timezone text,
  add column if not exists timezone_change_effective_at timestamptz;

alter table public.meal_logs
  add column if not exists category text not null default 'snack',
  add column if not exists icon text not null default '🍽️',
  add column if not exists fiber_g numeric(10,2) not null default 0,
  add column if not exists consumed boolean not null default true;

alter table public.workout_logs
  add column if not exists name text not null default 'Workout',
  add column if not exists calories_burned integer not null default 0,
  add column if not exists category text not null default 'strength',
  add column if not exists icon text not null default '🏋️';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'meal_logs_category_check'
      and conrelid = 'public.meal_logs'::regclass
  ) then
    alter table public.meal_logs add constraint meal_logs_category_check
      check (category in ('breakfast', 'lunch', 'shake', 'dinner', 'snack'));
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'meal_logs_fiber_g_check'
      and conrelid = 'public.meal_logs'::regclass
  ) then
    alter table public.meal_logs add constraint meal_logs_fiber_g_check
      check (fiber_g >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'workout_logs_category_check'
      and conrelid = 'public.workout_logs'::regclass
  ) then
    alter table public.workout_logs add constraint workout_logs_category_check
      check (category in ('strength', 'cardio', 'mobility'));
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'workout_logs_calories_burned_check'
      and conrelid = 'public.workout_logs'::regclass
  ) then
    alter table public.workout_logs add constraint workout_logs_calories_burned_check
      check (calories_burned >= 0);
  end if;
end
$$;

comment on column public.profiles.activity_timezone is
  'IANA timezone used for local activity dates; populated from the signed-in device.';
comment on column public.profiles.pending_activity_timezone is
  'Timezone scheduled to take effect at the next local midnight.';
comment on column public.meal_logs.category is 'Privilege UI meal category; shake maps to the existing snack meal_type.';
comment on column public.meal_logs.icon is 'Emoji used by the activity log UI.';
comment on column public.meal_logs.fiber_g is 'Dietary fiber in grams.';
comment on column public.meal_logs.consumed is 'Whether this meal is counted in daily nutrition totals.';
comment on column public.workout_logs.name is 'User-facing name of the completed workout.';
comment on column public.workout_logs.calories_burned is 'Self-reported calories burned by the completed workout.';
comment on column public.workout_logs.category is 'Privilege UI workout category.';
comment on column public.workout_logs.icon is 'Emoji used by the activity log UI.';

create table if not exists public.activity_reward_days (
  user_id uuid not null references public.profiles(id) on delete cascade,
  activity_date date not null,
  created_at timestamptz not null default now(),
  primary key (user_id, activity_date)
);
comment on table public.activity_reward_days is
  'Private idempotency ledger preventing multiple daily XP/store-point awards.';

create table if not exists public.store_points_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  points integer not null check (points <> 0),
  reason text not null,
  activity_date date not null,
  entry_type text not null default 'activity'
    check (entry_type in ('activity', 'redemption', 'challenge', 'adjustment')),
  created_at timestamptz not null default now()
);
comment on table public.store_points_ledger is
  'Immutable store-points transaction ledger, separate from XP and readable only by its owner.';

create table if not exists public.streak_freeze_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  freeze_month date not null check (extract(day from freeze_month) = 1),
  missed_date date not null,
  created_at timestamptz not null default now(),
  unique (user_id, freeze_month)
);
comment on table public.streak_freeze_usage is
  'Server-only record of the one automatically used missed-day freeze per calendar month.';

create table if not exists public.activity_streak_anchors (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  start_date date not null,
  last_activity_date date not null,
  current_streak integer not null check (current_streak >= 0),
  longest_streak integer not null check (longest_streak >= current_streak)
);
comment on table public.activity_streak_anchors is
  'Private baseline preserving streak history created before activity triggers were installed.';

insert into public.activity_streak_anchors(
  user_id, start_date, last_activity_date, current_streak, longest_streak
)
select user_id,
       last_activity_date - greatest(current_streak - 1, 0),
       last_activity_date,
       current_streak,
       longest_streak
  from public.streaks
 where last_activity_date is not null
   and current_streak > 0
on conflict(user_id) do nothing;

create index if not exists store_points_ledger_user_date_idx
  on public.store_points_ledger(user_id, activity_date desc);
create unique index if not exists store_points_activity_daily_unique_idx
  on public.store_points_ledger(user_id, activity_date)
  where entry_type = 'activity';
create index if not exists streak_freeze_usage_user_date_idx
  on public.streak_freeze_usage(user_id, missed_date);
create index if not exists meal_logs_user_date_created_idx
  on public.meal_logs(user_id, logged_date, created_at desc);
create index if not exists workout_logs_user_date_created_idx
  on public.workout_logs(user_id, activity_date, created_at desc);

alter table public.activity_reward_days enable row level security;
alter table public.streak_freeze_usage enable row level security;
alter table public.activity_streak_anchors enable row level security;
alter table public.store_points_ledger enable row level security;
revoke all on public.activity_reward_days, public.streak_freeze_usage,
  public.store_points_ledger, public.activity_streak_anchors
  from public, anon, authenticated;
grant all on public.activity_reward_days, public.streak_freeze_usage,
  public.store_points_ledger, public.activity_streak_anchors to service_role;
grant select on public.store_points_ledger to authenticated;
drop policy if exists registered_accounts_only on public.store_points_ledger;
create policy registered_accounts_only on public.store_points_ledger
  as restrictive for all to authenticated
  using (public.is_registered_user())
  with check (public.is_registered_user());
drop policy if exists own_store_points on public.store_points_ledger;
create policy own_store_points on public.store_points_ledger
  for select to authenticated using (user_id = auth.uid());

create or replace function public.activity_timezone_for_user(p_user_id uuid)
returns text
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    case
      when p.pending_activity_timezone is not null
       and now() >= p.timezone_change_effective_at
        then p.pending_activity_timezone
      else p.activity_timezone
    end,
    'UTC'
  )
  from public.profiles p
  where p.id = p_user_id
$$;
comment on function public.activity_timezone_for_user(uuid) is
  'Returns the active IANA timezone, applying pending changes at local midnight.';

create or replace function public.set_activity_timezone(p_timezone text)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  active_timezone text;
  pending_timezone text;
  effective_at_current timestamptz;
  effective_at timestamptz;
begin
  if not public.is_registered_user() then
    raise exception 'A registered account is required';
  end if;
  if p_timezone is null or not exists (
    select 1 from pg_catalog.pg_timezone_names where name = p_timezone
  ) then
    raise exception 'Invalid IANA timezone';
  end if;

  select activity_timezone, pending_activity_timezone, timezone_change_effective_at
    into active_timezone, pending_timezone, effective_at_current
    from public.profiles
   where id = auth.uid()
   for update;
  if not found then raise exception 'Profile not found'; end if;

  if active_timezone is null then
    update public.profiles
       set activity_timezone = p_timezone,
           pending_activity_timezone = null,
           timezone_change_effective_at = null
     where id = auth.uid();
    return;
  end if;

  if pending_timezone is not null and now() >= effective_at_current then
    active_timezone := pending_timezone;
    update public.profiles
       set activity_timezone = active_timezone,
           pending_activity_timezone = null,
           timezone_change_effective_at = null
     where id = auth.uid();
  end if;

  if p_timezone = active_timezone then
    update public.profiles
       set pending_activity_timezone = null,
           timezone_change_effective_at = null
     where id = auth.uid();
  else
    effective_at :=
      (((now() at time zone active_timezone)::date + 1)::timestamp
        at time zone active_timezone);
    update public.profiles
       set pending_activity_timezone = p_timezone,
           timezone_change_effective_at = effective_at
     where id = auth.uid();
  end if;
end
$$;
comment on function public.set_activity_timezone(text) is
  'Sets the device IANA timezone; subsequent changes take effect next local midnight.';
revoke all on function public.set_activity_timezone(text) from public, anon;
grant execute on function public.set_activity_timezone(text) to authenticated;

create or replace function public.activity_today()
returns date
language sql stable security definer set search_path = ''
as $$
  select (now() at time zone
    public.activity_timezone_for_user(auth.uid()))::date
  where public.is_registered_user()
$$;
comment on function public.activity_today() is
  'Returns the signed-in user’s current local calendar date.';
revoke all on function public.activity_today() from public, anon;
grant execute on function public.activity_today() to authenticated;

create or replace function public.store_points_balance()
returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce(sum(points), 0)::bigint
    from public.store_points_ledger
   where user_id = auth.uid()
     and public.is_registered_user()
$$;
comment on function public.store_points_balance() is
  'Returns the signed-in user’s store-points balance without loading the full ledger.';
revoke all on function public.store_points_balance() from public, anon;
grant execute on function public.store_points_balance() to authenticated;

create or replace function public.guard_activity_log()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  expected_date date;
  owner_id uuid;
begin
  owner_id := case when tg_op = 'DELETE' then old.user_id else new.user_id end;
  if auth.uid() is not null then
    if not public.is_registered_user() or owner_id <> auth.uid() then
      raise exception 'Activity log owner does not match the signed-in user';
    end if;
  end if;

  if tg_op = 'UPDATE' then
    if new.user_id <> old.user_id then
      raise exception 'Activity log owner and date cannot be changed';
    end if;
    if tg_table_name = 'meal_logs' then
      if new.logged_date <> old.logged_date then
        raise exception 'Activity log owner and date cannot be changed';
      end if;
      if new.consumed and not old.consumed then
        expected_date := (now() at time zone public.activity_timezone_for_user(owner_id))::date;
        if new.logged_date <> expected_date then
          raise exception 'Only today’s meal can be checked as consumed';
        end if;
      end if;
    else
      if new.activity_date <> old.activity_date then
        raise exception 'Activity log owner and date cannot be changed';
      end if;
    end if;
    return new;
  end if;

  if tg_op = 'INSERT' then
    expected_date := (now() at time zone public.activity_timezone_for_user(owner_id))::date;
    if tg_table_name = 'meal_logs' then
      if new.logged_date <> expected_date then
        raise exception 'Activity can only be logged for today in your active timezone';
      end if;
    else
      if new.activity_date <> expected_date then
        raise exception 'Activity can only be logged for today in your active timezone';
      end if;
    end if;
    return new;
  end if;
  return old;
end
$$;
comment on function public.guard_activity_log() is
  'Rejects client-supplied historical activity and prevents changing log ownership or dates.';

create or replace function public.recalculate_activity_streak(p_user_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  activity_day date;
  previous_day date;
  run_length integer := 0;
  longest integer := 0;
  last_day date;
begin
  perform 1 from public.profiles where id = p_user_id for update;
  select coalesce(max(longest_streak), 0)
    into longest from public.activity_streak_anchors
   where user_id = p_user_id;
  for activity_day in
    select distinct d
      from (
        select a.start_date + days.day_offset as d
          from public.activity_streak_anchors a
          cross join lateral generate_series(
            0, a.last_activity_date - a.start_date
          ) as days(day_offset)
         where a.user_id = p_user_id
        union all
        select logged_date as d from public.meal_logs
         where user_id = p_user_id and consumed
        union all
        select activity_date as d from public.workout_logs
         where user_id = p_user_id
      ) activity_days
     order by d
  loop
    last_day := activity_day;
    if previous_day is null then
      run_length := 1;
    elsif activity_day = previous_day + 1 then
      run_length := run_length + 1;
    elsif activity_day = previous_day + 2 and exists (
      select 1 from public.streak_freeze_usage f
       where f.user_id = p_user_id and f.missed_date = previous_day + 1
    ) then
      run_length := run_length + 2;
    else
      run_length := 1;
    end if;
    longest := greatest(longest, run_length);
    previous_day := activity_day;
  end loop;

  if last_day is null then
    update public.streaks
       set current_streak = 0, last_activity_date = null
     where user_id = p_user_id;
  else
    update public.streaks
       set current_streak = case
             when last_day >= (now() at time zone
               public.activity_timezone_for_user(p_user_id))::date - 1
               then run_length else 0 end,
           longest_streak = greatest(longest_streak, longest, current_streak),
           last_activity_date = last_day
     where user_id = p_user_id;
  end if;
end
$$;
comment on function public.recalculate_activity_streak(uuid) is
  'Recalculates the current and longest streak from completed activity and already-used freezes.';

create or replace function public.award_activity_day(p_user_id uuid, p_date date)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if p_date <> (now() at time zone
       public.activity_timezone_for_user(p_user_id))::date then
    raise exception 'Rewards can only be earned for today';
  end if;
  insert into public.activity_reward_days(user_id, activity_date)
  values(p_user_id, p_date)
  on conflict(user_id, activity_date) do nothing;
  if found then
    insert into public.xp_points(user_id, points, reason)
    values(p_user_id, 10, 'Daily activity XP: ' || p_date::text);
    insert into public.store_points_ledger(
      user_id, points, reason, activity_date, entry_type
    )
    values(p_user_id, 10, 'Daily activity points', p_date, 'activity');
  end if;
end
$$;
comment on function public.award_activity_day(uuid, date) is
  'Atomically awards at most 10 XP and 10 store points for one active calendar day.';

create or replace function public.process_activity_log()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  owner_id uuid;
  activity_day date;
  previous_day date;
  v_freeze_month date;
begin
  owner_id := case when tg_op = 'DELETE' then old.user_id else new.user_id end;

  if tg_op = 'INSERT' then
    if tg_table_name = 'meal_logs' then
      activity_day := new.logged_date;
      if not new.consumed then return new; end if;
    else
      activity_day := new.activity_date;
    end if;

    insert into public.streaks(user_id, current_streak, longest_streak, last_activity_date)
    values(owner_id, 0, 0, null)
    on conflict(user_id) do nothing;
    select last_activity_date into previous_day
      from public.streaks where user_id = owner_id for update;

    if previous_day is not null and activity_day = previous_day + 2 then
      v_freeze_month := date_trunc('month', previous_day + 1)::date;
      insert into public.streak_freeze_usage(user_id, freeze_month, missed_date)
      values(owner_id, v_freeze_month, previous_day + 1)
      on conflict(user_id, freeze_month) do nothing;
    end if;
    if tg_table_name = 'workout_logs' then
      perform public.award_activity_day(owner_id, activity_day);
    elsif new.consumed then
      perform public.award_activity_day(owner_id, activity_day);
    end if;
  elsif tg_op = 'UPDATE' then
    if tg_table_name = 'meal_logs' then
      if new.consumed and not old.consumed then
        perform public.award_activity_day(owner_id, new.logged_date);
      end if;
    end if;
  end if;

  perform public.recalculate_activity_streak(owner_id);
  if tg_op = 'DELETE' then return old; end if;
  return new;
end
$$;
comment on function public.process_activity_log() is
  'Awards 10 XP and 10 store points once per active local day, then updates streaks.';

drop trigger if exists guard_meal_activity_log on public.meal_logs;
create trigger guard_meal_activity_log
  before insert or update or delete on public.meal_logs
  for each row execute function public.guard_activity_log();
drop trigger if exists guard_workout_activity_log on public.workout_logs;
create trigger guard_workout_activity_log
  before insert or update or delete on public.workout_logs
  for each row execute function public.guard_activity_log();
drop trigger if exists process_meal_activity_log on public.meal_logs;
create trigger process_meal_activity_log
  after insert or update or delete on public.meal_logs
  for each row execute function public.process_activity_log();
drop trigger if exists process_workout_activity_log on public.workout_logs;
create trigger process_workout_activity_log
  after insert or update or delete on public.workout_logs
  for each row execute function public.process_activity_log();

revoke all on function public.activity_timezone_for_user(uuid),
  public.guard_activity_log(), public.process_activity_log(),
  public.recalculate_activity_streak(uuid), public.award_activity_day(uuid, date)
  from public, anon, authenticated;
