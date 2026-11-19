-- Apply after groups_moderation_fix.sql. No user data is seeded.
-- Only the current object is selectable. A client using the Storage API must
-- delete the old current object before changing avatar_path, or use a trusted
-- cleanup service for orphaned objects. These operations are not atomic.
begin;

alter table public.groups add column if not exists avatar_path text;
comment on column public.groups.avatar_path is
 'Current private group-avatars object path, managed by group_set_avatar.';

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('group-avatars', 'group-avatars', false, 2097152,
 array['image/jpeg', 'image/png', 'image/webp']::text[])
on conflict (id) do update set
 public = false,
 file_size_limit = excluded.file_size_limit,
 allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.group_set_avatar(p_group uuid, p_path text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
 owner_id uuid;
begin
 if not public.is_registered_user() then
  raise exception 'Sign in required';
 end if;

 select g.owner_id into owner_id
 from public.groups g where g.id = p_group for update;
 if not found or owner_id <> auth.uid() then
  raise exception 'Only the owner can change the group photo';
 end if;

 if p_path is not null then
  if p_path !~* ('^' || p_group::text || '/[^/]+\.(jpg|jpeg|png|webp)$')
     or not exists (
      select 1 from storage.objects o
      where o.bucket_id = 'group-avatars' and o.name = p_path
     ) then
   raise exception 'Invalid or missing group photo';
  end if;
 end if;

 update public.groups set avatar_path = p_path, updated_at = now()
 where id = p_group;
end
$$;
comment on function public.group_set_avatar(uuid, text) is
 'Owner-only assignment or removal of an existing group avatar object.';
revoke all on function public.group_set_avatar(uuid, text) from public, anon, authenticated;
grant execute on function public.group_set_avatar(uuid, text) to authenticated;

drop policy if exists group_avatars_insert on storage.objects;
create policy group_avatars_insert on storage.objects for insert to authenticated
with check (
 bucket_id = 'group-avatars'
 and exists (
  select 1 from public.groups g
  where g.id::text = (storage.foldername(objects.name))[1]
   and g.owner_id = auth.uid()
   and objects.name ~* ('^' || g.id::text || '/[^/]+\.(jpg|jpeg|png|webp)$')
 )
);

drop policy if exists group_avatars_select on storage.objects;
create policy group_avatars_select on storage.objects for select to authenticated
using (
 bucket_id = 'group-avatars'
 and exists (
  select 1 from public.groups g
  where g.id::text = (storage.foldername(objects.name))[1]
   and g.avatar_path = objects.name
   and public.group_can_view(g.id)
 )
);

drop policy if exists group_avatars_delete on storage.objects;
create policy group_avatars_delete on storage.objects for delete to authenticated
using (
 bucket_id = 'group-avatars'
 and exists (
  select 1 from public.groups g
  where g.id::text = (storage.foldername(objects.name))[1]
   and g.owner_id = auth.uid()
 )
);

commit;
