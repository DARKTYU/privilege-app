# Coach Edge Function

The Flutter app calls this function. Apply `supabase/coach_quota.sql` manually
only when you are ready; never run the isolated test against a real project.

In Supabase Dashboard > Edge Functions > Secrets, add:

- `GEMINI_API_KEY`: your private Gemini API key.
- `COACH_MODEL`: the Gemini model ID you have chosen and verified is available.
- `COACH_FALLBACK_MODEL`: optional alternative model ID.
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

Request body: `{"message":"Hello","consent":false,"app_language":"en"}` or, for one optional photo,
`{"message":"What is this?","consent":false,"photo_consent":true,"image":{"mime":"image/jpeg","data":"<base64>"}}`.
The message may be empty only when a photo is present; that is treated as asking
"what is this and what should I know about it?". A photo requires explicit `photo_consent: true`. This is independent from the
existing `consent` flag, which only controls calorie context. `app_language` accepts only
`en` or `ar`; other values are ignored. Text language wins when clear, while the
app language is the fallback for empty or unclear text, including photo-only
requests. If `consent` is
`true`, an optional `context` object can contain
numeric `calorie_target`, `calories_consumed`, and `calories_burned`. Other
context fields are ignored. Allowed image MIME types are `image/jpeg`,
`image/png`, and `image/webp`; the decoded image must not exceed 600 KB. Only
one image is accepted. The function forwards the inline base64 image to Gemini,
does not persist it, and never logs image data or request text.

Image-specific errors are `photo_consent_required`, `invalid_image`,
`invalid_image_mime`, `invalid_image_data`, `image_too_large`, and
`multiple_images`. Invalid image processing occurs only after authentication, registered-user,
age, emergency-keyword, consent and quota checks. Photo requests cost quota
before decoding, so malformed photos still consume their request cost. Emergency replies
therefore never decode or send an image. The function allows browser
cross-origin requests from any origin; callers must still authenticate. Usage is counted in UTC, including provider failures.
Missing or malformed provider settings are rejected before quota is consumed;
valid-looking but rejected credentials still consume quota. Quota is charged
before any Gemini attempt in `index.ts` by `coach_consume_quota`; provider
failures currently still consume it because there is no automatic refund. The
proposed un-applied refund function is in `docs/coach_quota_refund.sql`.
After authentication and message validation, the profile age check runs before
emergency keyword checks. An adult emergency match receives a fixed reply
without quota consumption or an AI call. For that reply `remaining` and
`reset_at` are null. Keyword checks are limited, not a safety guarantee; the
system prompt is an additional layer for non-matching messages.
Birth dates are self-reported, so the age check is not age verification.
Server-error logs contain codes and, for provider failures, safe status/reason
or error-name metadata and attempt count. Each provider attempt also emits one
safe log line with `has_image`, rounded image size in KB, attempt number,
duration in milliseconds, and provider status or error type. They never contain
image bytes, message text, or personal data.
A photo costs 3 quota units while a text-only request costs 1. At the default
limit of 30, this permits about 10 photo requests per day if they are the only
requests. Photo quota uses the three-argument `coach_consume_quota` overload
proposed in `docs/coach_photo_quota.sql`; review and apply that SQL manually
before enabling photo requests in the deployed function. Without that database
change, photo requests fail closed as `quota_unavailable`. The existing
two-argument quota function and text-only behavior remain unchanged.

The configured `COACH_MODEL` is deployment-specific, so this repository cannot
prove that the live secret is image-capable. Keep the current model; before
using photos, verify it supports image input in the official Gemini image
understanding documentation: https://ai.google.dev/gemini-api/docs/image-understanding
and generateContent request reference:
https://ai.google.dev/api/generate-content/generate-content . The REST endpoint
used here accepts `inline_data` image parts for image-capable Gemini models.

Text-only requests keep the existing timing: a 20-second first attempt and
12-second retry attempts, at most 3 attempts total, with one- and two-second
delays. Photo requests use a 25-second timeout and at most 2 attempts, with a
one-second delay, keeping the provider phase under 60 seconds. Defaults can be
overridden with `COACH_TEXT_PROVIDER_FIRST_TIMEOUT_MS`,
`COACH_TEXT_PROVIDER_ATTEMPTS`, `COACH_PHOTO_PROVIDER_TIMEOUT_MS`, and
`COACH_PHOTO_PROVIDER_ATTEMPTS`; invalid values fall back safely. Photo requests
do not invoke the fallback model. Eligible text-only failures can invoke the
optional fallback once with a 12-second timeout, after all main attempts fail
with 429, 5xx or timeout. A blank fallback is ignored; a malformed model is rejected before
quota use. Retries do not consume additional quota. The app aborts after
100 seconds; network delays outside the function can still cause a timeout.
The coach is instructed to answer fitness, nutrition, habit and app questions
with practical plans in the user's English or Arabic, using plain text. It
provides general safety guidance rather than diagnosing or treating medical
conditions, avoids extreme diets and performance-enhancing drugs, and responds
supportively without numbers or plans when there are signs of an eating
disorder. Calorie targets must respect safety limits and depend on sufficient
individual information. It explains calorie totals without adding burned
calories back. The provider output limit is 1,400 tokens; these prompt
instructions are not a guarantee of any particular response.
For photos, the prompt requires a one-line visual description, ranges rather
than exact estimates for food calories, safety guidance for equipment and form,
non-diagnostic responses for body/medical photos, no facial identification, and
warnings not to share IDs or private documents. It also redirects unrelated
photos briefly and uses Western digits in Arabic replies.
The prompt uses calorie context only for questions about calories, food, weight
or goals, and gives exact macro targets only with needed user-supplied details.
The prompt identifies supplied numbers as app context and treats today's
food and activity totals as a partial day. For weight goals it describes
calorie adjustments only when safe and based on an appropriate maintenance
target, and recommends reviewing weight trends after 2 to 3 weeks. Estimated
timelines depend on the individual. It avoids inventing screen locations for
editing personal details.
Arabic replies use natural simple Arabic, the specified Arabic screen names,
and Western digits; very short or vague messages receive a short greeting,
2-3 options, and one clarifying question. Emergency replies include the verified
Egypt numbers for ambulance 123, police 122 (112 from mobile), fire/civil defense
180, and mental health support 16328.

Arabic replies use the specified calorie and weight units; answers start directly
without a greeting. The prompt does not assume
whether an app calorie target represents maintenance or an existing adjustment;
it asks users to check their goal setting when that distinction matters.

Run the pure logic tests locally with Node 22.18+:

```powershell
node --test supabase\functions\coach\logic_test.ts
```
