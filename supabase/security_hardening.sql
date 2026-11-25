-- Security hardening: sanity limits on self-reported activity numbers.
-- Safe to run more than once. NOT VALID means existing rows are left alone
-- and only new or changed rows are checked, so nothing already saved breaks.
-- Run in the Supabase SQL Editor (test project first, then the real project).

do $$
begin
  if not exists (select 1 from pg_constraint
                 where conname = 'workout_logs_duration_max_check') then
    alter table public.workout_logs
      add constraint workout_logs_duration_max_check
      check (duration_minutes is null or duration_minutes <= 1440) not valid;
  end if;

  if not exists (select 1 from pg_constraint
                 where conname = 'workout_logs_calories_burned_max_check') then
    alter table public.workout_logs
      add constraint workout_logs_calories_burned_max_check
      check (calories_burned <= 20000) not valid;
  end if;

  if not exists (select 1 from pg_constraint
                 where conname = 'meal_logs_calories_max_check') then
    alter table public.meal_logs
      add constraint meal_logs_calories_max_check
      check (calories <= 10000) not valid;
  end if;
end $$;

-- Check: should return 3 rows.
select conname from pg_constraint
where conname in ('workout_logs_duration_max_check',
                  'workout_logs_calories_burned_max_check',
                  'meal_logs_calories_max_check');
