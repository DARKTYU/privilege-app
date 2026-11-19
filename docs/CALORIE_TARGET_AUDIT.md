# Calorie target audit

Read-only repository audit, 19 November 2026. This describes the checked-in
schema and app code; it does not inspect live Supabase data or verify the
deployed database schema. No code or SQL was changed or applied for this audit.

## Profile inputs

All columns below are in `public.profiles` in [schema.sql](../supabase/schema.sql).
The table definition allows each of them to be NULL. The generated
[`ProfileRow`](../lib/models/supabase_rows.dart) also represents them as
optional, but the app's separate `UserProfile` does not represent every field.

| Input | Existing database column | Collection and current behavior |
| --- | --- | --- |
| Weight | `weight_kg` (`numeric(5,2)`, positive if present) | [Onboarding](../lib/screens/onboarding.dart) requires 35–250 kg and rounds to whole kg; [Profile edit](../lib/screens/profile.dart) collects it too. Database may be NULL. Profile edit falls back to the existing in-memory value if parsing fails. |
| Height | `height_cm` (`numeric(5,2)`, positive if present) | Onboarding requires 120–230 cm and rounds to whole cm; Profile edit also collects it. Database may be NULL. |
| Age / birth date | `birth_date` (`date`) exists; there is no stored age column | No current onboarding or profile control collects it. It may be NULL. The app does not load it into `UserProfile`. |
| Sex | `gender` (`text`) exists, but it is not a validated, explicitly defined Mifflin sex input | No current screen collects it; it may be NULL. Decide the meaning and supported options before using this field; do not infer a sex coefficient from an unrelated gender identity. |
| Activity level | `activity_level` (`text`) | No current screen collects it; it may be NULL. There is no defined set of multiplier values or app-side mapping today. |
| Lose / maintain / gain | `goal` (`fitness_goal` enum: `lose`, `maintain`, `gain`) | May be NULL. Onboarding and Profile instead collect a detailed `training_goal` (`text`, also nullable). `AppState` writes a derived `goal`: metabolic fat loss -> lose, lean muscle hypertrophy -> gain, the other two -> maintain. It does not read `goal` back at sign-in. |

The sign-in query in [supabase_auth_service.dart](../lib/services/supabase_auth_service.dart)
loads weight, height, detailed training goal and the stored daily target, but
not birth date, gender, activity level or `goal`. When nullable weight, height,
training goal or daily target is missing, [state.dart](../lib/state.dart)
copies from `defaultUserProfile`: 78 kg, 182 cm, Natural Championship
Qualification and 2600 kcal respectively. This can make missing information
look like real user data; Profile edit may then save the fallback values.

## Current calorie target

[`user_profile.dart`](../lib/logic/user_profile.dart) calculates:

1. `BMR = round(10 * weight_kg + 6.25 * height_cm - 5 * 26 + 5)`.
   Age defaults to 26; `+5` is always used, regardless of the user.
2. `TDEE = round(BMR * 1.55)`; there is no personal activity multiplier.
3. Lowercase the **detailed training goal**: subtract 400 kcal if it contains
   `cut` or `championship`; add 300 if it contains `muscle` or `hypertrophy`;
   otherwise make no adjustment.

The onboarding screen calculates a preview and persists the result when setup
is completed. Profile editing recalculates and persists it on save, even if an
unrelated profile field was changed. Both use `profiles.daily_calorie_target`;
onboarding rounds weight and height first, while Profile uses its parsed
values. AppState loads the stored target on sign-in and copies it into
`targetCalories`; it also updates both values on onboarding/profile save.

**Mismatch:** `Metabolic Fat Loss & Calorie Deficit` is saved as `goal = lose`,
but its text contains neither `cut` nor `championship`, so the current formula
does **not** subtract 400 for it. `Natural Championship Qualification` is saved
as `goal = maintain`, yet its text triggers the 400 kcal subtraction. Lean
Muscle Mass Hypertrophy maps to gain and gets +300. Sports & Strength Split
Merger maps to maintain and gets no adjustment.

### Consumers of the computed/stored target

- Onboarding preview and persisted profile value; Profile's Calorie Goal stat.
- `AppState.targetCalories` supplies `calculateMacroTotals`. Initial/reset
  state uses 2500; missing stored profile values become 2600 via the default
  profile. `calculateMacroTotals` also has a standalone 2400 default, although
  AppState supplies its own target.
- The Food Log summary uses it for the calorie ring, remaining/over amount,
  goal text and derived macro goals.
- The Activity screen uses it for the Food Intake ring, Calories Consumed
  control, low-intake tip and the `Deficit Goal` percentage. That percentage
  is actually intake divided by calorie target, not a measured deficit.
- The legacy `calculateRadialSegments` helper computes its target segment from
  `MacroTotals.calorieTarget`; it is still used by a logic test but no longer
  by the Calories screen.

The tracked SQL contains the profile target column and update grant, but no
other SQL consumer of `daily_calorie_target` was found.

### The separate fixed 1800 balance

[`calculateCalorieBalance`](../lib/logic/fitness_logic.dart) defaults its `bmr`
argument to **1800** and computes `totalBurned = 1800 + logged active burn`
and `netDifference = consumed - totalBurned`. `AppState.calorieBalance` calls
it without overriding the default. The Activity card displays
`Estimated balance (BMR 1800)` and that net difference when its low-intake tip
is not shown. The helper also calculates surplus and deficit percentage.
`fitness_logic_test.dart` explicitly exercises it with 1800.

This is not the same quantity as the daily intake target. Replacing 1800 with
a TDEE-based target and then adding logged workouts would double-count activity
unless the product explicitly defines how exercise relates to the multiplier.
The Activity percentage labelled Deficit Goal similarly is not this balance.

## Macro goals

The current Food Log has no saved or individually configured macro goals.
[`_macroGoals`](../lib/screens/calories_food_summary.dart) derives them from
the same daily calorie target, rounded to whole grams: protein 30% / 4 kcal,
carbs 40% / 4 kcal, fat 30% / 9 kcal. It is marked `replaced in Stage 4`.
These are goals; the eaten values come from saved consumed meal snapshots.
The old manual form and quick adjustments also estimate meal macros, but those
are logged intake values, not daily goals.

## Smallest safe path to a personal target

1. **Reuse existing columns.** Weight, height, birth date, `gender`,
   `activity_level`, `goal` and `daily_calorie_target` already exist in the
   checked-in schema, so no new column is inherently required. Choose and
   document a suitable explicit sex/coefficient representation for Mifflin;
   reuse `gender` only if its meaning is appropriate, otherwise add a dedicated
   nullable field in a future migration. Define and validate allowed activity
   levels and goal values; decide whether database constraints/migration are
   needed for data quality. Do not silently reinterpret existing free text.
2. Add nullable fields to the app profile model, sign-in query and profile
   save/read paths. Keep missing values distinguishable from defaults. Collect
   birth date (derive age from the current date), the applicable sex
   coefficient, activity level and explicit lose/maintain/gain goal in
   Onboarding and Profile edit, alongside existing weight/height. Keep the
   separate detailed training goal if still needed; stop deriving nutrition
   goal from fragile goal-label substrings.
3. Implement and test one calculation: Mifflin-St Jeor BMR from weight,
   height, age and the chosen coefficient; multiply by a documented standard
   activity factor; apply a documented goal adjustment and rounding/validity
   policy. Set safe age/weight/height ranges and decide how to handle
   populations for whom this estimate is not appropriate. Do not assume age
   26 or +5 when inputs are missing.
4. Compute and persist one authoritative intake target when inputs change;
   keep `profile.dailyCalorieTarget` and `AppState.targetCalories` synchronized,
   and recalculate at an appropriate point after a birthday. Use this same
   target in onboarding preview, Profile, Food Log, macro goals, Activity ring,
   controls, tip and goal percentage. Review the standalone 2400 and 2500
   defaults so no alternate value is silently presented as personal.
5. For existing users with incomplete data, retain their previously stored
   target as a clearly labelled **legacy estimate**, and prompt them to complete
   the missing fields in Profile; do not overwrite real measurements with
   demo defaults. If no stored target exists, show an explicit unavailable /
   setup-needed state rather than inventing a personal value. Define the UX
   before implementation, including whether completing setup is optional.
6. Resolve the Activity balance separately: either show intake versus the one
   intake target, or clearly present a distinct expenditure estimate with a
   documented workout-counting policy. Do not label BMR as the calorie goal or
   add exercise twice to a multiplier that already includes it. If replacing
   the old balance, remove the fixed 1800 label and default consistently.
   Macro-goal policy is a separate choice; derive from the same authoritative
   target unless personalized macro goals are explicitly introduced.
7. Cover null/legacy profiles, all goal options, formula coefficients,
   activity factors, birthday boundary, profile load/save and every target
   display with tests; test that failed persistence does not publish an
   unsaved target.

## Existing tests touching the target

- [fitness_logic_test.dart](../test/fitness_logic_test.dart): estimated BMR
  with age 26 and relative cut/bulk comparison; explicit 1800 balance; macro
  totals supplied with a 2400 target and legacy radial segments. It does not
  verify exact values for all current goals.
- [calories_food_summary_test.dart](../test/calories_food_summary_test.dart):
  sets target to 100 and verifies over-target ring and text; mixed-day totals
  and theme coverage indirectly exercise the default target.
- [calories_screen_test.dart](../test/calories_screen_test.dart): verifies the
  Food Intake ring uses `300 / state.targetCalories` after a toggle.
- [supabase_rows_test.dart](../test/supabase_rows_test.dart): parses a sample
  profile row containing `daily_calorie_target`; it primarily asserts other row
  fields rather than a personal target calculation.
- [supabase_auth_test.dart](../test/supabase_auth_test.dart): mock profile
  fixture includes a NULL daily target; it is not an end-to-end assertion of
  the target fallback.

No focused test was found for onboarding/profile target persistence, the
fat-loss/championship mismatch, personal sex/activity inputs, birthday
recalculation, or exact 30/40/30 macro-goal values.
