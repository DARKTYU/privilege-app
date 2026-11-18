-- Apply after groups_phase1.sql. Existing content is not retroactively hidden.
begin;

alter table public.group_posts add column if not exists hidden_at timestamptz;
alter table public.group_posts add column if not exists hidden_reason text;
alter table public.group_comments add column if not exists hidden_at timestamptz;
alter table public.group_comments add column if not exists hidden_reason text;
alter table public.group_members add column if not exists banned_at timestamptz;
alter table public.group_members add column if not exists banned_by uuid
 references public.profiles(id) on delete set null;
comment on column public.group_posts.hidden_at is 'Time a moderator removed the author; hidden content is not restored on rejoin.';
comment on column public.group_posts.hidden_reason is 'Moderation action that hid the post.';
comment on column public.group_comments.hidden_at is 'Time a moderator removed the author; hidden content is not restored on rejoin.';
comment on column public.group_comments.hidden_reason is 'Moderation action that hid the comment.';
comment on column public.group_members.banned_at is 'Time of the current ban; null for historical bans without recorded metadata.';
comment on column public.group_members.banned_by is 'Moderator who imposed the current ban, if known.';

drop policy if exists group_members_read on public.group_members;
create policy group_members_read on public.group_members for select to authenticated using (
 public.group_is_member(group_id)
 and (user_id=auth.uid() or not public.community_is_blocked(user_id))
 and (status='active' or (status='pending' and public.group_is_moderator(group_id)))
);
drop policy if exists group_posts_read on public.group_posts;
create policy group_posts_read on public.group_posts for select to authenticated using (
 hidden_at is null and public.group_is_member(group_id)
 and (author_id=auth.uid() or not public.community_is_blocked(author_id))
);
drop policy if exists group_comments_read on public.group_comments;
create policy group_comments_read on public.group_comments for select to authenticated using (
 hidden_at is null and (author_id=auth.uid() or not public.community_is_blocked(author_id))
 and exists(select 1 from public.group_posts p where p.id=group_comments.post_id and p.hidden_at is null)
);
drop policy if exists group_likes_read on public.group_post_likes;
create policy group_likes_read on public.group_post_likes for select to authenticated using (
 (user_id=auth.uid() or not public.community_is_blocked(user_id))
 and exists(select 1 from public.group_posts p where p.id=group_post_likes.post_id and p.hidden_at is null)
);

-- Check hidden references without relying on the caller's post RLS. This also
-- protects an image path shared by a hidden and a visible post.
create or replace function public.group_image_readable(p_path text)
returns boolean language sql stable security definer set search_path = '' as $$
 select public.is_registered_user()
  and not exists(select 1 from public.group_posts p where p.image_path=p_path and p.hidden_at is not null)
  and exists(select 1 from public.group_posts p where p.image_path=p_path and p.hidden_at is null
   and public.group_is_member(p.group_id)
   and (p.author_id=auth.uid() or not public.community_is_blocked(p.author_id)))
$$;
comment on function public.group_image_readable(text) is 'Checks group image access, including hidden posts that share a path.';
revoke all on function public.group_image_readable(text) from public, anon;
grant execute on function public.group_image_readable(text) to authenticated;

drop policy if exists group_images_read on storage.objects;
create policy group_images_read on storage.objects for select to authenticated using (
 bucket_id='group-post-images' and public.group_image_readable(objects.name)
);
drop policy if exists group_images_upload on storage.objects;
create policy group_images_upload on storage.objects for insert to authenticated with check (
 bucket_id='group-post-images' and (storage.foldername(objects.name))[2]=auth.uid()::text
 and exists(select 1 from public.groups g where g.id::text=(storage.foldername(objects.name))[1]
  and g.images_allowed and public.group_is_member(g.id)
  and (g.who_can_post='everyone' or public.group_is_moderator(g.id)))
);
drop policy if exists group_images_delete on storage.objects;
create policy group_images_delete on storage.objects for delete to authenticated using (
 bucket_id='group-post-images' and (storage.foldername(objects.name))[2]=auth.uid()::text
 and exists(select 1 from public.groups g where g.id::text=(storage.foldername(objects.name))[1]
  and public.group_is_member(g.id))
);

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
 if not found or p_user=auth.uid() or p_user=g.owner_id or target.role='owner'
    or (actor_role='moderator' and target.role='moderator') then raise exception 'Not permitted'; end if;
 if p_action='approve' and target.status='pending' then
  if (select count(*) from public.group_members where group_id=p_group and status='active')>=g.member_limit then
   raise exception 'Group is full';
  end if;
  update public.group_members set status='active',updated_at=now() where id=target.id;
  perform public.group_notify(p_user,auth.uid(),'group_request_approved',p_group);
 elsif p_action in ('remove','ban') and target.status in ('active','pending') then
  update public.group_posts set hidden_at=now(),hidden_reason=p_action
   where group_id=p_group and author_id=p_user and hidden_at is null;
  update public.group_comments c set hidden_at=now(),hidden_reason=p_action
   from public.group_posts p where c.post_id=p.id and p.group_id=p_group
    and c.author_id=p_user and c.hidden_at is null;
  delete from public.group_post_likes l using public.group_posts p
   where l.post_id=p.id and p.group_id=p_group and p.author_id<>p_user and l.user_id=p_user;
  update public.group_members set status=case when p_action='ban' then 'banned' else 'left' end,
   role='member',updated_at=now(),
   banned_at=case when p_action='ban' then now() else null end,
   banned_by=case when p_action='ban' then auth.uid() else null end
   where id=target.id;
  delete from public.group_invites where group_id=p_group and user_id=p_user;
  perform public.group_notify(p_user,auth.uid(),case when p_action='ban' then 'group_banned' else 'group_removed' end,p_group);
 elsif p_action in ('promote','demote') and actor_role='owner' and target.status='active' then
  update public.group_members set role=case when p_action='promote' then 'moderator' else 'member' end,
   updated_at=now() where id=target.id;
 else raise exception 'Invalid member action';
 end if;
end $$;
comment on function public.group_manage_member(uuid,uuid,text) is 'Moderates membership atomically; removal or ban hides the member content and removes their likes on others posts.';
revoke all on function public.group_manage_member(uuid,uuid,text) from public, anon;
grant execute on function public.group_manage_member(uuid,uuid,text) to authenticated;

create or replace function public.group_unban(p_group uuid,p_user uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare g public.groups%rowtype;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 select * into g from public.groups where id=p_group for update;
 if not found or not public.group_is_moderator(p_group) or p_user=g.owner_id
    or p_user=auth.uid() then raise exception 'Not permitted'; end if;
 update public.group_members set status='left',role='member',banned_at=null,banned_by=null,updated_at=now()
  where group_id=p_group and user_id=p_user and status='banned' and role='member';
 if not found then raise exception 'Banned member not found'; end if;
 delete from public.group_invites where group_id=p_group and user_id=p_user;
end $$;
comment on function public.group_unban(uuid,uuid) is 'Lifts a ban without restoring membership, invitations or hidden content.';
revoke all on function public.group_unban(uuid,uuid) from public, anon;
grant execute on function public.group_unban(uuid,uuid) to authenticated;

create or replace function public.group_banned_members(p_group uuid)
returns table(user_id uuid,username text,full_name text,avatar_url text,
 banned_at timestamptz,banned_by uuid,banned_by_username text,banned_by_full_name text)
language plpgsql stable security definer set search_path = '' as $$
begin
 if not public.group_is_moderator(p_group) then raise exception 'Not permitted'; end if;
 return query select m.user_id,
   case when public.community_is_blocked(m.user_id) then null else p.username end,
   case when public.community_is_blocked(m.user_id) then null else p.full_name end,
   case when public.community_is_blocked(m.user_id) then null else p.avatar_url end,
   m.banned_at,m.banned_by,
   case when public.community_is_blocked(m.banned_by) then null else actor.username end,
   case when public.community_is_blocked(m.banned_by) then null else actor.full_name end
  from public.group_members m join public.profiles p on p.id=m.user_id
  left join public.profiles actor on actor.id=m.banned_by
  where m.group_id=p_group and m.status='banned'
  order by m.banned_at desc nulls last,m.user_id;
end $$;
comment on function public.group_banned_members(uuid) is 'Moderator-only banned list; blocked identities are redacted and older bans may lack date and actor.';
revoke all on function public.group_banned_members(uuid) from public, anon;
grant execute on function public.group_banned_members(uuid) to authenticated;

create or replace function public.group_member_count(p_group uuid)
returns bigint language sql stable security definer set search_path = '' as $$
 select count(*) from public.group_members m
 where m.group_id=p_group and m.status='active' and public.group_can_view(p_group)
$$;
comment on function public.group_member_count(uuid) is 'Counts all active members of a visible group without exposing blocked identities.';
revoke all on function public.group_member_count(uuid) from public, anon;
grant execute on function public.group_member_count(uuid) to authenticated;

create or replace function public.group_join(p_group uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare g public.groups%rowtype; m public.group_members%rowtype; invited boolean; result text; moderator uuid;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 select * into g from public.groups where id=p_group for update;
 if not found then raise exception 'Group is unavailable'; end if;
 select * into m from public.group_members where group_id=p_group and user_id=auth.uid();
 if m.status='banned' then raise exception 'banned_from_group'; end if;
 if g.owner_id<>auth.uid() and public.community_is_blocked(g.owner_id) then
  raise exception 'Group is unavailable';
 end if;
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
comment on function public.group_join(uuid) is 'Joins under the group lock; banned users receive banned_from_group and cannot use invitations.';
revoke all on function public.group_join(uuid) from public, anon;
grant execute on function public.group_join(uuid) to authenticated;

-- Serialize interactions with membership removal using the same group lock.
create or replace function public.group_create_comment(p_post uuid,p_body text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare p public.group_posts%rowtype; result uuid;
begin
 perform 1 from public.groups g where g.id=(select group_id from public.group_posts where id=p_post) for update;
 select * into p from public.group_posts where id=p_post;
 if not found or p.hidden_at is not null or not public.group_is_member(p.group_id)
    or public.community_is_blocked(p.author_id) then raise exception 'Post is unavailable'; end if;
 insert into public.group_comments(post_id,author_id,body)
 values(p_post,auth.uid(),btrim(p_body)) returning id into result;
 return result;
end $$;
comment on function public.group_create_comment(uuid,text) is 'Comments on visible group posts under the membership lock.';

create or replace function public.group_set_post_like(p_post uuid,p_liked boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare p public.group_posts%rowtype;
begin
 if p_liked is null then raise exception 'Like state is required'; end if;
 perform 1 from public.groups g where g.id=(select group_id from public.group_posts where id=p_post) for update;
 select * into p from public.group_posts where id=p_post;
 if not found or p.hidden_at is not null or not public.group_is_member(p.group_id)
    or public.community_is_blocked(p.author_id) then raise exception 'Post is unavailable'; end if;
 if p_liked then
  insert into public.group_post_likes(post_id,user_id) values(p_post,auth.uid())
   on conflict(post_id,user_id) do nothing;
 else
  delete from public.group_post_likes where post_id=p_post and user_id=auth.uid();
 end if;
end $$;
comment on function public.group_set_post_like(uuid,boolean) is 'Changes likes on visible posts under the membership lock.';

create or replace function public.group_delete_post(p_post uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare p public.group_posts%rowtype;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 perform 1 from public.groups g where g.id=(select group_id from public.group_posts where id=p_post) for update;
 select * into p from public.group_posts where id=p_post;
 if not found or p.hidden_at is not null or not public.group_is_member(p.group_id) or
   (p.author_id<>auth.uid() and (not public.group_is_moderator(p.group_id)
    or public.community_is_blocked(p.author_id))) then raise exception 'Not permitted'; end if;
 delete from public.group_posts where id=p_post;
end $$;
comment on function public.group_delete_post(uuid) is 'Removes a visible post by its author or an unblocked moderator.';

create or replace function public.group_report(
 p_group uuid,p_reason text,p_post uuid default null,p_user uuid default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare result uuid;
begin
 perform 1 from public.groups where id=p_group for update;
 if not public.group_can_view(p_group) or (p_post is not null and p_user is not null) then
  raise exception 'Group is unavailable';
 end if;
 if p_post is not null and not exists(select 1 from public.group_posts p
  where p.id=p_post and p.group_id=p_group and p.hidden_at is null and public.group_is_member(p_group)
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
comment on function public.group_report(uuid,text,uuid,uuid) is 'Reports a visible group, visible post or active member for trusted review.';

revoke all on function public.group_create_comment(uuid,text), public.group_set_post_like(uuid,boolean),
 public.group_delete_post(uuid), public.group_report(uuid,text,uuid,uuid) from public, anon;
grant execute on function public.group_create_comment(uuid,text), public.group_set_post_like(uuid,boolean),
 public.group_delete_post(uuid), public.group_report(uuid,text,uuid,uuid) to authenticated;

commit;
