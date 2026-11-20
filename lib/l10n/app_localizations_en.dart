// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get profileSaveError =>
      'Could not save your profile. Please try again.';

  @override
  String get sessionExpired => 'Please log in again.';
}
