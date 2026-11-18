-- Apply after comment_likes_v2.sql. This migration does not seed users.
begin;

create table if not exists public.groups (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.profiles(id) on delete cascade,
 name text not null check (length(btrim(name)) between 3 and 80),
 description text not null default '' check (length(description) <= 2000),
 category text not null check (length(btrim(category)) between 1 and 60),
 visibility text not null check (visibility in ('public','private')),
 join_mode text not null check (join_mode in ('open','approval','invite_only')),
 member_limit integer not null check (member_limit between 1 and 10000),
 rules text not null default '' check (length(rules) <= 5000),
 avatar_url text,
 who_can_post text not null default 'everyone' check (who_can_post in ('everyone','moderators')),
 images_allowed boolean not null default false,
 chat_enabled boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
comment on table public.groups is 'User-created groups and owner-controlled settings; chat is reserved for a later phase.';
create index if not exists groups_owner_idx on public.groups(owner_id);
create index if not exists groups_discover_idx on public.groups(visibility, category, name);

create table if not exists public.group_members (
 id uuid primary key default gen_random_uuid(),
 group_id uuid not null references public.groups(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 role text not null default 'member' check (role in ('owner','moderator','member')),
 status text not null check (status in ('active','pending','banned','left')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(group_id,user_id),
 check (role = 'member' or status = 'active')
);
comment on table public.group_members is 'Group memberships; status and roles are managed only by group functions.';
create index if not exists group_members_user_idx on public.group_members(user_id,status);
create index if not exists group_members_group_idx on public.group_members(group_id,status,role);

create table if not exists public.group_invites (
 id uuid primary key default gen_random_uuid(),
 group_id uuid not null references public.groups(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 invited_by uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(), unique(group_id,user_id)
);
comment on table public.group_invites is 'Private invitations to join a group; an invitation never overrides a ban.';
create index if not exists group_invites_user_idx on public.group_invites(user_id);

create table if not exists public.group_posts (
 id uuid primary key default gen_random_uuid(),
 group_id uuid not null references public.groups(id) on delete cascade,
 author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check (length(btrim(body)) between 1 and 5000),
 image_path text,
 created_at timestamptz not null default now()
);
comment on table public.group_posts is 'Group member posts subject to group posting and block rules.';
create index if not exists group_posts_feed_idx on public.group_posts(group_id,created_at desc,id desc);
create index if not exists group_posts_author_idx on public.group_posts(author_id,created_at desc);

create table if not exists public.group_post_rate_events (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now()
);
comment on table public.group_post_rate_events is 'Server-only posting rate records retained when a post is deleted.';
create index if not exists group_post_rate_user_idx on public.group_post_rate_events(user_id,created_at desc);
alter table public.group_post_rate_events enable row level security;
revoke all on public.group_post_rate_events from public, anon, authenticated;
grant all on public.group_post_rate_events to service_role;

create table if not exists public.group_comments (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.group_posts(id) on delete cascade,
 author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check (length(btrim(body)) between 1 and 2000),
 created_at timestamptz not null default now()
);
comment on table public.group_comments is 'Comments on visible group posts.';
create index if not exists group_comments_post_idx on public.group_comments(post_id,created_at,id);

create table if not exists public.group_post_likes (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.group_posts(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(), unique(post_id,user_id)
);
comment on table public.group_post_likes is 'One like per member per visible group post.';
create index if not exists group_post_likes_user_idx on public.group_post_likes(user_id);

create table if not exists public.group_reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null references public.profiles(id) on delete cascade,
 group_id uuid not null references public.groups(id) on delete cascade,
 post_id uuid references public.group_posts(id) on delete cascade,
 reported_user_id uuid references public.profiles(id) on delete cascade,
 reason text not null check (length(btrim(reason)) between 3 and 1000),
 created_at timestamptz not null default now(),
 check (post_id is null or reported_user_id is null)
);
comment on table public.group_reports is 'Private reports for trusted moderation of groups, posts and members.';
create index if not exists group_reports_group_idx on public.group_reports(group_id,created_at);
create index if not exists group_reports_reporter_idx on public.group_reports(reporter_id);

create or replace function public.group_is_member(p_group uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select public.is_registered_user() and exists (
  select 1 from public.group_members m join public.groups g on g.id=m.group_id
  where m.group_id=p_group and m.user_id=auth.uid() and m.status='active'
    and (g.owner_id=auth.uid() or not public.community_is_blocked(g.owner_id)))
$$;
comment on function public.group_is_member(uuid) is 'True when the caller is an active, unblocked group member.';
revoke all on function public.group_is_member(uuid) from public, anon;
grant execute on function public.group_is_member(uuid) to authenticated;

create or replace function public.group_can_view(p_group uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select public.is_registered_user() and exists (
  select 1 from public.groups g where g.id=p_group
  and (g.owner_id=auth.uid() or not public.community_is_blocked(g.owner_id))
  and not exists(select 1 from public.group_members m where m.group_id=g.id
    and m.user_id=auth.uid() and m.status='banned')
  and (g.visibility='public' or public.group_is_member(g.id)))
$$;
comment on function public.group_can_view(uuid) is 'Tests group visibility without exposing private group metadata to nonmembers.';
revoke all on function public.group_can_view(uuid) from public, anon;
grant execute on function public.group_can_view(uuid) to authenticated;

create or replace function public.group_is_moderator(p_group uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select public.group_is_member(p_group) and exists(select 1 from public.group_members m
  where m.group_id=p_group and m.user_id=auth.uid() and m.status='active'
   and m.role in ('owner','moderator'))
$$;
comment on function public.group_is_moderator(uuid) is 'Checks active owner or moderator status.';
revoke all on function public.group_is_moderator(uuid) from public, anon;
grant execute on function public.group_is_moderator(uuid) to authenticated;

do $$ declare t text; begin
 foreach t in array array['groups','group_members','group_invites','group_posts',
  'group_comments','group_post_likes','group_reports'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from public, anon, authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
  execute format('grant all on public.%I to service_role',t);
 end loop;
end $$;
drop policy if exists groups_read on public.groups;
create policy groups_read on public.groups for select to authenticated using (public.group_can_view(id));
drop policy if exists group_members_read on public.group_members;
create policy group_members_read on public.group_members for select to authenticated using (
 (user_id=auth.uid() and status='pending' and public.group_can_view(group_id))
 or (public.group_is_member(group_id) and (user_id=auth.uid() or not public.community_is_blocked(user_id))
 and (status='active' or public.group_is_moderator(group_id) or user_id=auth.uid())));
drop policy if exists group_invites_read on public.group_invites;
create policy group_invites_read on public.group_invites for select to authenticated using (
 public.is_registered_user() and user_id=auth.uid() and not public.community_is_blocked(invited_by));
drop policy if exists group_posts_read on public.group_posts;
create policy group_posts_read on public.group_posts for select to authenticated using (
 public.group_is_member(group_id) and (author_id=auth.uid() or not public.community_is_blocked(author_id)));
drop policy if exists group_comments_read on public.group_comments;
create policy group_comments_read on public.group_comments for select to authenticated using (
 (author_id=auth.uid() or not public.community_is_blocked(author_id))
 and exists(select 1 from public.group_posts p where p.id=post_id));
drop policy if exists group_likes_read on public.group_post_likes;
create policy group_likes_read on public.group_post_likes for select to authenticated using (
 (user_id=auth.uid() or not public.community_is_blocked(user_id))
 and exists(select 1 from public.group_posts p where p.id=post_id));
drop policy if exists group_reports_read on public.group_reports;
create policy group_reports_read on public.group_reports for select to authenticated using (
 public.is_registered_user() and reporter_id=auth.uid());

alter table public.community_notifications add column if not exists group_id uuid
 references public.groups(id) on delete cascade;
create index if not exists community_notifications_group_idx on public.community_notifications(group_id);
alter table public.community_notifications drop constraint if exists community_notifications_notification_type_check;
alter table public.community_notifications add constraint community_notifications_notification_type_check
 check (notification_type in ('friend_request','friend_accepted','post_comment','post_like',
 'comment_like','follow','friend_post','challenge_invite','challenge_result','level_up',
 'badge_earned','achievement_earned','reward_redeemed',
 'group_join_request','group_request_approved','group_removed','group_banned','group_invited'));
comment on column public.community_notifications.group_id is 'Group referenced by a group-related notification.';

create or replace function public.group_notify(p_recipient uuid,p_actor uuid,p_type text,p_group uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if p_recipient<>p_actor and not exists(select 1 from public.community_blocks b
   where (b.blocker_id=p_recipient and b.blocked_id=p_actor)
      or (b.blocker_id=p_actor and b.blocked_id=p_recipient))
 and not exists(select 1 from public.friendships f where f.status='blocked'
   and ((f.requester_id=p_recipient and f.addressee_id=p_actor)
     or (f.requester_id=p_actor and f.addressee_id=p_recipient))) then
  insert into public.community_notifications(recipient_id,actor_id,notification_type,group_id)
  values(p_recipient,p_actor,p_type,p_group);
 end if;
end $$;
comment on function public.group_notify(uuid,uuid,text,uuid) is 'Internal block-aware group notification helper.';
revoke all on function public.group_notify(uuid,uuid,text,uuid) from public, anon, authenticated;

create or replace function public.group_users_blocked(p_first uuid,p_second uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.community_blocks b
  where (b.blocker_id=p_first and b.blocked_id=p_second)
     or (b.blocker_id=p_second and b.blocked_id=p_first))
 or exists(select 1 from public.friendships f where f.status='blocked'
  and ((f.requester_id=p_first and f.addressee_id=p_second)
    or (f.requester_id=p_second and f.addressee_id=p_first)))
$$;
comment on function public.group_users_blocked(uuid,uuid) is 'Internal check for a block between two users.';
revoke all on function public.group_users_blocked(uuid,uuid) from public, anon, authenticated;

create or replace function public.group_create(
 p_name text,p_description text,p_category text,p_visibility text,p_join_mode text,
 p_member_limit integer,p_rules text,p_avatar_url text,p_who_can_post text,
 p_images_allowed boolean,p_chat_enabled boolean
) returns uuid language plpgsql security definer set search_path = '' as $$
declare result uuid;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
 if (select count(*) from public.groups where owner_id=auth.uid())>=3 then
  raise exception 'You can own at most three groups';
 end if;
 insert into public.groups(owner_id,name,description,category,visibility,join_mode,member_limit,
  rules,avatar_url,who_can_post,images_allowed,chat_enabled)
 values(auth.uid(),btrim(p_name),p_description,btrim(p_category),p_visibility,p_join_mode,
  p_member_limit,p_rules,p_avatar_url,p_who_can_post,p_images_allowed,p_chat_enabled)
 returning id into result;
 insert into public.group_members(group_id,user_id,role,status)
 values(result,auth.uid(),'owner','active');
 return result;
end $$;
comment on function public.group_create(text,text,text,text,text,integer,text,text,text,boolean,boolean) is
 'Creates a group and owner membership atomically, limiting each owner to three groups.';

create or replace function public.group_update_settings(
 p_group uuid,p_name text,p_description text,p_category text,p_visibility text,p_join_mode text,
 p_member_limit integer,p_rules text,p_avatar_url text,p_who_can_post text,
 p_images_allowed boolean,p_chat_enabled boolean
) returns void language plpgsql security definer set search_path = '' as $$
declare g public.groups%rowtype;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 select * into g from public.groups where id=p_group for update;
 if not found or g.owner_id<>auth.uid() then raise exception 'Only the owner can change group settings'; end if;
 if p_member_limit < (select count(*) from public.group_members where group_id=p_group and status='active') then
  raise exception 'Member limit cannot be below the current member count';
 end if;
 update public.groups set name=btrim(p_name),description=p_description,category=btrim(p_category),
  visibility=p_visibility,join_mode=p_join_mode,member_limit=p_member_limit,rules=p_rules,
  avatar_url=p_avatar_url,who_can_post=p_who_can_post,images_allowed=p_images_allowed,
  chat_enabled=p_chat_enabled,updated_at=now() where id=p_group;
end $$;
comment on function public.group_update_settings(uuid,text,text,text,text,text,integer,text,text,text,boolean,boolean) is
 'Only the owner can change settings; membership capacity is checked under the group lock.';

create or replace function public.group_join(p_group uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare g public.groups%rowtype; m public.group_members%rowtype; invited boolean; result text; moderator uuid;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 select * into g from public.groups where id=p_group for update;
 if not found or (g.owner_id<>auth.uid() and public.community_is_blocked(g.owner_id)) then
  raise exception 'Group is unavailable';
 end if;
 select * into m from public.group_members where group_id=p_group and user_id=auth.uid();
 if m.status='banned' then raise exception 'You are banned from this group'; end if;
 if m.status='active' then return 'active'; end if;
 if m.status='pending' then return 'pending'; end if;
 invited := exists(select 1 from public.group_invites i where i.group_id=p_group and i.user_id=auth.uid()
  and not public.community_is_blocked(i.invited_by));
 if (g.visibility='private' or g.join_mode='invite_only') and not invited then
  raise exception 'Group is unavailable';
 end if;
 result := case when invited or g.join_mode='open' then 'active' else 'pending' end;
 if result='active' and (select count(*) from public.group_members where group_id=p_group and status='active')>=g.member_limit then
  raise exception 'Group is full';
 end if;
 insert into public.group_members(group_id,user_id,role,status) values(p_group,auth.uid(),'member',result)
 on conflict(group_id,user_id) do update set role='member',status=excluded.status,updated_at=now();
 if invited then delete from public.group_invites where group_id=p_group and user_id=auth.uid(); end if;
 if result='pending' then
  for moderator in select user_id from public.group_members where group_id=p_group
    and status='active' and role in ('owner','moderator') loop
   perform public.group_notify(moderator,auth.uid(),'group_join_request',p_group);
  end loop;
 end if;
 return result;
end $$;
comment on function public.group_join(uuid) is 'Joins or requests membership under a locked capacity check; private groups require invitations.';

create or replace function public.group_invite(p_group uuid,p_user uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
 perform 1 from public.groups where id=p_group for update;
 if not public.group_is_moderator(p_group) or p_user=auth.uid() or public.community_is_blocked(p_user)
   or exists(select 1 from public.groups g where g.id=p_group and public.group_users_blocked(g.owner_id,p_user))
   or exists(select 1 from public.group_members where group_id=p_group and user_id=p_user and status in ('active','banned')) then
  raise exception 'Cannot invite this user';
 end if;
 insert into public.group_invites(group_id,user_id,invited_by) values(p_group,p_user,auth.uid())
 on conflict(group_id,user_id) do update set invited_by=excluded.invited_by,created_at=now();
 perform public.group_notify(p_user,auth.uid(),'group_invited',p_group);
end $$;
comment on function public.group_invite(uuid,uuid) is 'Invites an unblocked, non-banned user to a group.';

create or replace function public.group_leave(p_group uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 perform 1 from public.groups where id=p_group for update;
 if exists(select 1 from public.groups where id=p_group and owner_id=auth.uid()) then
  raise exception 'The owner cannot leave the group';
 end if;
 update public.group_members set status='left',role='member',updated_at=now()
 where group_id=p_group and user_id=auth.uid() and status in ('active','pending');
 if not found then raise exception 'Membership is unavailable'; end if;
 delete from public.group_invites where group_id=p_group and user_id=auth.uid();
end $$;
comment on function public.group_leave(uuid) is 'Leaves an active or pending membership; owners cannot leave.';

create or replace function public.group_manage_member(p_group uuid,p_user uuid,p_action text)
returns void language plpgsql security definer set search_path = '' as $$
declare g public.groups%rowtype; target public.group_members%rowtype; actor_role text;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 select * into g from public.groups where id=p_group for update;
 if not found or not public.group_is_moderator(p_group) or
   (p_action not in ('remove','ban') and
    (public.community_is_blocked(p_user) or public.group_users_blocked(g.owner_id,p_user))) then
  raise exception 'Not permitted';
 end if;
 select role into actor_role from public.group_members where group_id=p_group and user_id=auth.uid();
 select * into target from public.group_members where group_id=p_group and user_id=p_user;
 if not found or p_user=auth.uid() or target.role='owner'
    or (actor_role='moderator' and target.role='moderator') then raise exception 'Not permitted'; end if;
 if p_action='approve' and target.status='pending' then
  if (select count(*) from public.group_members where group_id=p_group and status='active')>=g.member_limit then
   raise exception 'Group is full';
  end if;
  update public.group_members set status='active',updated_at=now() where id=target.id;
  perform public.group_notify(p_user,auth.uid(),'group_request_approved',p_group);
 elsif p_action in ('remove','ban') and target.status in ('active','pending') then
  update public.group_members set status=case when p_action='ban' then 'banned' else 'left' end,
   role='member',updated_at=now() where id=target.id;
  delete from public.group_invites where group_id=p_group and user_id=p_user;
  perform public.group_notify(p_user,auth.uid(),case when p_action='ban' then 'group_banned' else 'group_removed' end,p_group);
 elsif p_action in ('promote','demote') and actor_role='owner' and target.status='active' then
  update public.group_members set role=case when p_action='promote' then 'moderator' else 'member' end,
   updated_at=now() where id=target.id;
 else raise exception 'Invalid member action';
 end if;
end $$;
comment on function public.group_manage_member(uuid,uuid,text) is 'Approves, removes or bans members; only the owner may change moderator roles.';

create or replace function public.group_create_post(p_group uuid,p_body text,p_image_path text default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare g public.groups%rowtype; result uuid;
begin
 if not public.group_is_member(p_group) then raise exception 'Membership required'; end if;
 select * into g from public.groups where id=p_group for update;
 if not public.group_is_member(p_group) then raise exception 'Membership required'; end if;
 if g.who_can_post='moderators' and not public.group_is_moderator(p_group) then
  raise exception 'Only moderators can post';
 end if;
 if p_image_path is not null and (not g.images_allowed or
   p_image_path not like p_group::text || '/' || auth.uid()::text || '/%' or
   not exists(select 1 from storage.objects o where o.bucket_id='group-post-images' and o.name=p_image_path)) then
  raise exception 'Image is not allowed';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,1));
 if (select count(*) from public.group_post_rate_events where user_id=auth.uid()
   and created_at > now()-interval '1 hour')>=20 then
  raise exception 'Posting limit reached; try again later';
 end if;
 insert into public.group_posts(group_id,author_id,body,image_path)
 values(p_group,auth.uid(),btrim(p_body),p_image_path) returning id into result;
 insert into public.group_post_rate_events(user_id) values(auth.uid());
 return result;
end $$;
comment on function public.group_create_post(uuid,text,text) is 'Creates an authorized group post, limited to 20 posts per account per hour.';

create or replace function public.group_delete_post(p_post uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare p public.group_posts%rowtype;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 select * into p from public.group_posts where id=p_post;
 if not found or not public.group_is_member(p.group_id) or
   (p.author_id<>auth.uid() and (not public.group_is_moderator(p.group_id)
    or public.community_is_blocked(p.author_id))) then raise exception 'Not permitted'; end if;
 delete from public.group_posts where id=p_post;
end $$;
comment on function public.group_delete_post(uuid) is 'Allows the author or an unblocked moderator to remove a post.';

create or replace function public.group_create_comment(p_post uuid,p_body text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare p public.group_posts%rowtype; result uuid;
begin
 select * into p from public.group_posts where id=p_post;
 if not found or not public.group_is_member(p.group_id) or public.community_is_blocked(p.author_id) then
  raise exception 'Post is unavailable';
 end if;
 insert into public.group_comments(post_id,author_id,body)
 values(p_post,auth.uid(),btrim(p_body)) returning id into result;
 return result;
end $$;
comment on function public.group_create_comment(uuid,text) is 'Adds a comment to an accessible group post.';

create or replace function public.group_set_post_like(p_post uuid,p_liked boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare p public.group_posts%rowtype;
begin
 if p_liked is null then raise exception 'Like state is required'; end if;
 select * into p from public.group_posts where id=p_post;
 if not found or not public.group_is_member(p.group_id) or public.community_is_blocked(p.author_id) then
  raise exception 'Post is unavailable';
 end if;
 if p_liked then
  insert into public.group_post_likes(post_id,user_id) values(p_post,auth.uid())
   on conflict(post_id,user_id) do nothing;
 else
  delete from public.group_post_likes where post_id=p_post and user_id=auth.uid();
 end if;
end $$;
comment on function public.group_set_post_like(uuid,boolean) is 'Sets the caller like on an accessible group post.';

create or replace function public.group_report(
 p_group uuid,p_reason text,p_post uuid default null,p_user uuid default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare result uuid;
begin
 if not public.group_can_view(p_group) or (p_post is not null and p_user is not null) then
  raise exception 'Group is unavailable';
 end if;
 if p_post is not null and not exists(select 1 from public.group_posts p
  where p.id=p_post and p.group_id=p_group and public.group_is_member(p_group)
   and p.author_id<>auth.uid() and not public.community_is_blocked(p.author_id)) then raise exception 'Post is unavailable'; end if;
 if p_user is not null and (p_user=auth.uid() or not public.group_is_member(p_group)
   or public.community_is_blocked(p_user) or not exists(select 1 from public.group_members m
    where m.group_id=p_group and m.user_id=p_user and m.status='active')) then
  raise exception 'Member is unavailable';
 end if;
 insert into public.group_reports(reporter_id,group_id,post_id,reported_user_id,reason)
 values(auth.uid(),p_group,p_post,p_user,btrim(p_reason)) returning id into result;
 return result;
end $$;
comment on function public.group_report(uuid,text,uuid,uuid) is 'Reports a visible group, post or active member for trusted review.';

create or replace function public.group_member_count(p_group uuid)
returns bigint language sql stable security definer set search_path = '' as $$
 select count(*) from public.group_members m
 where m.group_id=p_group and m.status='active' and public.group_can_view(p_group)
  and (m.user_id=auth.uid() or not public.community_is_blocked(m.user_id))
$$;
comment on function public.group_member_count(uuid) is 'Counts active, unblocked members of a visible group.';

-- Group notification IDs are private even when the group itself is private.
create or replace function public.group_notification_target(p_notification uuid)
returns uuid language sql stable security definer set search_path = '' as $$
 select n.group_id from public.community_notifications n
 where public.is_registered_user() and n.id=p_notification and n.recipient_id=auth.uid()
  and n.notification_type in ('group_join_request','group_request_approved','group_removed','group_banned','group_invited')
  and (n.actor_id is null or not public.community_is_blocked(n.actor_id))
$$;
comment on function public.group_notification_target(uuid) is 'Returns the group ID for a caller-owned group alert, without bypassing group RLS.';

do $$ declare signature text; begin
 foreach signature in array array[
  'public.group_create(text,text,text,text,text,integer,text,text,text,boolean,boolean)',
  'public.group_update_settings(uuid,text,text,text,text,text,integer,text,text,text,boolean,boolean)',
  'public.group_join(uuid)','public.group_invite(uuid,uuid)','public.group_leave(uuid)',
  'public.group_manage_member(uuid,uuid,text)','public.group_create_post(uuid,text,text)',
  'public.group_delete_post(uuid)','public.group_create_comment(uuid,text)',
  'public.group_set_post_like(uuid,boolean)','public.group_report(uuid,text,uuid,uuid)',
  'public.group_member_count(uuid)','public.group_notification_target(uuid)'] loop
  execute 'revoke all on function ' || signature || ' from public, anon';
  execute 'grant execute on function ' || signature || ' to authenticated';
 end loop;
end $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('group-post-images','group-post-images',false,8388608,
 array['image/jpeg','image/png','image/webp']::text[])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,
 allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists group_images_upload on storage.objects;
create policy group_images_upload on storage.objects for insert to authenticated with check (
 bucket_id='group-post-images' and (storage.foldername(name))[2]=auth.uid()::text
 and exists(select 1 from public.groups g where g.id::text=(storage.foldername(name))[1]
  and g.images_allowed and public.group_is_member(g.id)
  and (g.who_can_post='everyone' or public.group_is_moderator(g.id))));
drop policy if exists group_images_read on storage.objects;
create policy group_images_read on storage.objects for select to authenticated using (
 bucket_id='group-post-images' and exists(select 1 from public.group_posts p
  where p.image_path=name and public.group_is_member(p.group_id)
   and (p.author_id=auth.uid() or not public.community_is_blocked(p.author_id))));
drop policy if exists group_images_delete on storage.objects;
create policy group_images_delete on storage.objects for delete to authenticated using (
 bucket_id='group-post-images' and (storage.foldername(name))[2]=auth.uid()::text
 and exists(select 1 from public.groups g where g.id::text=(storage.foldername(name))[1]
  and public.group_is_member(g.id)));

commit;
