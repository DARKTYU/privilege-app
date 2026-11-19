-- ISOLATED TEST DATABASE ONLY. All fixtures and changes are rolled back.
begin;

create function pg_temp.assert_food_log(ok boolean, message text)
returns void language plpgsql as $$
begin
 if ok is distinct from true then raise exception 'Test failed: %', message; end if;
end $$;

insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-4000-8000-000000000a01','{}'),
 ('00000000-0000-4000-8000-000000000a02','{}'),
 ('00000000-0000-4000-8000-000000000a03','{}');
select set_config('request.jwt.claims','{}',true);
insert into public.challenges(id,creator_id,title,type,start_date,end_date)
values ('00000000-0000-4000-8000-000000000a04',
 '00000000-0000-4000-8000-000000000a01','Food log test','streak',current_date,current_date);
insert into public.challenge_participants(challenge_id,user_id) values
 ('00000000-0000-4000-8000-000000000a04','00000000-0000-4000-8000-000000000a01'),
 ('00000000-0000-4000-8000-000000000a04','00000000-0000-4000-8000-000000000a02');

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000a01',true);
insert into public.meal_logs(id,user_id,logged_date,meal_type,name,calories,protein_g,carbs_g,fat_g,fiber_g,
 food_id,grams,serving_label,sugar_g,sodium_mg,source)
values ('00000000-0000-4000-8000-000000000a11',auth.uid(),public.activity_today(),'lunch',
 'Koshary',344,10.8,57,8.2,6.4,'eg_koshary_traditional',200,'Bowl',4.8,770,'food_db');
select pg_temp.assert_food_log((select source='food_db' and food_id='eg_koshary_traditional'
 and grams=200 and sugar_g=4.8 and sodium_mg=770
 from public.meal_logs where id='00000000-0000-4000-8000-000000000a11'), 'food log inserted');

select pg_temp.assert_food_log((select current_streak=1 and last_activity_date=public.activity_today()
 from public.streaks where user_id=auth.uid()), 'food log updates streak');
select pg_temp.assert_food_log((select count(*)=1 from public.xp_points
 where user_id=auth.uid() and points=10 and reason='Daily activity XP: '||public.activity_today()::text),
 'food log awards daily XP');
select pg_temp.assert_food_log(public.store_points_balance()=10, 'food log awards store points');
select pg_temp.assert_food_log((select count(*)=1 from public.user_badges ub join public.badges b on b.id=ub.badge_id
 where ub.user_id=auth.uid() and b.code='meals_1'), 'food log awards first-meal badge');
select pg_temp.assert_food_log((select progress=1 from public.user_achievements ua
 join public.achievements a on a.id=ua.achievement_id
 where ua.user_id=auth.uid() and a.code='meal_10'), 'food log advances meal achievement');
select pg_temp.assert_food_log((select score=1 from public.challenge_participants
 where challenge_id='00000000-0000-4000-8000-000000000a04' and user_id=auth.uid()),
 'food log advances Arena streak score');

update public.meal_logs set grams=150,calories=258,protein_g=8.1,carbs_g=42.8,
 fat_g=6.2,fiber_g=4.8,sugar_g=3.6,sodium_mg=577.5
where id='00000000-0000-4000-8000-000000000a11';
select pg_temp.assert_food_log((select grams=150 and calories=258 and protein_g=8.1
 and carbs_g=42.8 and fat_g=6.2 and fiber_g=4.8 and sugar_g=3.6 and sodium_mg=577.5
 from public.meal_logs where id='00000000-0000-4000-8000-000000000a11'), 'portion edit saved');
select pg_temp.assert_food_log(public.store_points_balance()=10 and
 (select count(*)=1 from public.xp_points where user_id=auth.uid() and reason like 'Daily activity XP:%'),
 'editing does not repeat daily rewards');
select pg_temp.assert_food_log((select score=1 from public.challenge_participants
 where challenge_id='00000000-0000-4000-8000-000000000a04' and user_id=auth.uid()),
 'portion edit preserves Arena score');

do $$ begin
 begin
  update public.meal_logs set user_id='00000000-0000-4000-8000-000000000a03'
  where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'owner change unexpectedly succeeded';
 exception when insufficient_privilege then null;
  when raise_exception then
   if sqlerrm not in ('Activity log owner does not match the signed-in user',
                      'Activity log owner and date cannot be changed') then raise; end if;
 end;
 begin
  update public.meal_logs set logged_date=logged_date-1
  where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'date change unexpectedly succeeded';
 exception when raise_exception then
  if sqlerrm<>'Activity log owner and date cannot be changed' then raise; end if;
 end;
 begin
  insert into public.meal_logs(user_id,logged_date,meal_type,name,calories,protein_g,carbs_g,fat_g,source,food_id,grams)
  values(auth.uid(),public.activity_today()-1,'snack','Old',1,0,0,0,'food_db','food',100);
  raise exception 'historical insertion unexpectedly succeeded';
 exception when raise_exception then
  if sqlerrm<>'Activity can only be logged for today in your active timezone' then raise; end if;
 end;
end $$;

do $$ begin
 begin
  update public.meal_logs set grams=0 where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'zero grams accepted';
 exception when check_violation then null; end;
 begin
  update public.meal_logs set grams=3000.1 where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'excess grams accepted';
 exception when check_violation then null; end;
 begin
  update public.meal_logs set sugar_g=-0.1 where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'negative sugar accepted';
 exception when check_violation then null; end;
 begin
  update public.meal_logs set sodium_mg=-0.1 where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'negative sodium accepted';
 exception when check_violation then null; end;
 begin
  update public.meal_logs set source='unknown' where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'unknown source accepted';
 exception when check_violation then null; end;
 begin
  update public.meal_logs set food_id=null where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'missing food id accepted';
 exception when check_violation then null; end;
 begin
  update public.meal_logs set grams=null where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'missing grams accepted';
 exception when check_violation then null; end;
 begin
  update public.meal_logs set source=null where id='00000000-0000-4000-8000-000000000a11';
  raise exception 'null source accepted';
 exception when not_null_violation then null; end;
end $$;
update public.meal_logs set grams=1,sugar_g=0,sodium_mg=0
where id='00000000-0000-4000-8000-000000000a11';
update public.meal_logs set grams=3000
where id='00000000-0000-4000-8000-000000000a11';

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000a02',true);
select pg_temp.assert_food_log((select count(*)=0 from public.meal_logs
 where id='00000000-0000-4000-8000-000000000a11'), 'other users cannot read food log');
update public.meal_logs set grams=20 where id='00000000-0000-4000-8000-000000000a11';
delete from public.meal_logs where id='00000000-0000-4000-8000-000000000a11';
insert into public.meal_logs(id,user_id,logged_date,meal_type,name,calories,protein_g,carbs_g,fat_g)
values ('00000000-0000-4000-8000-000000000a12',auth.uid(),public.activity_today(),'snack','Manual',100,1,1,1);
select pg_temp.assert_food_log((select source='manual' and food_id is null and grams is null
 and serving_label is null and sugar_g is null and sodium_mg is null
 from public.meal_logs where id='00000000-0000-4000-8000-000000000a12'), 'manual defaults unchanged');
select pg_temp.assert_food_log((select current_streak=1 from public.streaks where user_id=auth.uid())
 and public.store_points_balance()=10
 and (select count(*)=1 from public.xp_points where user_id=auth.uid() and reason like 'Daily activity XP:%')
 and (select count(*)=1 from public.user_badges ub join public.badges b on b.id=ub.badge_id
      where ub.user_id=auth.uid() and b.code='meals_1')
 and (select progress=1 from public.user_achievements ua join public.achievements a on a.id=ua.achievement_id
      where ua.user_id=auth.uid() and a.code='meal_10')
 and (select score=1 from public.challenge_participants
      where challenge_id='00000000-0000-4000-8000-000000000a04' and user_id=auth.uid()),
 'manual log receives the same streak, XP, points, badge, achievement and Arena effects');

insert into public.meal_logs(user_id,logged_date,meal_type,name,calories,protein_g,carbs_g,fat_g)
select auth.uid(),public.activity_today(),'snack','Additional manual',100,1,1,1
from generate_series(1,9);
select pg_temp.assert_food_log((select completed_at is not null and progress=10
 from public.user_achievements ua join public.achievements a on a.id=ua.achievement_id
 where ua.user_id=auth.uid() and a.code='meal_10')
 and (select count(*)=1 from public.xp_points where user_id=auth.uid() and reason='Achievement: meal_10'),
 'manual meals complete achievement and award achievement XP once');
delete from public.meal_logs where name='Additional manual';

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000a01',true);
select pg_temp.assert_food_log((select grams=3000 from public.meal_logs
 where id='00000000-0000-4000-8000-000000000a11'), 'other user could not update or delete food log');
insert into public.meal_logs(user_id,logged_date,meal_type,name,calories,protein_g,carbs_g,fat_g,source,food_id,grams)
select auth.uid(),public.activity_today(),'snack','Additional food',100,1,1,1,'food_db','test_food',100
from generate_series(1,9);
select pg_temp.assert_food_log((select completed_at is not null and progress=10
 from public.user_achievements ua join public.achievements a on a.id=ua.achievement_id
 where ua.user_id=auth.uid() and a.code='meal_10')
 and (select count(*)=1 from public.xp_points where user_id=auth.uid() and reason='Achievement: meal_10'),
 'food logs complete achievement and award achievement XP once');
delete from public.meal_logs where name='Additional food';
delete from public.meal_logs where id='00000000-0000-4000-8000-000000000a11';
select pg_temp.assert_food_log((select count(*)=0 from public.meal_logs
 where id='00000000-0000-4000-8000-000000000a11'), 'food log deleted');
select pg_temp.assert_food_log((select score=0 from public.challenge_participants
 where challenge_id='00000000-0000-4000-8000-000000000a04' and user_id=auth.uid()),
 'deleting last meal clears Arena score');
select pg_temp.assert_food_log(public.store_points_balance()=10
 and (select count(*)=1 from public.xp_points where user_id=auth.uid() and reason like 'Daily activity XP:%'),
 'delete preserves already-awarded daily XP and points');

rollback;
