-- Apply after community_notifications_v2.sql.
begin;

-- Existing generated usernames remain valid until changed. Signup still uses
-- the UUID-derived placeholder; every user-selected username is constrained.
create or replace function public.validate_profile_username_v2()
returns trigger language plpgsql set search_path = '' as $$
begin
 if tg_op = 'UPDATE' and new.username is not distinct from old.username then
  return new;
 end if;
 if tg_op = 'INSERT' and new.username = 'user_' || replace(new.id::text, '-', '') then
  return new;
 end if;
 if new.username is null or new.username !~ '^[A-Za-z0-9_]{3,20}$' then
  raise exception 'Username must be 3 to 20 letters, numbers or underscores'
   using errcode = '23514';
 end if;
 return new;
end $$;
comment on function public.validate_profile_username_v2() is
 'Validates chosen usernames while retaining existing and signup-generated placeholders.';
drop trigger if exists profile_username_v2 on public.profiles;
create trigger profile_username_v2 before insert or update of username on public.profiles
 for each row execute function public.validate_profile_username_v2();

create or replace function public.community_comments_page_v2(
 p_post_id uuid, p_before_created_at timestamptz default null,
 p_before_id uuid default null, p_limit integer default 30
) returns table (
 id uuid, post_id uuid, author_id uuid, username text, full_name text,
 avatar_url text, body text, created_at timestamptz, like_count bigint,
 liked_by_me boolean, liked_by_author boolean, post_author_avatar_url text
) language sql stable security invoker set search_path = '' as $$
 select c.id, c.post_id, c.author_id, cp.username, cp.full_name, cp.avatar_url,
  c.body, c.created_at,
  (select count(*) from public.community_comment_likes l where l.comment_id = c.id),
  exists(select 1 from public.community_comment_likes l where l.comment_id = c.id and l.user_id = auth.uid()),
  exists(select 1 from public.community_comment_likes l where l.comment_id = c.id and l.user_id = p.author_id),
  owner.avatar_url
 from public.community_comments c
 join public.community_posts p on p.id = c.post_id
 join public.community_profiles cp on cp.id = c.author_id
 join public.community_profiles owner on owner.id = p.author_id
 where c.post_id = p_post_id
  and (p_before_created_at is null or (c.created_at, c.id) < (p_before_created_at, p_before_id))
 order by c.created_at desc, c.id desc
 limit greatest(1, least(coalesce(p_limit, 30), 50))
$$;
comment on function public.community_comments_page_v2(uuid,timestamptz,uuid,integer) is
 'Returns visible comments and block-filtered like counts and author-like status.';
revoke all on function public.community_comments_page_v2(uuid,timestamptz,uuid,integer) from public, anon;
grant execute on function public.community_comments_page_v2(uuid,timestamptz,uuid,integer) to authenticated;

create or replace function public.community_comment_likers(
 p_comment_id uuid, p_limit integer default 50, p_offset integer default 0
) returns table (user_id uuid, username text, full_name text, avatar_url text)
language sql stable security invoker set search_path = '' as $$
 select p.id, p.username, p.full_name, p.avatar_url
 from public.community_comment_likes l
 join public.community_comments c on c.id = l.comment_id
 join public.community_profiles p on p.id = l.user_id
 where l.comment_id = p_comment_id
 order by p.username, p.id
 limit greatest(1, least(coalesce(p_limit, 50), 100))
 offset greatest(0, coalesce(p_offset, 0))
$$;
comment on function public.community_comment_likers(uuid,integer,integer) is
 'Lists safe identities of visible comment likers, filtered by existing RLS and blocks.';
revoke all on function public.community_comment_likers(uuid,integer,integer) from public, anon;
grant execute on function public.community_comment_likers(uuid,integer,integer) to authenticated;

create or replace function public.community_discover_users(p_limit integer default 30)
returns table (user_id uuid, username text, full_name text, avatar_url text,
 relationship text, followed_by_me boolean)
language sql stable security definer set search_path = '' as $$
 select cp.id, cp.username, cp.full_name, cp.avatar_url, 'none'::text,
  exists(select 1 from public.community_follows f
   where f.follower_id = auth.uid() and f.followed_id = cp.id)
 from public.community_profiles cp
 where public.is_registered_user() and cp.id <> auth.uid()
  and not public.community_is_blocked(cp.id)
  and not exists(select 1 from public.friendships f
   where f.status in ('accepted','pending')
    and ((f.requester_id = auth.uid() and f.addressee_id = cp.id)
      or (f.addressee_id = auth.uid() and f.requester_id = cp.id)))
 order by cp.username, cp.id
 limit greatest(1, least(coalesce(p_limit, 30), 50))
$$;
comment on function public.community_discover_users(integer) is
 'Suggests unblocked non-friends without pending requests, filtering before limiting.';
revoke all on function public.community_discover_users(integer) from public, anon;
grant execute on function public.community_discover_users(integer) to authenticated;

commit;
