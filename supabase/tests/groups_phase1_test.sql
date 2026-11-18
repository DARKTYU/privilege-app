-- Run only in an isolated test database. All fixtures roll back.
begin;
create function pg_temp.assert_group_test(ok boolean, message text) returns void
language plpgsql as $$ begin
 if ok is distinct from true then raise exception 'Test failed: %', message; end if;
end $$;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-4000-8000-000000000701','{}'),
 ('00000000-0000-4000-8000-000000000702','{}'),
 ('00000000-0000-4000-8000-000000000703','{}'),
 ('00000000-0000-4000-8000-000000000704','{}');
select set_config('request.jwt.claims','{}',true);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000701',true);
select public.group_create('Test group','','fitness','public','approval',2,'',null,'everyone',false,false);
select public.group_create('Private group','','fitness','private','invite_only',5,'',null,'everyone',false,false);
select set_config('test.private_group',(select id::text from public.groups where name='Private group'),true);
select pg_temp.assert_group_test((select count(*)=2 from public.groups), 'owner sees groups');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000702',true);
select pg_temp.assert_group_test((select count(*)=0 from public.groups where name='Private group'), 'private group invisible');
do $$ begin
 begin
  perform public.group_join(current_setting('test.private_group')::uuid);
  raise exception 'private join accepted';
 exception when raise_exception then if sqlerrm<>'Group is unavailable' then raise; end if; end;
end $$;
select pg_temp.assert_group_test(public.group_join((select id from public.groups where name='Test group'))='pending','approval request');
select pg_temp.assert_group_test((select count(*)=1 from public.group_members where user_id=auth.uid() and status='pending'), 'pending membership visible');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000701',true);
select pg_temp.assert_group_test((select count(*)=1 from public.community_notifications
 where notification_type='group_join_request'), 'join request notification');
select public.group_manage_member((select id from public.groups where name='Test group'),
 '00000000-0000-4000-8000-000000000702','approve');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000702',true);
select pg_temp.assert_group_test((select count(*)=1 from public.community_notifications
 where notification_type='group_request_approved'), 'approval notification');
select public.group_create_post((select id from public.groups where name='Test group'),'Member post',null);
do $$ begin
 begin
  perform public.group_update_settings((select id from public.groups where name='Test group'),
    'Test group','','fitness','public','open',4,'',null,'everyone',false,false);
  raise exception 'non-owner settings accepted';
 exception when raise_exception then
  if sqlerrm<>'Only the owner can change group settings' then raise; end if;
 end;
 begin
  perform public.group_manage_member((select id from public.groups where name='Test group'),
   '00000000-0000-4000-8000-000000000701','ban');
  raise exception 'member moderation accepted';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000703',true);
select public.group_join((select id from public.groups where name='Test group'));
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000701',true);
insert into public.community_blocks(blocked_id) values ('00000000-0000-4000-8000-000000000703');
do $$ begin
 begin
  perform public.group_manage_member((select id from public.groups where name='Test group'),
   '00000000-0000-4000-8000-000000000703','approve');
  raise exception 'blocked request approved';
 exception when raise_exception then if sqlerrm<>'Not permitted' then raise; end if; end;
end $$;
delete from public.community_blocks where blocked_id='00000000-0000-4000-8000-000000000703';
do $$ begin
 begin
  perform public.group_manage_member((select id from public.groups where name='Test group'),
   '00000000-0000-4000-8000-000000000703','approve');
  raise exception 'capacity exceeded';
 exception when raise_exception then if sqlerrm<>'Group is full' then raise; end if; end;
end $$;
select public.group_invite((select id from public.groups where name='Private group'),
 '00000000-0000-4000-8000-000000000704');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000704',true);
select pg_temp.assert_group_test((select count(*)=0 from public.groups where name='Private group'), 'invited nonmember cannot read private group');
select pg_temp.assert_group_test(public.group_join((select group_id from public.group_invites limit 1))='active','invited user joins private group');
select pg_temp.assert_group_test((select count(*)=1 from public.groups where name='Private group'),'private group visible to member');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000701',true);
select public.group_manage_member((select id from public.groups where name='Private group'),
 '00000000-0000-4000-8000-000000000704','promote');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000704',true);
select pg_temp.assert_group_test(public.group_is_moderator((select id from public.groups where name='Private group')), 'moderator promotion');
select set_config('test.moderator_post',public.group_create_post(
 (select id from public.groups where name='Private group'),'Moderator post',null)::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000701',true);
select public.group_create_comment(current_setting('test.moderator_post')::uuid,'Comment');
select public.group_set_post_like(current_setting('test.moderator_post')::uuid,true);
select public.group_set_post_like(current_setting('test.moderator_post')::uuid,true);
select pg_temp.assert_group_test((select count(*)=1 from public.group_post_likes
 where post_id=current_setting('test.moderator_post')::uuid),'one like per user');
select public.group_report((select id from public.groups where name='Private group'),'Post report',
 current_setting('test.moderator_post')::uuid,null);
select public.group_report((select id from public.groups where name='Private group'),'Member report',
 null,'00000000-0000-4000-8000-000000000704');
select public.group_report((select id from public.groups where name='Private group'),'Group report',null,null);
select pg_temp.assert_group_test((select count(*)=3 from public.group_reports),'reports stored');
insert into public.community_blocks(blocked_id) values ('00000000-0000-4000-8000-000000000704');
select pg_temp.assert_group_test((select count(*)=0 from public.group_posts
 where id=current_setting('test.moderator_post')::uuid),'blocked author post hidden');
do $$ begin
 begin
  perform public.group_create_comment(current_setting('test.moderator_post')::uuid,'Blocked');
  raise exception 'blocked comment accepted';
 exception when raise_exception then if sqlerrm<>'Post is unavailable' then raise; end if; end;
end $$;
delete from public.community_blocks where blocked_id='00000000-0000-4000-8000-000000000704';
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000704',true);
insert into public.community_blocks(blocked_id) values ('00000000-0000-4000-8000-000000000701');
select pg_temp.assert_group_test((select count(*)=0 from public.groups where name='Private group'),
 'group hidden when member blocks owner');
delete from public.community_blocks where blocked_id='00000000-0000-4000-8000-000000000701';
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000701',true);
do $$ declare g uuid; p uuid; i integer; begin
 select id into g from public.groups where name='Private group';
 begin
  perform public.group_create_post(g,'image',g::text || '/' || auth.uid()::text || '/pic.png');
  raise exception 'disabled image accepted';
 exception when raise_exception then if sqlerrm<>'Image is not allowed' then raise; end if; end;
 for i in 1..20 loop
  p:=public.group_create_post(g,'Rate test',null);
  perform public.group_delete_post(p);
 end loop;
 begin
  perform public.group_create_post(g,'Over limit',null);
  raise exception 'posting limit bypassed';
 exception when raise_exception then if sqlerrm<>'Posting limit reached; try again later' then raise; end if; end;
end $$;
select public.group_create('Third group','','fitness','public','open',4,'',null,'everyone',false,false);
do $$ begin
 begin
  perform public.group_create('Fourth group','','fitness','public','open',4,'',null,'everyone',false,false);
  raise exception 'group limit bypassed';
 exception when raise_exception then if sqlerrm<>'You can own at most three groups' then raise; end if; end;
end $$;
select public.group_manage_member((select id from public.groups where name='Test group'),
 '00000000-0000-4000-8000-000000000702','ban');
select public.group_manage_member((select id from public.groups where name='Test group'),
 '00000000-0000-4000-8000-000000000703','approve');
select public.group_update_settings((select id from public.groups where name='Test group'),
 'Test group','','fitness','public','approval',2,'',null,'moderators',false,false);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000703',true);
do $$ begin
 begin
  perform public.group_create_post((select id from public.groups where name='Test group'),'No',null);
  raise exception 'non-moderator post accepted';
 exception when raise_exception then if sqlerrm<>'Only moderators can post' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000702',true);
select pg_temp.assert_group_test((select count(*)=1 from public.community_notifications
 where notification_type='group_banned'), 'ban notification');
select pg_temp.assert_group_test((select count(*)=0 from public.groups where name='Test group'), 'banned user cannot view');
do $$ begin
 begin
  perform public.group_join((select group_id from public.community_notifications
   where notification_type='group_banned' limit 1));
  raise exception 'banned user joined';
 exception when raise_exception then if sqlerrm<>'You are banned from this group' then raise; end if; end;
end $$;
select pg_temp.assert_group_test(not has_table_privilege('authenticated','public.group_members','INSERT'),
 'direct member writes denied');
select pg_temp.assert_group_test(not has_table_privilege('authenticated','public.group_posts','INSERT'),
 'direct post writes denied');
rollback;
