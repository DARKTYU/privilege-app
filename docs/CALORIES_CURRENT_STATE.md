# Current Calories and meal storage

Read-only audit of the repository, November 2026. This describes existing
behavior, not a proposed change.

## What the app does today

- The Calories screen (`lib/screens/calories.dart`) shows today's meal and
  workout logs, calorie rings, macro totals and an estimated balance. Its add
  form accepts a name and calories and derives rough macros from the selected
  category rather than looking up a food. Quick-add also estimates macros;
  reducing a meal's calories does not recompute its macros.
- `MealItem` in `lib/logic/fitness_logic.dart` holds a name, time, calories,
  integer protein, carbs, fat and fiber, category, icon and consumed flag.
  `AppState` in `lib/state.dart` keeps today's meals and workouts in memory,
  reloads them after writes, and totals only consumed meals.
- `ActivityRepository` in `lib/services/activity_repository.dart` writes and
  reads the signed-in user's `meal_logs` directly. It calls
  `set_activity_timezone` and `activity_today` to determine the active local
  date. Activity guards permit inserts only for today in that timezone and
  prevent changing a log's owner or date. Meal changes also trigger existing
  activity, streak, rewards and Arena processing.

## Daily goal and balance

- Onboarding and profile editing calculate a recommended daily target from
  weight and height: estimated BMR uses an assumed age of 26 and a fixed +5
  term; the app multiplies BMR by 1.55, subtracts 400 for cut/championship
  goals or adds 300 for muscle/hypertrophy goals. The profile target is stored
  in `profiles.daily_calorie_target` and loaded into the Calories state.
- The displayed balance separately uses a **fixed 1800 kcal BMR** plus logged
  workout burn, not the personalized recommendation.

## What a future logged-food entry needs

`meal_logs` currently stores user ID, local date, meal type, name, calories,
protein, carbs, fat, fiber, category, icon and consumed status. It has no
food-database ID, portion grams, sugar or sodium fields. The separate
`food_items` table uses UUID IDs and is not connected to the bundled JSON's
string IDs or the existing meal log.

A future integration needs an agreed persistent representation for the JSON
food ID and grams, meal type and allowed local date, plus a snapshot of the
scaled calories and macros (including sugar and sodium if those are to be
retained). It must adapt the model, repository and database schema and respect
the existing RLS and activity triggers; changing those is outside this stage.
