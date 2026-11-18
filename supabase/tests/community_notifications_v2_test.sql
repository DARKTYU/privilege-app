-- Local isolated test database only: creates test auth users and rolls back.
-- Run after all migrations including community_notifications_v2.sql.
begin;
create function pg_temp.assert_true(ok boolean, message text) returns void
language plpgsql as $$ begin
 if ok is distinct from true then raise exception 'Test failed: %', message; end if;
end $$;

insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-4000-8000-000000000101', '{}'),
 ('00000000-0000-4000-8000-000000000102', '{}'),
 ('00000000-0000-4000-8000-000000000103', '{}'),
 ('00000000-0000-4000-8000-000000000104', '{}');
select set_config('request.jwt.claims', '{}', true);
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);
insert into public.friendships(requester_id, addressee_id) values
 (auth.uid(), '00000000-0000-4000-8000-000000000102');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000102', true);
select pg_temp.assert_true((select count(*) = 1 from public.community_notifications
 where notification_type = 'friend_request'), 'friend request recipient');
select public.respond_to_friendship((select id from public.friendships
 where requester_id = '00000000-0000-4000-8000-000000000101' and addressee_id = auth.uid()), 'accept');
insert into public.community_follows(followed_id) values ('00000000-0000-4000-8000-000000000101');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);
select pg_temp.assert_true((select count(*) = 1 from public.community_notifications
 where notification_type = 'friend_accepted'), 'friend acceptance recipient');
select pg_temp.assert_true((select count(*) = 1 from public.community_notifications
 where notification_type = 'follow'), 'follow recipient');
insert into public.community_posts(id, body, visibility) values
 ('00000000-0000-4000-8000-000000000301', 'Friends post', 'friends'),
 ('00000000-0000-4000-8000-000000000302', 'Public post', 'public');
insert into public.community_likes(post_id) values ('00000000-0000-4000-8000-000000000302');
insert into public.community_comments(post_id, body) values
 ('00000000-0000-4000-8000-000000000302', 'Own comment');
select pg_temp.assert_true((select count(*) = 0 from public.community_notifications
 where notification_type in ('friend_post', 'post_like', 'post_comment')), 'no self notifications');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000103', true);
select pg_temp.assert_true((select count(*) = 0 from public.community_notifications
 where notification_type = 'friend_post'), 'non-friends receive no post alerts');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000102', true);
select pg_temp.assert_true((select count(*) = 2 from public.community_notifications
 where notification_type = 'friend_post'), 'friend sees public and friends-only post alerts');
select pg_temp.assert_true((select count(*) = 0 from public.community_notifications
 where recipient_id <> auth.uid()), 'notifications are private under RLS');
insert into public.community_likes(post_id) values ('00000000-0000-4000-8000-000000000302');
delete from public.community_likes where post_id = '00000000-0000-4000-8000-000000000302' and user_id = auth.uid();
insert into public.community_likes(post_id) values ('00000000-0000-4000-8000-000000000302');
insert into public.community_comments(post_id, body) values
 ('00000000-0000-4000-8000-000000000302', 'Nice work');
select public.community_set_comment_like((select id from public.community_comments where body = 'Own comment'), true);
select public.community_set_comment_like((select id from public.community_comments where body = 'Own comment'), false);
select public.community_set_comment_like((select id from public.community_comments where body = 'Own comment'), true);
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);
select pg_temp.assert_true((select count(*) = 1 from public.community_notifications
 where notification_type = 'post_like'), 'repeated post like alert deduplicated');
select pg_temp.assert_true((select count(*) = 1 from public.community_notifications
 where notification_type = 'post_comment'), 'comment recipient');
select pg_temp.assert_true((select count(*) = 1 from public.community_notifications
 where notification_type = 'comment_like'), 'repeated comment like alert deduplicated');
select pg_temp.assert_true((select comment_body = 'Nice work' from public.community_notifications_page_v2(50)
 where notification_type = 'post_comment'), 'comment text included for visible post');
select public.community_set_comment_like((select id from public.community_comments where body = 'Own comment'), true);
select pg_temp.assert_true((select count(*) = 1 from public.community_notifications
 where notification_type = 'comment_like'), 'self comment like does not alert');
select pg_temp.assert_true((select count(*) = 0 from public.community_notification_settings),
 'settings default to enabled without creating a row');
select public.community_set_notification_settings(false, false, false, false);
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000102', true);
insert into public.community_posts(id, body) values
 ('00000000-0000-4000-8000-000000000303', 'Muted friend post');
insert into public.community_comments(post_id, body) values
 ('00000000-0000-4000-8000-000000000301', 'Muted comment');
insert into public.community_likes(post_id) values ('00000000-0000-4000-8000-000000000301');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000103', true);
insert into public.friendships(requester_id, addressee_id) values
 (auth.uid(), '00000000-0000-4000-8000-000000000101');
insert into public.community_follows(followed_id) values ('00000000-0000-4000-8000-000000000101');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);
select pg_temp.assert_true((select count(*) = 0 from public.community_notifications
 where post_id in ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000303')
 or actor_id = '00000000-0000-4000-8000-000000000103'), 'all mute categories');
select public.community_set_notification_settings(true, true, true, true);
insert into public.community_blocks(blocked_id) values ('00000000-0000-4000-8000-000000000102');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000102', true);
insert into public.community_posts(id, body) values
 ('00000000-0000-4000-8000-000000000304', 'Blocked friend post');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);
select pg_temp.assert_true((select count(*) = 0 from public.community_notifications
 where post_id = '00000000-0000-4000-8000-000000000304'), 'blocked friend post suppressed');
select pg_temp.assert_true(public.community_unread_count() =
 (select count(*) from public.community_notifications where read_at is null
   and (actor_id is null or not public.community_is_blocked(actor_id))), 'blocked unread excluded');
select pg_temp.assert_true(not has_table_privilege('authenticated', 'public.community_comment_likes', 'INSERT'),
 'comment like direct writes denied');
select pg_temp.assert_true(not has_table_privilege('authenticated', 'public.community_notification_settings', 'INSERT'),
 'settings direct writes denied');
select pg_temp.assert_true(not has_table_privilege('authenticated', 'public.community_notifications', 'INSERT'),
 'notification direct writes denied');
do $$ begin
 begin
  perform public.community_set_comment_like((select id from public.community_comments where body = 'Nice work'), true);
  raise exception 'Test failed: blocked comment like allowed';
 exception when raise_exception then
  if sqlerrm <> 'Comment is unavailable' then raise; end if;
 end;
end $$;
-- Exercise both block directions and friendship-status blocks as the trusted
-- trigger owner, including interactions that client RLS normally rejects.
reset role;
insert into public.community_likes(post_id, user_id)
 values('00000000-0000-4000-8000-000000000303', '00000000-0000-4000-8000-000000000101');
insert into public.community_comments(post_id, author_id, body)
 values('00000000-0000-4000-8000-000000000303', '00000000-0000-4000-8000-000000000101', 'Blocked interaction');
insert into public.community_comment_likes(comment_id, user_id)
 select id, '00000000-0000-4000-8000-000000000101' from public.community_comments where body = 'Nice work';
insert into public.community_follows(follower_id, followed_id)
 values('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000102');
select pg_temp.assert_true((select count(*) = 0 from public.community_notifications
 where recipient_id = '00000000-0000-4000-8000-000000000102'
 and actor_id = '00000000-0000-4000-8000-000000000101'
 and (post_id = '00000000-0000-4000-8000-000000000303'
      or notification_type in ('follow', 'comment_like'))),
 'block suppresses likes, comments, comment likes and follows in reverse direction');
delete from public.community_blocks where blocker_id = '00000000-0000-4000-8000-000000000101'
 and blocked_id = '00000000-0000-4000-8000-000000000102';
update public.friendships set status = 'blocked', blocked_by = '00000000-0000-4000-8000-000000000102'
 where requester_id = '00000000-0000-4000-8000-000000000101'
 and addressee_id = '00000000-0000-4000-8000-000000000102';
insert into public.community_posts(id, author_id, body)
 values('00000000-0000-4000-8000-000000000305', '00000000-0000-4000-8000-000000000101', 'Friendship block');
select pg_temp.assert_true((select count(*) = 0 from public.community_notifications
 where post_id = '00000000-0000-4000-8000-000000000305' and notification_type = 'friend_post'),
 'friendship block suppresses friend post');
rollback;
