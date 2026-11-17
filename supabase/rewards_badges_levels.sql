-- Stage 4: progression and digital rewards.
-- Apply after schema.sql, seed.sql, auth_migration.sql, activity_tracking.sql,
-- community_games_rewards.sql and arena_challenges.sql.
begin;

-- These additions deliberately leave the Stage 1--3 tables and functions in
-- place. Existing reward rows are not automatically offered in the store.
alter table public.rewards
  add column if not exists reward_kind text,
  add column if not exists cost_points integer,
  add column if not exists stock integer,
  add column if not exists required_tier text,
  add column if not exists is_active boolean not null default false;

do $$ begin
  if not exists (select 1 from pg_constraint where conrelid = 'public.rewards'::regclass
                 and conname = 'stage4_rewards_kind_check') then
    alter table public.rewards add constraint stage4_rewards_kind_check
      check (reward_kind is null or reward_kind in ('freeze', 'theme', 'frame', 'title'));
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.rewards'::regclass
                 and conname = 'stage4_rewards_cost_check') then
    alter table public.rewards add constraint stage4_rewards_cost_check
      check (cost_points is null or cost_points > 0);
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.rewards'::regclass
                 and conname = 'stage4_rewards_stock_check') then
    alter table public.rewards add constraint stage4_rewards_stock_check
      check (stock is null or stock >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.rewards'::regclass
                 and conname = 'stage4_rewards_tier_check') then
    alter table public.rewards add constraint stage4_rewards_tier_check
      check (required_tier is null or required_tier in ('Free', 'Silver', 'Gold'));
  end if;
  if not exists (select 1 from pg_constraint where conrelid = 'public.rewards'::regclass
                 and conname = 'stage4_rewards_active_check') then
    alter table public.rewards add constraint stage4_rewards_active_check
      check (not is_active or (reward_kind is not null and cost_points is not null
                               and required_tier is not null and xp = 0));
  end if;
end $$;

comment on column public.rewards.reward_kind is
  'Digital store item type; null for rewards predating the Stage 4 store.';
comment on column public.rewards.cost_points is
  'Store-points price, separate from lifetime XP.';
comment on column public.rewards.stock is
  'Remaining quantity, or null for unlimited digital stock.';
comment on column public.rewards.required_tier is
  'Minimum active subscription tier required to redeem.';
comment on column public.rewards.is_active is
  'Whether this digital item is offered in the store.';

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null,
  metric text not null check (metric in ('meals', 'workouts', 'active_days',
    'longest_streak', 'challenges_joined', 'challenges_won', 'posts')),
  threshold integer not null check (threshold > 0),
  created_at timestamptz not null default now(),
  unique (metric, threshold)
);
comment on table public.badges is 'Shared, activity-derived badge definitions.';

create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  badge_id uuid not null references public.badges(id),
  earned_at timestamptz not null default now(),
  unique (user_id, badge_id)
);
comment on table public.user_badges is 'Badges earned once per account from real activity.';
create index if not exists stage4_user_badges_user_idx
  on public.user_badges(user_id, earned_at desc);

create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null,
  metric text not null check (metric in ('meals', 'workouts', 'active_days',
    'longest_streak', 'challenges_joined', 'challenges_won', 'posts')),
  threshold integer not null check (threshold > 0),
  xp_award integer not null check (xp_award > 0),
  created_at timestamptz not null default now(),
  unique (metric, threshold)
);
comment on table public.achievements is 'Shared activity milestones with a one-time XP award.';

create table if not exists public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id),
  progress integer not null default 0 check (progress >= 0),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, achievement_id)
);
comment on table public.user_achievements is 'Private progress and one-time achievement completion.';
create index if not exists stage4_user_achievements_user_idx
  on public.user_achievements(user_id, completed_at);

create table if not exists public.reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reward_id uuid not null references public.rewards(id),
  reward_kind text not null check (reward_kind in ('freeze', 'theme', 'frame', 'title')),
  request_id uuid not null,
  points_spent integer not null check (points_spent > 0),
  points_entry_id uuid not null unique references public.store_points_ledger(id),
  status text not null check (status in ('fulfilled')),
  created_at timestamptz not null default now(),
  unique (user_id, request_id)
);
comment on table public.reward_redemptions is 'Server-fulfilled digital reward purchases, keyed for retry safety.';
create index if not exists stage4_redemptions_user_idx
  on public.reward_redemptions(user_id, created_at desc);
create index if not exists stage4_redemptions_reward_idx
  on public.reward_redemptions(reward_id);
create unique index if not exists stage4_one_cosmetic_redemption_idx
  on public.reward_redemptions(user_id, reward_id) where reward_kind <> 'freeze';

create table if not exists public.purchased_freeze_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  missed_date date not null,
  freeze_month date not null check (freeze_month = date_trunc('month', missed_date::timestamp)::date),
  created_at timestamptz not null default now(),
  unique (user_id, missed_date)
);
comment on table public.purchased_freeze_usage is
  'Append-only record of purchased tokens used after the free monthly freeze.';
create index if not exists stage4_purchased_freeze_month_idx
  on public.purchased_freeze_usage(user_id, freeze_month);

do $$
declare t text;
begin
  foreach t in array array['badges', 'user_badges', 'achievements',
    'user_achievements', 'reward_redemptions', 'purchased_freeze_usage'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from public, anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('grant all on public.%I to service_role', t);
    execute format('drop policy if exists stage4_registered on public.%I', t);
    execute format('create policy stage4_registered on public.%I as restrictive for all to authenticated using (public.is_registered_user()) with check (public.is_registered_user())', t);
  end loop;
  foreach t in array array['badges', 'achievements'] loop
    execute format('drop policy if exists stage4_catalog_read on public.%I', t);
    execute format('create policy stage4_catalog_read on public.%I for select to authenticated using (true)', t);
  end loop;
  foreach t in array array['user_badges', 'user_achievements',
    'reward_redemptions', 'purchased_freeze_usage'] loop
    execute format('drop policy if exists stage4_owner_read on public.%I', t);
    execute format('create policy stage4_owner_read on public.%I for select to authenticated using (user_id = auth.uid())', t);
  end loop;
end $$;

insert into public.levels(name, min_xp) values
 ('Bronze',0), ('Silver',500), ('Gold',1500), ('Platinum',3000),
 ('Diamond',6000), ('Elite',10000), ('Champion',20000)
on conflict do nothing;

insert into public.badges(code, name, description, metric, threshold)
select metric || '_' || threshold, label || ' ' || threshold,
       description || ' ' || threshold || '.', metric, threshold
from (values
 ('meals','Meals','Consumed meals logged:'),
 ('workouts','Workouts','Completed workouts logged:'),
 ('active_days','Active days','Days with rewarded activity:'),
 ('longest_streak','Streak','Longest streak reached:'),
 ('challenges_joined','Challenges joined','Arena challenges joined:'),
 ('challenges_won','Challenges won','Arena challenges won:'),
 ('posts','Community posts','Community posts created:')
) m(metric,label,description)
cross join (values (1), (7), (30), (100), (365)) t(threshold)
on conflict do nothing;

insert into public.achievements(code, name, description, metric, threshold, xp_award)
values
 ('meal_10','Meal logger','Log 10 consumed meals.','meals',10,25),
 ('meal_100','Nutrition regular','Log 100 consumed meals.','meals',100,100),
 ('workout_10','Getting moving','Log 10 completed workouts.','workouts',10,25),
 ('workout_100','Workout century','Log 100 completed workouts.','workouts',100,150),
 ('days_30','Thirty active days','Log activity on 30 days.','active_days',30,100),
 ('days_100','One hundred active days','Log activity on 100 days.','active_days',100,200),
 ('streak_7','One-week streak','Reach a seven-day streak.','longest_streak',7,50),
 ('streak_30','Thirty-day streak','Reach a 30-day streak.','longest_streak',30,150),
 ('join_1','Arena entrant','Join a challenge.','challenges_joined',1,25),
 ('win_1','Arena winner','Win a challenge.','challenges_won',1,50),
 ('post_1','First post','Create a community post.','posts',1,25),
 ('post_10','Community contributor','Create 10 community posts.','posts',10,100)
on conflict do nothing;

insert into public.rewards(name, description, xp, reward_kind, cost_points, stock, required_tier, is_active)
values
 ('Streak freeze token','Automatically covers one eligible missed day after the free monthly freeze.',0,'freeze',50,null,'Free',true),
 ('Sunrise theme','A digital profile theme.',0,'theme',100,null,'Free',true),
 ('Midnight theme','A digital profile theme.',0,'theme',120,null,'Free',true),
 ('Forest theme','A digital profile theme.',0,'theme',120,null,'Free',true),
 ('Ocean theme','A digital profile theme.',0,'theme',140,null,'Free',true),
 ('Ember theme','A digital profile theme.',0,'theme',160,null,'Silver',true),
 ('Aurora theme','A digital profile theme.',0,'theme',180,null,'Silver',true),
 ('Galaxy theme','A digital profile theme.',0,'theme',220,null,'Gold',true),
 ('Bronze frame','A digital profile frame.',0,'frame',80,null,'Free',true),
 ('Silver frame','A digital profile frame.',0,'frame',120,null,'Free',true),
 ('Gold frame','A digital profile frame.',0,'frame',160,null,'Silver',true),
 ('Platinum frame','A digital profile frame.',0,'frame',200,null,'Silver',true),
 ('Diamond frame','A digital profile frame.',0,'frame',250,null,'Gold',true),
 ('Flame frame','A digital profile frame.',0,'frame',150,null,'Free',true),
 ('Leaf frame','A digital profile frame.',0,'frame',150,null,'Free',true),
 ('Wave frame','A digital profile frame.',0,'frame',150,null,'Free',true),
 ('Early Riser title','A digital profile title.',0,'title',75,null,'Free',true),
 ('Steady Steps title','A digital profile title.',0,'title',75,null,'Free',true),
 ('Trailblazer title','A digital profile title.',0,'title',100,null,'Free',true),
 ('Focused title','A digital profile title.',0,'title',100,null,'Free',true),
 ('Momentum title','A digital profile title.',0,'title',125,null,'Silver',true),
 ('Determined title','A digital profile title.',0,'title',125,null,'Silver',true),
 ('Champion Spirit title','A digital profile title.',0,'title',200,null,'Gold',true),
 ('Community Builder title','A digital profile title.',0,'title',100,null,'Free',true)
on conflict (name) do nothing;

alter table public.community_notifications
  drop constraint if exists community_notifications_notification_type_check;
alter table public.community_notifications
  add constraint community_notifications_notification_type_check
  check (notification_type in ('friend_request','friend_accepted','post_comment',
    'post_like','challenge_invite','challenge_result','level_up',
    'badge_earned','achievement_earned','reward_redeemed'));

-- A deletion cascading from account removal is allowed, but active accounts'
-- ledgers are append-only even for privileged writers.
create or replace function public.stage4_guard_ledger()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' and not exists (
    select 1 from public.profiles where id = old.user_id
  ) then return old; end if;
  raise exception 'Ledger entries are immutable';
end $$;
comment on function public.stage4_guard_ledger() is
 'Prevents changing ledger entries while allowing account-deletion cascades.';

create or replace function public.stage4_guard_xp_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.points <= 0 then raise exception 'XP awards must be positive'; end if;
  return new;
end $$;
comment on function public.stage4_guard_xp_insert() is
 'Rejects negative XP entries without changing existing historical ledger rows.';

do $$
declare t text;
begin
 foreach t in array array['xp_points','store_points_ledger','reward_redemptions',
   'purchased_freeze_usage'] loop
  execute format('drop trigger if exists stage4_immutable on public.%I', t);
  execute format('create trigger stage4_immutable before update or delete on public.%I for each row execute function public.stage4_guard_ledger()', t);
 end loop;
end $$;
drop trigger if exists stage4_positive_xp on public.xp_points;
create trigger stage4_positive_xp before insert on public.xp_points
 for each row execute function public.stage4_guard_xp_insert();

create or replace function public.stage4_notify_level()
returns trigger language plpgsql security definer set search_path = '' as $$
declare old_threshold integer; new_threshold integer;
begin
 if new.level_id is distinct from old.level_id then
  select min_xp into old_threshold from public.levels where id = old.level_id;
  select min_xp into new_threshold from public.levels where id = new.level_id;
  if old_threshold is not null and new_threshold > old_threshold then
   insert into public.community_notifications(recipient_id, notification_type)
   values(new.id, 'level_up');
  end if;
 end if;
 return new;
end $$;
comment on function public.stage4_notify_level() is
 'Notifies the account when its existing XP level trigger moves it upward.';
drop trigger if exists stage4_level_notification on public.profiles;
create trigger stage4_level_notification after update of level_id on public.profiles
 for each row execute function public.stage4_notify_level();

create or replace function public.stage4_freeze_balance(p_user_id uuid)
returns bigint language sql stable security definer set search_path = '' as $$
 select (select count(*) from public.reward_redemptions
          where user_id = p_user_id and reward_kind = 'freeze' and status = 'fulfilled')
      - (select count(*) from public.purchased_freeze_usage where user_id = p_user_id)
$$;
comment on function public.stage4_freeze_balance(uuid) is
 'Internal count of unspent purchased freeze tokens.';

create or replace function public.stage4_extra_freeze()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 -- Stage 1 attempts the free monthly freeze first. Only substitute a token
 -- when that month already has a different free frozen day.
 if exists (select 1 from public.streak_freeze_usage
            where user_id = new.user_id and freeze_month = new.freeze_month) then
  perform 1 from public.profiles where id = new.user_id for update;
  if not exists (select 1 from public.streak_freeze_usage
                 where user_id = new.user_id and missed_date = new.missed_date)
     and not exists (select 1 from public.purchased_freeze_usage
                     where user_id = new.user_id and missed_date = new.missed_date)
     and public.stage4_freeze_balance(new.user_id) > 0
     and (select count(*) from public.purchased_freeze_usage
          where user_id = new.user_id and freeze_month = new.freeze_month) < 2 then
   insert into public.purchased_freeze_usage(user_id, missed_date, freeze_month)
   values(new.user_id, new.missed_date, new.freeze_month);
  end if;
  return null;
 end if;
 return new;
end $$;
comment on function public.stage4_extra_freeze() is
 'Uses at most two purchased tokens per month only after the free monthly freeze.';
drop trigger if exists stage4_extra_freeze on public.streak_freeze_usage;
create trigger stage4_extra_freeze before insert on public.streak_freeze_usage
 for each row execute function public.stage4_extra_freeze();

create or replace function public.recalculate_activity_streak(p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare activity_day date; previous_day date; run_length integer := 0;
  longest integer := 0; last_day date;
begin
 perform 1 from public.profiles where id = p_user_id for update;
 select coalesce(max(longest_streak), 0) into longest
 from public.activity_streak_anchors where user_id = p_user_id;
 for activity_day in
  select distinct d from (
   select a.start_date + days.day_offset as d from public.activity_streak_anchors a
   cross join lateral generate_series(0, a.last_activity_date - a.start_date) as days(day_offset)
   where a.user_id = p_user_id
   union all select logged_date from public.meal_logs where user_id = p_user_id and consumed
   union all select activity_date from public.workout_logs where user_id = p_user_id
  ) activity_days order by d
 loop
  last_day := activity_day;
  if previous_day is null then run_length := 1;
  elsif activity_day = previous_day + 1 then run_length := run_length + 1;
  elsif activity_day = previous_day + 2 and (
    exists (select 1 from public.streak_freeze_usage f
            where f.user_id = p_user_id and f.missed_date = previous_day + 1)
    or exists (select 1 from public.purchased_freeze_usage f
               where f.user_id = p_user_id and f.missed_date = previous_day + 1)
  ) then run_length := run_length + 2;
  else run_length := 1;
  end if;
  longest := greatest(longest, run_length);
  previous_day := activity_day;
 end loop;
 if last_day is null then
  update public.streaks set current_streak = 0, last_activity_date = null
   where user_id = p_user_id;
 else
  update public.streaks set
   current_streak = case when last_day >=
    (now() at time zone public.activity_timezone_for_user(p_user_id))::date - 1
    then run_length else 0 end,
   longest_streak = greatest(longest_streak, longest, current_streak),
   last_activity_date = last_day where user_id = p_user_id;
 end if;
end $$;
comment on function public.recalculate_activity_streak(uuid) is
 'Preserves Stage 1 streak calculation and also recognizes purchased one-day freezes.';

create or replace function public.stage4_guard_points_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
declare balance bigint;
begin
 perform 1 from public.profiles where id = new.user_id for update;
 if not found then raise exception 'Account not found'; end if;
 select coalesce(sum(points), 0) into balance from public.store_points_ledger
 where user_id = new.user_id;
 if balance + new.points < 0 then raise exception 'Insufficient store points'; end if;
 return new;
end $$;
comment on function public.stage4_guard_points_insert() is
 'Serializes point transactions per account and rejects a negative balance.';
drop trigger if exists stage4_points_balance on public.store_points_ledger;
create trigger stage4_points_balance before insert on public.store_points_ledger
 for each row execute function public.stage4_guard_points_insert();

create or replace function public.redeem_digital_reward(p_reward_id uuid, p_request_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
 owner_id uuid := auth.uid();
 reward public.rewards%rowtype;
 previous public.reward_redemptions%rowtype;
 redemption_id uuid;
 points_entry_id uuid;
 balance bigint;
 tier_rank integer;
 required_rank integer;
begin
 if not public.is_registered_user() or p_reward_id is null or p_request_id is null then
  raise exception 'A registered account, reward and request ID are required';
 end if;
 perform 1 from public.profiles where id = owner_id for update;
 if not found then raise exception 'Account not found'; end if;
 select * into previous from public.reward_redemptions
 where user_id = owner_id and request_id = p_request_id;
 if found then
  if previous.reward_id <> p_reward_id then
   raise exception 'Request ID already belongs to another reward';
  end if;
  return previous.id;
 end if;
 select * into reward from public.rewards where id = p_reward_id for update;
 if not found or not reward.is_active or reward.reward_kind is null
    or reward.cost_points is null or reward.required_tier is null then
  raise exception 'Reward is not available';
 end if;
 if reward.stock is not null and reward.stock < 1 then
  raise exception 'Reward is out of stock';
 end if;
 perform 1 from public.user_subscriptions where user_id = owner_id for update;
 select coalesce(max(case p.name when 'Gold' then 2 when 'Silver' then 1 else 0 end), 0)
 into tier_rank from public.user_subscriptions s
 join public.subscription_plans p on p.id = s.plan_id
 where s.user_id = owner_id and s.status = 'active'
   and s.started_at <= now() and (s.expires_at is null or s.expires_at > now());
 required_rank := case reward.required_tier when 'Gold' then 2 when 'Silver' then 1 else 0 end;
 if tier_rank < required_rank then raise exception 'Subscription tier does not qualify'; end if;
 if reward.reward_kind = 'freeze' then
  if public.stage4_freeze_balance(owner_id) >= 3 then
   raise exception 'You can hold at most three freeze tokens';
  end if;
 elsif exists (select 1 from public.reward_redemptions
               where user_id = owner_id and reward_id = reward.id and status = 'fulfilled') then
  raise exception 'You already own this item';
 end if;
 select coalesce(sum(points), 0) into balance from public.store_points_ledger
 where user_id = owner_id;
 if balance < reward.cost_points then raise exception 'Insufficient store points'; end if;
 if reward.stock is not null then
  update public.rewards set stock = stock - 1 where id = reward.id;
 end if;
 insert into public.store_points_ledger(user_id, points, reason, activity_date, entry_type)
 values(owner_id, -reward.cost_points, 'Digital reward: ' || reward.name,
        (now() at time zone public.activity_timezone_for_user(owner_id))::date, 'redemption')
 returning id into points_entry_id;
 insert into public.reward_redemptions(
  user_id, reward_id, reward_kind, request_id, points_spent, points_entry_id, status
 ) values(owner_id, reward.id, reward.reward_kind, p_request_id,
          reward.cost_points, points_entry_id, 'fulfilled') returning id into redemption_id;
 insert into public.community_notifications(recipient_id, notification_type)
 values(owner_id, 'reward_redeemed');
 return redemption_id;
end $$;
comment on function public.redeem_digital_reward(uuid,uuid) is
 'Atomically buys one digital item using store points; request IDs make retries idempotent.';
revoke all on function public.redeem_digital_reward(uuid,uuid) from public, anon, authenticated;
grant execute on function public.redeem_digital_reward(uuid,uuid) to authenticated;

create or replace function public.stage4_update_progress(p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
 metrics jsonb;
 badge record;
 achievement record;
 old_progress public.user_achievements%rowtype;
 progress_value integer;
begin
 perform 1 from public.profiles where id = p_user_id for update;
 if not found then return; end if;
 select jsonb_build_object(
  'meals', (select count(*) from public.meal_logs where user_id = p_user_id and consumed),
  'workouts', (select count(*) from public.workout_logs where user_id = p_user_id),
  'active_days', (select count(*) from public.activity_reward_days where user_id = p_user_id),
  'longest_streak', coalesce((select longest_streak from public.streaks where user_id = p_user_id), 0),
  'challenges_joined', (select count(*) from public.challenge_participants where user_id = p_user_id),
  'challenges_won', (select count(*) from public.challenges where winner_id = p_user_id and finalized_at is not null),
  'posts', (select count(*) from public.community_posts where author_id = p_user_id)
 ) into metrics;
 for badge in select * from public.badges order by metric, threshold loop
  if (metrics ->> badge.metric)::bigint >= badge.threshold then
   insert into public.user_badges(user_id, badge_id) values(p_user_id, badge.id)
   on conflict(user_id, badge_id) do nothing;
   if found then
    insert into public.community_notifications(recipient_id, notification_type)
    values(p_user_id, 'badge_earned');
   end if;
  end if;
 end loop;
 for achievement in select * from public.achievements order by metric, threshold loop
  progress_value := least((metrics ->> achievement.metric)::bigint, achievement.threshold)::integer;
  insert into public.user_achievements(user_id, achievement_id, progress)
  values(p_user_id, achievement.id, progress_value)
  on conflict(user_id, achievement_id) do nothing;
  select * into old_progress from public.user_achievements
  where user_id = p_user_id and achievement_id = achievement.id for update;
  if old_progress.completed_at is null and progress_value >= achievement.threshold then
   update public.user_achievements set progress = achievement.threshold,
    completed_at = now(), updated_at = now() where id = old_progress.id;
   insert into public.xp_points(user_id, points, reason)
    values(p_user_id, achievement.xp_award, 'Achievement: ' || achievement.code);
   insert into public.community_notifications(recipient_id, notification_type)
    values(p_user_id, 'achievement_earned');
  elsif progress_value > old_progress.progress then
   update public.user_achievements set progress = progress_value, updated_at = now()
    where id = old_progress.id;
  end if;
 end loop;
end $$;
comment on function public.stage4_update_progress(uuid) is
 'Internal idempotent badge and achievement award based on saved activity; completed awards are never reversed.';

create or replace function public.refresh_my_progress()
returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.is_registered_user() then raise exception 'A registered account is required'; end if;
 perform public.stage4_update_progress(auth.uid());
end $$;
comment on function public.refresh_my_progress() is
 'Rechecks only the signed-in user’s progress from server-owned activity data.';
revoke all on function public.refresh_my_progress() from public, anon, authenticated;
grant execute on function public.refresh_my_progress() to authenticated;

create or replace function public.stage4_activity_progress_trigger()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if tg_table_name = 'community_posts' then
  perform public.stage4_update_progress(new.author_id);
 else
  perform public.stage4_update_progress(new.user_id);
 end if;
 return new;
end $$;
comment on function public.stage4_activity_progress_trigger() is
 'Updates achievements following saved activity, a post, or a challenge join.';

drop trigger if exists zz_stage4_meal_progress on public.meal_logs;
create trigger zz_stage4_meal_progress after insert or update of consumed on public.meal_logs
 for each row execute function public.stage4_activity_progress_trigger();
drop trigger if exists zz_stage4_workout_progress on public.workout_logs;
create trigger zz_stage4_workout_progress after insert on public.workout_logs
 for each row execute function public.stage4_activity_progress_trigger();
drop trigger if exists zz_stage4_post_progress on public.community_posts;
create trigger zz_stage4_post_progress after insert on public.community_posts
 for each row execute function public.stage4_activity_progress_trigger();
drop trigger if exists zz_stage4_join_progress on public.challenge_participants;
create trigger zz_stage4_join_progress after insert on public.challenge_participants
 for each row execute function public.stage4_activity_progress_trigger();

create or replace function public.stage4_challenge_winner_trigger()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if new.finalized_at is not null and old.finalized_at is null and new.winner_id is not null then
  perform public.stage4_update_progress(new.winner_id);
 end if;
 return new;
end $$;
comment on function public.stage4_challenge_winner_trigger() is
 'Awards challenge-win progress after the existing Arena finalizer selects a winner.';
drop trigger if exists zz_stage4_challenge_winner on public.challenges;
create trigger zz_stage4_challenge_winner after update of finalized_at on public.challenges
 for each row execute function public.stage4_challenge_winner_trigger();

create or replace function public.stage4_lock_activity_challenges()
returns trigger language plpgsql security definer set search_path = '' as $$
declare owner_id uuid; day date;
begin
 owner_id := case when tg_op = 'DELETE' then old.user_id else new.user_id end;
 if tg_table_name = 'meal_logs' then
  day := case when tg_op = 'DELETE' then old.logged_date else new.logged_date end;
 else
  day := case when tg_op = 'DELETE' then old.activity_date else new.activity_date end;
 end if;
 -- Arena join/finalization locks challenge rows before progression locks the
 -- profile. Take the same order before Stage 1's activity triggers run.
 perform c.id from public.challenge_participants cp
 join public.challenges c on c.id = cp.challenge_id
 where cp.user_id = owner_id and c.finalized_at is null
   and day between c.start_date and c.end_date
 order by c.id for update of c;
 if tg_op = 'DELETE' then return old; end if;
 return new;
end $$;
comment on function public.stage4_lock_activity_challenges() is
 'Orders Arena and account locks consistently when activity and joins happen concurrently.';
drop trigger if exists stage4_lock_meal_challenges on public.meal_logs;
create trigger stage4_lock_meal_challenges before insert or update or delete on public.meal_logs
 for each row execute function public.stage4_lock_activity_challenges();
drop trigger if exists stage4_lock_workout_challenges on public.workout_logs;
create trigger stage4_lock_workout_challenges before insert or update or delete on public.workout_logs
 for each row execute function public.stage4_lock_activity_challenges();

create or replace function public.public_user_badges(p_user_id uuid)
returns table(code text, name text, description text, earned_at timestamptz)
language sql stable security definer set search_path = '' as $$
 select b.code, b.name, b.description, ub.earned_at
 from public.user_badges ub join public.badges b on b.id = ub.badge_id
 where public.is_registered_user() and ub.user_id = p_user_id
   and (p_user_id = auth.uid() or not public.community_is_blocked(p_user_id))
 order by ub.earned_at, b.name
$$;
comment on function public.public_user_badges(uuid) is
 'Returns only earned public badge descriptions for a visible, unblocked account.';
revoke all on function public.public_user_badges(uuid) from public, anon, authenticated;
grant execute on function public.public_user_badges(uuid) to authenticated;

create or replace function public.my_freeze_token_balance()
returns bigint language sql stable security definer set search_path = '' as $$
 select case when public.is_registered_user()
  then public.stage4_freeze_balance(auth.uid()) else null end
$$;
comment on function public.my_freeze_token_balance() is
 'Returns the signed-in user’s unspent purchased freeze tokens.';
revoke all on function public.my_freeze_token_balance() from public, anon, authenticated;
grant execute on function public.my_freeze_token_balance() to authenticated;

revoke all on function public.stage4_guard_ledger(), public.stage4_guard_xp_insert(),
 public.stage4_notify_level(), public.stage4_freeze_balance(uuid),
 public.stage4_extra_freeze(), public.stage4_guard_points_insert(),
 public.stage4_update_progress(uuid), public.stage4_activity_progress_trigger(),
 public.stage4_challenge_winner_trigger(), public.stage4_lock_activity_challenges()
 from public, anon, authenticated;

-- Reconcile existing users once; unique keys and completion timestamps prevent
-- duplicate awards on re-run. No fake users or user-specific seed data is added.
do $$
declare owner record; old_min integer; new_level uuid; new_min integer;
begin
 for owner in select id from public.profiles order by id loop
  perform 1 from public.profiles where id = owner.id for update;
  select l.min_xp into old_min from public.profiles p
  left join public.levels l on l.id = p.level_id where p.id = owner.id;
  select l.id, l.min_xp into new_level, new_min from public.levels l
  where l.min_xp <= greatest(coalesce(
    (select sum(x.points) from public.xp_points x where x.user_id = owner.id), 0), 0)
  order by l.min_xp desc limit 1;
  if new_level is not null and (old_min is null or new_min > old_min) then
   update public.profiles set level_id = new_level where id = owner.id;
  end if;
  perform public.stage4_update_progress(owner.id);
 end loop;
end $$;

-- Realtime follows existing publication settings; RLS still filters each row.
do $$
declare t text;
begin
 if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
    and not (select puballtables from pg_publication where pubname = 'supabase_realtime') then
  foreach t in array array['profiles','xp_points','store_points_ledger','user_badges',
    'user_achievements','reward_redemptions','purchased_freeze_usage','rewards'] loop
   if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
                  and schemaname = 'public' and tablename = t) then
    execute format('alter publication supabase_realtime add table public.%I', t);
   end if;
  end loop;
 end if;
end $$;

commit;
