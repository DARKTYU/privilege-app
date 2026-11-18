# Privilege project status

Handoff as of 18 November 2026.

## Project and environments

- **Privilege** ("Eat well stay well") is a Flutter app with a Supabase backend.
- **PrivilegeFitness** is the real project. **PrivilegeFitness-Test** is the
  separate test project, reported empty so far and intended for Stage 5 fake
  demo data.
- The live-project configuration and migration history below are based on the
  project owner's report, not a live database inspection. Do not apply SQL
  without explicit approval, and always verify the target project first.

## Git and current milestone

- Branch: `stage-2-community`, containing Stages 2-4, notifications and groups.
- Tags present: `stage-1-working`, `stage-3-working`, `stage-3-polished`,
  `stage-4a-applied`, `stage-4-working`, and `groups-phase1-working`.
- Latest commits at handoff:
  - `12a3295` - Groups moderation screens: banned list, unban, refresh.
  - `5c7e25a` - Groups moderation database fix.
  - `fc2bb06` - Group photo upload, image display and author names.

## Database and backend

The owner reports these migrations were applied to the real project in this
order:

1. `supabase/schema.sql`
2. `supabase/seed.sql`
3. `supabase/auth_migration.sql`
4. `supabase/activity_tracking.sql`
5. `supabase/community_games_rewards.sql`
6. `supabase/arena_challenges.sql`
7. `supabase/rewards_badges_levels.sql`
8. `supabase/community_notifications_v2.sql`
9. `supabase/comment_likes_v2.sql`
10. `supabase/groups_phase1.sql`
11. `supabase/groups_moderation_fix.sql`

Everything under `supabase/tests/` is test-only and **must never be run in the
real project**. Run database checks only against an isolated test database.

Reported live configuration:

- Realtime is enabled for community, notification, friendship, challenge,
  reward and XP tables. Group tables are **not** in Realtime yet.
- The pg_cron job `privilege-arena-schedules` runs
  `process_arena_schedules` hourly at minute 15.
- `community-posts` and `group-post-images` are private storage buckets.
- Removed or banned members' group posts and comments are soft-hidden and do
  not return when they rejoin. Previously issued signed image URLs can remain
  usable until they expire.

## Implemented and tested

- Activity and progression, community, Arena challenges, rewards, badges,
  levels and in-app notifications are implemented through Stages 1-4.
- Groups support creation, public and private groups, joining, leaving,
  invitations, posts with photos, and owner/moderator promote, demote, remove,
  ban and unban actions. Moderators have a banned list; private groups are
  hidden from Discover. Removal and banning hide the affected content.
- Groups moderation screens refresh after actions, on pull-to-refresh and when
  the app resumes. Group tables are not currently reported as realtime-enabled.
- **Still needs a manual test:** the group-full/member-limit case requires a
  third account.
- At the last moderation handoff, all 97 Flutter tests passed; the isolated
  SQL checks passed, including running the moderation migration twice.
  `flutter analyze` reported four pre-existing informational brace lints and
  exited with code 1. No debug app was connected for hot reload.

## Agreed rules

- Challenge scores are self-reported and unverified; no cash prizes.
- No calorie-goal challenges.
- A streak day requires at least one meal or completed workout on the user's
  local day.
- One free streak freeze per month. A purchased freeze token is used only after
  the free freeze, for a single missed day; frozen days give no XP or store
  points and do not count as active challenge days.
- XP and store points are separate ledgers; scoring occurs only through
  `SECURITY DEFINER` functions.
- Fake demo data belongs only in the test project.
- Never put secrets in chat, code or Git.

## Next steps, in order

1. **Groups UI polish:** avatars, tab highlight, fixed categories, member
   badges, plural fix and form counters.
2. **Friends messaging outside Community:** private chats, a Messages icon and
   unread counts; design the foundation for reuse by group chat.
3. **Group chat.**
4. **Push notifications:** Firebase FCM and a Supabase Edge Function.
5. **Stage 5:** fake demo data in the test project and a safe real/test switch.
6. **Group voice calls.**

## Known issues and later work

- Home Plan Organiser: "Add Split" unchecks days; this may be local/mock state.
  Start with a read-only audit.
- Shortcut chips overlap the AI button on Home/Profile, and the Sign Out button
  is partly hidden behind them.
- Purchased cosmetics are recorded but not applied.
- BMR is fixed at 1800 rather than personalized; quick-add macros do not match
  calories.
- Google and Facebook login are not wired in the app; password reset remains
  to be addressed.
- AI chat is "coming soon"; diet-plan tables and food data still need loading.
- Polish badge names and icons; usernames can show the generated `@user_...`
  until the user sets one.
- Release preparation: app name, icon and package ID; privacy policy; account
  deletion; real-phone testing; and an RLS review.
