-- ISOLATED TEST DATABASE ONLY. Fixtures and changes are rolled back.
begin;
create function pg_temp.assert_group_fix(ok boolean, message text) returns void
language plpgsql as $$ begin
 if ok is distinct from true then raise exception 'Test failed: %', message; end if;
end $$;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-4000-8000-000000000801','{}'),
 ('00000000-0000-4000-8000-000000000802','{}'),
 ('00000000-0000-4000-8000-000000000803','{}'),
 ('00000000-0000-4000-8000-000000000804','{}'),
 ('00000000-0000-4000-8000-000000000805','{}');
select set_config('request.jwt.claims','{}',true);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000801',true);
select set_config('test.group_a',public.group_create('Group A','','fitness','public','open',20,'',null,'everyone',true,false)::text,true);
select set_config('test.group_b',public.group_create('Group B','','fitness','public','open',20,'',null,'everyone',false,false)::text,true);
select set_config('test.owner_post',public.group_create_post(current_setting('test.group_a')::uuid,'Owner post',null)::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000802',true);
select public.group_join(current_setting('test.group_a')::uuid);
select public.group_join(current_setting('test.group_b')::uuid);
select set_config('test.other_post',public.group_create_post(current_setting('test.group_b')::uuid,'Other group post',null)::text,true);
select public.group_create_comment(current_setting('test.owner_post')::uuid,'Member comment');
select public.group_set_post_like(current_setting('test.owner_post')::uuid,true);
select public.group_set_post_like(current_setting('test.other_post')::uuid,true);
select set_config('test.image',current_setting('test.group_a')||'/00000000-0000-4000-8000-000000000802/photo.png',true);
reset role;
insert into storage.objects(bucket_id,name) values('group-post-images',current_setting('test.image'));
set local role authenticated;
select set_config('test.member_post',public.group_create_post(current_setting('test.group_a')::uuid,'Member image post',current_setting('test.image'))::text,true);
select pg_temp.assert_group_fix((select count(*)=1 from storage.objects where bucket_id='group-post-images' and name=current_setting('test.image')),'visible image readable');
insert into storage.objects(bucket_id,name)
 values('group-post-images',current_setting('test.group_a')||'/00000000-0000-4000-8000-000000000802/upload-test.png');
do $$ begin
 begin
  insert into storage.objects(bucket_id,name)
   values('group-post-images',current_setting('test.group_a')||'/00000000-0000-4000-8000-000000000801/forged.png');
  raise exception 'forged image upload accepted';
 exception when insufficient_privilege then null; end;
end $$;
delete from storage.objects where bucket_id='group-post-images'
 and name=current_setting('test.group_a')||'/00000000-0000-4000-8000-000000000802/upload-test.png';
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000803',true);
select public.group_join(current_setting('test.group_a')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000804',true);
select public.group_join(current_setting('test.group_a')::uuid);
select set_config('test.voluntary_post',public.group_create_post(current_setting('test.group_a')::uuid,'Voluntary leave post',null)::text,true);
select public.group_leave(current_setting('test.group_a')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000801',true);
select public.group_manage_member(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000803','promote');
select public.group_create_comment(current_setting('test.member_post')::uuid,'Owner on member post');
select public.group_set_post_like(current_setting('test.member_post')::uuid,true);
insert into public.community_blocks(blocked_id) values ('00000000-0000-4000-8000-000000000802');
select pg_temp.assert_group_fix(public.group_member_count(current_setting('test.group_a')::uuid)=3,'count includes blocked active members');
delete from public.community_blocks where blocked_id='00000000-0000-4000-8000-000000000802';
select pg_temp.assert_group_fix((select count(*)=1 from public.group_posts where id=current_setting('test.voluntary_post')::uuid),'leaving preserves posts');
select pg_temp.assert_group_fix(public.group_member_count(current_setting('test.group_a')::uuid)=3,'count after leave');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_members where status='left'),'removed and left members not listed');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000804',true);
select public.group_join(current_setting('test.group_a')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000801',true);
select public.group_manage_member(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000804','promote');

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000803',true);
do $$ begin
 begin
  perform public.group_manage_member(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000801','ban');
  raise exception 'owner ban unexpectedly succeeded';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
 begin
  perform public.group_unban(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000801');
  raise exception 'owner unban unexpectedly succeeded';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
 begin
  perform public.group_manage_member(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000804','remove');
  raise exception 'moderator removed another moderator';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
 begin
  perform public.group_manage_member(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000804','ban');
  raise exception 'moderator banned another moderator';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000801',true);
select public.group_manage_member(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000804','demote');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000804',true);
select public.group_leave(current_setting('test.group_a')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000803',true);
select public.group_manage_member(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000802','remove');
select pg_temp.assert_group_fix(public.group_member_count(current_setting('test.group_a')::uuid)=2,'count after removal');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_posts where id=current_setting('test.member_post')::uuid),'removed post hidden');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_comments where post_id=current_setting('test.owner_post')::uuid),'removed comment hidden');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_comments where post_id=current_setting('test.member_post')::uuid),'comments on hidden posts are hidden');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_post_likes where post_id=current_setting('test.owner_post')::uuid),'removed member like deleted');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_post_likes where post_id=current_setting('test.member_post')::uuid),'likes on hidden posts are hidden');
select pg_temp.assert_group_fix(not public.group_image_readable(current_setting('test.image')),'hidden image denied');
select pg_temp.assert_group_fix((select count(*)=0 from storage.objects where bucket_id='group-post-images' and name=current_setting('test.image')),'hidden image denied by storage RLS');
do $$ begin
 begin
  perform public.group_create_comment(current_setting('test.member_post')::uuid,'Not allowed');
  raise exception 'hidden post accepted comment';
 exception when raise_exception then if sqlerrm<>'Post is unavailable' then raise; end if; end;
 begin
  perform public.group_set_post_like(current_setting('test.member_post')::uuid,true);
  raise exception 'hidden post accepted like';
 exception when raise_exception then if sqlerrm<>'Post is unavailable' then raise; end if; end;
 begin
  perform public.group_report(current_setting('test.group_a')::uuid,'Hidden post',current_setting('test.member_post')::uuid,null);
  raise exception 'hidden post report accepted';
 exception when raise_exception then if sqlerrm<>'Post is unavailable' then raise; end if; end;
end $$;
reset role;
select pg_temp.assert_group_fix((select hidden_at is not null and hidden_reason='remove' from public.group_posts where id=current_setting('test.member_post')::uuid),'post soft hidden');
select pg_temp.assert_group_fix((select hidden_at is not null and hidden_reason='remove' from public.group_comments where post_id=current_setting('test.owner_post')::uuid),'comment soft hidden');
select pg_temp.assert_group_fix((select count(*)=1 from public.group_post_likes where post_id=current_setting('test.other_post')::uuid),'other group like remains');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000802',true);
select pg_temp.assert_group_fix(public.group_join(current_setting('test.group_a')::uuid)='active','removed member can rejoin');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_posts where id=current_setting('test.member_post')::uuid),'rejoin does not restore post');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_comments where post_id=current_setting('test.owner_post')::uuid),'rejoin does not restore comment');
select pg_temp.assert_group_fix((select count(*)=0 from storage.objects where bucket_id='group-post-images' and name=current_setting('test.image')),'rejoin does not restore image access');
do $$ begin
 begin
  perform public.group_delete_post(current_setting('test.member_post')::uuid);
  raise exception 'hidden post could be deleted by rejoined author';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
end $$;
select set_config('test.new_post',public.group_create_post(current_setting('test.group_a')::uuid,'Post after rejoin',null)::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000803',true);
select public.group_manage_member(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000802','ban');
select pg_temp.assert_group_fix(public.group_member_count(current_setting('test.group_a')::uuid)=2,'count after ban');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_members where status='banned'),'ban excluded from members');
select pg_temp.assert_group_fix((select count(*)=1 from public.group_banned_members(current_setting('test.group_a')::uuid)
 where user_id='00000000-0000-4000-8000-000000000802' and banned_at is not null
 and banned_by='00000000-0000-4000-8000-000000000803'),'ban metadata returned to moderator');
insert into public.community_blocks(blocked_id) values ('00000000-0000-4000-8000-000000000802');
select pg_temp.assert_group_fix((select count(*)=1 from public.group_banned_members(current_setting('test.group_a')::uuid)
 where user_id='00000000-0000-4000-8000-000000000802' and username is null and full_name is null and avatar_url is null),
 'blocked banned member retained with identity redacted');
delete from public.community_blocks where blocked_id='00000000-0000-4000-8000-000000000802';
do $$ begin
 begin
  perform public.group_invite(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000802');
  raise exception 'banned user was invited';
 exception when raise_exception then if sqlerrm<>'Cannot invite this user' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000802',true);
do $$ begin
 begin
  perform public.group_join(current_setting('test.group_a')::uuid);
  raise exception 'banned user joined';
 exception when raise_exception then if sqlerrm<>'banned_from_group' then raise; end if; end;
 begin
  perform public.group_banned_members(current_setting('test.group_a')::uuid);
  raise exception 'banned list available to nonmoderator';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
end $$;
-- Even a stale invitation inserted by a privileged actor cannot bypass a ban.
reset role;
insert into public.group_invites(group_id,user_id,invited_by)
 values(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000802','00000000-0000-4000-8000-000000000801');
set local role authenticated;
do $$ begin
 begin
  perform public.group_join(current_setting('test.group_a')::uuid);
  raise exception 'banned user joined via stale invitation';
 exception when raise_exception then if sqlerrm<>'banned_from_group' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000803',true);
select public.group_unban(current_setting('test.group_a')::uuid,'00000000-0000-4000-8000-000000000802');
select pg_temp.assert_group_fix(public.group_member_count(current_setting('test.group_a')::uuid)=2,'unban does not add member');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_banned_members(current_setting('test.group_a')::uuid)),'unbanned user absent from banned list');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000802',true);
select pg_temp.assert_group_fix(public.group_join(current_setting('test.group_a')::uuid)='active','unbanned member can rejoin');
select pg_temp.assert_group_fix((select count(*)=0 from public.group_posts where id in (current_setting('test.member_post')::uuid,current_setting('test.new_post')::uuid)),'unban never restores content');
select pg_temp.assert_group_fix(public.group_member_count(current_setting('test.group_a')::uuid)=3,'count after rejoin');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000801',true);
select public.group_update_settings(current_setting('test.group_b')::uuid,'Group B','','fitness','public','approval',20,'',null,'everyone',false,false);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000805',true);
select pg_temp.assert_group_fix(public.group_join(current_setting('test.group_b')::uuid)='pending','approval remains pending');
select pg_temp.assert_group_fix((select count(*)=1 from public.group_members where user_id=auth.uid() and group_id=current_setting('test.group_b')::uuid),'pending request visible to requester');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000802',true);
select pg_temp.assert_group_fix((select count(*)=0 from public.group_members
 where user_id='00000000-0000-4000-8000-000000000805' and status='pending'),'other member cannot see pending request');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000805',true);
do $$ begin
 begin
  perform public.group_unban(current_setting('test.group_b')::uuid,'00000000-0000-4000-8000-000000000802');
  raise exception 'nonmoderator unbanned a user';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000801',true);
select pg_temp.assert_group_fix((select count(*)=1 from public.group_members
 where user_id='00000000-0000-4000-8000-000000000805' and status='pending'),'moderator sees pending member');
select pg_temp.assert_group_fix(not has_table_privilege('authenticated','public.group_posts','UPDATE'),'direct post updates denied');
select pg_temp.assert_group_fix(not has_function_privilege('anon','public.group_unban(uuid,uuid)','EXECUTE'),'anonymous unban denied');
rollback;
