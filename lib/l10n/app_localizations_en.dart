// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get communityHeading => 'Your community';

  @override
  String get communitySubtitle => 'Share progress and connect with others.';

  @override
  String get communityCreatePost => 'Create a post';

  @override
  String get communityFeed => 'Feed';

  @override
  String get communityPeople => 'People';

  @override
  String get communityGroups => 'Groups';

  @override
  String get communityFeedEmpty => 'No posts yet. Be the first to share!';

  @override
  String get communitySearchPeople => 'Search people';

  @override
  String get communityClearSearch => 'Clear search';

  @override
  String get communityFriendRequests => 'Friend requests';

  @override
  String get communityFriends => 'Friends';

  @override
  String get communityDiscoverPeople => 'People to discover';

  @override
  String get communityResults => 'Results';

  @override
  String get communityNoPeople =>
      'No people found. Try a different name or username.';

  @override
  String get communityTimeNow => 'now';

  @override
  String communityMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String communityHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String communityDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String communityPostTime(String username, String time) {
    return '@$username · $time';
  }

  @override
  String get coachTitle => 'Privilege Coach';

  @override
  String get coachAiBadge => 'AI';

  @override
  String get coachNewChat => 'New chat';

  @override
  String get coachClose => 'Close chat';

  @override
  String get coachInfo =>
      'AI can make mistakes - not medical advice - tap for details';

  @override
  String get coachAbout => 'About the coach';

  @override
  String get coachNoticeMistakes => 'The coach can make mistakes.';

  @override
  String get coachNoticeMedical =>
      'Not medical advice. For health problems, ask a doctor.';

  @override
  String get coachNoticeCloud =>
      'Messages are sent to Google Gemini to get a reply.';

  @override
  String get coachNoticePrivacy =>
      'Do not share personal or health details you do not want sent.';

  @override
  String get coachNoticeMemory =>
      'The coach does not remember earlier messages.';

  @override
  String get coachGotIt => 'Got it';

  @override
  String get coachConsent =>
      'Share my calorie target and today’s totals with the coach';

  @override
  String get coachWelcome => 'Hi! How can I help today?';

  @override
  String get coachTraining => 'Training ideas';

  @override
  String get coachProteinRecipe => 'High-protein recipe';

  @override
  String get coachCaloriesLeft => 'Calories left?';

  @override
  String get coachSnacks => 'Snack ideas';

  @override
  String get coachResponding => 'Coach is responding…';

  @override
  String coachRequestsLeft(String count) {
    return 'Requests left today: $count';
  }

  @override
  String get coachInputHint => 'Message the coach';

  @override
  String get coachSend => 'Send';

  @override
  String coachCounter(String count) {
    return '$count/2000';
  }

  @override
  String get coachPreferenceError =>
      'Could not save or load consent. Please try again.';

  @override
  String get coachSignInError => 'Sign in with an account to use the coach.';

  @override
  String get coachBirthDateError =>
      'Add your birth date in Profile to use the coach.';

  @override
  String get coachAgeError => 'The AI coach is for users 18 and over.';

  @override
  String get coachQuotaError => 'Daily limit reached.';

  @override
  String coachQuotaResetError(String date) {
    return 'Daily limit reached. Resets: $date';
  }

  @override
  String get coachUnavailable => 'The coach is unavailable right now.';

  @override
  String get coachLocalHelp =>
      'Local help (not AI): ask about your calories, weekly plan or streak in the app.';

  @override
  String coachUnavailableHelp(String error, String help) {
    return '$error\n\n$help';
  }

  @override
  String get coachTryAgain => 'Try again';

  @override
  String get recipeSignIn => 'Sign in to save favorites.';

  @override
  String recipeLoadFavoritesError(String error) {
    return 'Could not load favorites: $error';
  }

  @override
  String recipeSaveFavoriteError(String error) {
    return 'Could not save favorite: $error';
  }

  @override
  String get recipeDeviceSaveError => 'The device did not save the favorite.';

  @override
  String recipeLogged(String name, String kcal) {
    return 'Logged $name ($kcal kcal)';
  }

  @override
  String recipeLogError(String error) {
    return 'Could not log recipe: $error';
  }

  @override
  String get recipeDatabaseError => 'Could not load the food database.';

  @override
  String get recipeSampleNotice =>
      'Sample recipes. Favorites are saved on this device.';

  @override
  String get recipeLoadingActivity => 'Loading today’s activity...';

  @override
  String get recipeActivityUnavailable => 'Today’s activity is unavailable.';

  @override
  String get recipeTargetUnavailable => 'Daily target unavailable.';

  @override
  String recipeRemaining(String kcal, String protein) {
    return 'Remaining today: $kcal kcal · $protein g protein';
  }

  @override
  String get recipeTargetReached => 'You have reached today\'s target';

  @override
  String get recipeBestFit => 'Best fit for today';

  @override
  String get recipeAll => 'All recipes';

  @override
  String get recipeFilterAll => 'All';

  @override
  String get recipeFits => 'Fits today';

  @override
  String get recipeHighProtein => 'High protein';

  @override
  String get recipeHighFiber => 'High fiber';

  @override
  String get recipeLight => 'Light';

  @override
  String get recipeQuick => 'Quick';

  @override
  String get recipeRetryFavorites => 'Retry favorites';

  @override
  String get recipeNoMatches => 'No recipes match this filter.';

  @override
  String get recipeRemoveFavorite => 'Remove favorite';

  @override
  String get recipeAddFavorite => 'Add favorite';

  @override
  String recipeKcal(String amount) {
    return '$amount kcal';
  }

  @override
  String recipeMacro(String amount, String macro) {
    return '$amount g $macro';
  }

  @override
  String recipeSummary(String minutes, String difficulty, String meal) {
    return '$minutes min · $difficulty · $meal';
  }

  @override
  String get recipeDifficultyEasy => 'Easy';

  @override
  String get recipeDifficultyEasyMedium => 'Easy / Medium';

  @override
  String get recipeDifficultyInstant => 'Instant';

  @override
  String get recipeEstimated => 'Estimated from ingredients';

  @override
  String recipeOver(String kcal) {
    return 'Over by $kcal kcal';
  }

  @override
  String get recipeNutritionUnavailable => 'Nutrition not available';

  @override
  String get recipeLogging => 'Logging...';

  @override
  String get recipeLog => 'Log';

  @override
  String get recipePhotosError => 'Could not load recipe photos.';

  @override
  String get recipePhotoIllustration => 'Photo is for illustration';

  @override
  String recipePhotoCredit(String credit) {
    return 'Photo: $credit';
  }

  @override
  String get recipeDetails => 'Recipe details';

  @override
  String get recipeNutritionPerServing => 'Nutrition per serving';

  @override
  String recipeMacroLine(String protein, String carbs, String fat) {
    return 'Protein $protein g · Carbs $carbs g · Fat $fat g';
  }

  @override
  String recipeMicroLine(String fiber, String sugar, String sodium) {
    return 'Fiber $fiber g · Sugar $sugar g · Sodium $sodium mg';
  }

  @override
  String get recipeIngredients => 'Ingredients';

  @override
  String recipeIngredientAmount(String name, String amount) {
    return '$name: $amount g';
  }

  @override
  String get recipeIngredientUnavailable => 'Ingredient details unavailable.';

  @override
  String get recipeHowToCook => 'How to cook';

  @override
  String recipeStep(String number, String step) {
    return '$number. $step';
  }

  @override
  String get cravingLogin => 'Please log in again.';

  @override
  String cravingLoadError(String error) {
    return 'Could not load cravings: $error';
  }

  @override
  String cravingLimitError(String error) {
    return 'The selected month already has 2 cravings. $error';
  }

  @override
  String cravingSaveError(String error) {
    return 'Could not save: $error';
  }

  @override
  String get cravingValidate => 'Enter 1 to 200 characters.';

  @override
  String get cravingDeleteTitle => 'Delete craving?';

  @override
  String get cravingPreviousMonth => 'Previous month';

  @override
  String get cravingNextMonth => 'Next month';

  @override
  String get cravingMonday => 'M';

  @override
  String get cravingTuesday => 'T';

  @override
  String get cravingWednesday => 'W';

  @override
  String get cravingThursday => 'T';

  @override
  String get cravingFriday => 'F';

  @override
  String get cravingSaturday => 'S';

  @override
  String get cravingSunday => 'S';

  @override
  String cravingUsed(String count) {
    return '$count of 2 used this month';
  }

  @override
  String get cravingMonthlyLimit =>
      'Monthly limit reached. Edit or delete an entry to make room.';

  @override
  String cravingDay(String day) {
    return 'Craving for day $day';
  }

  @override
  String get cravingCharacters => '1 to 200 characters';

  @override
  String get cravingAdd => 'Add craving';

  @override
  String get cravingEmpty => 'No meals added yet.';

  @override
  String get cravingEdit => 'Edit';

  @override
  String get cravingEditTitle => 'Edit craving';

  @override
  String get cravingNotes => 'Notes';

  @override
  String cravingDate(String date) {
    return 'Date: $date';
  }

  @override
  String get academyAllGuides => 'All Guides';

  @override
  String get academyGymLifts => 'Gym Lifts';

  @override
  String get academySportMechanics => 'Sport Mechanics';

  @override
  String get academyStarterRules => 'Starter Rules';

  @override
  String get academyDisclaimer =>
      'General information, not professional advice. Check with a qualified coach or doctor.';

  @override
  String get academyCues => 'Key Execution Cues';

  @override
  String get academyMistakes => 'Common Mistakes to Avoid';

  @override
  String get academyMastered => 'Mastered Cue';

  @override
  String get academySubtitle =>
      'Biomechanical masterclasses for gym lifts, sports conditioning & fitness foundations.';

  @override
  String get academySearch => 'Search bench, squats, basketball, nutrition...';

  @override
  String get academyEmpty => 'No guides match your search.';

  @override
  String academyMuscles(String muscles) {
    return 'Muscles: $muscles';
  }

  @override
  String academyBurn(String kcal, String minutes) {
    return 'about $kcal kcal / $minutes mins';
  }

  @override
  String get academyLifetime => 'Lifetime Knowledge';

  @override
  String get academyLearn => 'Learn';

  @override
  String get plannerTitle => 'Plan Organiser';

  @override
  String get plannerSubtitle => 'Weekly calendar & schedule planner';

  @override
  String get plannerCancel => 'Cancel';

  @override
  String get plannerDelete => 'Delete';

  @override
  String get plannerSave => 'Save';

  @override
  String get plannerRetry => 'Retry';

  @override
  String get plannerAddSplit => 'Add Split';

  @override
  String get plannerEditSplit => 'Edit split';

  @override
  String get plannerEditDay => 'Edit this day';

  @override
  String get plannerPlanDay => 'Plan this day';

  @override
  String get plannerRestDay => 'Rest day';

  @override
  String get plannerRest => 'Rest';

  @override
  String get plannerWorkout => 'Workout';

  @override
  String get plannerSplitUnavailable => 'The split is no longer available.';

  @override
  String get plannerLogOnlyToday =>
      'Logging is available on the workout day only.';

  @override
  String get plannerPreviousWeek => 'Previous week';

  @override
  String get plannerNextWeek => 'Next week';

  @override
  String get plannerPlannedWorkout => 'Planned workout';

  @override
  String get plannerCompletedWorkout => 'Completed workout';

  @override
  String get plannerRestLegend => '— Rest day';

  @override
  String get plannerNothingPlanned => 'Nothing planned for this day.';

  @override
  String get plannerWorkoutLogged => 'Workout logged';

  @override
  String get plannerWorkoutNotLogged => 'Workout not logged';

  @override
  String get plannerRemove => 'Remove';

  @override
  String get plannerRemoveDayTitle => 'Remove planned day?';

  @override
  String get plannerRemoveDayDetails => 'This does not delete any workout log.';

  @override
  String get plannerLogWorkout => 'Log this workout';

  @override
  String get plannerAvailableOnDay => 'Available on the day';

  @override
  String get plannerMySplits => 'My splits';

  @override
  String get plannerNoSplits =>
      'No splits yet. Create one or add starter splits.';

  @override
  String get plannerCreateFirst => 'Create your first split';

  @override
  String get plannerAddStarters => 'Add starter splits';

  @override
  String get plannerDeleteDetails =>
      'Days already planned will stay unchanged.';

  @override
  String get plannerDeleteExplanation =>
      'Deleting a split keeps the days already planned.';

  @override
  String get plannerToday => 'Today';

  @override
  String get plannerName => 'Name';

  @override
  String get plannerType => 'Type';

  @override
  String get plannerDuration => 'Duration (minutes)';

  @override
  String get plannerDurationHint => '1 to 600 minutes';

  @override
  String get plannerEffort => 'Effort (%)';

  @override
  String get plannerEffortHint => '0 to 100';

  @override
  String get plannerInvalidName => 'Enter a name between 1 and 100 characters.';

  @override
  String get plannerInvalidDuration => 'Enter 1 to 600 minutes.';

  @override
  String get plannerInvalidEffort => 'Enter effort from 0 to 100%.';

  @override
  String get plannerPush => 'Push';

  @override
  String get plannerPull => 'Pull';

  @override
  String get plannerLegs => 'Legs';

  @override
  String plannerSaveError(String error) {
    return 'Could not save: $error';
  }

  @override
  String plannerLoadError(String error) {
    return 'Could not load planner: $error';
  }

  @override
  String plannerOpenError(String error) {
    return 'Could not open workout logger: $error';
  }

  @override
  String plannerSelectedDay(String date) {
    return 'Selected day: $date';
  }

  @override
  String plannerWorkoutSummary(String minutes, String effort) {
    return 'Workout · $minutes min · $effort% effort';
  }

  @override
  String plannerSplitSummary(String minutes, String effort) {
    return '$minutes min · $effort% effort';
  }

  @override
  String plannerEditName(String name) {
    return 'Edit $name';
  }

  @override
  String plannerDeleteName(String name) {
    return 'Delete $name';
  }

  @override
  String plannerDeleteQuestion(String name) {
    return 'Delete $name?';
  }

  @override
  String get splitPushDay => 'Push Day';

  @override
  String get splitPullDay => 'Pull Day';

  @override
  String get splitLegDay => 'Leg Day Hypertrophy';

  @override
  String get splitUpper => 'Upper Body Power';

  @override
  String get splitCalisthenics => 'Calisthenics & Core';

  @override
  String get splitOlympic => 'Olympic Weightlifting';

  @override
  String get sportBasketball => 'Basketball';

  @override
  String get sportFootball => 'Football / Soccer';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get sportBoxing => 'Boxing / MMA';

  @override
  String get sportSwimming => 'Swimming Laps';

  @override
  String get sportSprints => 'Track Sprint Intervals';

  @override
  String get intensityLight => 'Light';

  @override
  String get intensityModerate => 'Moderate';

  @override
  String get intensityVigorous => 'Vigorous';

  @override
  String get mergeTitle => 'Splits & Sports Merge';

  @override
  String get mergeSubtitle => 'Combine gym splits with daily sports.';

  @override
  String get mergeManage => 'Manage splits';

  @override
  String get mergeSignIn => 'Please log in again.';

  @override
  String get mergeInvalidTotal =>
      'Enter valid durations with a combined total of 1 to 600 minutes.';

  @override
  String get mergeNameTooLong =>
      'The combined name must be 100 characters or fewer.';

  @override
  String get mergeReplaceTitle => 'Replace existing plan?';

  @override
  String get mergeReplace => 'Replace';

  @override
  String get mergeSuccess => 'Planned successfully.';

  @override
  String get mergeWorkoutSplit => 'Workout split';

  @override
  String get mergeSplit => 'Split';

  @override
  String get mergeSport => 'Sport';

  @override
  String get mergeUnavailable => 'Unavailable';

  @override
  String get mergeInvalidDuration => 'Invalid duration';

  @override
  String get mergeSprintEstimate =>
      'Track sprint intervals use the HIIT or circuit estimate.';

  @override
  String get mergeAddWeight => 'Calorie estimate unavailable - add your weight';

  @override
  String get mergeCompleteProfile => 'Complete your profile';

  @override
  String get mergeSportUnavailable =>
      'Calorie estimate unavailable for this sport.';

  @override
  String get mergeEstimateNote =>
      'Estimate based on activity type, duration, intensity and your weight.';

  @override
  String get mergePlanDate => 'Plan on a date';

  @override
  String get mergeLogWorkout => 'Log workout';

  @override
  String get mergeLogSport => 'Log sport';

  @override
  String get mergePlannerEffort => 'Planner effort (%)';

  @override
  String get mergeContinue => 'Continue';

  @override
  String mergeLoadError(String error) {
    return 'Could not load splits: $error';
  }

  @override
  String mergePlanError(String error) {
    return 'Could not plan: $error';
  }

  @override
  String mergeReplaceDetails(String date, String name) {
    return '$date already has \"$name\". Replace it?';
  }

  @override
  String mergeSavedName(String name) {
    return '$name (My split)';
  }

  @override
  String mergeMinutesLabel(String label) {
    return '$label minutes';
  }

  @override
  String mergeCombinedDuration(String duration) {
    return 'Combined duration: $duration';
  }

  @override
  String mergeMinutes(String minutes) {
    return '$minutes minutes';
  }

  @override
  String mergeShortMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String mergeNamedValue(String name, String value) {
    return '$name: $value';
  }

  @override
  String mergeCalories(String calories) {
    return '$calories kcal';
  }

  @override
  String mergeEstimatedCalories(String value) {
    return 'Estimated calories burned: $value';
  }

  @override
  String mergeDate(String date) {
    return 'Date: $date';
  }

  @override
  String get caloriesSubtitle => 'Meals, macros & activity';

  @override
  String get foodLog => 'Food Log';

  @override
  String get activity => 'Activity';

  @override
  String get foodUnavailable =>
      'This food is no longer available in the food database. The meal was not changed.';

  @override
  String foodOpenError(String error) {
    return 'Could not open food: $error';
  }

  @override
  String activitySaveError(String error) {
    return 'Could not save activity: $error';
  }

  @override
  String burnedAmount(String amount) {
    return '$amount kcal burned';
  }

  @override
  String deleteNamed(String name) {
    return 'Delete $name';
  }

  @override
  String get noWorkouts => 'No workouts logged today yet.';

  @override
  String get manualInvalidCalories =>
      'Enter a calorie amount greater than zero.';

  @override
  String get manualTitle => 'Log Nutrition or Workout Burn';

  @override
  String get manualFood => 'Food Intake (+)';

  @override
  String get manualBurn => 'Workout Burn (+)';

  @override
  String get manualFoodHint => 'e.g. Grass-fed Steak';

  @override
  String get manualBurnHint => 'e.g. Olympic Lifts';

  @override
  String get caloriesKcal => 'Calories (kcal)';

  @override
  String get manualProtein => '🔴 Protein';

  @override
  String get manualCarbs => '🔵 Carbs';

  @override
  String get manualFats => '🟠 Fats';

  @override
  String get manualGreens => '🟢 Greens';

  @override
  String get manualStrength => '🟡 Strength / Gym';

  @override
  String get manualCardio => '🔷 Cardio / Sports';

  @override
  String get manualMobility => '🟢 Mobility / Stage';

  @override
  String get saveActivity => 'Save activity';

  @override
  String get activityTitle => 'Activity Rings & Workouts';

  @override
  String get activitySubtitle => 'Track workouts and calories burned';

  @override
  String get burned => 'Burned';

  @override
  String burnTarget(String amount) {
    return '/ $amount kcal target';
  }

  @override
  String get burnGoalNote => 'Daily burn goal • total includes mobility';

  @override
  String get burnRingNote => 'Each ring uses the daily burn goal.';

  @override
  String totalBurn(String amount) {
    return 'Total burn ($amount kcal)';
  }

  @override
  String strengthBurn(String amount) {
    return 'Strength burn ($amount kcal)';
  }

  @override
  String cardioBurn(String amount) {
    return 'Cardio burn ($amount kcal)';
  }

  @override
  String get burnStats => 'Burn Stats';

  @override
  String get strengthBurnLabel => 'Strength Burn';

  @override
  String get cardioBurnLabel => 'Cardio Burn';

  @override
  String get burnTypeStrength => 'strength';

  @override
  String get burnTypeCardio => 'cardio';

  @override
  String get burnTypeMobility => 'mobility';

  @override
  String workoutLogs(String count) {
    return 'Workout Logs ($count)';
  }

  @override
  String get workoutInvalidDuration =>
      'Enter a duration between 1 and 600 minutes.';

  @override
  String get workoutInvalidCalories => 'Enter calories between 0 and 5000.';

  @override
  String get workoutSaved => 'Workout logged.';

  @override
  String get workoutRefreshError =>
      'Saved, but the activity list could not be refreshed. Please retry.';

  @override
  String workoutSaveError(String error) {
    return 'Could not save workout: $error';
  }

  @override
  String get workoutStrength => 'Strength training';

  @override
  String get workoutWalking => 'Walking';

  @override
  String get workoutRunning => 'Running';

  @override
  String get workoutCycling => 'Cycling';

  @override
  String get workoutSwimming => 'Swimming';

  @override
  String get workoutFootball => 'Football';

  @override
  String get workoutBasketball => 'Basketball';

  @override
  String get workoutTennis => 'Tennis';

  @override
  String get workoutCircuit => 'HIIT or circuit';

  @override
  String get workoutMartialArts => 'Boxing or martial arts';

  @override
  String get workoutYoga => 'Yoga or stretching';

  @override
  String get workoutJumpRope => 'Jump rope';

  @override
  String get workoutOther => 'Other';

  @override
  String workoutActivityLabel(String icon, String name) {
    return '$icon $name';
  }

  @override
  String workoutSavedTitle(String name, String minutes) {
    return '$name - $minutes min';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get workoutIntensity => 'Intensity';

  @override
  String get workoutEstimateUnavailable =>
      'Estimate unavailable — enter calories manually.';

  @override
  String workoutEstimate(String amount) {
    return '≈ $amount kcal burned';
  }

  @override
  String get workoutFormula => 'MET x weight x hours';

  @override
  String get workoutEstimateNote => 'Calorie burn is an estimate.';

  @override
  String get workoutManualOther => 'Other activities require manual calories.';

  @override
  String get workoutCaloriesEditable => 'Calories burned (editable)';

  @override
  String get workoutCaloriesHint => '0 to 5000 kcal';

  @override
  String get workoutUseEstimate => 'Use estimate';

  @override
  String get workoutSaving => 'Saving...';

  @override
  String get workoutSave => 'Save workout';

  @override
  String get foodEaten => 'kcal eaten';

  @override
  String get foodBalance => 'DAILY ENERGY BALANCE';

  @override
  String get foodTargetUnavailable => 'target unavailable';

  @override
  String get foodOver => 'kcal over';

  @override
  String get foodLeft => 'kcal left';

  @override
  String get foodEstimated => ' • Estimated';

  @override
  String foodGoalSummary(String goal, String estimated, String count) {
    return 'Goal: $goal$estimated • Logged items: $count';
  }

  @override
  String get foodProtein => 'Protein';

  @override
  String get foodCarbs => 'Carbs';

  @override
  String get foodFats => 'Fats';

  @override
  String get foodFiber => 'Fiber';

  @override
  String get foodSugar => 'Sugar';

  @override
  String get foodSodium => 'Sodium';

  @override
  String foodGrams(String amount) {
    return '$amount g';
  }

  @override
  String foodMilligrams(String amount) {
    return '$amount mg';
  }

  @override
  String foodMacroGoal(String eaten, String goal) {
    return '$eaten / $goal g';
  }

  @override
  String foodLabelValue(String label, String value) {
    return '$label $value';
  }

  @override
  String get foodAdd => 'Add food';

  @override
  String get foodCompleteProfile =>
      'Complete your profile for an accurate target';

  @override
  String get foodDismissReminder => 'Dismiss profile reminder';

  @override
  String get foodToday => 'Today\'s Food Log';

  @override
  String get foodAll => 'All';

  @override
  String get foodBreakfast => 'Breakfast';

  @override
  String get foodLunch => 'Lunch';

  @override
  String get foodDinner => 'Dinner';

  @override
  String get foodSnacks => 'Snacks';

  @override
  String get foodSnacksHeading => 'Snacks & Toppings';

  @override
  String get foodEmpty => 'Your daily log is empty';

  @override
  String get foodEmptyHint => 'Add a meal to start tracking today.';

  @override
  String foodHeading(String icon, String name) {
    return '$icon $name';
  }

  @override
  String foodGroupTotals(String calories, String protein) {
    return '$calories kcal • ${protein}g P';
  }

  @override
  String foodNoItems(String meal) {
    return 'No items logged for $meal.';
  }

  @override
  String foodUncheck(String name) {
    return 'Uncheck $name';
  }

  @override
  String foodLogNamed(String name) {
    return 'Log $name';
  }

  @override
  String get foodManualEntry => 'Manual entry';

  @override
  String foodCustomGrams(String amount) {
    return '$amount g custom';
  }

  @override
  String foodServing(String name, String amount) {
    return '$name ($amount)';
  }

  @override
  String foodProteinShort(String amount) {
    return '$amount P';
  }

  @override
  String foodCarbsShort(String amount) {
    return '$amount C';
  }

  @override
  String foodFatsShort(String amount) {
    return '$amount F';
  }

  @override
  String foodCaloriesLines(String amount) {
    return '$amount\nkcal';
  }

  @override
  String foodEditPortion(String name) {
    return 'Edit portion $name';
  }

  @override
  String foodDuplicate(String name) {
    return 'Duplicate $name';
  }

  @override
  String get foodDuplicateUnavailable =>
      'This food is no longer available to duplicate.';

  @override
  String get foodSavedRefreshError =>
      'Food was saved, but the activity list could not be refreshed. Please retry.';

  @override
  String get foodDeletedRefreshError =>
      'Food was deleted, but the activity list could not be refreshed. Please retry.';

  @override
  String get foodDuplicated => 'Food duplicated.';

  @override
  String get foodDeleted => 'Food deleted.';

  @override
  String foodDuplicateError(String error) {
    return 'Could not duplicate food: $error';
  }

  @override
  String foodDeleteError(String error) {
    return 'Could not delete food: $error';
  }

  @override
  String foodUpdateError(String error) {
    return 'Could not update meal: $error';
  }

  @override
  String get explorerLoadError => 'Could not load the food database.';

  @override
  String get explorerManual => 'Can\'t find it? Quick add manually';

  @override
  String get explorerSearch => 'Search foods in English or Arabic...';

  @override
  String get explorerClear => 'Clear search';

  @override
  String explorerShowing(String shown, String total) {
    return 'Showing $shown of $total';
  }

  @override
  String get explorerEmpty => 'No matching foods found';

  @override
  String get explorerEmptyHint => 'Try another search or remove a filter.';

  @override
  String get explorerDisclaimer =>
      'Nutrition values are approximate estimates.';

  @override
  String explorerPer100(String calories) {
    return 'Per 100 g: $calories kcal';
  }

  @override
  String get explorerLog => '+ Log';

  @override
  String get explorerStandard => '100 g standard reference';

  @override
  String get explorerInvalidWeight => 'Enter a weight between 1 and 3000 g.';

  @override
  String explorerUpdated(String name) {
    return 'Updated $name.';
  }

  @override
  String explorerLogged(String name, String calories) {
    return 'Logged $name ($calories kcal)';
  }

  @override
  String explorerSaveError(String error) {
    return 'Could not save food: $error';
  }

  @override
  String get explorerPortions => 'Quick Household & Restaurant Portions';

  @override
  String get explorerExactWeight => 'Exact Weight (Grams)';

  @override
  String get unitGrams => 'g';

  @override
  String explorerNutrient(String name, String amount) {
    return '$name: $amount';
  }

  @override
  String get explorerMeal => 'Log to Meal';

  @override
  String get explorerAdd => '+ Add to Daily Log';

  @override
  String get explorerSaveChanges => 'Save changes';

  @override
  String get foodFat => 'Fat';

  @override
  String get foodSnackSingular => 'Snack';

  @override
  String get groupAmerican => 'American & Latin';

  @override
  String get groupAsian => 'Asian';

  @override
  String get groupCafes => 'Cafes & Bakeries';

  @override
  String get groupEgyptian => 'Egyptian';

  @override
  String get groupEuropean => 'European';

  @override
  String get groupMiddleEastern => 'Middle Eastern & African';

  @override
  String get groupRaw => 'Raw & Fitness Staples';

  @override
  String get groupRestaurants => 'Restaurants & Fast Food';

  @override
  String get groupSnacks => 'Snacks';

  @override
  String get tagProtein => 'High Protein';

  @override
  String get tagFitness => 'Fitness Staple';

  @override
  String get tagStreet => 'Street Food';

  @override
  String get tagVegan => 'Vegan';

  @override
  String get tagKeto => 'Keto Friendly';

  @override
  String get tagLowCarb => 'Low Carb';

  @override
  String get tagOils => 'Oils';

  @override
  String get tagToppings => 'Toppings';

  @override
  String get tagDesserts => 'Desserts';

  @override
  String get tagRaw => 'Raw';

  @override
  String get tagCooked => 'Cooked';

  @override
  String get profileInvalid =>
      'Enter a valid birth date (age 13–100), sex, activity, weight (30–300 kg), and height (120–230 cm).';

  @override
  String profileSaveError(String error) {
    return 'Could not save your profile. Please try again.';
  }

  @override
  String get profileWeight => 'Weight (kg)';

  @override
  String get profileHeight => 'Height (cm)';

  @override
  String get profileChooseBirth => 'Choose birth date';

  @override
  String profileBirth(String date) {
    return 'Birth date: $date';
  }

  @override
  String get profileSex => 'Sex for the estimate';

  @override
  String get profileMale => 'Male';

  @override
  String get profileFemale => 'Female';

  @override
  String get profileUnspecified => 'Prefer not to say';

  @override
  String get profileActivity => 'Activity level';

  @override
  String get profileSedentary => 'Sedentary';

  @override
  String get profileSedentaryDescription => 'Mostly sitting, little exercise.';

  @override
  String get profileLightDescription => 'Light exercise 1–3 days per week.';

  @override
  String get profileModerateDescription => 'Exercise 3–5 days per week.';

  @override
  String get profileVeryActive => 'Very active';

  @override
  String get profileVeryActiveDescription => 'Hard exercise 6–7 days per week.';

  @override
  String get profileAthlete => 'Athlete';

  @override
  String get profileAthleteDescription =>
      'Very demanding daily training or physical work.';

  @override
  String profileTarget(String target, String estimated) {
    return 'Your daily target: $target$estimated';
  }

  @override
  String profileBmr(String bmr, String maintenance) {
    return 'BMR: $bmr • Maintenance: $maintenance';
  }

  @override
  String get profileCompleteFields =>
      'Complete all fields for a personal estimate.';

  @override
  String profileAdjustment(String amount, String minor) {
    return 'Goal adjustment: $amount kcal$minor';
  }

  @override
  String get profileMinor => ' (maintenance for under 18)';

  @override
  String get profileDisclaimer => 'Estimates are not medical advice.';

  @override
  String get profileSave => 'Save profile';

  @override
  String get memberFree => 'Free';

  @override
  String get memberSilver => 'Silver';

  @override
  String get memberGold => 'Gold';

  @override
  String get membershipTitle => 'Privilege membership';

  @override
  String get membershipLoading => 'Loading membership...';

  @override
  String get membershipUnavailable => 'Membership unavailable';

  @override
  String get membershipUnavailableConnection =>
      'Membership unavailable. Check your connection.';

  @override
  String membershipCurrent(String tier) {
    return 'Current membership: $tier';
  }

  @override
  String membershipProfile(String tier) {
    return 'Privilege $tier Member';
  }

  @override
  String get membershipRetry => 'Retry membership';

  @override
  String get membershipBenefits => 'Available in the app';

  @override
  String get membershipFood => 'Food and workout logging';

  @override
  String get membershipCommunity => 'Community and streak tracking';

  @override
  String get membershipAcademy => 'Academy exercise guides';

  @override
  String get membershipRewards => 'Rewards and achievements';

  @override
  String get membershipSplits => 'Create and save custom splits';

  @override
  String membershipBenefit(String benefit) {
    return '• $benefit';
  }

  @override
  String get membershipComingSoon =>
      'Coming soon. Payments are not available yet.';

  @override
  String get profileTitle => 'Athlete Profile';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileUpdated => 'Profile successfully updated!';

  @override
  String get profileFullName => 'Full Name';

  @override
  String get profileFullNameHint => 'Full name';

  @override
  String get profileGoal => 'Target Goal';

  @override
  String get profileChooseGoal => 'Choose a target goal';

  @override
  String get profileBio => 'Athlete bio';

  @override
  String profileHandle(String username) {
    return '@$username';
  }

  @override
  String get profileSaveChanges => 'Save Changes';

  @override
  String get profileAddBio => 'Add a bio';

  @override
  String profileQuotedBio(String bio) {
    return '“$bio”';
  }

  @override
  String get profileCurrentWeight => 'Current Weight';

  @override
  String get profileHeightLabel => 'Height';

  @override
  String get profileCalorieGoal => 'Calorie Goal';

  @override
  String get profileNotSet => 'Not set';

  @override
  String profileKg(String amount) {
    return '$amount kg';
  }

  @override
  String profileCm(String amount) {
    return '$amount cm';
  }

  @override
  String profileCalorieValue(String amount, String estimated) {
    return '$amount$estimated';
  }

  @override
  String get profileCompleteCalorie => 'Complete your calorie profile';

  @override
  String get profileEditCalorie => 'Edit calorie profile';

  @override
  String get profileRewards => 'Rewards Store';

  @override
  String get profileBadges => 'Badges & Achievements';

  @override
  String get profileActiveTarget => 'Active Target:';

  @override
  String get profileTrack => 'Track →';

  @override
  String get profileSignOut => 'Sign Out of Privilege';

  @override
  String get alertsUnavailable => 'Alerts (updates unavailable)';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsTryAgain => 'Try again';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get alertsMarkRead => 'Mark all as read';

  @override
  String get alertsEmpty => 'You are all caught up.';

  @override
  String get alertsGroupMissing => 'This group is no longer available.';

  @override
  String get alertsNoDestination => 'This alert has no destination.';

  @override
  String get alertsLikes => 'Likes';

  @override
  String get alertsComments => 'Comments';

  @override
  String get alertsFriendPosts => 'Friend posts';

  @override
  String get alertsFriendRequests => 'Friend requests, acceptances and follows';

  @override
  String get alertSomeone => 'Someone';

  @override
  String alertFriendRequest(String name) {
    return '$name sent you a friend request.';
  }

  @override
  String alertFriendAccepted(String name) {
    return '$name accepted your friend request.';
  }

  @override
  String alertCommentBody(String name, String body) {
    return '$name commented: $body';
  }

  @override
  String alertComment(String name) {
    return '$name commented on your post.';
  }

  @override
  String alertPostLike(String name) {
    return '$name liked your post.';
  }

  @override
  String alertCommentLike(String name) {
    return '$name liked your comment.';
  }

  @override
  String alertFollow(String name) {
    return '$name started following you.';
  }

  @override
  String alertFriendPost(String name) {
    return '$name shared a new post.';
  }

  @override
  String alertChallengeInvite(String name) {
    return '$name invited you to a challenge.';
  }

  @override
  String get alertChallengeResult => 'Your challenge results are ready.';

  @override
  String get alertBadge => 'You earned a badge!';

  @override
  String get alertAchievement => 'You completed an achievement!';

  @override
  String get alertLevel => 'You reached a new level!';

  @override
  String get alertReward => 'Your reward has been redeemed.';

  @override
  String alertGroupRequest(String name) {
    return '$name requested to join your group.';
  }

  @override
  String alertGroupApproved(String name) {
    return '$name approved your group request.';
  }

  @override
  String alertGroupRemoved(String name) {
    return '$name removed you from a group.';
  }

  @override
  String alertGroupBanned(String name) {
    return '$name banned you from a group.';
  }

  @override
  String alertGroupInvited(String name) {
    return '$name invited you to a group.';
  }

  @override
  String get alertUnknown => 'You have a new notification.';

  @override
  String get progressLoadError =>
      'Could not load progress. Check your connection.';

  @override
  String get progressNoLevels => 'No levels are available yet.';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelPro => 'Pro';

  @override
  String get levelBronze => 'Bronze';

  @override
  String get levelSilver => 'Silver';

  @override
  String get levelGold => 'Gold';

  @override
  String get levelPlatinum => 'Platinum';

  @override
  String get levelDiamond => 'Diamond';

  @override
  String get levelElite => 'Elite';

  @override
  String get levelChampion => 'Champion';

  @override
  String progressLevel(String name) {
    return 'Level: $name';
  }

  @override
  String progressHighest(String xp) {
    return '$xp XP · Highest level';
  }

  @override
  String progressNext(String xp, String remaining, String name) {
    return '$xp XP · $remaining XP to $name';
  }

  @override
  String progressFreeze(String count) {
    return 'Freeze tokens: $count';
  }

  @override
  String progressPoints(String count) {
    return '$count store points';
  }

  @override
  String rewardConfirm(String name) {
    return 'Redeem $name?';
  }

  @override
  String rewardSpend(String count) {
    return 'Spend $count store points?';
  }

  @override
  String get rewardRedeem => 'Redeem';

  @override
  String get rewardRequestSaveError => 'Could not save the redemption request.';

  @override
  String get rewardRequestClearError =>
      'Could not clear the completed redemption request.';

  @override
  String get rewardDone => 'Reward redeemed.';

  @override
  String rewardFreezeCount(String count) {
    return 'Freeze tokens: $count / 3';
  }

  @override
  String get rewardInfo =>
      'Digital items only. Themes, frames and titles are saved to your rewards; applying them is not available yet.';

  @override
  String get rewardEmpty => 'No rewards are available right now.';

  @override
  String get rewardUnlimited => 'Unlimited stock';

  @override
  String rewardRemaining(String count) {
    return '$count remaining';
  }

  @override
  String rewardDetails(String cost, String tier, String stock) {
    return '$cost points · $tier tier · $stock';
  }

  @override
  String rewardRequires(String tier) {
    return 'Requires $tier tier';
  }

  @override
  String rewardNeedPoints(String count) {
    return 'Need $count more points';
  }

  @override
  String get rewardRedeeming => 'Redeeming...';

  @override
  String get rewardOwned => 'Owned';

  @override
  String get rewardOutOfStock => 'Out of stock';

  @override
  String get rewardErrorPoints => 'Not enough store points.';

  @override
  String get rewardErrorStock => 'This reward is out of stock.';

  @override
  String get rewardErrorTier =>
      'Your subscription tier does not qualify for this reward.';

  @override
  String get rewardErrorTokens => 'You can hold at most three freeze tokens.';

  @override
  String get rewardErrorOwned => 'You already own this item.';

  @override
  String get rewardErrorUnavailable => 'This reward is no longer available.';

  @override
  String get rewardErrorGeneral =>
      'Could not confirm redemption. Check your connection and retry.';

  @override
  String get progressBadges => 'Badges';

  @override
  String get progressNoBadges => 'No badges available yet.';

  @override
  String get progressEarned => 'Earned';

  @override
  String get progressLocked => 'Locked';

  @override
  String progressBadgeDetails(String description, String status) {
    return '$description\n$status';
  }

  @override
  String get progressAchievements => 'Achievements';

  @override
  String get progressNoAchievements => 'No achievements available yet.';

  @override
  String progressAchievementValue(
      String progress, String threshold, String xp) {
    return '$progress / $threshold · $xp XP';
  }

  @override
  String get progressCompleted => 'Completed';

  @override
  String pathSaveError(String error) {
    return 'Could not save checklist: $error';
  }

  @override
  String pathTracked(String value) {
    return 'Tracked by the app · $value';
  }

  @override
  String get pathSelfReported => 'Self-reported, not verified';

  @override
  String get pathOutside => 'Done outside the app';

  @override
  String get pathLoading => 'Loading';

  @override
  String get pathTitle => 'Your pathway';

  @override
  String get pathDisclaimer =>
      'Self-reported progress, not verified or certified';

  @override
  String get pathLoadingChecks => 'Loading checklist...';

  @override
  String pathLoadError(String error) {
    return 'Could not load checklist: $error';
  }

  @override
  String get pathFoundation => 'Foundation';

  @override
  String get pathLongestStreak => 'Longest streak (all time)';

  @override
  String pathDays(String days) {
    return '$days days';
  }

  @override
  String get pathSetGoal => 'Set a personal training goal';

  @override
  String get pathLearnBasics => 'Learn the basics of your chosen sport';

  @override
  String get pathNovice => 'Novice';

  @override
  String get pathWorkouts => 'Workouts logged (all time)';

  @override
  String get pathRoutine => 'Practice a consistent routine';

  @override
  String get pathCoach => 'Ask a qualified coach for feedback';

  @override
  String get pathCompetitor => 'Competitor-ready';

  @override
  String get pathMeals => 'Consumed meals logged (all time)';

  @override
  String get pathSkills => 'Practice your event skills';

  @override
  String get pathRequirements => 'Review an event organizer’s requirements';

  @override
  String get pathNational => 'National level';

  @override
  String get pathAppLevel => 'App level';

  @override
  String get pathNotAvailable => 'Not available';

  @override
  String get pathMilestone => 'Plan your next training milestone';

  @override
  String get pathEvents => 'Explore national events and their rules';

  @override
  String get pathPro => 'Pro pathway';

  @override
  String get pathPreparation => 'Make a long-term preparation plan';

  @override
  String get pathResearch => 'Research the official pathway for your sport';

  @override
  String get pathRegister =>
      'How to register: check the organizer\'s official site for rules and registration';

  @override
  String plannerWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get language => 'Language / اللغة';

  @override
  String get languageError => 'Could not save language. Please try again.';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'Make Privilege feel like yours';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get photoPrivate => 'Stored privately on this device';

  @override
  String get opening => 'Opening…';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get remove => 'Remove';

  @override
  String get appearance => 'App appearance';

  @override
  String get chooseTheme => 'Choose a color theme';

  @override
  String get savedDevice => 'Your selection is saved on this device.';

  @override
  String get choosePhotos => 'Choose from photos';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get smallerPhoto => 'Choose a smaller photo (under 900 KB).';

  @override
  String get photoUpdated => 'Profile photo updated.';

  @override
  String get photoRemoved => 'Profile photo removed.';

  @override
  String get cameraError => 'Could not open the camera or photo library.';

  @override
  String get savePhotoError => 'Could not save your profile photo.';

  @override
  String get saveThemeError => 'Could not save your theme.';

  @override
  String get themePrivilege => 'Privilege';

  @override
  String get themeOcean => 'Deep Ocean';

  @override
  String get themeForest => 'Evergreen';

  @override
  String get themeViolet => 'Violet Edge';

  @override
  String get themePrivilegeDescription =>
      'Crimson energy with a premium gold finish';

  @override
  String get themeOceanDescription => 'Midnight blue with bright, clear aqua';

  @override
  String get themeForestDescription => 'Deep evergreen with a fresh mint spark';

  @override
  String get themeVioletDescription =>
      'Graphite plum with a luminous violet glow';

  @override
  String get home => 'Home';

  @override
  String get splits => 'Splits';

  @override
  String get calories => 'Calories';

  @override
  String get profile => 'Profile';

  @override
  String get community => 'Community';

  @override
  String get recipes => 'Recipes';

  @override
  String get arena => 'Streak Arena';

  @override
  String get cheatMeals => 'Cheat Meals';

  @override
  String get cravingsTitle => 'Cravings & Treats';

  @override
  String get classified => 'Classified Level';

  @override
  String get academy => 'Academy';

  @override
  String get academyTitle => 'Fitness Academy';

  @override
  String get vipPlans => 'VIP Plans';

  @override
  String get botTooltip => 'AI Privilege Bot';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createAccountDescription =>
      'Create an account with your email and password.';

  @override
  String get loginDescription => 'Log in with your email and password.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordHint =>
      'Use 8-72 characters with at least one letter and one number.';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get createAccount => 'Create account';

  @override
  String get logIn => 'Log In';

  @override
  String get alreadyAccount => 'Already have an account? Log in';

  @override
  String get newAccount => 'New here? Create an account';

  @override
  String get loginUnavailableFeatures =>
      'Password reset and social sign-in will be available after setup.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get enterPassword => 'Enter your password.';

  @override
  String get invalidPassword =>
      'Password must be 8-72 characters and include a letter and a number.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get invalidCredentials => 'Incorrect email or password.';

  @override
  String get emailNotConfirmed =>
      'Please confirm your email before logging in.';

  @override
  String get networkError =>
      'Could not connect. Check your internet connection and try again.';

  @override
  String get signInError => 'Could not sign in right now. Please try again.';

  @override
  String get registrationError => 'Could not sign in. Please try again.';

  @override
  String get registrationCreated => 'Account created. Log in to continue.';

  @override
  String get registrationConfirm =>
      'If this email can be registered, check your inbox for a confirmation link, then log in.';

  @override
  String get setupTitle => 'ATHLETE TARGET SETUP';

  @override
  String get setupSubtitle =>
      'Personalize your athletic splits and calorie targets';

  @override
  String get fullName => 'Full Name';

  @override
  String get exampleName => 'e.g. Alex Johnson';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Letters, numbers and underscores';

  @override
  String get weight => 'Weight';

  @override
  String get height => 'Height';

  @override
  String get primaryGoal => 'Primary Target Goal';

  @override
  String get goalChampionship => 'Natural Championship Qualification';

  @override
  String get goalMuscle => 'Lean Muscle Mass Hypertrophy';

  @override
  String get goalSports => 'Sports & Strength Split Merger';

  @override
  String get goalFatLoss => 'Metabolic Fat Loss & Calorie Deficit';

  @override
  String get estimatedTarget => 'Estimated Calorie Target:';

  @override
  String get enterDetails => 'Enter details and choose a goal';

  @override
  String get kcalPerDay => 'kcal/day';

  @override
  String get saving => 'Saving...';

  @override
  String get completeSetup => 'Complete Setup & Enter';

  @override
  String get invalidUsername =>
      'Username must be 3 to 20 letters, numbers or underscores.';

  @override
  String get invalidName => 'Enter your name (up to 60 characters).';

  @override
  String get missingMeasurements => 'Enter both your weight and height.';

  @override
  String get invalidMeasurements =>
      'Weight must be 35-250 kg and height 120-230 cm.';

  @override
  String get chooseGoal => 'Choose a primary target goal.';

  @override
  String get usernameTaken => 'That username is already taken.';

  @override
  String get sessionExpired => 'Please log in again.';
}
