-- Stage 3: activity-based Arena challenges and leaderboards.
-- Apply after schema.sql, seed.sql, auth_migration.sql, activity_tracking.sql,
-- and community_games_rewards.sql. No prizes or XP/store-point awards are issued.
begin;

alter table public.challenges
  add column if not exists visibility text not null default 'public';
alter table public.challenges
  add column if not exists is_one_v_one boolean not null default false;
alter table public.challenges
  add column if not exists description text not null default '';

alter table public.challenges
  drop constraint if exists challenges_type_check;
alter table public.challenges
  add constraint challenges_type_check
  check (type in ('streak', 'workout_count'));
alter table public.challenges
  drop constraint if exists challenges_visibility_check;
alter table public.challenges
  add constraint challenges_visibility_check
  check (visibility in ('public', 'private'));
alter table public.challenges
  drop constraint if exists challenges_no_prizes_check;
alter table public.challenges
  add constraint challenges_no_prizes_check check (prize_id is null);

comment on column public.challenges.type is
  'Arena metric: streak active days (meal or workout) or completed workout count.';
comment on column public.challenges.visibility is
  'Public challenges are discoverable; private challenges are friend 1v1 invitations.';
comment on column public.challenges.is_one_v_one is
  'True only for a private challenge with exactly two accepted participants.';
comment on column public.challenges.description is
  'Optional public challenge instructions; challenges have no cash or real-world prizes.';

create table if not exists public.challenge_invitations (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  inviter_id uuid not null references public.profiles(id) on delete cascade,
  invitee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'expired')),
  expires_at timestamptz not null,
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (inviter_id <> invitee_id),
  unique (challenge_id, invitee_id)
);
comment on table public.challenge_invitations is
  'Private friend-versus-friend Arena invitations with expiring, controlled responses.';
create index if not exists challenge_invitations_inbox_idx
  on public.challenge_invitations(invitee_id, status, expires_at);
create index if not exists challenge_invitations_challenge_idx
  on public.challenge_invitations(challenge_id, status);

create table if not exists public.challenge_progress_logs (
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  activity_date date not null,
  score_units integer not null check (score_units >= 0),
  updated_at timestamptz not null default now(),
  primary key (challenge_id, user_id, activity_date)
);
comment on table public.challenge_progress_logs is
  'Server-derived daily challenge scores from the participant’s real activity logs.';
create index if not exists challenge_progress_user_date_idx
  on public.challenge_progress_logs(user_id, activity_date desc);

alter table public.challenge_invitations enable row level security;
alter table public.challenge_progress_logs enable row level security;
revoke all on public.challenge_invitations, public.challenge_progress_logs
  from public, anon, authenticated;
grant select on public.challenge_invitations, public.challenge_progress_logs
  to authenticated;
grant all on public.challenge_invitations, public.challenge_progress_logs
  to service_role;

create or replace function public.arena_is_participant(p_challenge_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select public.is_registered_user() and exists (
    select 1 from public.challenge_participants cp
    where cp.challenge_id = p_challenge_id and cp.user_id = auth.uid()
  )
$$;
comment on function public.arena_is_participant(uuid) is
  'Checks only whether the signed-in user participates in a challenge.';
revoke all on function public.arena_is_participant(uuid) from public, anon;
grant execute on function public.arena_is_participant(uuid) to authenticated;

create or replace function public.rank_arena_challenge(p_challenge_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  with ranked as (
    select id,
      row_number() over(order by score desc, created_at, id)::integer as place
    from public.challenge_participants
    where challenge_id = p_challenge_id
  )
  update public.challenge_participants cp
  set rank = ranked.place
  from ranked where cp.id = ranked.id;
end
$$;
comment on function public.rank_arena_challenge(uuid) is
  'Assigns deterministic challenge ranks from server-calculated scores.';
revoke all on function public.rank_arena_challenge(uuid)
  from public, anon, authenticated;

drop policy if exists challenge_invitations_registered
  on public.challenge_invitations;
create policy challenge_invitations_registered
  on public.challenge_invitations as restrictive for all to authenticated
  using (public.is_registered_user())
  with check (public.is_registered_user());
drop policy if exists challenge_invitations_participant_read
  on public.challenge_invitations;
create policy challenge_invitations_participant_read
  on public.challenge_invitations for select to authenticated
  using (inviter_id = auth.uid() or invitee_id = auth.uid());

drop policy if exists challenge_progress_registered
  on public.challenge_progress_logs;
create policy challenge_progress_registered
  on public.challenge_progress_logs as restrictive for all to authenticated
  using (public.is_registered_user())
  with check (public.is_registered_user());
drop policy if exists challenge_progress_participant_read
  on public.challenge_progress_logs;
create policy challenge_progress_participant_read
  on public.challenge_progress_logs for select to authenticated
  using (public.arena_is_participant(challenge_id));

drop policy if exists authenticated_read on public.challenges;
drop policy if exists challenges_visible_read on public.challenges;
create policy challenges_visible_read on public.challenges
  for select to authenticated
  using (
    public.is_registered_user()
    and (
      (visibility = 'public' and not public.community_is_blocked(creator_id))
      or creator_id = auth.uid()
      or public.arena_is_participant(id)
      or exists (
        select 1 from public.challenge_invitations ci
        where ci.challenge_id = challenges.id and ci.invitee_id = auth.uid()
      )
    )
  );
drop policy if exists authenticated_read on public.challenge_participants;
drop policy if exists challenge_participants_visible_read
  on public.challenge_participants;
create policy challenge_participants_visible_read
  on public.challenge_participants for select to authenticated
  using (
    public.is_registered_user()
    and exists (
      select 1 from public.challenges c
      where c.id = challenge_participants.challenge_id
        and (
          c.visibility = 'public'
          or public.arena_is_participant(c.id)
        )
    )
  );
revoke insert, update, delete on public.challenges,
  public.challenge_participants from authenticated;
grant select on public.challenges, public.challenge_participants
  to authenticated;
grant all on public.challenges, public.challenge_participants to service_role;

drop trigger if exists set_updated_at on public.challenge_invitations;
create trigger set_updated_at before update on public.challenge_invitations
  for each row execute function public.touch_updated_at();

alter table public.community_notifications
  add column if not exists challenge_id uuid
  references public.challenges(id) on delete cascade;
alter table public.community_notifications
  drop constraint if exists community_notifications_notification_type_check;
alter table public.community_notifications
  add constraint community_notifications_notification_type_check
  check (notification_type in (
    'friend_request', 'friend_accepted', 'post_comment', 'post_like',
    'challenge_invite', 'challenge_result'
  ));
comment on column public.community_notifications.challenge_id is
  'Arena challenge associated with a challenge invitation or result notice.';

create or replace function public.refresh_arena_challenge_day(
  p_user_id uuid, p_activity_date date
)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  challenge_row record;
  units integer;
begin
  if p_user_id is null or p_activity_date is null then return; end if;

  for challenge_row in
    select c.id, c.type
    from public.challenge_participants cp
    join public.challenges c on c.id = cp.challenge_id
    where cp.user_id = p_user_id
      and c.finalized_at is null
      and p_activity_date between c.start_date and c.end_date
    order by c.id
    for update of c
  loop
    if challenge_row.type = 'streak' then
      select case when exists (
        select 1 from public.meal_logs m
        where m.user_id = p_user_id
          and m.logged_date = p_activity_date and m.consumed
        union all
        select 1 from public.workout_logs w
        where w.user_id = p_user_id and w.activity_date = p_activity_date
      ) then 1 else 0 end into units;
    else
      select count(*)::integer into units
      from public.workout_logs w
      where w.user_id = p_user_id and w.activity_date = p_activity_date;
    end if;

    if units > 0 then
      insert into public.challenge_progress_logs(
        challenge_id, user_id, activity_date, score_units, updated_at
      )
      values(challenge_row.id, p_user_id, p_activity_date, units, now())
      on conflict(challenge_id, user_id, activity_date)
      do update set score_units = excluded.score_units,
                    updated_at = excluded.updated_at;
    else
      delete from public.challenge_progress_logs
      where challenge_id = challenge_row.id
        and user_id = p_user_id
        and activity_date = p_activity_date;
    end if;

    update public.challenge_participants cp
    set score = coalesce((
      select sum(pl.score_units)::numeric(14,2)
      from public.challenge_progress_logs pl
      where pl.challenge_id = challenge_row.id
        and pl.user_id = p_user_id
    ), 0)
    where cp.challenge_id = challenge_row.id and cp.user_id = p_user_id;

    perform public.rank_arena_challenge(challenge_row.id);
  end loop;
end
$$;
comment on function public.refresh_arena_challenge_day(uuid,date) is
  'Recomputes challenge day scores strictly from consumed meal and completed workout rows.';
revoke all on function public.refresh_arena_challenge_day(uuid,date)
  from public, anon, authenticated;

create or replace function public.refresh_arena_activity_trigger()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  affected_user uuid;
  affected_date date;
begin
  if tg_op <> 'INSERT' then
    affected_user := old.user_id;
    if tg_table_name = 'meal_logs' then
      affected_date := old.logged_date;
    else
      affected_date := old.activity_date;
    end if;
    perform public.refresh_arena_challenge_day(affected_user, affected_date);
  end if;
  if tg_op <> 'DELETE' then
    affected_user := new.user_id;
    if tg_table_name = 'meal_logs' then
      affected_date := new.logged_date;
    else
      affected_date := new.activity_date;
    end if;
    if tg_table_name <> 'meal_logs' then
      perform public.refresh_arena_challenge_day(affected_user, affected_date);
    elsif new.consumed then
      perform public.refresh_arena_challenge_day(affected_user, affected_date);
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end
$$;
comment on function public.refresh_arena_activity_trigger() is
  'Recalculates affected Arena scores whenever real meal/workout logs change.';
revoke all on function public.refresh_arena_activity_trigger()
  from public, anon, authenticated;

drop trigger if exists refresh_arena_meal_progress on public.meal_logs;
create trigger refresh_arena_meal_progress
  after insert or update or delete on public.meal_logs
  for each row execute function public.refresh_arena_activity_trigger();
drop trigger if exists refresh_arena_workout_progress on public.workout_logs;
create trigger refresh_arena_workout_progress
  after insert or update or delete on public.workout_logs
  for each row execute function public.refresh_arena_activity_trigger();

create or replace function public.refresh_arena_challenge_history(
  p_challenge_id uuid, p_user_id uuid
)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  challenge_row public.challenges%rowtype;
  day date;
  last_day date;
begin
  select * into challenge_row from public.challenges
  where id = p_challenge_id for update;
  if not found or challenge_row.finalized_at is not null then return; end if;
  if not exists (
    select 1 from public.challenge_participants cp
    where cp.challenge_id = p_challenge_id and cp.user_id = p_user_id
  ) then return; end if;

  delete from public.challenge_progress_logs
  where challenge_id = p_challenge_id and user_id = p_user_id;
  last_day := least(
    challenge_row.end_date,
    (now() at time zone public.activity_timezone_for_user(p_user_id))::date
  );
  if last_day >= challenge_row.start_date then
    for day in
      select distinct activity_date from (
        select m.logged_date as activity_date
        from public.meal_logs m
        where challenge_row.type = 'streak'
          and m.user_id = p_user_id and m.consumed
          and m.logged_date between challenge_row.start_date and last_day
        union all
        select w.activity_date
        from public.workout_logs w
        where w.user_id = p_user_id
          and w.activity_date between challenge_row.start_date and last_day
      ) active_days
    loop
      perform public.refresh_arena_challenge_day(p_user_id, day);
    end loop;
  end if;
end
$$;
comment on function public.refresh_arena_challenge_history(uuid,uuid) is
  'Backfills an accepted participant’s challenge progress from their existing real logs.';
revoke all on function public.refresh_arena_challenge_history(uuid,uuid)
  from public, anon, authenticated;

create or replace function public.create_public_arena_challenge(
  p_title text, p_type text, p_start_date date, p_end_date date,
  p_description text default ''
)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare new_challenge_id uuid;
begin
  if not public.is_registered_user() then
    raise exception 'A registered account is required';
  end if;
  if p_type not in ('streak', 'workout_count')
     or length(btrim(coalesce(p_title, ''))) not between 3 and 80
     or length(coalesce(p_description, '')) > 500
     or p_start_date < public.activity_today()
     or p_end_date < p_start_date
     or p_end_date > p_start_date + 30 then
    raise exception 'Invalid challenge details';
  end if;
  insert into public.challenges(
    creator_id, title, type, start_date, end_date, description, visibility
  )
  values(auth.uid(), btrim(p_title), p_type, p_start_date, p_end_date,
         btrim(coalesce(p_description, '')), 'public')
  returning id into new_challenge_id;
  insert into public.challenge_participants(challenge_id, user_id, score, rank)
  values(new_challenge_id, auth.uid(), 0, 1);
  perform public.rank_arena_challenge(new_challenge_id);
  return new_challenge_id;
end
$$;
comment on function public.create_public_arena_challenge(text,text,date,date,text) is
  'Creates a public streak or workout-count challenge and joins its creator.';
revoke all on function public.create_public_arena_challenge(text,text,date,date,text)
  from public, anon;
grant execute on function public.create_public_arena_challenge(text,text,date,date,text)
  to authenticated;

create or replace function public.join_public_arena_challenge(p_challenge_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare c public.challenges%rowtype;
begin
  if not public.is_registered_user() then
    raise exception 'A registered account is required';
  end if;
  select * into c from public.challenges
  where id = p_challenge_id and visibility = 'public'
  for update;
  if not found or c.finalized_at is not null
     or public.activity_today() > c.end_date
     or public.community_is_blocked(c.creator_id) then
    raise exception 'This challenge is not available';
  end if;
  insert into public.challenge_participants(challenge_id, user_id, score, rank)
  values(c.id, auth.uid(), 0, null)
  on conflict(challenge_id, user_id) do nothing;
  perform public.refresh_arena_challenge_history(c.id, auth.uid());
  perform public.rank_arena_challenge(c.id);
end
$$;
comment on function public.join_public_arena_challenge(uuid) is
  'Joins an open public challenge and derives initial score from existing activity logs.';
revoke all on function public.join_public_arena_challenge(uuid) from public, anon;
grant execute on function public.join_public_arena_challenge(uuid) to authenticated;

create or replace function public.create_friend_arena_challenge(
  p_friend_id uuid, p_title text, p_type text,
  p_start_date date, p_end_date date
)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare new_challenge_id uuid; invitation_id uuid; expires timestamptz;
begin
  if not public.is_registered_user()
     or p_friend_id = auth.uid()
     or not public.community_are_friends(p_friend_id)
     or p_type not in ('streak', 'workout_count')
     or length(btrim(coalesce(p_title, ''))) not between 3 and 80
     or p_start_date < public.activity_today()
     or p_end_date < p_start_date
     or p_end_date > p_start_date + 30 then
    raise exception 'Invalid friend challenge details';
  end if;
  expires := least(
    now() + interval '7 days',
    (p_start_date + 1)::timestamp at time zone
      public.activity_timezone_for_user(p_friend_id)
  );
  if expires <= now() then raise exception 'The challenge start date has passed'; end if;

  insert into public.challenges(
    creator_id, title, type, start_date, end_date, visibility, is_one_v_one
  )
  values(auth.uid(), btrim(p_title), p_type, p_start_date, p_end_date,
         'private', true)
  returning id into new_challenge_id;
  insert into public.challenge_participants(challenge_id, user_id, score, rank)
  values(new_challenge_id, auth.uid(), 0, 1);
  insert into public.challenge_invitations(
    challenge_id, inviter_id, invitee_id, expires_at
  )
  values(new_challenge_id, auth.uid(), p_friend_id, expires)
  returning id into invitation_id;
  insert into public.community_notifications(
    recipient_id, actor_id, notification_type, challenge_id
  )
  values(p_friend_id, auth.uid(), 'challenge_invite', new_challenge_id);
  return invitation_id;
end
$$;
comment on function public.create_friend_arena_challenge(uuid,text,text,date,date) is
  'Creates a private 1v1 challenge for an accepted friend and sends an expiring invite.';
revoke all on function public.create_friend_arena_challenge(uuid,text,text,date,date)
  from public, anon;
grant execute on function public.create_friend_arena_challenge(uuid,text,text,date,date)
  to authenticated;

create or replace function public.respond_to_arena_invitation(
  p_invitation_id uuid, p_action text
)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  invitation public.challenge_invitations%rowtype;
  challenge_row public.challenges%rowtype;
begin
  if not public.is_registered_user() or p_action not in ('accept', 'decline') then
    raise exception 'Invalid invitation response';
  end if;
  select * into invitation from public.challenge_invitations
  where id = p_invitation_id and invitee_id = auth.uid()
  for update;
  if not found or invitation.status <> 'pending' then
    raise exception 'Invitation is no longer available';
  end if;
  select * into challenge_row from public.challenges
  where id = invitation.challenge_id for update;
  if invitation.expires_at <= now()
     or challenge_row.finalized_at is not null
     or public.activity_today() > challenge_row.start_date then
    update public.challenge_invitations
    set status = 'expired', responded_at = now()
    where id = invitation.id;
    return;
  end if;
  update public.challenge_invitations
  set status = case when p_action = 'accept' then 'accepted' else 'declined' end,
      responded_at = now()
  where id = invitation.id;
  if p_action = 'accept' then
    if not public.community_are_friends(invitation.inviter_id) then
      raise exception 'The friend connection is no longer active';
    end if;
    insert into public.challenge_participants(challenge_id, user_id, score, rank)
    values(invitation.challenge_id, auth.uid(), 0, null)
    on conflict(challenge_id, user_id) do nothing;
    perform public.refresh_arena_challenge_history(
      invitation.challenge_id, auth.uid()
    );
    perform public.rank_arena_challenge(invitation.challenge_id);
  end if;
end
$$;
comment on function public.respond_to_arena_invitation(uuid,text) is
  'Accepts or declines an unexpired private Arena invitation; acceptance joins as participant.';
revoke all on function public.respond_to_arena_invitation(uuid,text)
  from public, anon;
grant execute on function public.respond_to_arena_invitation(uuid,text)
  to authenticated;

create or replace function public.arena_challenge_inbox()
returns table (
  invitation_id uuid, challenge_id uuid, title text, challenge_type text,
  start_date date, end_date date, inviter_id uuid, inviter_username text,
  inviter_full_name text, inviter_avatar_url text, expires_at timestamptz,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select i.id, c.id, c.title, c.type, c.start_date, c.end_date,
         i.inviter_id, cp.username, cp.full_name, cp.avatar_url,
         i.expires_at, i.created_at
  from public.challenge_invitations i
  join public.challenges c on c.id = i.challenge_id
  join public.community_profiles cp on cp.id = i.inviter_id
  where public.is_registered_user()
    and i.invitee_id = auth.uid()
    and i.status = 'pending'
    and i.expires_at > now()
  order by i.created_at desc, i.id desc
$$;
comment on function public.arena_challenge_inbox() is
  'Lists only the caller’s pending and unexpired private challenge invitations.';
revoke all on function public.arena_challenge_inbox() from public, anon;
grant execute on function public.arena_challenge_inbox() to authenticated;

create or replace function public.arena_challenges(
  p_scope text default 'open', p_limit integer default 30
)
returns table (
  id uuid, creator_id uuid, title text, description text, type text,
  visibility text, is_one_v_one boolean, start_date date, end_date date,
  finalized_at timestamptz, winner_id uuid, participant_count bigint,
  my_score numeric, my_rank integer, joined boolean, creator_username text,
  creator_full_name text
)
language sql stable security definer set search_path = ''
as $$
  select c.id, c.creator_id, c.title, c.description, c.type,
         c.visibility, c.is_one_v_one, c.start_date, c.end_date,
         c.finalized_at, c.winner_id,
         (select count(*) from public.challenge_participants cp
          where cp.challenge_id = c.id),
         mine.score, mine.rank, mine.user_id is not null,
         creator.username, creator.full_name
  from public.challenges c
  join public.community_profiles creator on creator.id = c.creator_id
  left join public.challenge_participants mine
    on mine.challenge_id = c.id and mine.user_id = auth.uid()
  where public.is_registered_user()
    and c.type in ('streak', 'workout_count')
    and (
      (p_scope = 'open' and c.visibility = 'public'
        and c.finalized_at is null
        and public.activity_today() <= c.end_date
        and not public.community_is_blocked(c.creator_id))
      or (p_scope = 'mine' and mine.user_id is not null)
      or (p_scope = 'finished' and c.visibility = 'public'
        and c.finalized_at is not null
        and not public.community_is_blocked(c.creator_id))
    )
  order by c.start_date, c.created_at desc, c.id
  limit greatest(1, least(coalesce(p_limit, 30), 100))
$$;
comment on function public.arena_challenges(text,integer) is
  'Lists visible open, joined, or finished challenges with the caller’s score and rank.';
revoke all on function public.arena_challenges(text,integer) from public, anon;
grant execute on function public.arena_challenges(text,integer) to authenticated;

create or replace function public.arena_challenge_standings(p_challenge_id uuid)
returns table (
  user_id uuid, username text, full_name text, avatar_url text,
  score numeric, rank integer, is_me boolean
)
language sql stable security definer set search_path = ''
as $$
  select cp.user_id, identity.username, identity.full_name, identity.avatar_url,
         cp.score, cp.rank, cp.user_id = auth.uid()
  from public.challenge_participants cp
  join public.challenges c on c.id = cp.challenge_id
  join public.community_profiles identity on identity.id = cp.user_id
  where public.is_registered_user() and c.id = p_challenge_id
    and (
      c.visibility = 'public'
      or public.arena_is_participant(c.id)
    )
    and not public.community_is_blocked(cp.user_id)
  order by cp.score desc, cp.created_at, cp.id
$$;
comment on function public.arena_challenge_standings(uuid) is
  'Returns a visible challenge’s standings using safe community identity fields.';
revoke all on function public.arena_challenge_standings(uuid) from public, anon;
grant execute on function public.arena_challenge_standings(uuid) to authenticated;

create or replace function public.arena_leaderboard(
  p_scope text default 'global', p_period text default 'weekly',
  p_metric text default 'streak', p_level_id uuid default null,
  p_limit integer default 50
)
returns table (
  user_id uuid, username text, full_name text, avatar_url text,
  score bigint, current_streak integer, level_id uuid, level_name text,
  place bigint, is_me boolean
)
language sql stable security definer set search_path = ''
as $$
  with caller as (
    select auth.uid() as user_id
    where public.is_registered_user()
  ), candidates as (
    select p.id, p.level_id, p.activity_timezone
    from public.profiles p, caller me
    where (p_scope = 'global'
      or (p_scope = 'friends' and (
        p.id = me.user_id or exists (
          select 1 from public.friendships f
          where f.status = 'accepted'
            and ((f.requester_id = me.user_id and f.addressee_id = p.id)
              or (f.addressee_id = me.user_id and f.requester_id = p.id))
        )
      ))
      or (p_scope = 'level' and p.level_id = coalesce(
        p_level_id, (select level_id from public.profiles where id = me.user_id)
      )))
      and not public.community_is_blocked(p.id)
  ), scored as (
    select candidate.id, candidate.level_id,
      case
        when p_metric = 'workout_count' then (
          select count(*)::bigint
          from public.workout_logs w
          where w.user_id = candidate.id
            and (p_period = 'all_time' or
              w.activity_date >= case p_period
                when 'weekly' then date_trunc('week',
                  (now() at time zone coalesce(candidate.activity_timezone, 'UTC')))::date
                when 'monthly' then date_trunc('month',
                  (now() at time zone coalesce(candidate.activity_timezone, 'UTC')))::date
              end)
            and w.activity_date <=
              (now() at time zone coalesce(candidate.activity_timezone, 'UTC'))::date
        )
        else (
          select count(distinct active.activity_date)::bigint
          from (
            select m.logged_date as activity_date
            from public.meal_logs m
            where m.user_id = candidate.id and m.consumed
            union
            select w.activity_date
            from public.workout_logs w where w.user_id = candidate.id
          ) active
          where (p_period = 'all_time' or active.activity_date >=
            case p_period
              when 'weekly' then date_trunc('week',
                (now() at time zone coalesce(candidate.activity_timezone, 'UTC')))::date
              when 'monthly' then date_trunc('month',
                (now() at time zone coalesce(candidate.activity_timezone, 'UTC')))::date
            end)
            and active.activity_date <=
              (now() at time zone coalesce(candidate.activity_timezone, 'UTC'))::date
        )
      end as score,
      coalesce(s.current_streak, 0)::integer as current_streak
    from candidates candidate
    left join public.streaks s on s.user_id = candidate.id
    where p_scope in ('global', 'friends', 'level')
      and p_period in ('all_time', 'weekly', 'monthly')
      and p_metric in ('streak', 'workout_count')
  ), ranked as (
    select scored.*,
      row_number() over(order by score desc, id)::bigint as place
    from scored
  )
  select r.id, identity.username, identity.full_name, identity.avatar_url,
         r.score, r.current_streak, r.level_id, l.name, r.place,
         r.id = auth.uid()
  from ranked r
  join public.community_profiles identity on identity.id = r.id
  left join public.levels l on l.id = r.level_id
  order by r.place
  limit greatest(1, least(coalesce(p_limit, 50), 100))
$$;
comment on function public.arena_leaderboard(text,text,text,uuid,integer) is
  'Ranks registered users by real active days or workout logs, globally, among friends, or by level.';
revoke all on function public.arena_leaderboard(text,text,text,uuid,integer)
  from public, anon;
grant execute on function public.arena_leaderboard(text,text,text,uuid,integer)
  to authenticated;

create or replace function public.finalize_challenge(p_challenge_id uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare c public.challenges%rowtype; winner uuid;
begin
  select * into c from public.challenges where id = p_challenge_id for update;
  if not found then raise exception 'Challenge not found'; end if;
  if c.finalized_at is not null then return c.winner_id; end if;
  if (now() at time zone
        public.activity_timezone_for_user(c.creator_id))::date <= c.end_date then
    raise exception 'Challenge has not ended';
  end if;
  with ranked as (
    select id,
      row_number() over(order by score desc, created_at, id)::integer as place
    from public.challenge_participants where challenge_id = c.id
  )
  update public.challenge_participants cp
  set rank = ranked.place from ranked where cp.id = ranked.id;
  select cp.user_id into winner from public.challenge_participants cp
  where cp.challenge_id = c.id and cp.rank = 1;
  update public.challenges set finalized_at = now(), winner_id = winner
  where id = c.id;
  insert into public.community_notifications(
    recipient_id, notification_type, challenge_id
  )
  select cp.user_id, 'challenge_result', c.id
  from public.challenge_participants cp
  where cp.challenge_id = c.id
  on conflict do nothing;
  return winner;
end
$$;
comment on function public.finalize_challenge(uuid) is
  'Closes an ended challenge and ranks its server-derived scores without granting prizes.';
revoke all on function public.finalize_challenge(uuid)
  from public, anon, authenticated;
grant execute on function public.finalize_challenge(uuid) to service_role;

create or replace function public.process_arena_schedules()
returns integer
language plpgsql security definer set search_path = ''
as $$
declare challenge_row record; affected integer := 0;
begin
  update public.challenge_invitations i
  set status = 'expired', responded_at = now()
  from public.challenges c
  where c.id = i.challenge_id and i.status = 'pending'
    and i.expires_at <= now();
  get diagnostics affected = row_count;

  for challenge_row in
    select c.id from public.challenges c
    where c.finalized_at is null
      and (now() at time zone
        public.activity_timezone_for_user(c.creator_id))::date > c.end_date
    order by c.end_date, c.id
  loop
    perform public.finalize_challenge(challenge_row.id);
    affected := affected + 1;
  end loop;
  return affected;
end
$$;
comment on function public.process_arena_schedules() is
  'Expires unanswered friend invitations and finalizes ended challenges; safe for scheduled reruns.';
revoke all on function public.process_arena_schedules()
  from public, anon, authenticated;
grant execute on function public.process_arena_schedules() to service_role;

do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'cron')
     and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                 where n.nspname = 'cron' and p.proname = 'schedule') then
    begin
      perform cron.schedule(
        'privilege-arena-schedules',
        '15 * * * *',
        'select public.process_arena_schedules()'
      );
    exception when others then
      raise notice 'Could not schedule Arena maintenance; invoke process_arena_schedules from pg_cron when available.';
    end;
  end if;
end
$$;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = 'challenges') then
      alter publication supabase_realtime add table public.challenges;
    end if;
    if not exists (select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = 'challenge_participants') then
      alter publication supabase_realtime add table public.challenge_participants;
    end if;
    if not exists (select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = 'challenge_invitations') then
      alter publication supabase_realtime add table public.challenge_invitations;
    end if;
  end if;
end
$$;

commit;
