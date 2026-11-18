-- Isolated local test database only. All fixtures are rolled back.
begin;
create function pg_temp.check_result(value boolean, message text) returns void
language plpgsql as $$ begin
 if value is distinct from true then raise exception 'Test failed: %', message; end if;
end $$;
insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-4000-8000-000000000601','{}'),
 ('00000000-0000-4000-8000-000000000602','{}'),
 ('00000000-0000-4000-8000-000000000603','{}');
select set_config('request.jwt.claims', '{}', true);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000601', true);
update public.profiles set username='Hossam_1' where id=auth.uid();
insert into public.community_posts(id, body) values
 ('00000000-0000-4000-8000-000000000604','Post');
insert into public.community_comments(post_id, body) values
 ('00000000-0000-4000-8000-000000000604','Test comment');
select public.community_set_comment_like((select id from public.community_comments where body='Test comment'), true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000602', true);
select public.community_set_comment_like((select id from public.community_comments where body='Test comment'), true);
select pg_temp.check_result((select like_count=2 and liked_by_me and liked_by_author
 from public.community_comments_page_v2('00000000-0000-4000-8000-000000000604')),
 'count, own like and author like');
select pg_temp.check_result((select count(*)=2 from public.community_comment_likers(
 (select id from public.community_comments where body='Test comment'))), 'visible liker identities');
do $$ begin
 begin
  update public.profiles set username='hossam_1' where id=auth.uid();
  raise exception 'duplicate username was accepted';
 exception when unique_violation then null; end;
 begin
  update public.profiles set username='too_long_username_123456' where id=auth.uid();
  raise exception 'long username was accepted';
 exception when check_violation then null; end;
 begin
  update public.profiles set username='bad-name' where id=auth.uid();
  raise exception 'invalid username was accepted';
 exception when check_violation then null; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000603', true);
insert into public.community_blocks(blocked_id) values ('00000000-0000-4000-8000-000000000602');
select pg_temp.check_result((select like_count=1 and not liked_by_me and liked_by_author
 from public.community_comments_page_v2('00000000-0000-4000-8000-000000000604')),
 'blocked liker excluded from count');
select pg_temp.check_result((select count(*)=1 from public.community_comment_likers(
 (select id from public.community_comments where body='Test comment'))), 'blocked liker excluded from list');
insert into public.friendships(requester_id,addressee_id) values
 (auth.uid(),'00000000-0000-4000-8000-000000000601');
select pg_temp.check_result((select count(*)=0 from public.community_discover_users(30)
 where user_id in ('00000000-0000-4000-8000-000000000601',
 '00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000603')),
 'discovery excludes self, pending requests and blocked accounts');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000601', true);
select public.respond_to_friendship((select id from public.friendships
 where requester_id='00000000-0000-4000-8000-000000000603'
 and addressee_id=auth.uid()), 'accept');
select pg_temp.check_result((select count(*)=0 from public.community_discover_users(30)
 where user_id='00000000-0000-4000-8000-000000000603'),
 'discovery excludes accepted friends');
rollback;
