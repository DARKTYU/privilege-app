-- Account deletion support. Apply once in the Supabase SQL Editor of the REAL
-- project (PrivilegeFitness). It only adds one function and changes no data.
--
-- The `delete-account` Edge Function calls this with the service role to find
-- every stored photo that belongs to the account, removes those files, and then
-- deletes the auth user. All user tables already use ON DELETE CASCADE from
-- public.profiles, which cascades from auth.users, so their rows go with it.
begin;

create or replace function public.account_storage_paths(p_user uuid)
returns table(bucket text, path text)
language sql
stable
security definer
set search_path = ''
as $$
  -- Post photos live under <user id>/<post id>/<file>.
  select o.bucket_id::text, o.name::text
  from storage.objects o
  where o.bucket_id = 'community-posts'
    and (storage.foldername(o.name))[1] = p_user::text
  union all
  -- Group post photos live under <group id>/<user id>/<file>. Photos inside
  -- groups the user owns go too, because those groups are deleted with them.
  select o.bucket_id::text, o.name::text
  from storage.objects o
  where o.bucket_id = 'group-post-images'
    and ((storage.foldername(o.name))[2] = p_user::text
      or (storage.foldername(o.name))[1] in (
        select g.id::text from public.groups g where g.owner_id = p_user))
  union all
  -- Group avatars live under <group id>/<file>; only the owner's groups go.
  select o.bucket_id::text, o.name::text
  from storage.objects o
  where o.bucket_id = 'group-avatars'
    and (storage.foldername(o.name))[1] in (
      select g.id::text from public.groups g where g.owner_id = p_user)
$$;

comment on function public.account_storage_paths(uuid) is
  'Service-role only: lists storage objects owned by an account so they can be removed before the account is deleted.';
revoke all on function public.account_storage_paths(uuid) from public, anon, authenticated;
grant execute on function public.account_storage_paths(uuid) to service_role;

commit;
