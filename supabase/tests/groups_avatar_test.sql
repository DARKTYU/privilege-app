-- ISOLATED TEST DATABASE ONLY. All fixtures and changes are rolled back.
begin;

create function pg_temp.assert_group_avatar(ok boolean, message text)
returns void language plpgsql as $$
begin
 if ok is distinct from true then raise exception 'Test failed: %', message; end if;
end $$;

select pg_temp.assert_group_avatar(
 (select not public and file_size_limit = 2097152
  and allowed_mime_types = array['image/jpeg','image/png','image/webp']::text[]
  from storage.buckets where id = 'group-avatars'), 'private bucket limits');
select pg_temp.assert_group_avatar(
 not has_function_privilege('anon', 'public.group_set_avatar(uuid,text)', 'execute'),
 'anonymous caller cannot execute setter');

insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-4000-8000-000000000901','{}'),
 ('00000000-0000-4000-8000-000000000902','{}'),
 ('00000000-0000-4000-8000-000000000903','{}');
select set_config('request.jwt.claims','{}',true);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000901',true);
select set_config('test.avatar_public',public.group_create(
 'Avatar public','','fitness','public','open',10,'','https://example.test/legacy.png','everyone',false,false)::text,true);
select set_config('test.avatar_private',public.group_create(
 'Avatar private','','fitness','private','invite_only',10,'',null,'everyone',false,false)::text,true);
select set_config('test.avatar_one',current_setting('test.avatar_public')||'/one.jpg',true);
select set_config('test.avatar_two',current_setting('test.avatar_public')||'/two.webp',true);
select set_config('test.avatar_private_path',current_setting('test.avatar_private')||'/private.png',true);

insert into storage.objects(bucket_id,name) values
 ('group-avatars',current_setting('test.avatar_one')),
 ('group-avatars',current_setting('test.avatar_two')),
 ('group-avatars',current_setting('test.avatar_private_path'));
select pg_temp.assert_group_avatar(
 (select count(*)=0 from storage.objects where bucket_id='group-avatars'),
 'unassigned uploads are not readable');
do $$ begin
 begin
  insert into storage.objects(bucket_id,name)
  values('group-avatars',current_setting('test.avatar_public')||'/nested/bad.png');
  raise exception 'nested upload accepted';
 exception when insufficient_privilege then null; end;
 begin
  insert into storage.objects(bucket_id,name)
  values('group-avatars',current_setting('test.avatar_public')||'/bad.gif');
  raise exception 'invalid extension accepted';
 exception when insufficient_privilege then null; end;
 begin
  perform public.group_set_avatar(current_setting('test.avatar_public')::uuid,
   current_setting('test.avatar_private_path'));
  raise exception 'wrong folder accepted';
 exception when raise_exception then
  if sqlerrm <> 'Invalid or missing group photo' then raise; end if;
 end;
 begin
  perform public.group_set_avatar(current_setting('test.avatar_public')::uuid,
   current_setting('test.avatar_public')||'/missing.png');
  raise exception 'missing object accepted';
 exception when raise_exception then
  if sqlerrm <> 'Invalid or missing group photo' then raise; end if;
 end;
end $$;

select public.group_set_avatar(current_setting('test.avatar_public')::uuid,current_setting('test.avatar_one'));
select public.group_set_avatar(current_setting('test.avatar_private')::uuid,current_setting('test.avatar_private_path'));
select pg_temp.assert_group_avatar(
 (select avatar_path=current_setting('test.avatar_one')
  and avatar_url='https://example.test/legacy.png'
  from public.groups where id=current_setting('test.avatar_public')::uuid),
 'group read exposes path without changing legacy URL');
select public.group_update_settings(current_setting('test.avatar_public')::uuid,
 'Avatar public','','fitness','public','open',10,'','https://example.test/legacy.png','everyone',false,false);
select pg_temp.assert_group_avatar(
 (select avatar_path=current_setting('test.avatar_one') from public.groups
  where id=current_setting('test.avatar_public')::uuid),
 'existing settings function preserves avatar path');

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000902',true);
select pg_temp.assert_group_avatar(
 (select count(*)=1 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_one')), 'public group photo visible');
select pg_temp.assert_group_avatar(
 (select count(*)=0 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_private_path')), 'private photo hidden from outsider');
do $$ begin
 begin
  insert into storage.objects(bucket_id,name)
  values('group-avatars',current_setting('test.avatar_public')||'/intruder.jpg');
  raise exception 'non-owner upload accepted';
 exception when insufficient_privilege then null; end;
 begin
  perform public.group_set_avatar(current_setting('test.avatar_public')::uuid,
   current_setting('test.avatar_two'));
  raise exception 'non-owner setter accepted';
 exception when raise_exception then
  if sqlerrm <> 'Only the owner can change the group photo' then raise; end if;
 end;
end $$;
delete from storage.objects where bucket_id='group-avatars' and name=current_setting('test.avatar_one');
select pg_temp.assert_group_avatar(
 (select count(*)=1 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_one')), 'non-owner cannot delete');

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000901',true);
select public.group_invite(current_setting('test.avatar_private')::uuid,'00000000-0000-4000-8000-000000000902');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000902',true);
select pg_temp.assert_group_avatar(
 (select count(*)=0 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_private_path')), 'invitation alone does not grant private photo access');
select public.group_join(current_setting('test.avatar_private')::uuid);
select pg_temp.assert_group_avatar(
 (select count(*)=1 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_private_path')), 'private member can read photo');
insert into public.community_blocks(blocked_id) values ('00000000-0000-4000-8000-000000000901');
select pg_temp.assert_group_avatar(
 (select count(*)=0 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_private_path')), 'blocking owner hides group photo');
delete from public.community_blocks where blocked_id='00000000-0000-4000-8000-000000000901';
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000901',true);
select public.group_manage_member(current_setting('test.avatar_private')::uuid,'00000000-0000-4000-8000-000000000902','promote');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000902',true);
do $$ begin
 begin
  perform public.group_set_avatar(current_setting('test.avatar_private')::uuid,null);
  raise exception 'moderator setter accepted';
 exception when raise_exception then
  if sqlerrm <> 'Only the owner can change the group photo' then raise; end if;
 end;
end $$;

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000901',true);
select public.group_set_avatar(current_setting('test.avatar_public')::uuid,current_setting('test.avatar_two'));
select pg_temp.assert_group_avatar(
 (select count(*)=0 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_one')), 'replaced photo no longer readable by owner');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000903',true);
select pg_temp.assert_group_avatar(
 (select count(*)=0 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_one')), 'replaced photo no longer readable by others');
select pg_temp.assert_group_avatar(
 (select count(*)=1 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_two')), 'replacement readable');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000901',true);
delete from storage.objects where bucket_id='group-avatars' and name=current_setting('test.avatar_two');
select pg_temp.assert_group_avatar(
 (select count(*)=0 from storage.objects where bucket_id='group-avatars'
  and name=current_setting('test.avatar_two')), 'owner can delete current photo before removal');
select public.group_set_avatar(current_setting('test.avatar_public')::uuid,null);
select pg_temp.assert_group_avatar(
 (select avatar_path is null and avatar_url='https://example.test/legacy.png'
  from public.groups where id=current_setting('test.avatar_public')::uuid),
 'remove clears path without touching legacy URL');

rollback;
