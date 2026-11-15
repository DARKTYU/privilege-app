# Privilege (Flutter)

Privilege is a fitness and nutrition app. Email/password sign-up, login and
profiles use Supabase. Configure the project in `lib/supabase_config.dart` and
follow the database setup instructions in `supabase/README.md`.

## Run and test

1. Run `flutter pub get`.
2. Select a device in VS Code and press **F5**, or run `flutter run`.
3. Create an account with an email and password. If email confirmation is
   enabled, open the email confirmation link before logging in.
4. Log in and complete onboarding. Sign out from the Profile screen, then log
   in again to check that the profile was saved.
5. In Supabase, check **Authentication > Users** and **Table Editor >
   profiles** for the new user and matching profile.

Run `flutter test` to execute tests and `flutter analyze` to check the code.

## Current limitations

- Google, Facebook and X sign-in and password recovery are not yet connected.
- AI chat, photo analysis and voice check-ins are coming soon. The chat screen
  does not send messages to an AI service.
- Existing accounts from the removed account system are not imported.
- Profile photos and theme selections are stored locally on the device.
