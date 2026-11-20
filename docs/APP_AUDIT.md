# Privilege app audit

**Audit date:** 19 November 2026. **Submission:** 28 November 2026.

## Scope and evidence

This is a read-only review of the current Flutter source, checked-in SQL and
platform configuration, not an inspection of the live Supabase project. A
database table or migration in the repository does not prove that it is
deployed or configured correctly. Statements about database-backed behavior
mean that the app is wired to the relevant service and checked-in schema, not
that a live end-to-end test was performed. No SQL was applied.

Effort is for one developer: **S** less than half a day; **M** about a day;
**L** more than a day. Estimates are rough and exclude third-party review,
store approval and unpredictable provider setup. Priority reflects an honest
submission, not an assumption that every unfinished feature must be built.
Narrow-phone issues are based on layout inspection and existing tests unless
explicitly called out; this audit did not visually test every screen on a
physical device.

Baseline: `flutter test` passed **173 tests**. `flutter analyze` reported four
existing informational brace lints in
[`validators.dart`](../lib/logic/validators.dart),
[`champion.dart`](../lib/screens/champion.dart),
[`recipes.dart`](../lib/screens/recipes.dart), and
[`splits.dart`](../lib/screens/splits.dart); it exited nonzero. Tests use
fakes/mocks where indicated and are not proof of live configuration.

## 1. Login and accounts

**Working / database:** Email registration, password login, session restore,
profile lookup, onboarding and sign-out call Supabase Auth and `profiles`.
Confirmation handling depends on Supabase settings. The login form validates
email, password length/letter/number for registration and matching
confirmation; the service handles common sign-in and network errors.
See [`login.dart`](../lib/screens/login.dart),
[`supabase_auth_service.dart`](../lib/services/supabase_auth_service.dart),
[`validators.dart`](../lib/logic/validators.dart), and
[`state.dart`](../lib/state.dart).

**Not implemented:** Password reset and Google/Facebook sign-in are explicitly
described as unavailable; no reset or OAuth flow is wired. There is no in-app
account-deletion flow. Existing Supabase configuration, email delivery and
provider settings were not checked.

**Problems / risks:** The profile sign-out button is at the end of a scroll
view, while [`home_shell.dart`](../lib/screens/home_shell.dart) overlays the
center-docked AI button near the shortcut strip. The previous overlap report
is credible for Home/Profile; reproduce on 360 x 640, gesture/navigation bar
variants and larger text before claiming it fixed. No in-app deletion leaves
users without a self-service way to remove account and associated health/social
data. Check server-side cleanup, user-generated content, storage objects,
retention and reauthentication before implementing it. Do not put an admin or
service-role credential in the client. Validation is client feedback, not a
substitute for server-side enforcement.

**Priority / effort:** sign-out visibility **must-have S**; reset **must-have
M**, including email/deep-link verification; account deletion and privacy
workflow **must-have L** for a public account-enabled release; defer or clearly
hide social login **should-have S**, real provider integration **L**.

## 2. Plan Organiser

**What works:** The current week, selection, day toggles and sliders update on
screen. Dates are generated from the local current week.

**Mock / bug:** [`plan.dart`](../lib/screens/plan.dart) initializes a hardcoded
seven-day example. “Add Split” toggles the selected day's workout/rest state,
so it can uncheck an existing day; it does not add a split. The top plus
switches the first rest day to a workout. “Quick Add” shows a success message
but does not store a session. The five cards are tied to the first five days,
not the selected day. Nothing is saved or linked to Splits or Calories; screen
state is lost when the widget is recreated. The schema contains plan/split
tables and an append function, but this screen does not call them.

**Risk / layout:** Misleading “Added” feedback can make users believe a plan is
saved. Seven narrow day cells and the three-column cards need small-screen and
large-text checks.

**Priority / effort:** remove false success / relabel or disable nonworking
actions **must-have S**; a real owner-isolated planner with persistence,
validation and recovery **should-have L**. Do not claim a saved plan until
read/write and reload are verified.

## 3. Splits and Sports Merge

**What works:** A deterministic local calculation in
[`fitness_logic.dart`](../lib/logic/fitness_logic.dart) sums the chosen preset
minutes and calories and produces a heuristic fatigue score, recovery hours,
hydration and carbohydrates. Selection and custom entries work in the current
screen instance.

**Mock / gaps:** Inputs are hardcoded examples from [`data.dart`](../lib/data.dart)
or self-entered; the calculation is not personalized, measured or a validated
training-load model. Custom inputs fall back to default numbers on parse
failure. The “synced” and partner-avatar status is decorative; custom splits
and merge results are not persisted, sent to the Plan Organiser, or logged in
Calories. “Save & Select Split” means local selection, not database saving.

**Risk / layout:** Recovery and hydration numbers can look like professional
advice; add a clear estimate disclaimer and avoid invented synchronization
claims. Three side-by-side stats and long names need a 360 px / text-scale
check.

**Priority / effort:** honest labels, validation and disclaimer **must-have
S–M**; durable split/plan integration and explicit workout logging
**should-have L**.

## 4. Recipes

**Working / database:** [`recipes.dart`](../lib/screens/recipes.dart) displays
two bundled examples. Log sends a manual meal through `appState.addMeal` to
`meal_logs`, so it appears in the Food Log and uses the existing activity
processing path, subject to a successful backend write.

**Mock / bugs:** “from million recipes” is false: there are two local recipes,
not a provider or database feed. Favorites are a widget-local set and reset
when the screen is recreated despite a `user_favorite_recipes` table. Logged
protein and calories are from the examples, but **carbs 45 g, fat 14 g and
fiber 6 g are fabricated for every recipe**, so logged nutrition can be
misleading. “Quick-Action: Save” and “Saved” imply persistence; the heart and
button toggle the same temporary set.

**Risk / layout:** Incorrect nutrition can affect health decisions; the
side-by-side long button labels and image overlays need narrow-screen testing.
External photos are listed below.

**Priority / effort:** correct nutrition or disable recipe logging, replace
false catalogue and save labels **must-have S–M**; persistent favorites and
verified recipes **should-have M–L**.

## 5. AI chat

**What works:** [`chat.dart`](../lib/screens/chat.dart) displays a local
conversation and explicitly says messages were not sent. Photo and voice
buttons say “coming soon.”

**Not implemented / risk:** There is no AI service call, model, key, saved
conversation or photo/voice analysis in this flow. Subscription marketing
nevertheless promises AI features. For future AI, keep the provider key in a
server-side secret store (for example an authenticated backend function),
never in Flutter, Git, an APK or a browser bundle. Add user consent, a clear
health-data privacy policy, access/rate limits, safe responses and deletion/
retention rules before sending messages or images to any provider.

**Priority / effort:** align all claims and disable misleading entry points
**must-have S**; real privacy-reviewed AI **nice-to-have L**, defer for this
submission.

## 6. Cheat meals

**Update 20 Nov 2026:** The screen now saves cravings per user and date; the
reset-on-leaving issue is fixed. Monthly limits are enforced by the database.
The findings below describe the earlier audit, not the current screen.

**What works:** [`cheats.dart`](../lib/screens/cheats.dart) shows a local
current-month calendar and allows local additions/deletions.

**Mock / bugs:** Days 8 and 20, notes and two sample meals are hardcoded.
Entries are only a list of strings in widget memory: no persistence,
date/month-safe saved record, Plan Organiser link or Calories log. Add accepts
other days and more than two items despite “2 Allowed / Month”; the limit is
only visual. Existing `cheat_meals` is not used by this screen.

**Risk / layout:** “Allowed” and “budgeted” could imply medical or dietary
rules without a basis. Do not present example meals as the user's own history.
Calendar density should be tested at large text.

**Priority / effort:** remove fake history and restrictive claims or label as a
demo **must-have S**; actual planning and food-log integration
**nice-to-have L**.

## 7. Classified Level

**Update 20 Nov 2026:** The five self-reported checklist ticks now persist per
user; the reset-on-leaving issue is fixed. They remain unverified. The findings
below describe the earlier audit, not the current screen.

**What works:** [`champion.dart`](../lib/screens/champion.dart) calculates a
local score from toggles and fixed example numbers.

**Mock / risk:** “100% Natural Status Verified”, “WADA Tested”, eligibility,
registration and contest pass #88 are fabricated by local state; no
verification, federation integration, registration or pass is performed.
The Pro/Elite gate is also locally mutable. Body-fat and muscle thresholds
should not be treated as medical or official qualification criteria.

**Honest five-step version:** (1) choose a goal, (2) choose an event or record
an event link, (3) make a personal preparation checklist, (4) mark
self-reported progress without claiming verification, (5) review next steps
and visit the organizer for official requirements/registration. If saved,
store user-owned entries with clear deletion and privacy rules.

**Priority / effort:** remove false verification, eligibility and registration
claims **must-have S**; build a labeled, persistent five-step tracker
**should-have L**.

## 8. Academy

**What works:** Six local guides in [`data.dart`](../lib/data.dart) are
searchable/filterable; tapping opens a details sheet. “Mastered Cue” closes the
sheet, it does not save completion. No academy content is fetched from the
database.

**Risks:** Exercise cues, nutrition advice and calorie-burn figures have no
provenance or professional review in the app. Avoid asserting medical or
individual suitability; have qualified reviewers check the advice. Six
Unsplash image URLs are inventoried below; the code has no photo attribution,
license record or evidence of permission for this particular use. Unsplash
hosting alone is not proof of rights; check the original photo/license,
identifiable people, model/property releases and any platform terms. Remote
loading exposes the viewer's IP to the host and requires network.

**Priority / effort:** source/content and image review or hide unverified
guides **must-have M–L**; persisted learning progress **nice-to-have M**.

## 9. VIP plans and subscriptions

**What works / database:** Profile membership display reads active
`user_subscriptions`/`subscription_plans` through
[`progression_repository.dart`](../lib/services/progression_repository.dart).
Some reward entitlements also use that backend tier.

**Mock / conflict:** [`subscription.dart`](../lib/screens/subscription.dart)
shows hardcoded prices and calls `appState.setTier` only; no purchase, charge,
receipt, entitlement verification or database update occurs. The button claims
“Plan switched” and “All features unlocked.” Its Free/Pro/Elite local tier is
separate from the database Free/Silver/Gold membership. The loaded profile
retains a demo Pro default, so local feature gates can disagree with real
membership. The offers claim Gemini photo/voice, certified WADA coaching,
official entry and special rewards that are not established by this flow.

**Risk:** False payment/benefit/official-status claims and inconsistent
authorization are release blockers. UI feature gates are not security controls.
An honest submission should show only real benefits and actual status, clearly
say purchases are unavailable, remove prices/upgrade actions unless they
actually work, and avoid fabricated credentials or vouchers.

**Priority / effort:** disable simulated upgrades and remove false claims
**must-have S–M**; real store billing, server-side entitlement validation and
restore/cancellation **nice-to-have L**, defer.

## 10. Home and Profile

**Home:** The Home tab is the mock Plan Organiser, not a separate live
dashboard. The shell uses an `IndexedStack`; local tab state can survive tab
switches but is not durable. Its shortcut chips and center-docked AI floating
button share the bottom area on non-Calories tabs. The Calories tab has extra
space specifically added for its chips; Home/Profile do not. Verify overlap
and whether Sign Out is fully reachable on actual narrow devices, with
keyboard, text scaling and Android navigation modes.

**Profile:** Name, username, bio, weight, height, detailed goal and personal
target fields use `profiles`; level and membership are loaded from the
progression repository. Profile photo is stored as base64 in local
SharedPreferences under a per-user key, not synchronized to the backend:
other users and other devices do not see it. It remains on the device until
removed; per-user storage does not equal encryption. The fallback photo,
body-fat 11%, muscle 42 kg, natural status and several other values come from
the default demo profile rather than verified user records. Body fat is
displayed as a real profile stat. Default bio can also survive if a backend
value is null. See [`user_profile.dart`](../lib/logic/user_profile.dart),
[`profile.dart`](../lib/screens/profile.dart) and
[`settings.dart`](../lib/screens/settings.dart).

**Risk / priority:** remove fabricated personal metrics and default photo or
explicitly mark examples **must-have S–M**; fix/verify overlap and reachable
logout **must-have S–M**; decide secure photo storage/sync and retention
**should-have L**. Long profile names/email and the fixed two-column stat grid
need visual testing.

## 11. External images and remote assets

The following are every hardcoded external image URL found in runtime Dart
source. Exact URLs are included so the owner can inspect each asset. The
repository does not establish a license for any of them.

| Screen / use | Exact URL |
|---|---|
| Recipes: High-Protein Burger | https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop&q=80 |
| Recipes: Anabolic Muscle Shake | https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=600&auto=format&fit=crop&q=80 |
| Academy: Bench Press | https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&auto=format&fit=crop&q=80 |
| Academy: Back Squat | https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&auto=format&fit=crop&q=80 |
| Academy: Deadlift | https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&auto=format&fit=crop&q=80 |
| Academy: Basketball | https://images.unsplash.com/photo-1546519638-68e109498ffc?w=600&auto=format&fit=crop&q=80 |
| Academy: Boxing | https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?w=600&auto=format&fit=crop&q=80 |
| Academy: Foundations | https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&auto=format&fit=crop&q=80 |
| Profile and Settings default avatar | https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256&h=256&fit=crop&crop=faces |
| Splits: fabricated “you” avatar | https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=64&h=64&fit=crop |
| Splits: fabricated partner avatar | https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=64&h=64&fit=crop |
| Unused example rival avatar in data | https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=64&h=64&fit=crop |
| Unused example rival avatar in data | https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=64&h=64&fit=crop |
| Unused example Arena friend in data | https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=96&h=96&fit=crop |
| Unused example Arena friend in data | https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=96&h=96&fit=crop |
| Unused example Arena friend in data | https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=96&h=96&fit=crop |

In addition, Community, Groups and Alerts can render **dynamic**
database-provided profile avatar URLs; Community and Groups load uploaded
images using Supabase Storage signed URLs. Their actual URLs and rights cannot
be inventoried without the live data. Obtain upload rights/consent, enforce
access control and account for signed-URL expiry. The test-only example URL in
`supabase/tests` is not a production image. Bundled
[`logo.png`](../assets/images/logo.png) also needs a provenance check.

**Priority / effort:** inventory and clear/replace images **must-have M–L**;
dynamic upload policy and moderation **should-have L**.

## 12. Release readiness and privacy

* **Identity:** Android launcher label is `flutter_application_1` and
  application ID/namespace is `com.example.flutter_application_1`; iOS display
  name is `Flutter Application 1` and bundle ID is
  `com.example.flutterApplication1`. Web manifest still has the Flutter
  template name/description. Android and iOS launcher icons are the default
  Flutter logo, not the bundled Privilege logo. See
  [`build.gradle.kts`](../android/app/build.gradle.kts),
  [`AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml),
  [`Info.plist`](../ios/Runner/Info.plist) and
  [`manifest.json`](../web/manifest.json). **Must-have M.**
* **Signing:** Android release is configured with the debug signing key. Use a
  properly protected release signing setup and verify the final artifact;
  never commit a private signing key. **Must-have M.**
* **Permissions:** Android declares Internet and camera; iOS declares camera
  and photo-library descriptions. Profile supports camera/gallery selection;
  Community and Groups use gallery selection. Review merged release manifests, actual OS
  prompts and permission minimization on each target platform. **Must-have S.**
* **Debug banner:** explicitly disabled in
  [`main.dart`](../lib/main.dart). Build and inspect a release artifact to
  verify the final build and logs. **Must-have S.**
* **Privacy / deletion:** no privacy policy link or in-app account deletion
  was found. Publish a real policy covering health/profile data, local photos,
  Supabase, social content, third-party images, retention, support and
  deletion; provide deletion and verify app-store requirements for the actual
  distribution channel. **Must-have L** (policy/legal review external).
* **Keys / secrets:** the app includes a Supabase project URL and a
  *publishable* client key in [`supabase_config.dart`](../lib/supabase_config.dart).
  A publishable key is intended to be distributed, not a service-role secret;
  it does not replace correct RLS, grants, Storage rules and backend checks.
  A heuristic working-tree scan for private-key headers, common provider
  secret prefixes and credential assignments found no matching secret values.
  It excluded Git history, generated/dependency directories, binary files and
  files over 3 MB; it cannot prove the repository, history, CI, dashboards or
  production are secret-free. Search references to `service_role` in SQL are
  role/grant identifiers, not by themselves exposed credentials. Run an
  approved history/CI secret scan and independently review live RLS,
  authorization, storage and function grants; rotate any verified exposed
  secret. **Must-have M–L.**
* **TODOs:** Android ID/signing and the simulated subscription purchase flow
  are explicit TODOs. See platform and subscription files above.
* **Demo data:** planner, splits, recipes, cheat meals, classified tracker,
  subscription claims, Academy guidance and profile defaults described above
  are exposed to users. Remove, accurately label or replace before submission.
  Food nutrition and workout burn are estimates, not measured facts. The
  generic manual meal form also invents macro values and offers a generic
  workout option; disclose or correct it rather than implying precision.
  **Must-have M–L.**
* **Backend:** verify live migration/version status, real accounts, policies
  and triggers in a separate approved test environment. Social feeds, groups,
  alerts, Arena and progression have repository/database paths, but were not
  independently audited end-to-end here. Reported prior migration state is
  in [`PROJECT_STATUS.md`](PROJECT_STATUS.md), not a live verification.
  **Must-have M–L.**

## 13. Ranked nine-day submission plan

This is a risk-first, single-developer plan. It assumes a submission can
honestly omit unfinished purchases, social sign-in and AI. Some L items overlap
days; policy, security and store work may require external time. If the
submission is a private academic demo rather than a public release, confirm
which account-deletion/store requirements apply; do not pretend a demo is
production-ready.

| Day | Priority and deliverable | Effort |
|---|---|---|
| 19 Nov | Remove or clearly disable fabricated WADA, contest pass, paid-plan, AI and fake registration claims; mark unimplemented features. | M |
| 20 Nov | Correct or disable recipe logging with fabricated macros; remove “million recipes”, fake favorites/saves and fake personal metrics. | M |
| 21 Nov | Fix Home/Profile overlap and logout reachability; test 360 x 640, large text and keyboard. Fix planner “Add Split” and fake Quick Add feedback by disabling or labeling, not pretending to persist. | M |
| 22 Nov | Account recovery: implement and test reset links, expired links, validation and email delivery with a test project; document social login as unavailable. | M–L |
| 23 Nov | Privacy policy and account-deletion design/implementation, including reauthentication, related records and storage cleanup; start external review. | L, day 1 |
| 24 Nov | Finish deletion and verify with isolated accounts; review live-equivalent RLS, function grants, private images and secret handling without using production test data. | L, day 2 |
| 25 Nov | Clear/replace remote images, remove remaining misleading health/recovery claims, verify content provenance; trim unsupported demo features. | M–L |
| 26 Nov | Set app identity, package IDs, launcher icons and protected release signing; check permissions, release build and installation on physical devices. | M |
| 27 Nov | Run full tests and analyzer, targeted end-to-end account/food/workout/social smoke tests, offline/error/accessibility checks; verify fixes and prepare an honest feature/known-limitations submission. Reserve time for regressions. | M–L |

Do not add a real billing system, AI provider, a fully connected planner or
competition qualification under deadline pressure unless their remaining
security, privacy and product work is explicitly funded and tested.
