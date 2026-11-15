-- Privilege: Eat well, stay well.
-- Apply to a new Supabase project. Re-running preserves existing table data.
-- This bootstrap script does not migrate pre-existing table definitions.

create extension if not exists pgcrypto;

do $$ begin create type public.fitness_goal as enum ('lose', 'maintain', 'gain'); exception when duplicate_object then null; end $$;
do $$ begin create type public.subscription_status as enum ('active', 'cancelled', 'expired', 'pending'); exception when duplicate_object then null; end $$;
do $$ begin create type public.meal_type as enum ('breakfast', 'lunch', 'dinner', 'snack'); exception when duplicate_object then null; end $$;
do $$ begin create type public.chat_role as enum ('user', 'assistant'); exception when duplicate_object then null; end $$;
do $$ begin create type public.friendship_status as enum ('pending', 'accepted', 'blocked'); exception when duplicate_object then null; end $$;

create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

create or replace function public.is_registered_user() returns boolean
language sql stable set search_path = '' as $$
 select auth.uid() is not null and coalesce(auth.jwt()->>'is_anonymous', 'false') <> 'true'
$$;
revoke all on function public.is_registered_user() from public, anon;
grant execute on function public.is_registered_user() to authenticated;

create table if not exists public.levels (
 id uuid primary key default gen_random_uuid(), name text not null unique,
 min_xp integer not null unique check (min_xp >= 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 username text not null unique check (username ~ '^[A-Za-z0-9_]{3,40}$'),
 full_name text, avatar_url text, birth_date date, gender text,
 height_cm numeric(5,2) check (height_cm > 0), weight_kg numeric(5,2) check (weight_kg > 0),
 goal public.fitness_goal, activity_level text, daily_calorie_target integer check (daily_calorie_target > 0),
 level_id uuid references public.levels(id) on delete set null,
 training_goal text, bio text not null default '', onboarding_completed boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists profiles_username_ci_idx on public.profiles(lower(username));
create table if not exists public.subscription_plans (
 id uuid primary key default gen_random_uuid(), name text not null unique,
 price_usd numeric(8,2) not null check (price_usd >= 0), feature_flags jsonb not null default '{}'::jsonb check (jsonb_typeof(feature_flags) = 'object'),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.user_subscriptions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 plan_id uuid not null references public.subscription_plans(id), status public.subscription_status not null,
 started_at timestamptz not null default now(), expires_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check (expires_at is null or expires_at > started_at)
);
create table if not exists public.sports (
 id uuid primary key default gen_random_uuid(), name text not null unique, description text not null default '',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.exercises (
 id uuid primary key default gen_random_uuid(), name text not null unique, category text not null,
 muscle_group text not null, difficulty text not null, tutorial_video_url text, instructions text not null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.workout_splits (
 id uuid primary key default gen_random_uuid(), name text not null unique, description text not null default '',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.split_days (
 id uuid primary key default gen_random_uuid(), split_id uuid not null references public.workout_splits(id) on delete cascade,
 day_number integer not null check (day_number > 0), name text not null, unique(split_id, day_number),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.split_day_exercises (
 id uuid primary key default gen_random_uuid(), split_day_id uuid not null references public.split_days(id) on delete cascade,
 exercise_id uuid not null references public.exercises(id), position integer not null check (position >= 0),
 sets integer not null check (sets > 0), reps integer not null check (reps > 0), rest_seconds integer not null default 60 check (rest_seconds >= 0),
 unique(split_day_id, position), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.workout_plans (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 name text not null, description text not null default '',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.plan_days (
 id uuid primary key default gen_random_uuid(), plan_id uuid not null references public.workout_plans(id) on delete cascade,
 day_number integer not null check (day_number > 0), name text not null, unique(plan_id, day_number),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.plan_day_exercises (
 id uuid primary key default gen_random_uuid(), plan_day_id uuid not null references public.plan_days(id) on delete cascade,
 exercise_id uuid not null references public.exercises(id), position integer not null check (position >= 0),
 sets integer not null check (sets > 0), reps integer not null check (reps > 0), rest_seconds integer not null default 60 check (rest_seconds >= 0),
 unique(plan_day_id, position), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.user_sports (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 sport_id uuid not null references public.sports(id), notes text not null default '', unique(user_id, sport_id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.workout_logs (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 exercise_id uuid references public.exercises(id) on delete set null, activity_date date not null default current_date,
 sets integer check (sets > 0), reps integer check (reps > 0), duration_minutes integer check (duration_minutes > 0), notes text not null default '',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.food_items (
 id uuid primary key default gen_random_uuid(), name text not null unique,
 calories_per_100g numeric(10,2) not null check (calories_per_100g >= 0),
 protein_per_100g numeric(8,2) not null check (protein_per_100g >= 0),
 carbs_per_100g numeric(8,2) not null check (carbs_per_100g >= 0), fat_per_100g numeric(8,2) not null check (fat_per_100g >= 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.recipes (
 id uuid primary key default gen_random_uuid(), name text not null unique, instructions text not null,
 servings integer not null default 1 check (servings > 0), image_url text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.recipe_ingredients (
 id uuid primary key default gen_random_uuid(), recipe_id uuid not null references public.recipes(id) on delete cascade,
 food_item_id uuid not null references public.food_items(id), grams numeric(10,2) not null check (grams > 0),
 unique(recipe_id, food_item_id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.recipe_tags (
 id uuid primary key default gen_random_uuid(), recipe_id uuid not null references public.recipes(id) on delete cascade,
 tag text not null, unique(recipe_id, tag), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.user_favorite_recipes (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 recipe_id uuid not null references public.recipes(id) on delete cascade, unique(user_id, recipe_id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.meal_logs (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 logged_date date not null default current_date, meal_type public.meal_type not null, name text not null,
 calories numeric(10,2) not null check (calories >= 0), protein_g numeric(10,2) not null check (protein_g >= 0),
 carbs_g numeric(10,2) not null check (carbs_g >= 0), fat_g numeric(10,2) not null check (fat_g >= 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.cheat_meals (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 planned_date date not null, notes text not null default '',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.chat_conversations (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 title text not null default '', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.chat_messages (
 id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
 role public.chat_role not null, content text not null check (length(content) > 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.friendships (
 id uuid primary key default gen_random_uuid(), requester_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 addressee_id uuid not null references public.profiles(id) on delete cascade, status public.friendship_status not null default 'pending',
 blocked_by uuid references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check (requester_id <> addressee_id),
 check ((status = 'blocked' and blocked_by is not null and blocked_by in (requester_id, addressee_id)) or (status <> 'blocked' and blocked_by is null))
);
create unique index if not exists friendships_pair_idx on public.friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));
create table if not exists public.streaks (
 id uuid primary key default gen_random_uuid(), user_id uuid not null unique references public.profiles(id) on delete cascade,
 current_streak integer not null default 0 check (current_streak >= 0),
 longest_streak integer not null default 0 check (longest_streak >= current_streak), last_activity_date date,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.rewards (
 id uuid primary key default gen_random_uuid(), name text not null unique, description text not null default '', xp integer not null default 0 check (xp >= 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.challenges (
 id uuid primary key default gen_random_uuid(), creator_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 title text not null, type text not null, start_date date not null, end_date date not null check (end_date >= start_date),
 prize_id uuid references public.rewards(id) on delete set null, finalized_at timestamptz,
 winner_id uuid references public.profiles(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.challenge_participants (
 id uuid primary key default gen_random_uuid(), challenge_id uuid not null references public.challenges(id) on delete cascade,
 user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 score numeric(14,2) not null default 0 check (score >= 0), rank integer check (rank > 0), unique(challenge_id, user_id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.user_rewards (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 reward_id uuid not null references public.rewards(id), challenge_id uuid references public.challenges(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id, challenge_id)
);
create table if not exists public.xp_points (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 points integer not null check (points <> 0), reason text not null, user_reward_id uuid unique references public.user_rewards(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

-- Each table has both RLS and an updated_at trigger. Authenticated users get
-- read access; policies below limit rows and grant writes explicitly.
do $$
declare t text;
begin
 foreach t in array array['levels','profiles','subscription_plans','user_subscriptions','sports','exercises','workout_splits','split_days','split_day_exercises','workout_plans','plan_days','plan_day_exercises','user_sports','workout_logs','food_items','recipes','recipe_ingredients','recipe_tags','user_favorite_recipes','meal_logs','cheat_meals','chat_conversations','chat_messages','friendships','streaks','rewards','challenges','challenge_participants','user_rewards','xp_points'] loop
  execute format('comment on table public.%I is %L', t, 'Privilege application data: ' || replace(t, '_', ' ') || '.');
  execute format('alter table public.%I enable row level security', t);
  execute format('drop trigger if exists set_updated_at on public.%I', t);
  execute format('create trigger set_updated_at before update on public.%I for each row execute function public.touch_updated_at()', t);
  execute format('revoke all on public.%I from public, anon, authenticated', t);
  execute format('grant select on public.%I to authenticated', t);
  execute format('grant all on public.%I to service_role', t);
  execute format('drop policy if exists registered_accounts_only on public.%I', t);
  execute format('create policy registered_accounts_only on public.%I as restrictive for all to authenticated using (public.is_registered_user()) with check (public.is_registered_user())', t);
 end loop;
end $$;

-- Shared catalogues are read-only to clients.
do $$
declare t text;
begin
 foreach t in array array['levels','subscription_plans','sports','exercises','workout_splits','split_days','split_day_exercises','food_items','recipes','recipe_ingredients','recipe_tags','rewards','challenges','challenge_participants'] loop
  execute format('drop policy if exists authenticated_read on public.%I', t);
  execute format('create policy authenticated_read on public.%I for select to authenticated using (auth.uid() is not null)', t);
 end loop;
end $$;

-- Directly owned user tables. Subscriptions, streaks, rewards and XP are
-- deliberately server-managed to prevent forged payments or rewards.
do $$
declare t text;
begin
 foreach t in array array['workout_plans','user_sports','workout_logs','user_favorite_recipes','meal_logs','cheat_meals','chat_conversations'] loop
  execute format('grant insert, update, delete on public.%I to authenticated', t);
  execute format('drop policy if exists own_rows on public.%I', t);
  execute format('create policy own_rows on public.%I for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
 end loop;
 foreach t in array array['user_subscriptions','streaks','user_rewards','xp_points'] loop
  execute format('drop policy if exists own_read on public.%I', t);
  execute format('create policy own_read on public.%I for select to authenticated using (user_id = auth.uid())', t);
 end loop;
end $$;
drop policy if exists profile_read on public.profiles;
create policy profile_read on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists profile_update on public.profiles;
create policy profile_update on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
grant update (username, full_name, avatar_url, birth_date, gender, height_cm, weight_kg, goal, activity_level, daily_calorie_target, training_goal, bio, onboarding_completed) on public.profiles to authenticated;

grant insert, update, delete on public.plan_days, public.plan_day_exercises, public.chat_messages to authenticated;
drop policy if exists own_plan_days on public.plan_days;
create policy own_plan_days on public.plan_days for all to authenticated
 using (exists (select 1 from public.workout_plans p where p.id = plan_id and p.user_id = auth.uid()))
 with check (exists (select 1 from public.workout_plans p where p.id = plan_id and p.user_id = auth.uid()));
drop policy if exists own_plan_exercises on public.plan_day_exercises;
create policy own_plan_exercises on public.plan_day_exercises for all to authenticated
 using (exists (select 1 from public.plan_days d join public.workout_plans p on p.id = d.plan_id where d.id = plan_day_id and p.user_id = auth.uid()))
 with check (exists (select 1 from public.plan_days d join public.workout_plans p on p.id = d.plan_id where d.id = plan_day_id and p.user_id = auth.uid()));
drop policy if exists own_messages on public.chat_messages;
create policy own_messages on public.chat_messages for all to authenticated
 using (exists (select 1 from public.chat_conversations c where c.id = conversation_id and c.user_id = auth.uid()))
 with check (exists (select 1 from public.chat_conversations c where c.id = conversation_id and c.user_id = auth.uid()));

drop policy if exists friendship_read on public.friendships;
create policy friendship_read on public.friendships for select to authenticated using (auth.uid() in (requester_id, addressee_id));
drop policy if exists friendship_insert on public.friendships;
create policy friendship_insert on public.friendships for insert to authenticated with check (requester_id = auth.uid() and status = 'pending');
grant insert (requester_id, addressee_id) on public.friendships to authenticated;
-- State transitions are performed by a controlled function, not unrestricted updates.
create or replace function public.respond_to_friendship(p_id uuid, p_action text) returns void
language plpgsql security definer set search_path = '' as $$
declare f public.friendships%rowtype;
begin
 select * into f from public.friendships where id = p_id for update;
 if not found or not public.is_registered_user() or auth.uid() not in (f.requester_id, f.addressee_id) then raise exception 'Friendship not found'; end if;
 if p_action = 'accept' and f.status = 'pending' and auth.uid() = f.addressee_id then
  update public.friendships set status = 'accepted' where id = p_id;
 elsif p_action = 'decline' and f.status = 'pending' and auth.uid() = f.addressee_id then
  delete from public.friendships where id = p_id;
 elsif p_action = 'cancel' and f.status = 'pending' and auth.uid() = f.requester_id then
  delete from public.friendships where id = p_id;
 elsif p_action = 'remove' and f.status = 'accepted' then
  delete from public.friendships where id = p_id;
 elsif p_action = 'block' and f.status in ('pending', 'accepted') then
  update public.friendships set status = 'blocked', blocked_by = auth.uid() where id = p_id;
 elsif p_action = 'unblock' and f.status = 'blocked' and f.blocked_by = auth.uid() then
  delete from public.friendships where id = p_id;
 else raise exception 'Invalid friendship action'; end if;
end $$;
revoke all on function public.respond_to_friendship(uuid,text) from public, anon;
grant execute on function public.respond_to_friendship(uuid,text) to authenticated;
drop policy if exists challenge_insert on public.challenges;
create policy challenge_insert on public.challenges for insert to authenticated with check (creator_id = auth.uid() and prize_id is null);
grant insert (creator_id, title, type, start_date, end_date) on public.challenges to authenticated;
drop policy if exists participant_insert on public.challenge_participants;
create policy participant_insert on public.challenge_participants for insert to authenticated with check (
 user_id = auth.uid() and exists (select 1 from public.challenges c where c.id = challenge_id and c.finalized_at is null and current_date <= c.end_date)
);
grant insert (challenge_id, user_id) on public.challenge_participants to authenticated;

-- Copy selected split days into an existing plan, preserving the requested order.
create or replace function public.merge_splits_into_plan(p_plan_id uuid, p_split_ids uuid[]) returns void
language plpgsql security invoker set search_path = '' as $$
declare selected_split_id uuid; d record; next_day integer; new_day uuid;
begin
 if not public.is_registered_user() or not exists (select 1 from public.workout_plans where id = p_plan_id and user_id = auth.uid()) then
  raise exception 'Plan not found';
 end if;
 if p_split_ids is null or cardinality(p_split_ids) = 0 then raise exception 'Select at least one split'; end if;
 perform 1 from public.workout_plans where id = p_plan_id for update;
 select coalesce(max(day_number), 0) into next_day from public.plan_days where plan_id = p_plan_id;
 foreach selected_split_id in array p_split_ids loop
  if selected_split_id is null or not exists (select 1 from public.workout_splits where id = selected_split_id) then raise exception 'Split not found'; end if;
  for d in select * from public.split_days where split_days.split_id = selected_split_id order by day_number loop
   next_day := next_day + 1;
   insert into public.plan_days(plan_id, day_number, name) values(p_plan_id, next_day, d.name) returning id into new_day;
   insert into public.plan_day_exercises(plan_day_id, exercise_id, position, sets, reps, rest_seconds)
    select new_day, exercise_id, position, sets, reps, rest_seconds from public.split_day_exercises where split_day_id = d.id order by position;
  end loop;
 end loop;
end $$;
revoke all on function public.merge_splits_into_plan(uuid,uuid[]) from public, anon;
grant execute on function public.merge_splits_into_plan(uuid,uuid[]) to authenticated;

create or replace function public.create_profile_for_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id, username, full_name, avatar_url, level_id)
 values (new.id, 'user_' || replace(new.id::text, '-', ''), nullif(new.raw_user_meta_data->>'full_name', ''),
         nullif(new.raw_user_meta_data->>'avatar_url', ''), (select id from public.levels order by min_xp limit 1))
 on conflict (id) do nothing;
 return new;
end $$;
drop trigger if exists privilege_create_profile on auth.users;
create trigger privilege_create_profile after insert on auth.users for each row execute function public.create_profile_for_new_user();

create or replace function public.refresh_user_level() returns trigger
language plpgsql security definer set search_path = '' as $$
declare target uuid; total bigint;
begin
 target := case when tg_op = 'DELETE' then old.user_id else new.user_id end;
 perform 1 from public.profiles where id = target for update;
 select coalesce(sum(points), 0) into total from public.xp_points where user_id = target;
 update public.profiles set level_id = (select id from public.levels where min_xp <= greatest(total, 0) order by min_xp desc limit 1) where id = target;
 if tg_op = 'UPDATE' and old.user_id <> new.user_id then
  perform 1 from public.profiles where id = old.user_id for update;
  select coalesce(sum(points), 0) into total from public.xp_points where user_id = old.user_id;
  update public.profiles set level_id = (select id from public.levels where min_xp <= greatest(total, 0) order by min_xp desc limit 1) where id = old.user_id;
 end if;
 if tg_op = 'DELETE' then return old; end if;
 return new;
end $$;
drop trigger if exists refresh_level on public.xp_points;
create trigger refresh_level after insert or update or delete on public.xp_points for each row execute function public.refresh_user_level();

-- Record a streak only through a trusted server; the supplied date is UTC.
create or replace function public.record_streak(p_user_id uuid, p_date date) returns void
language plpgsql security definer set search_path = '' as $$
begin
 if p_date is null or p_date > (now() at time zone 'UTC')::date then raise exception 'Invalid activity date'; end if;
 insert into public.streaks(user_id, current_streak, longest_streak, last_activity_date)
 values(p_user_id, 1, 1, p_date)
 on conflict(user_id) do update set
  current_streak = case when excluded.last_activity_date = public.streaks.last_activity_date + 1 then public.streaks.current_streak + 1 when excluded.last_activity_date > public.streaks.last_activity_date then 1 else public.streaks.current_streak end,
  longest_streak = greatest(public.streaks.longest_streak, case when excluded.last_activity_date = public.streaks.last_activity_date + 1 then public.streaks.current_streak + 1 else 1 end),
  last_activity_date = greatest(public.streaks.last_activity_date, excluded.last_activity_date);
end $$;

-- Finalization is serialized and idempotent. Ties resolve by earliest join.
create or replace function public.finalize_challenge(p_challenge_id uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare c public.challenges%rowtype; winner uuid; award_id uuid; reward_xp integer;
begin
 select * into c from public.challenges where id = p_challenge_id for update;
 if not found then raise exception 'Challenge not found'; end if;
 if c.finalized_at is not null then return c.winner_id; end if;
 if (now() at time zone 'UTC')::date <= c.end_date then raise exception 'Challenge has not ended'; end if;
 with ranked as (
   select id, row_number() over(order by score desc, created_at, id)::integer as placement
   from public.challenge_participants where challenge_id = c.id
 ) update public.challenge_participants p set rank = ranked.placement from ranked where p.id = ranked.id;
 select user_id into winner from public.challenge_participants where challenge_id = c.id and rank = 1;
 update public.challenges set finalized_at = now(), winner_id = winner where id = c.id;
 if winner is not null and c.prize_id is not null then
  insert into public.user_rewards(user_id, reward_id, challenge_id) values(winner, c.prize_id, c.id) returning id into award_id;
  select xp into reward_xp from public.rewards where id = c.prize_id;
  if reward_xp > 0 then insert into public.xp_points(user_id, points, reason, user_reward_id) values(winner, reward_xp, 'Challenge reward', award_id); end if;
 end if;
 return winner;
end $$;
revoke all on function public.record_streak(uuid,date), public.finalize_challenge(uuid), public.create_profile_for_new_user(), public.refresh_user_level() from public, anon, authenticated;
grant execute on function public.record_streak(uuid,date), public.finalize_challenge(uuid) to service_role;

create or replace view public.daily_summaries with (security_invoker = true) as
 select user_id, logged_date, sum(calories) as total_calories, sum(protein_g) as total_protein_g,
 sum(carbs_g) as total_carbs_g, sum(fat_g) as total_fat_g
 from public.meal_logs group by user_id, logged_date;
revoke all on public.daily_summaries from public, anon;
grant select on public.daily_summaries to authenticated;

-- A deliberately restricted public directory; private health details stay private.
create or replace view public.community_profiles as
 select id, username, full_name, avatar_url from public.profiles where public.is_registered_user();
revoke all on public.community_profiles from public, anon;
grant select on public.community_profiles to authenticated;

create index if not exists subscriptions_user_idx on public.user_subscriptions(user_id);
create index if not exists plans_user_idx on public.workout_plans(user_id);
create index if not exists plan_exercises_exercise_idx on public.plan_day_exercises(exercise_id);
create index if not exists split_exercises_exercise_idx on public.split_day_exercises(exercise_id);
create index if not exists user_sports_sport_idx on public.user_sports(sport_id);
create index if not exists workout_logs_user_date_idx on public.workout_logs(user_id, activity_date);
create index if not exists workout_logs_exercise_idx on public.workout_logs(exercise_id);
create index if not exists recipe_ingredients_food_idx on public.recipe_ingredients(food_item_id);
create index if not exists favorites_recipe_idx on public.user_favorite_recipes(recipe_id);
create index if not exists meal_logs_user_date_idx on public.meal_logs(user_id, logged_date);
create index if not exists cheat_meals_user_date_idx on public.cheat_meals(user_id, planned_date);
create index if not exists conversations_user_idx on public.chat_conversations(user_id);
create index if not exists messages_conversation_date_idx on public.chat_messages(conversation_id, created_at);
create index if not exists friendships_addressee_idx on public.friendships(addressee_id);
create index if not exists friendships_blocked_by_idx on public.friendships(blocked_by);
create index if not exists challenges_creator_idx on public.challenges(creator_id);
create index if not exists challenges_end_idx on public.challenges(end_date);
create index if not exists participants_user_idx on public.challenge_participants(user_id);
create index if not exists rewards_user_idx on public.user_rewards(user_id);
create index if not exists xp_user_idx on public.xp_points(user_id);
create index if not exists profiles_level_idx on public.profiles(level_id);
create index if not exists subscriptions_plan_idx on public.user_subscriptions(plan_id);
create index if not exists challenges_prize_idx on public.challenges(prize_id);
create index if not exists challenges_winner_idx on public.challenges(winner_id);
create index if not exists user_rewards_reward_idx on public.user_rewards(reward_id);
create index if not exists user_rewards_challenge_idx on public.user_rewards(challenge_id);
