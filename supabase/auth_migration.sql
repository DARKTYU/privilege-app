-- Apply once to the existing Supabase project before using the new app.
-- Safe to re-run; preserves existing profile rows.
alter table public.profiles
  add column if not exists training_goal text,
  add column if not exists bio text not null default '',
  add column if not exists onboarding_completed boolean not null default false;

grant update (training_goal, bio, onboarding_completed)
  on public.profiles to authenticated;

comment on column public.profiles.training_goal is 'Detailed goal selected in the Privilege app.';
comment on column public.profiles.bio is 'User-editable profile biography.';
comment on column public.profiles.onboarding_completed is 'Whether the user has completed athlete setup.';
