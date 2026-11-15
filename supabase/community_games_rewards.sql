-- Community foundation only. Games, rewards, activity integration and image
-- storage are not yet implemented; do not treat this as the complete migration.
-- Apply after schema.sql, seed.sql and auth_migration.sql.
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
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
comment on table public.community_posts is 'Text posts visible to all registered users or accepted friends.';
create index if not exists community_posts_feed_idx on public.community_posts(created_at desc, id desc);
create index if not exists community_posts_author_idx on public.community_posts(author_id, created_at desc);

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

do $$
declare t text;
begin
 foreach t in array array['community_blocks','community_follows','community_posts','community_comments','community_likes','community_reports'] loop
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
grant insert (body, visibility) on public.community_posts to authenticated;
grant insert (post_id, body) on public.community_comments to authenticated;
grant insert (post_id) on public.community_likes to authenticated;
grant insert (post_id, reason) on public.community_reports to authenticated;

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
grant update (body, visibility) on public.community_posts to authenticated;
drop policy if exists posts_update on public.community_posts;
create policy posts_update on public.community_posts for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());
drop trigger if exists set_updated_at on public.community_posts;
create trigger set_updated_at before update on public.community_posts for each row execute function public.touch_updated_at();

drop policy if exists comments_read on public.community_comments;
create policy comments_read on public.community_comments for select to authenticated
 using (not public.community_is_blocked(author_id) and exists (select 1 from public.community_posts p where p.id = post_id));
drop policy if exists comments_insert on public.community_comments;
create policy comments_insert on public.community_comments for insert to authenticated
 with check (author_id = auth.uid() and exists (select 1 from public.community_posts p where p.id = post_id));
drop policy if exists comments_delete on public.community_comments;
create policy comments_delete on public.community_comments for delete to authenticated using (author_id = auth.uid());
grant update (body) on public.community_comments to authenticated;
drop policy if exists comments_update on public.community_comments;
create policy comments_update on public.community_comments for update to authenticated
 using (author_id = auth.uid() and exists (select 1 from public.community_posts p where p.id = post_id))
 with check (author_id = auth.uid() and exists (select 1 from public.community_posts p where p.id = post_id));
drop trigger if exists set_updated_at on public.community_comments;
create trigger set_updated_at before update on public.community_comments for each row execute function public.touch_updated_at();

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
 body text, visibility text, created_at timestamptz, friend_group integer,
 like_count bigint, comment_count bigint, liked_by_me boolean
)
language sql stable security invoker set search_path = '' as $$
 with feed as (
  select p.id, p.author_id, cp.username, cp.full_name, cp.avatar_url,
         p.body, p.visibility, p.created_at,
         case when public.community_are_friends(p.author_id) then 0 else 1 end as friend_group
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

commit;
