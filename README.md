# Privilege

**Eat Well; Stay Well.** Privilege is a Flutter fitness and nutrition app backed
by Supabase, with an AI coach for practical training, nutrition, habit and app
questions. The app supports English and Arabic.

## Key features

- **Sign-in with email and password** backed by Supabase authentication.
- **Plan Organiser** for planning a week and managing workout splits.
- **Splits and sports** for combining workout and sport plans and estimating
  activity.
- **Calories and food log** for tracking food, workouts and daily calorie totals.
- **Recipes** for discovering fitness-friendly meal ideas.
- **Community** with a feed, people and groups.
- **Streak Arena** with challenges, standings and leaderboards.
- **Classified Level** with points, rewards and badges.
- **Academy** with exercise and sport guides.
- **Cheat meals** for planning and tracking treats.
- **VIP Plans** for viewing membership options (payments are not available).
- **AI coach** for personalised help based on the information you choose to
  share.

## Setup

1. Install a supported Flutter SDK.
2. Install dependencies:

   ```powershell
   flutter pub get
   ```

3. Configure Supabase in [`lib/supabase_config.dart`](lib/supabase_config.dart):
   replace `url` with the project's Supabase URL and `publishableKey` with its
   publishable key. Never put a service-role key or any other secret in the app.
   The backend must already have the required schema and Edge Function setup.

4. Set up the backend from [`supabase/README.md`](supabase/README.md). Apply
   the SQL files in [`supabase/`](supabase/) through the Supabase SQL Editor in
   the documented order: start with `schema.sql`, then `seed.sql`, and use
   `auth_migration.sql` when upgrading a database created from an earlier
   schema. Follow
   [`supabase/functions/coach/README.md`](supabase/functions/coach/README.md)
   to deploy the `coach` function and configure the `GEMINI_API_KEY`,
   `COACH_MODEL`, `COACH_FALLBACK_MODEL`, and `COACH_DAILY_LIMIT` secrets as
   applicable. Keep secret values out of the repository.

5. Select a device and run the app:

   ```powershell
   flutter run
   ```

6. Run the Flutter checks:

   ```powershell
   flutter test
   flutter analyze
   ```

## How the AI coach works

The app sends a signed-in user's message to the Supabase `coach` Edge Function.
The function validates the request, authenticates the user, checks the required
adult age profile, and applies server-enforced daily usage limits. Emergency
messages are handled with a fixed safety response, while accepted requests are
sent to Google Gemini with safety instructions to produce a reply for fitness
and nutrition guidance.

Sharing calorie information is optional. When consent is enabled, the app sends
only the calorie target and today's food and activity totals as context. The
function does not store messages or log their text. Users should not share
personal or health details they do not want sent to Google Gemini. The consent
setting is stored on the device and can be changed from the coach screen. API
keys and other provider secrets remain in the Edge Function environment, not
in the Flutter app.

## Current limitations

- Payments are not available.
- Account deletion is not available yet.
- Arena scores are self-reported and unverified.
- The AI coach has no memory of earlier messages and currently uses a free-tier
  model.
- The coach's emergency detection is keyword-based and cannot catch every
  phrasing.
- Group chat is not implemented yet.
- Recipe photos are not added yet.
- Password reset and social sign-in are not connected yet.
