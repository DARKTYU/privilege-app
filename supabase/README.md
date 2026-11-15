# Privilege Supabase database

The Flutter app now uses Supabase email/password authentication and saves its
onboarding and profile fields to Supabase. Existing Express accounts are not
imported; Supabase users are new accounts. Social sign-in, password recovery,
payment processing, the Express AI endpoint and other application data have not
yet been migrated.

## Setup

1. Create a Supabase project at https://supabase.com and keep its database
   password and service-role key private. Never put the service-role key in the
   Flutter app or share it in chat.
2. In the project's SQL Editor, run `schema.sql`, then run `seed.sql`.
   Both can be re-run against a database created by these scripts. They are
   bootstrap scripts, not a migration mechanism for changing existing tables.
   If you already ran an earlier version of the schema, run `auth_migration.sql`
   to add the onboarding and profile fields without deleting data.
3. Configure email authentication and Google, Facebook and X/Twitter in
   Supabase Authentication and each provider's developer console, using
   Supabase's callback URL. Disable anonymous sign-ins. Provider approval and
   domain restrictions still apply.
4. Configure Supabase email delivery and redirects before production. Existing
   SMTP settings and reset-code behavior are not automatically transferred.
5. The app uses the project URL and publishable key in `lib/supabase_config.dart`.
   After an app restart, create a new account. If email confirmation is enabled,
   open the email confirmation link before logging in. The profile's generated
   username is assigned by the database trigger. Complete onboarding, then
   sign out from Profile and log back in to verify profile persistence.
   Check **Authentication > Users** and **Table Editor > profiles** for the
   new matching user ID and the saved onboarding fields.

The default Supabase email service is intended for testing and may restrict
delivery; configure custom SMTP for production. The old app's code-based
password reset is not compatible with Supabase and is currently unavailable.
The Express AI endpoint authenticates legacy tokens, not Supabase tokens.
Keep the legacy database and server until all remaining features are migrated.

## Social providers (not yet implemented in the app)

In Supabase Authentication > Sign In / Providers, enable Google, Facebook, or
X/Twitter only after configuring each provider's developer application. Register
the Supabase callback URL shown on that provider's settings page in the provider
console and enter that provider's client ID and secret in Supabase, not Flutter.
Configure app deep links and Supabase redirect allowlists before implementing
the mobile OAuth flow.

- Google: create an OAuth web client in Google Cloud, configure its consent
  screen, and add the Supabase callback as an authorized redirect URI.
- Facebook: create a Meta app, enable Facebook Login, configure its valid OAuth
  redirect URI and app permissions, and complete any required review.
- X: create an X developer app, enable OAuth 2.0 user authentication and add
  the callback URL. X platform access restrictions and costs may apply.

See the official [Google](https://supabase.com/docs/guides/auth/social-login/auth-google),
[Facebook](https://supabase.com/docs/guides/auth/social-login/auth-facebook), and
[X/Twitter](https://supabase.com/docs/guides/auth/social-login/auth-twitter) guides.

## Relationships

- `auth.users` 1:1 `profiles`; profiles belong to one level.
- Users own subscriptions, workout plans, sports, logs, meals, favourites and
  conversations; plans contain days and exercises. Shared splits contain
  template days and exercises, which can be copied into an owned plan with
  `merge_splits_into_plan`.
- Recipes contain ingredients and tags; `daily_summaries` aggregates meal logs.
- Friendships connect two profiles. Challenges have participants and an optional
  reward; trusted services award user rewards and XP, which updates levels.

## Access and trusted operations

RLS restricts private rows to their owner; authenticated users can read
catalogues, challenges, leaderboards and the limited `community_profiles`
directory (ID, username, full name and avatar only). Friendship state changes
use `respond_to_friendship`. Anonymous Supabase users are also denied access;
leave anonymous sign-ins disabled.
Service credentials bypass RLS and must only be used by a trusted server.

Subscriptions, streaks, participant scores, finalization, rewards and XP must
be managed by a trusted server. Client-created challenges cannot set prizes;
only trusted staff may assign a prize and must verify scores before calling
`finalize_challenge` after the end date (UTC). Finalization is idempotent and
ties are broken by join time then participant ID. Payment verification, score
verification and scheduling are not included. `record_streak` requires a
trusted activity date and ignores older or repeated dates.

`supabase_rows.dart` contains complete database-row models, not insert/update
DTOs: its `toJson` includes IDs, timestamps and server-owned fields. Select only
the columns allowed for a given write; sending the complete object to an insert
or update can fail or try to overwrite fields. Regenerate models with
`node scripts/generate_supabase_models.js` followed by
`dart format lib/models/supabase_rows.dart`.

## Assumptions

- Plan prices are USD per billing period; the billing period is not modeled and
  the sample feature flags are illustrative, not entitlement enforcement.
- Food nutrition values are sample values per 100 g; meal logs store snapshots
  entered by the application, not automatically calculated recipe values.
- Dates used for challenge expiry and streak validation are UTC; users' local
  timezone handling must be implemented by the trusted service.
- The database stores chat messages but does not implement an AI provider.
- XP levels depend on the sum of ledger points. Catalogue edits, account
  lifecycle, backups, privacy compliance and production security review need
  operational processes before release.
