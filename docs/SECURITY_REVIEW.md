# Privilege: Security Review (25 Nov 2026)

Scope: the Supabase SQL files, the `coach` Edge Function and the Flutter code
in the repository. This is a review of the repository files. The live
database state is confirmed separately with the read-only SQL queries
(Query 1 to 4) run in the Supabase dashboard.

## Summary

| Severity | Count |
|----------|-------|
| High     | 0     |
| Medium   | 1     |
| Low      | 3     |

No high-severity problems were found. The database follows a default-deny
design: rewards, XP and scores are written only by the server.

## What is already strong

- **Row Level Security everywhere.** Every table has RLS enabled, all rights are
  revoked from `public` and `anon`, and a restrictive policy requires a
  registered (non-anonymous) account (`schema.sql`).
- **XP, points, streaks, rewards and subscriptions are server-only.** Clients
  can only read their own rows. There is no client insert policy on `xp_points`.
- **XP cannot be farmed by repeating actions.** Daily XP and points are
  awarded through `award_activity_day`, which uses a primary key on
  `(user_id, activity_date)`, so at most 10 XP and 10 points per day
  (`activity_tracking.sql`). Badges and achievements are one-time awards and
  are never reversed, so add/delete cycles earn nothing extra.
- **Activity can only be logged for "today"** in the user's timezone. Dates and
  owners cannot be changed afterwards (`guard_activity_log`).
- **Private profile data.** Other users see only username, name and avatar
  through the `community_profiles` view. Weight, height, goal and birth date
  are visible only to the owner.
- **Storage.** All buckets are private with size and file type limits:
  community photos 8 MB, group photos 8 MB, group avatars 2 MB; JPEG, PNG
  and WebP only. Upload and delete policies are tied to the owner's folder.
- **Leaderboards and challenge scores are calculated on the server** from the
  saved logs. The week start is defined in the database, not sent by the app.
- **Friendship and group changes go through controlled functions**
  (`respond_to_friendship`, group functions), not free updates.
- **Coach function.** It checks the JWT, rejects anonymous users, enforces 18+,
  validates the input, charges a daily quota atomically and returns only
  short error codes (no internal details). The service key is read from the
  server environment only.
- **No secrets in the code.** Only the public publishable key is in the app
  (`supabase_config.dart`), which is expected and safe.

## Findings

| # | Item | Risk | Severity | Fix | Who |
|---|------|------|----------|-----|-----|
| 1 | Self-reported numbers have no upper limit: `workout_logs.calories_burned`, `workout_logs.duration_minutes` and `meal_logs.calories` only require `>= 0`. Arena and leaderboard scores are derived from these rows, so a user could log absurd values to top a ranking. | Cheating on rankings (no money or data at risk) | Medium | Run `supabase/security_hardening.sql` (sanity caps, NOT VALID so old rows are untouched). | Me, in the Supabase dashboard |
| 2 | No rate limit was found in the SQL for community posts, comments and likes (groups do have one: `group_post_rate_events`). | Spam from one account | Low | Mention as a limitation, or add a small per-minute limit later. | Future work |
| 3 | The leaderboard week uses `date_trunc('week')`, which starts on Monday, while the planner shows Sunday-first weeks in Arabic. | Confusing weekly boundaries | Low | Document, or change the leaderboard week start. | Future work |
| 4 | Coach quota is charged even when the AI provider fails (a refund SQL is drafted in `docs/coach_quota_refund.sql` but not applied). | User loses quota on provider errors | Low | Apply the refund SQL after testing, or document it. | Future work |

## Still to confirm outside the repository

1. Run Query 1 and 2 in the Supabase dashboard (RLS on for all tables, policies
   match the SQL files).
2. In the Supabase dashboard, confirm "Verify JWT with legacy secret" is OFF
   for the `coach` function and `COACH_DAILY_LIMIT` is back to 30.
3. Scan git history for leaked secrets (command in the chat), because the
   review only saw the current files.
4. Email confirmation and password reset were not reviewed in depth.

## Known limitations (for the report)

- Scores and calories are self-reported; there is no device or wearable check.
- No payments or in-app account deletion.
- The photo calorie estimate is approximate and can vary between runs.
- The coach emergency check is keyword-based.
