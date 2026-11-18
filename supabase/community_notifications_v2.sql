-- Apply after rewards_badges_levels.sql. No user or demonstration data is seeded.
begin;

alter table public.community_notifications
  add column if not exists comment_id uuid
  references public.community_comments(id) on delete set null;
alter table public.community_notifications
  drop constraint if exists community_notifications_notification_type_check;
alter table public.community_notifications
  add constraint community_notifications_notification_type_check
  check (notification_type in (
    'friend_request', 'friend_accepted', 'post_comment', 'post_like',
    'comment_like', 'follow', 'friend_post', 'challenge_invite',
    'challenge_result', 'level_up', 'badge_earned', 'achievement_earned',
    'reward_redeemed'
  ));
comment on column public.community_notifications.comment_id is
 'Associated comment, when the alert concerns a comment.';
create index if not exists community_notifications_comment_idx
 on public.community_notifications(comment_id) where comment_id is not null;

create table if not exists public.community_notification_settings (
 user_id uuid primary key references public.profiles(id) on delete cascade,
 likes_enabled boolean not null default true,
 comments_enabled boolean not null default true,
 friend_posts_enabled boolean not null default true,
 friend_requests_enabled boolean not null default true,
 updated_at timestamptz not null default now()
);
comment on table public.community_notification_settings is
 'Per-account alert preferences; missing rows mean every category is enabled. Friend requests also covers acceptances and follows.';
alter table public.community_notification_settings enable row level security;
revoke all on public.community_notification_settings from public, anon, authenticated;
grant select on public.community_notification_settings to authenticated;
grant all on public.community_notification_settings to service_role;
drop policy if exists notification_settings_registered on public.community_notification_settings;
create policy notification_settings_registered on public.community_notification_settings
 as restrictive for all to authenticated
 using (public.is_registered_user()) with check (public.is_registered_user());
drop policy if exists notification_settings_owner on public.community_notification_settings;
create policy notification_settings_owner on public.community_notification_settings
 for select to authenticated using (user_id = auth.uid());

create or replace function public.community_set_notification_settings(
 p_likes boolean, p_comments boolean, p_friend_posts boolean, p_friend_requests boolean
) returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 if p_likes is null or p_comments is null or p_friend_posts is null
    or p_friend_requests is null then raise exception 'All settings are required'; end if;
 insert into public.community_notification_settings(
  user_id, likes_enabled, comments_enabled, friend_posts_enabled, friend_requests_enabled)
 values(auth.uid(), p_likes, p_comments, p_friend_posts, p_friend_requests)
 on conflict(user_id) do update set
  likes_enabled = excluded.likes_enabled, comments_enabled = excluded.comments_enabled,
  friend_posts_enabled = excluded.friend_posts_enabled,
  friend_requests_enabled = excluded.friend_requests_enabled, updated_at = now();
end $$;
comment on function public.community_set_notification_settings(boolean,boolean,boolean,boolean) is
 'Updates only the signed-in registered account notification preferences.';
revoke all on function public.community_set_notification_settings(boolean,boolean,boolean,boolean) from public, anon;
grant execute on function public.community_set_notification_settings(boolean,boolean,boolean,boolean) to authenticated;

create table if not exists public.community_comment_likes (
 id uuid primary key default gen_random_uuid(),
 comment_id uuid not null references public.community_comments(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 unique(comment_id, user_id)
);
comment on table public.community_comment_likes is 'One like per account and visible comment.';
create index if not exists community_comment_likes_user_idx on public.community_comment_likes(user_id);
alter table public.community_comment_likes enable row level security;
revoke all on public.community_comment_likes from public, anon, authenticated;
grant select on public.community_comment_likes to authenticated;
grant all on public.community_comment_likes to service_role;
drop policy if exists comment_likes_registered on public.community_comment_likes;
create policy comment_likes_registered on public.community_comment_likes
 as restrictive for all to authenticated
 using (public.is_registered_user()) with check (public.is_registered_user());
drop policy if exists comment_likes_visible on public.community_comment_likes;
create policy comment_likes_visible on public.community_comment_likes for select to authenticated
 using (not public.community_is_blocked(user_id)
   and exists (select 1 from public.community_comments c where c.id = comment_id));

-- A durable claim prevents a second alert after an unlike, even if the first
-- notification was deleted. Post/comment deletion removes the claim.
create table if not exists public.community_like_notification_claims (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid not null references public.profiles(id) on delete cascade,
 recipient_id uuid not null references public.profiles(id) on delete cascade,
 post_id uuid references public.community_posts(id) on delete cascade,
 comment_id uuid references public.community_comments(id) on delete cascade,
 check ((post_id is null) <> (comment_id is null))
);
comment on table public.community_like_notification_claims is
 'Server-only durable deduplication claims for post and comment like alerts.';
create unique index if not exists community_post_like_claim_unique
 on public.community_like_notification_claims(actor_id, recipient_id, post_id)
 where post_id is not null;
create unique index if not exists community_comment_like_claim_unique
 on public.community_like_notification_claims(actor_id, recipient_id, comment_id)
 where comment_id is not null;
alter table public.community_like_notification_claims enable row level security;
revoke all on public.community_like_notification_claims from public, anon, authenticated;
grant all on public.community_like_notification_claims to service_role;

-- Preserve deduplication for legacy alerts without changing or deleting them.
insert into public.community_like_notification_claims(actor_id, recipient_id, post_id)
select distinct actor_id, recipient_id, post_id from public.community_notifications
where notification_type = 'post_like' and actor_id is not null and post_id is not null
on conflict do nothing;

create or replace function public.community_notification_allowed(
 p_recipient uuid, p_actor uuid, p_category text
) returns boolean language sql stable security definer set search_path = '' as $$
 select p_category in ('likes', 'comments', 'friend_posts', 'friend_requests')
 and p_recipient is not null and p_actor is not null and p_recipient <> p_actor
 and not exists (
  select 1 from public.community_blocks b
  where (b.blocker_id = p_recipient and b.blocked_id = p_actor)
     or (b.blocker_id = p_actor and b.blocked_id = p_recipient))
 and not exists (
  select 1 from public.friendships f where f.status = 'blocked'
   and ((f.requester_id = p_recipient and f.addressee_id = p_actor)
     or (f.requester_id = p_actor and f.addressee_id = p_recipient)))
 and coalesce((select case p_category
   when 'likes' then s.likes_enabled
   when 'comments' then s.comments_enabled
   when 'friend_posts' then s.friend_posts_enabled
   when 'friend_requests' then s.friend_requests_enabled
   else false end
  from public.community_notification_settings s where s.user_id = p_recipient), true)
$$;
comment on function public.community_notification_allowed(uuid,uuid,text) is
 'Internal recipient/actor block, self-action and preference check.';
revoke all on function public.community_notification_allowed(uuid,uuid,text) from public, anon, authenticated;

create or replace function public.community_notify_friendship()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if tg_op = 'INSERT' and new.status = 'pending'
    and public.community_notification_allowed(new.addressee_id, new.requester_id, 'friend_requests') then
  insert into public.community_notifications(recipient_id, actor_id, notification_type, friendship_id)
  values(new.addressee_id, new.requester_id, 'friend_request', new.id);
 elsif tg_op = 'UPDATE' and old.status = 'pending' and new.status = 'accepted'
    and public.community_notification_allowed(new.requester_id, new.addressee_id, 'friend_requests') then
  insert into public.community_notifications(recipient_id, actor_id, notification_type, friendship_id)
  values(new.requester_id, new.addressee_id, 'friend_accepted', new.id);
 end if;
 return new;
end $$;
comment on function public.community_notify_friendship() is 'Notifies unblocked users of requests and acceptances respecting preferences.';
revoke all on function public.community_notify_friendship() from public, anon, authenticated;

create or replace function public.community_notify_interaction()
returns trigger language plpgsql security definer set search_path = '' as $$
declare author uuid; actor uuid; claim uuid;
begin
 select p.author_id into author from public.community_posts p where p.id = new.post_id;
 if tg_table_name = 'community_comments' then
  actor := new.author_id;
  if public.community_notification_allowed(author, actor, 'comments') then
   insert into public.community_notifications(recipient_id, actor_id, notification_type, post_id, comment_id)
   values(author, actor, 'post_comment', new.post_id, new.id);
  end if;
 else
  actor := new.user_id;
  if public.community_notification_allowed(author, actor, 'likes') then
   insert into public.community_like_notification_claims(actor_id, recipient_id, post_id)
   values(actor, author, new.post_id) on conflict do nothing returning id into claim;
   if claim is not null then
    insert into public.community_notifications(recipient_id, actor_id, notification_type, post_id)
    values(author, actor, 'post_like', new.post_id);
   end if;
  end if;
 end if;
 return new;
end $$;
comment on function public.community_notify_interaction() is 'Notifies post authors of eligible comments and first likes.';
revoke all on function public.community_notify_interaction() from public, anon, authenticated;

create or replace function public.community_notify_comment_like()
returns trigger language plpgsql security definer set search_path = '' as $$
declare author uuid; post uuid; claim uuid;
begin
 select c.author_id, c.post_id into author, post from public.community_comments c where c.id = new.comment_id;
 if public.community_notification_allowed(author, new.user_id, 'likes') then
  insert into public.community_like_notification_claims(actor_id, recipient_id, comment_id)
  values(new.user_id, author, new.comment_id) on conflict do nothing returning id into claim;
  if claim is not null then
   insert into public.community_notifications(recipient_id, actor_id, notification_type, post_id, comment_id)
   values(author, new.user_id, 'comment_like', post, new.comment_id);
  end if;
 end if;
 return new;
end $$;
comment on function public.community_notify_comment_like() is 'Notifies a comment author once per liker and comment.';
revoke all on function public.community_notify_comment_like() from public, anon, authenticated;
drop trigger if exists community_comment_like_notification on public.community_comment_likes;
create trigger community_comment_like_notification after insert on public.community_comment_likes
 for each row execute function public.community_notify_comment_like();

create or replace function public.community_set_comment_like(p_comment_id uuid, p_liked boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare c_author uuid; p_author uuid; p_visibility text;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 if p_liked is null then raise exception 'Like state is required'; end if;
 select c.author_id, p.author_id, p.visibility into c_author, p_author, p_visibility
 from public.community_comments c join public.community_posts p on p.id = c.post_id
 where c.id = p_comment_id;
 if not found or public.community_is_blocked(c_author) or public.community_is_blocked(p_author)
    or (p_author <> auth.uid() and p_visibility = 'friends'
        and not public.community_are_friends(p_author)) then
  raise exception 'Comment is unavailable';
 end if;
 if p_liked then
  insert into public.community_comment_likes(comment_id, user_id)
  values(p_comment_id, auth.uid()) on conflict(comment_id, user_id) do nothing;
 else
  delete from public.community_comment_likes where comment_id = p_comment_id and user_id = auth.uid();
 end if;
end $$;
comment on function public.community_set_comment_like(uuid,boolean) is
 'Sets the caller like on a visible, unblocked comment without allowing direct table writes.';
revoke all on function public.community_set_comment_like(uuid,boolean) from public, anon;
grant execute on function public.community_set_comment_like(uuid,boolean) to authenticated;

create or replace function public.community_notify_follow()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if public.community_notification_allowed(new.followed_id, new.follower_id, 'friend_requests') then
  insert into public.community_notifications(recipient_id, actor_id, notification_type)
  values(new.followed_id, new.follower_id, 'follow');
 end if;
 return new;
end $$;
comment on function public.community_notify_follow() is 'Notifies an unblocked followed user, subject to social notification settings.';
revoke all on function public.community_notify_follow() from public, anon, authenticated;
drop trigger if exists community_follow_notification on public.community_follows;
create trigger community_follow_notification after insert on public.community_follows
 for each row execute function public.community_notify_follow();

create or replace function public.community_notify_friend_post()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.community_notifications(recipient_id, actor_id, notification_type, post_id)
 select case when f.requester_id = new.author_id then f.addressee_id else f.requester_id end,
        new.author_id, 'friend_post', new.id
 from public.friendships f
 where f.status = 'accepted' and new.author_id in (f.requester_id, f.addressee_id)
  and public.community_notification_allowed(
   case when f.requester_id = new.author_id then f.addressee_id else f.requester_id end,
   new.author_id, 'friend_posts');
 return new;
end $$;
comment on function public.community_notify_friend_post() is 'Notifies only eligible accepted friends about a new post.';
revoke all on function public.community_notify_friend_post() from public, anon, authenticated;
drop trigger if exists community_friend_post_notification on public.community_posts;
create trigger community_friend_post_notification after insert on public.community_posts
 for each row execute function public.community_notify_friend_post();

create or replace function public.community_unread_count()
returns bigint language sql stable security definer set search_path = '' as $$
 select count(*) from public.community_notifications n
 left join public.community_posts p on p.id = n.post_id
 where n.recipient_id = auth.uid() and n.read_at is null and public.is_registered_user()
  and (n.actor_id is null or not public.community_is_blocked(n.actor_id))
  and (n.post_id is null or (p.id is not null and
    (p.author_id = auth.uid() or (not public.community_is_blocked(p.author_id)
      and (p.visibility = 'public' or public.community_are_friends(p.author_id))))))
$$;
comment on function public.community_unread_count() is 'Counts caller unread alerts excluding blocked actors and inaccessible posts.';
revoke all on function public.community_unread_count() from public, anon;
grant execute on function public.community_unread_count() to authenticated;

-- Keep the existing RPC unchanged for older app versions.
create or replace function public.community_notifications_page_v2(p_limit integer default 30)
returns table (
 id uuid, notification_type text, post_id uuid, friendship_id uuid, comment_id uuid,
 read_at timestamptz, created_at timestamptz, actor_id uuid,
 username text, full_name text, avatar_url text, comment_body text
) language sql stable security definer set search_path = '' as $$
 select n.id, n.notification_type, n.post_id, n.friendship_id, n.comment_id,
        n.read_at, n.created_at, n.actor_id, cp.username, cp.full_name, cp.avatar_url,
        case when n.notification_type = 'post_comment' then c.body else null end
 from public.community_notifications n
 left join public.community_profiles cp on cp.id = n.actor_id
 left join public.community_comments c on c.id = n.comment_id
 left join public.community_posts p on p.id = n.post_id
 where public.is_registered_user() and n.recipient_id = auth.uid()
  and (n.actor_id is null or not public.community_is_blocked(n.actor_id))
  and (n.post_id is null or (p.id is not null and
    (p.author_id = auth.uid() or (not public.community_is_blocked(p.author_id)
      and (p.visibility = 'public' or public.community_are_friends(p.author_id))))))
 order by n.created_at desc, n.id desc
 limit greatest(1, least(coalesce(p_limit, 30), 100))
$$;
comment on function public.community_notifications_page_v2(integer) is
 'Returns the caller visible alerts, safe actor identity and visible comment text.';
revoke all on function public.community_notifications_page_v2(integer) from public, anon;
grant execute on function public.community_notifications_page_v2(integer) to authenticated;

do $$ begin
 if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
    and not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'community_comment_likes') then
  alter publication supabase_realtime add table public.community_comment_likes;
 end if;
end $$;

commit;
