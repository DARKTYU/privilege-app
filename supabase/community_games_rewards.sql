-- Stage 2: community posts, comments, likes, follows, friends, public profiles,
-- notifications, private post-image storage and realtime.
-- Apply after schema.sql, seed.sql, auth_migration.sql and activity_tracking.sql.
begin;

create table if not exists public.community_blocks (
 id uuid primary key default gen_random_uuid(),
 blocker_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 blocked_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 unique(blocker_id, blocked_id), check (blocker_id <> blocked_id)
);
comment on table public.community_blocks is 'Account blocks affecting community content.';
create index if not exists community_blocks_blocked_idx on public.community_blocks(blocked_id);

create table if not exists public.community_follows (
 id uuid primary key default gen_random_uuid(),
 follower_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 followed_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 unique(follower_id, followed_id), check (follower_id <> followed_id)
);
comment on table public.community_follows is 'User follow relationships; follows do not confer friendship.';
create index if not exists community_follows_followed_idx on public.community_follows(followed_id);

create table if not exists public.community_posts (
 id uuid primary key default gen_random_uuid(),
 author_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 body text not null check (length(btrim(body)) between 1 and 5000),
 visibility text not null default 'public' check (visibility in ('public', 'friends')),
 image_path text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.community_posts add column if not exists image_path text;
comment on table public.community_posts is 'Text posts visible to all registered users or accepted friends.';
create index if not exists community_posts_feed_idx on public.community_posts(created_at desc, id desc);
create index if not exists community_posts_author_idx on public.community_posts(author_id, created_at desc);
comment on column public.community_posts.image_path is
 'Private Storage object path; downloads are controlled by post visibility and blocks.';

create table if not exists public.community_comments (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.community_posts(id) on delete cascade,
 author_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 body text not null check (length(btrim(body)) between 1 and 2000),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
comment on table public.community_comments is 'Comments on visible community posts.';
create index if not exists community_comments_post_idx on public.community_comments(post_id, created_at, id);
create index if not exists community_comments_author_idx on public.community_comments(author_id);

create table if not exists public.community_likes (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.community_posts(id) on delete cascade,
 user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 unique(post_id, user_id)
);
comment on table public.community_likes is 'One like per user and visible post.';
create index if not exists community_likes_user_idx on public.community_likes(user_id);

create table if not exists public.community_reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 post_id uuid not null references public.community_posts(id) on delete cascade,
 reason text not null check (length(btrim(reason)) between 3 and 1000),
 created_at timestamptz not null default now(),
 unique(reporter_id, post_id)
);
comment on table public.community_reports is 'Private moderation reports; review requires a trusted administrator.';
create index if not exists community_reports_post_idx on public.community_reports(post_id);

create table if not exists public.community_notifications (
 id uuid primary key default gen_random_uuid(),
 recipient_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 actor_id uuid references public.profiles(id) on delete set null,
 notification_type text not null check (notification_type in (
   'friend_request', 'friend_accepted', 'post_comment', 'post_like'
 )),
 post_id uuid references public.community_posts(id) on delete cascade,
 friendship_id uuid references public.friendships(id) on delete cascade,
 read_at timestamptz,
 created_at timestamptz not null default now(),
 check (actor_id is null or actor_id <> recipient_id)
);
comment on table public.community_notifications is
 'Private user notifications for friend requests, accepted requests, comments and likes.';
create index if not exists community_notifications_inbox_idx
 on public.community_notifications(recipient_id, created_at desc, id desc);
create index if not exists community_notifications_unread_idx
 on public.community_notifications(recipient_id) where read_at is null;

create or replace function public.community_is_blocked(p_other uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select exists (
   select 1 from public.community_blocks b
   where (b.blocker_id = auth.uid() and b.blocked_id = p_other)
      or (b.blocked_id = auth.uid() and b.blocker_id = p_other)
 ) or exists (
   select 1 from public.friendships f where f.status = 'blocked'
     and ((f.requester_id = auth.uid() and f.addressee_id = p_other)
       or (f.addressee_id = auth.uid() and f.requester_id = p_other))
 )
$$;
comment on function public.community_is_blocked(uuid) is 'Whether either account has blocked the other.';
revoke all on function public.community_is_blocked(uuid) from public, anon;
grant execute on function public.community_is_blocked(uuid) to authenticated;

create or replace function public.community_are_friends(p_other uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select not public.community_is_blocked(p_other) and exists (
   select 1 from public.friendships f where f.status = 'accepted'
   and ((f.requester_id = auth.uid() and f.addressee_id = p_other)
     or (f.addressee_id = auth.uid() and f.requester_id = p_other))
 )
$$;
comment on function public.community_are_friends(uuid) is 'Whether the caller and another user are unblocked accepted friends.';
revoke all on function public.community_are_friends(uuid) from public, anon;
grant execute on function public.community_are_friends(uuid) to authenticated;

-- This view contains only the approved public identity fields. Its owner
-- bypasses profiles' private self-only RLS; consumers cannot select profiles.
create or replace view public.community_profiles
with (security_invoker = false, security_barrier = true) as
 select p.id, p.username, p.full_name, p.avatar_url
 from public.profiles p
 where public.is_registered_user();
revoke all on public.community_profiles from public, anon;
grant select on public.community_profiles to authenticated;

create or replace function public.community_search_users(
 p_query text default '', p_limit integer default 20, p_offset integer default 0
)
returns table (
 user_id uuid, username text, full_name text, avatar_url text,
 relationship text, followed_by_me boolean
)
language sql stable security definer set search_path = '' as $$
 with normalized as (
   select left(regexp_replace(btrim(coalesce(p_query, '')), '[%_]', '', 'g'), 40) as term
 )
 select cp.id, cp.username, cp.full_name, cp.avatar_url,
   case
     when exists (
       select 1 from public.friendships f
       where f.status = 'accepted'
         and ((f.requester_id = auth.uid() and f.addressee_id = cp.id)
           or (f.addressee_id = auth.uid() and f.requester_id = cp.id))
     ) then 'friends'
     when exists (
       select 1 from public.friendships f
       where f.status = 'pending' and f.requester_id = auth.uid()
         and f.addressee_id = cp.id
     ) then 'request_outgoing'
     when exists (
       select 1 from public.friendships f
       where f.status = 'pending' and f.addressee_id = auth.uid()
         and f.requester_id = cp.id
     ) then 'request_incoming'
     else 'none'
   end,
   exists (
     select 1 from public.community_follows cf
     where cf.follower_id = auth.uid() and cf.followed_id = cp.id
   )
 from public.community_profiles cp, normalized n
 where public.is_registered_user()
   and cp.id <> auth.uid()
   and not public.community_is_blocked(cp.id)
   and (n.term = '' or cp.username ilike n.term || '%'
        or coalesce(cp.full_name, '') ilike n.term || '%')
 order by
   case when n.term = '' then (
     select count(*)
     from public.friendships mine
     join public.friendships candidate
       on candidate.status = 'accepted'
      and cp.id in (candidate.requester_id, candidate.addressee_id)
     where mine.status = 'accepted'
       and auth.uid() in (mine.requester_id, mine.addressee_id)
       and (case when mine.requester_id = auth.uid()
                 then mine.addressee_id else mine.requester_id end)
           = (case when candidate.requester_id = cp.id
                   then candidate.addressee_id else candidate.requester_id end)
       and not public.community_is_blocked(
         case when mine.requester_id = auth.uid()
              then mine.addressee_id else mine.requester_id end
       )
   ) else 0 end desc,
   cp.username, cp.id
 limit greatest(1, least(coalesce(p_limit, 20), 50))
 offset greatest(0, least(coalesce(p_offset, 0), 500))
$$;
comment on function public.community_search_users(text,integer,integer) is
 'Searches or suggests registered profiles, returning only safe identity and relationship state.';
revoke all on function public.community_search_users(text,integer,integer) from public, anon;
grant execute on function public.community_search_users(text,integer,integer) to authenticated;

create or replace function public.community_friends()
returns table (
 friendship_id uuid, user_id uuid, username text, full_name text, avatar_url text
)
language sql stable security definer set search_path = '' as $$
 select f.id, cp.id, cp.username, cp.full_name, cp.avatar_url
 from public.friendships f
 join public.community_profiles cp
   on cp.id = case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end
 where public.is_registered_user() and f.status = 'accepted'
   and auth.uid() in (f.requester_id, f.addressee_id)
   and not public.community_is_blocked(cp.id)
 order by cp.username
$$;
comment on function public.community_friends() is
 'Lists accepted, unblocked friends with safe community profile fields.';
revoke all on function public.community_friends() from public, anon;
grant execute on function public.community_friends() to authenticated;

create or replace function public.community_friend_requests()
returns table (
 friendship_id uuid, user_id uuid, username text, full_name text,
 avatar_url text, request_direction text, created_at timestamptz
)
language sql stable security definer set search_path = '' as $$
 select f.id, cp.id, cp.username, cp.full_name, cp.avatar_url,
   case when f.addressee_id = auth.uid() then 'incoming' else 'outgoing' end,
   f.created_at
 from public.friendships f
 join public.community_profiles cp
   on cp.id = case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end
 where public.is_registered_user()
   and f.status = 'pending'
   and auth.uid() in (f.requester_id, f.addressee_id)
   and not public.community_is_blocked(cp.id)
 order by f.created_at desc, f.id desc
$$;
comment on function public.community_friend_requests() is
 'Lists pending friend requests for the caller with safe profile fields.';
revoke all on function public.community_friend_requests() from public, anon;
grant execute on function public.community_friend_requests() to authenticated;

create or replace function public.community_public_profile(p_user_id uuid)
returns table (
 user_id uuid, username text, full_name text, avatar_url text, level_name text,
 current_streak integer, longest_streak integer, post_count bigint,
 friend_count bigint, follower_count bigint, followed_by_me boolean, relationship text
)
language sql stable security definer set search_path = '' as $$
 select cp.id, cp.username, cp.full_name, cp.avatar_url, l.name,
   coalesce(s.current_streak, 0), coalesce(s.longest_streak, 0),
   (select count(*) from public.community_posts p where p.author_id = cp.id),
   (select count(*) from public.friendships f where f.status = 'accepted'
      and (f.requester_id = cp.id or f.addressee_id = cp.id)),
   (select count(*) from public.community_follows cf where cf.followed_id = cp.id),
   exists(select 1 from public.community_follows cf
      where cf.follower_id = auth.uid() and cf.followed_id = cp.id),
   case
     when auth.uid() = cp.id then 'self'
     when exists(select 1 from public.friendships f where f.status = 'accepted'
       and ((f.requester_id = auth.uid() and f.addressee_id = cp.id)
         or (f.addressee_id = auth.uid() and f.requester_id = cp.id))) then 'friends'
     when exists(select 1 from public.friendships f where f.status = 'pending'
       and f.requester_id = auth.uid() and f.addressee_id = cp.id) then 'request_outgoing'
     when exists(select 1 from public.friendships f where f.status = 'pending'
       and f.addressee_id = auth.uid() and f.requester_id = cp.id) then 'request_incoming'
     else 'none'
   end
 from public.community_profiles cp
 left join public.profiles p on p.id = cp.id
 left join public.levels l on l.id = p.level_id
 left join public.streaks s on s.user_id = cp.id
 where public.is_registered_user() and cp.id = p_user_id
   and (cp.id = auth.uid() or not public.community_is_blocked(cp.id))
$$;
comment on function public.community_public_profile(uuid) is
 'Returns safe public identity, level and aggregate community/streak stats, never health profile fields.';
revoke all on function public.community_public_profile(uuid) from public, anon;
grant execute on function public.community_public_profile(uuid) to authenticated;

do $$
declare t text;
begin
 foreach t in array array['community_blocks','community_follows','community_posts','community_comments','community_likes','community_reports','community_notifications'] loop
  execute format('alter table public.%I enable row level security', t);
  execute format('revoke all on public.%I from public, anon, authenticated', t);
  execute format('grant select, delete on public.%I to authenticated', t);
  execute format('grant all on public.%I to service_role', t);
  execute format('drop policy if exists registered_accounts_only on public.%I', t);
  execute format('create policy registered_accounts_only on public.%I as restrictive for all to authenticated using (public.is_registered_user()) with check (public.is_registered_user())', t);
 end loop;
end $$;
grant insert (blocked_id) on public.community_blocks to authenticated;
grant insert (followed_id) on public.community_follows to authenticated;
grant insert (id, body, visibility, image_path) on public.community_posts to authenticated;
grant insert (post_id, body) on public.community_comments to authenticated;
grant insert (post_id) on public.community_likes to authenticated;
grant insert (post_id, reason) on public.community_reports to authenticated;
grant select, update (read_at) on public.community_notifications to authenticated;

drop policy if exists blocks_read on public.community_blocks;
create policy blocks_read on public.community_blocks for select to authenticated using (blocker_id = auth.uid());
drop policy if exists blocks_insert on public.community_blocks;
create policy blocks_insert on public.community_blocks for insert to authenticated with check (blocker_id = auth.uid());
drop policy if exists blocks_delete on public.community_blocks;
create policy blocks_delete on public.community_blocks for delete to authenticated using (blocker_id = auth.uid());

drop policy if exists follows_read on public.community_follows;
create policy follows_read on public.community_follows for select to authenticated
 using (not public.community_is_blocked(follower_id) and not public.community_is_blocked(followed_id));
drop policy if exists follows_insert on public.community_follows;
create policy follows_insert on public.community_follows for insert to authenticated
 with check (follower_id = auth.uid() and not public.community_is_blocked(followed_id));
drop policy if exists follows_delete on public.community_follows;
create policy follows_delete on public.community_follows for delete to authenticated using (follower_id = auth.uid());

drop policy if exists posts_read on public.community_posts;
create policy posts_read on public.community_posts for select to authenticated
 using (author_id = auth.uid() or (not public.community_is_blocked(author_id)
   and (visibility = 'public' or public.community_are_friends(author_id))));
drop policy if exists posts_insert on public.community_posts;
create policy posts_insert on public.community_posts for insert to authenticated with check (author_id = auth.uid());
drop policy if exists posts_delete on public.community_posts;
create policy posts_delete on public.community_posts for delete to authenticated using (author_id = auth.uid());
grant update (body, visibility, image_path) on public.community_posts to authenticated;
drop policy if exists posts_update on public.community_posts;
create policy posts_update on public.community_posts for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());
drop trigger if exists set_updated_at on public.community_posts;
create trigger set_updated_at before update on public.community_posts for each row execute function public.touch_updated_at();

drop policy if exists comments_read on public.community_comments;
create policy comments_read on public.community_comments for select to authenticated
 using (not public.community_is_blocked(author_id) and exists (
   select 1 from public.community_posts p where p.id = post_id
 ));
drop policy if exists comments_insert on public.community_comments;
create policy comments_insert on public.community_comments for insert to authenticated
 with check (author_id = auth.uid() and exists (
   select 1 from public.community_posts p where p.id = post_id
     and not public.community_is_blocked(p.author_id)
 ));
drop policy if exists comments_delete on public.community_comments;
create policy comments_delete on public.community_comments for delete to authenticated using (author_id = auth.uid());
grant update (body) on public.community_comments to authenticated;
drop policy if exists comments_update on public.community_comments;
create policy comments_update on public.community_comments for update to authenticated
 using (author_id = auth.uid() and exists (select 1 from public.community_posts p where p.id = post_id))
 with check (author_id = auth.uid() and exists (select 1 from public.community_posts p where p.id = post_id));
drop trigger if exists set_updated_at on public.community_comments;
create trigger set_updated_at before update on public.community_comments for each row execute function public.touch_updated_at();

drop policy if exists notifications_read on public.community_notifications;
create policy notifications_read on public.community_notifications for select to authenticated
 using (recipient_id = auth.uid());
drop policy if exists notifications_update on public.community_notifications;
create policy notifications_update on public.community_notifications for update to authenticated
 using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

create or replace function public.community_notify_friendship()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if tg_op = 'INSERT' and new.status = 'pending' then
   insert into public.community_notifications(recipient_id, actor_id, notification_type, friendship_id)
   values(new.addressee_id, new.requester_id, 'friend_request', new.id);
 elsif tg_op = 'UPDATE' and old.status = 'pending' and new.status = 'accepted' then
   insert into public.community_notifications(recipient_id, actor_id, notification_type, friendship_id)
   values(new.requester_id, new.addressee_id, 'friend_accepted', new.id);
 end if;
 return new;
end $$;
comment on function public.community_notify_friendship() is
 'Creates private friend-request and acceptance notifications.';
revoke all on function public.community_notify_friendship() from public, anon, authenticated;
drop trigger if exists community_friendship_notification on public.friendships;
create trigger community_friendship_notification
 after insert or update of status on public.friendships
 for each row execute function public.community_notify_friendship();

create or replace function public.community_notify_interaction()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
 post_author uuid;
 actor_id uuid;
begin
 select author_id into post_author from public.community_posts where id = new.post_id;
 if tg_table_name = 'community_comments' then
  actor_id := new.author_id;
 else
  actor_id := new.user_id;
 end if;
 if post_author is not null and post_author <> actor_id then
  insert into public.community_notifications(recipient_id, actor_id, notification_type, post_id)
  values(post_author, actor_id,
     case when tg_table_name = 'community_comments' then 'post_comment' else 'post_like' end,
     new.post_id);
 end if;
 return new;
end $$;
comment on function public.community_notify_interaction() is
 'Notifies a post author when another registered user comments or likes.';
revoke all on function public.community_notify_interaction() from public, anon, authenticated;
drop trigger if exists community_comment_notification on public.community_comments;
create trigger community_comment_notification after insert on public.community_comments
 for each row execute function public.community_notify_interaction();
drop trigger if exists community_like_notification on public.community_likes;
create trigger community_like_notification after insert on public.community_likes
 for each row execute function public.community_notify_interaction();

create or replace function public.community_unread_count()
returns bigint language sql stable security definer set search_path = '' as $$
 select count(*) from public.community_notifications
 where recipient_id = auth.uid() and read_at is null and public.is_registered_user()
$$;
comment on function public.community_unread_count() is
 'Returns the signed-in user’s unread notification count.';
revoke all on function public.community_unread_count() from public, anon;
grant execute on function public.community_unread_count() to authenticated;

create or replace function public.community_notifications_page(p_limit integer default 30)
returns table (
 id uuid, notification_type text, post_id uuid, friendship_id uuid,
 read_at timestamptz, created_at timestamptz, actor_id uuid,
 username text, full_name text, avatar_url text
)
language sql stable security definer set search_path = '' as $$
 select n.id, n.notification_type, n.post_id, n.friendship_id, n.read_at,
        n.created_at, n.actor_id, cp.username, cp.full_name, cp.avatar_url
 from public.community_notifications n
 left join public.community_profiles cp on cp.id = n.actor_id
 where public.is_registered_user()
   and n.recipient_id = auth.uid()
   and (n.actor_id is null or not public.community_is_blocked(n.actor_id))
 order by n.created_at desc, n.id desc
 limit greatest(1, least(coalesce(p_limit, 30), 100))
$$;
comment on function public.community_notifications_page(integer) is
 'Returns only the caller’s recent notifications and safe actor identity fields.';
revoke all on function public.community_notifications_page(integer) from public, anon;
grant execute on function public.community_notifications_page(integer) to authenticated;

create or replace function public.community_comments_page(
 p_post_id uuid, p_before_created_at timestamptz default null,
 p_before_id uuid default null, p_limit integer default 30
)
returns table (
 id uuid, post_id uuid, author_id uuid, username text, full_name text,
 avatar_url text, body text, created_at timestamptz
)
language sql stable security invoker set search_path = '' as $$
 select c.id, c.post_id, c.author_id, cp.username, cp.full_name, cp.avatar_url,
        c.body, c.created_at
 from public.community_comments c
 join public.community_profiles cp on cp.id = c.author_id
 where c.post_id = p_post_id
   and (p_before_created_at is null
        or (c.created_at, c.id) < (p_before_created_at, p_before_id))
 order by c.created_at desc, c.id desc
 limit greatest(1, least(coalesce(p_limit, 30), 50))
$$;
comment on function public.community_comments_page(uuid,timestamptz,uuid,integer) is
 'Returns a bounded newest-first keyset page of comments visible under RLS.';
revoke all on function public.community_comments_page(uuid,timestamptz,uuid,integer) from public, anon;
grant execute on function public.community_comments_page(uuid,timestamptz,uuid,integer) to authenticated;

drop policy if exists likes_read on public.community_likes;
create policy likes_read on public.community_likes for select to authenticated
 using (not public.community_is_blocked(user_id) and exists (select 1 from public.community_posts p where p.id = post_id));
drop policy if exists likes_insert on public.community_likes;
create policy likes_insert on public.community_likes for insert to authenticated
 with check (user_id = auth.uid() and exists (select 1 from public.community_posts p where p.id = post_id));
drop policy if exists likes_delete on public.community_likes;
create policy likes_delete on public.community_likes for delete to authenticated using (user_id = auth.uid());

revoke select, delete on public.community_reports from authenticated;
drop policy if exists reports_insert on public.community_reports;
create policy reports_insert on public.community_reports for insert to authenticated
 with check (reporter_id = auth.uid() and exists (select 1 from public.community_posts p where p.id = post_id and p.author_id <> auth.uid()));

create or replace function public.community_feed(
 p_before_group integer default null, p_before_time timestamptz default null,
 p_before_id uuid default null, p_limit integer default 20
)
returns table (
 id uuid, author_id uuid, username text, full_name text, avatar_url text,
 body text, visibility text, image_path text, created_at timestamptz, friend_group integer,
 like_count bigint, comment_count bigint, liked_by_me boolean
)
language sql stable security invoker set search_path = '' as $$
 with feed as (
  select p.id, p.author_id, cp.username, cp.full_name, cp.avatar_url,
         p.body, p.visibility, p.image_path, p.created_at,
         case when p.author_id = auth.uid()
                    or public.community_are_friends(p.author_id)
              then 0 else 1 end as friend_group
  from public.community_posts p join public.community_profiles cp on cp.id = p.author_id
 )
 select f.*, (select count(*) from public.community_likes l where l.post_id = f.id),
  (select count(*) from public.community_comments c where c.post_id = f.id),
  exists(select 1 from public.community_likes l where l.post_id = f.id and l.user_id = auth.uid())
 from feed f
 where p_before_group is null or f.friend_group > p_before_group
   or (f.friend_group = p_before_group and (f.created_at, f.id) < (p_before_time, p_before_id))
 order by f.friend_group, f.created_at desc, f.id desc
 limit greatest(1, least(coalesce(p_limit, 20), 50))
$$;
comment on function public.community_feed(integer,timestamptz,uuid,integer) is
 'Authenticated, RLS-filtered community feed; accepted friends first, then newest posts.';
revoke all on function public.community_feed(integer,timestamptz,uuid,integer) from public, anon;
grant execute on function public.community_feed(integer,timestamptz,uuid,integer) to authenticated;

-- A private bucket ensures friends-only post images are not anonymously exposed.
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values (
 'community-posts', 'community-posts', false, 8388608,
 array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update set
 public = false,
 file_size_limit = excluded.file_size_limit,
 allowed_mime_types = excluded.allowed_mime_types;
drop policy if exists community_images_upload_own on storage.objects;
create policy community_images_upload_own on storage.objects
 for insert to authenticated with check (
   bucket_id = 'community-posts'
   and (storage.foldername(name))[1] = auth.uid()::text
   and public.is_registered_user()
 );
drop policy if exists community_images_read_visible on storage.objects;
create policy community_images_read_visible on storage.objects
 for select to authenticated using (
   bucket_id = 'community-posts'
   and public.is_registered_user()
   and exists (
     select 1 from public.community_posts p
     where p.id::text = (storage.foldername(name))[2]
       and (
         p.author_id = auth.uid()
         or (
           not public.community_is_blocked(p.author_id)
           and (p.visibility = 'public' or public.community_are_friends(p.author_id))
         )
       )
   )
 );
drop policy if exists community_images_delete_own on storage.objects;
create policy community_images_delete_own on storage.objects
 for delete to authenticated using (
   bucket_id = 'community-posts'
   and (storage.foldername(name))[1] = auth.uid()::text
 );

-- Realtime is optional in local/test Supabase stacks; expose community changes
-- when the standard Supabase publication is present.
do $$
begin
 if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
   if not exists (select 1 from pg_publication_tables
                  where pubname = 'supabase_realtime'
                    and schemaname = 'public' and tablename = 'community_posts') then
     alter publication supabase_realtime add table public.community_posts;
   end if;
   if not exists (select 1 from pg_publication_tables
                  where pubname = 'supabase_realtime'
                    and schemaname = 'public' and tablename = 'community_comments') then
     alter publication supabase_realtime add table public.community_comments;
   end if;
   if not exists (select 1 from pg_publication_tables
                  where pubname = 'supabase_realtime'
                    and schemaname = 'public' and tablename = 'community_likes') then
     alter publication supabase_realtime add table public.community_likes;
   end if;
   if not exists (select 1 from pg_publication_tables
                  where pubname = 'supabase_realtime'
                    and schemaname = 'public' and tablename = 'community_notifications') then
     alter publication supabase_realtime add table public.community_notifications;
   end if;
   if not exists (select 1 from pg_publication_tables
                  where pubname = 'supabase_realtime'
                    and schemaname = 'public' and tablename = 'friendships') then
     alter publication supabase_realtime add table public.friendships;
   end if;
 end if;
end $$;

commit;
