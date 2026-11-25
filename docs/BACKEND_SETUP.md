# Backend setup (your own Supabase project)

Only needed if you want to run Privilege against your own backend instead of the project's. Back to the [README](../README.md).

## Steps

1. Create a Supabase project. Keep the service-role key private; never put it in the app.
2. Authentication: enable email sign-in and keep anonymous sign-ins **disabled**.
3. In the SQL Editor run the files in `supabase/` **in this order**:
   1. `schema.sql`, `seed.sql`, `auth_migration.sql`
   2. `activity_tracking.sql`, `community_games_rewards.sql`
   3. `arena_challenges.sql`, `rewards_badges_levels.sql`
   4. `community_notifications_v2.sql`, `comment_likes_v2.sql`
   5. `groups_phase1.sql`, `groups_moderation_fix.sql`, `groups_avatar.sql`, `group_chat.sql`
   6. `planner_organiser.sql`, `cheat_meals_limit_and_classified_checks.sql`
   7. `coach_quota.sql`, `coach_quota_refund.sql`, `meal_logs_food_link.sql`
   8. `subscriptions_demo.sql`, `security_hardening.sql`, `account_deletion.sql`
4. Put your project URL and **publishable** key in `lib/supabase_config.dart`. (A publishable key is meant to be public; row-level security protects the data.)
5. Deploy the Edge Functions in `supabase/functions/`. Read each folder's `README.md` for the required secrets (`GEMINI_API_KEY`, `COACH_MODEL`, `COACH_FALLBACK_MODEL`, `COACH_DAILY_LIMIT`).

Never run the SQL files in `supabase/tests/` against a real project; they are for an empty test project.
