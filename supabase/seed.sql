-- Safe to re-run; sample catalog entries are identified by their names.
insert into public.levels(name, min_xp) values
 ('Bronze',0), ('Silver',500), ('Gold',1500), ('Platinum',3000)
on conflict (name) do nothing;
insert into public.subscription_plans(name, price_usd, feature_flags) values
 ('Free',0,'{"basic_workouts":true,"ai_chat":false}'),
 ('Silver',9.99,'{"basic_workouts":true,"ai_chat":true}'),
 ('Gold',14.99,'{"basic_workouts":true,"ai_chat":true,"premium_plans":true}')
on conflict (name) do nothing;
insert into public.sports(name, description) values
 ('Running','Cardiovascular running'), ('Swimming','Full-body swimming'), ('Football','Team field sport')
on conflict (name) do nothing;
insert into public.exercises(name, category, muscle_group, difficulty, instructions) values
 ('Push-up','Strength','Chest','Beginner','Lower your chest toward the floor, then press back up.'),
 ('Bodyweight squat','Strength','Legs','Beginner','Sit back into a squat, then stand.'),
 ('Bent-over row','Strength','Back','Intermediate','Hinge at the hips and pull the weight toward your torso.')
on conflict (name) do nothing;
insert into public.workout_splits(name, description) values
 ('Push Pull Legs','Three-day strength split'), ('Upper Lower','Two-day strength split')
on conflict (name) do nothing;
insert into public.split_days(split_id, day_number, name)
select s.id, d.n, d.name from public.workout_splits s
join (values ('Push Pull Legs',1,'Push'),('Push Pull Legs',2,'Pull'),('Push Pull Legs',3,'Legs'),
 ('Upper Lower',1,'Upper'),('Upper Lower',2,'Lower')) d(split_name,n,name) on d.split_name=s.name
on conflict (split_id, day_number) do nothing;
insert into public.split_day_exercises(split_day_id, exercise_id, position, sets, reps, rest_seconds)
select d.id, e.id, 0, 3, 10, 60 from public.split_days d
join public.workout_splits s on s.id=d.split_id
join public.exercises e on e.name = case when d.name in ('Push','Upper') then 'Push-up' when d.name='Pull' then 'Bent-over row' else 'Bodyweight squat' end
where s.name in ('Push Pull Legs','Upper Lower')
on conflict (split_day_id, position) do nothing;
insert into public.food_items(name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g) values
 ('Oats',389,16.9,66.3,6.9), ('Banana',89,1.1,22.8,0.3), ('Plain yogurt',61,3.5,4.7,3.3)
on conflict (name) do nothing;
insert into public.recipes(name, instructions, servings) values
 ('Banana yogurt oats','Combine oats and yogurt, then top with sliced banana.',1)
on conflict (name) do nothing;
insert into public.recipe_ingredients(recipe_id, food_item_id, grams)
select r.id, f.id, x.grams from public.recipes r
join (values ('Oats',50),('Banana',100),('Plain yogurt',150)) x(name,grams) on true
join public.food_items f on f.name=x.name where r.name='Banana yogurt oats'
on conflict (recipe_id, food_item_id) do nothing;
insert into public.recipe_tags(recipe_id, tag)
select id, 'breakfast' from public.recipes where name='Banana yogurt oats'
on conflict (recipe_id, tag) do nothing;
insert into public.rewards(name, description, xp) values
 ('Challenge winner','Awarded to the winner of a verified challenge.',100),
 ('Consistency badge','Awarded for consistent activity.',25)
on conflict (name) do nothing;
-- Profiles created before seeding receive their appropriate starting level.
update public.profiles p set level_id = (
 select l.id from public.levels l where l.min_xp <= greatest(coalesce((select sum(x.points) from public.xp_points x where x.user_id=p.id),0),0)
 order by l.min_xp desc limit 1
) where p.level_id is null;
