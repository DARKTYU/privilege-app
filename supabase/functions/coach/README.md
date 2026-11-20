# Coach Edge Function

The app is not connected yet. Apply `supabase/coach_quota.sql` manually first
only when you are ready; never run the isolated test against a real project.

In Supabase Dashboard > Edge Functions > Secrets, add:

- `GEMINI_API_KEY`: your private Gemini API key.
- `COACH_MODEL`: the Gemini model ID you have chosen and verified is available.
- `COACH_DAILY_LIMIT`: a positive whole number (optional; defaults to 30).

Supabase supplies `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to Edge
Functions. Keep all secret values out of the app, Git, screenshots and chat.
Use a provider tier and privacy terms appropriate for health-related data.

When ready to deploy manually:

1. Select the correct project in the Supabase Dashboard.
2. Open Edge Functions, choose **Deploy a new function** > **Via Editor**.
3. Name it `coach`; replace the editor contents with this folder's `index.ts`.
4. Keep JWT verification enabled, then click **Deploy function**.
5. Test using a registered adult test user's access token, not a service key.
   The mobile client must send `Authorization: Bearer <user access token>`.

Request body: `{"message":"Hello","consent":false}`. If consent is `true`,
an optional `context` object can contain numeric `calorie_target`,
`calories_consumed`, and `calories_burned`. Other context fields are ignored.
The function allows browser cross-origin requests from any origin; callers must
still authenticate. Usage is counted in UTC, including provider failures.
Missing or malformed provider settings are rejected before quota is consumed;
valid-looking but rejected credentials still consume quota.
After authentication and message validation, emergency keyword matches receive
a fixed reply without an age check, quota consumption or AI call. For that reply
`remaining` and `reset_at` are null. Keyword checks are limited, not a safety
guarantee; the system prompt is an additional layer for non-matching messages.
Birth dates are self-reported, so the age check is not age verification.

Run the pure logic tests locally with Node 22.18+:

```powershell
node --test supabase\functions\coach\logic_test.ts
```
