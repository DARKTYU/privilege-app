-- Apply after the existing activity, Arena and rewards migrations.
-- Adds optional food-database details without changing existing activity rules.
begin;

alter table public.meal_logs
  add column if not exists food_id text,
  add column if not exists grams numeric(7,1),
  add column if not exists serving_label text,
  add column if not exists sugar_g numeric(7,1),
  add column if not exists sodium_mg numeric(8,1),
  add column if not exists source text not null default 'manual';

do $$
begin
 if not exists (select 1 from pg_constraint where conrelid = 'public.meal_logs'::regclass
                and conname = 'meal_logs_food_link_source_check') then
  alter table public.meal_logs add constraint meal_logs_food_link_source_check
   check (source in ('manual', 'food_db'));
 end if;
 if not exists (select 1 from pg_constraint where conrelid = 'public.meal_logs'::regclass
                and conname = 'meal_logs_food_link_grams_check') then
  alter table public.meal_logs add constraint meal_logs_food_link_grams_check
   check (grams is null or grams between 1 and 3000);
 end if;
 if not exists (select 1 from pg_constraint where conrelid = 'public.meal_logs'::regclass
                and conname = 'meal_logs_food_link_sugar_check') then
  alter table public.meal_logs add constraint meal_logs_food_link_sugar_check
   check (sugar_g is null or sugar_g >= 0);
 end if;
 if not exists (select 1 from pg_constraint where conrelid = 'public.meal_logs'::regclass
                and conname = 'meal_logs_food_link_sodium_check') then
  alter table public.meal_logs add constraint meal_logs_food_link_sodium_check
   check (sodium_mg is null or sodium_mg >= 0);
 end if;
 if not exists (select 1 from pg_constraint where conrelid = 'public.meal_logs'::regclass
                and conname = 'meal_logs_food_link_required_check') then
  alter table public.meal_logs add constraint meal_logs_food_link_required_check
   check (source <> 'food_db' or (food_id is not null and grams is not null));
 end if;
end $$;

comment on column public.meal_logs.food_id is 'Bundled food database string ID, not a public.food_items UUID.';
comment on column public.meal_logs.grams is 'Selected food portion in grams.';
comment on column public.meal_logs.serving_label is 'Optional household serving label at logging time.';
comment on column public.meal_logs.sugar_g is 'Optional sugar estimate for the logged portion.';
comment on column public.meal_logs.sodium_mg is 'Optional sodium estimate for the logged portion.';
comment on column public.meal_logs.source is 'Manual meal or bundled food database entry.';

commit;
