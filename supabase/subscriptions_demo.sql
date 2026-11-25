-- Demo membership checkout. Apply once in the Supabase SQL Editor of the REAL
-- project (PrivilegeFitness), after schema.sql, seed.sql and rewards_badges_levels.sql.
--
-- No real payment is taken. These two functions let a signed-in user start or
-- cancel a 30-day Silver/Gold membership so the whole flow (checkout screen,
-- server-enforced tiers in the rewards store) can be demonstrated. They are the
-- ONLY way the app writes user_subscriptions; clients still cannot insert rows.
--
-- To go live later: delete public.subscribe_demo and have a payment provider's
-- webhook (running with the service role) write user_subscriptions instead.
begin;

create or replace function public.subscribe_demo(p_plan text)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
 owner_id uuid := auth.uid();
 chosen public.subscription_plans%rowtype;
 ends timestamptz := now() + interval '30 days';
begin
 if owner_id is null or not public.is_registered_user() then
  raise exception 'Sign in required';
 end if;
 select * into chosen from public.subscription_plans where name = p_plan;
 if not found or chosen.price_usd <= 0 then
  raise exception 'Plan is not available';
 end if;
 -- Serialize concurrent taps for the same user.
 perform 1 from public.profiles where id = owner_id for update;
 update public.user_subscriptions
    set status = 'cancelled', updated_at = now()
  where user_id = owner_id and status = 'active';
 insert into public.user_subscriptions(user_id, plan_id, status, started_at, expires_at)
 values (owner_id, chosen.id, 'active', now(), ends);
 return ends;
end
$$;
comment on function public.subscribe_demo(text) is
 'Demo checkout: starts a 30-day paid plan for the caller without taking payment.';
revoke all on function public.subscribe_demo(text) from public, anon, authenticated;
grant execute on function public.subscribe_demo(text) to authenticated;

create or replace function public.cancel_subscription()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
 owner_id uuid := auth.uid();
begin
 if owner_id is null or not public.is_registered_user() then
  raise exception 'Sign in required';
 end if;
 update public.user_subscriptions
    set status = 'cancelled', updated_at = now()
  where user_id = owner_id and status = 'active';
end
$$;
comment on function public.cancel_subscription() is
 'Cancels the caller''s active membership; the account returns to Free immediately.';
revoke all on function public.cancel_subscription() from public, anon, authenticated;
grant execute on function public.cancel_subscription() to authenticated;

commit;
