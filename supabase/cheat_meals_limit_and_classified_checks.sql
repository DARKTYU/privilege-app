-- Run manually in the Supabase SQL Editor after schema.sql.
begin;
do $$ begin if to_regprocedure('public.is_registered_user()') is null or to_regprocedure('public.touch_updated_at()') is null then raise exception 'Required schema helper functions are missing'; end if; end $$;
do $$ begin if not exists (select 1 from pg_catalog.pg_constraint where conrelid = 'public.cheat_meals'::regclass and conname = 'cheat_meals_notes_length_check') then alter table public.cheat_meals add constraint cheat_meals_notes_length_check check (char_length(btrim(notes)) between 1 and 200) not valid; end if; end $$;
create or replace function public.enforce_cheat_meal_monthly_limit() returns trigger language plpgsql set search_path = '' as $$
declare month_start date; month_end date; other_count bigint; excluded_id uuid; begin
 if current_setting('transaction_isolation') <> 'read committed' then raise exception 'cheat meal limit requires read committed isolation'; end if;
 month_start := date_trunc('month', new.planned_date::timestamp)::date; month_end := (month_start + interval '1 month')::date;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('cheat_meals:' || new.user_id::text || ':' || (extract(year from month_start)::integer * 12 + extract(month from month_start)::integer)::text, 0));
 if tg_op = 'UPDATE' then excluded_id := old.id; end if;
 select count(*) into other_count from public.cheat_meals c where c.user_id = new.user_id and c.planned_date >= month_start and c.planned_date < month_end and (excluded_id is null or c.id <> excluded_id);
 if other_count >= 2 then raise exception 'cheat meal limit: at most 2 meals per calendar month' using errcode = 'P0001'; end if; return new;
end $$;
revoke all on function public.enforce_cheat_meal_monthly_limit() from public, anon, authenticated;
drop trigger if exists cheat_meals_monthly_limit on public.cheat_meals; create trigger cheat_meals_monthly_limit before insert or update of user_id, planned_date on public.cheat_meals for each row execute function public.enforce_cheat_meal_monthly_limit();
create table if not exists public.classified_checks (user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade, item_key text not null check (char_length(item_key) between 1 and 100), primary key (user_id, item_key));
comment on table public.classified_checks is 'item_key values are stable constant IDs, never display text.'; alter table public.classified_checks enable row level security;
revoke all on public.classified_checks from public, anon, authenticated; grant select, insert, delete on public.classified_checks to authenticated; grant all on public.classified_checks to service_role;
drop policy if exists classified_owner on public.classified_checks; create policy classified_owner on public.classified_checks for all to authenticated using (public.is_registered_user() and user_id = auth.uid()) with check (public.is_registered_user() and user_id = auth.uid());
commit;
