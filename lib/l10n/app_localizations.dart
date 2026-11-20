import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Organiser'**
  String get plannerTitle;

  /// No description provided for @plannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly calendar & schedule planner'**
  String get plannerSubtitle;

  /// No description provided for @plannerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get plannerCancel;

  /// No description provided for @plannerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get plannerDelete;

  /// No description provided for @plannerSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get plannerSave;

  /// No description provided for @plannerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get plannerRetry;

  /// No description provided for @plannerAddSplit.
  ///
  /// In en, this message translates to:
  /// **'Add Split'**
  String get plannerAddSplit;

  /// No description provided for @plannerEditSplit.
  ///
  /// In en, this message translates to:
  /// **'Edit split'**
  String get plannerEditSplit;

  /// No description provided for @plannerEditDay.
  ///
  /// In en, this message translates to:
  /// **'Edit this day'**
  String get plannerEditDay;

  /// No description provided for @plannerPlanDay.
  ///
  /// In en, this message translates to:
  /// **'Plan this day'**
  String get plannerPlanDay;

  /// No description provided for @plannerRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get plannerRestDay;

  /// No description provided for @plannerRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get plannerRest;

  /// No description provided for @plannerWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get plannerWorkout;

  /// No description provided for @plannerSplitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The split is no longer available.'**
  String get plannerSplitUnavailable;

  /// No description provided for @plannerLogOnlyToday.
  ///
  /// In en, this message translates to:
  /// **'Logging is available on the workout day only.'**
  String get plannerLogOnlyToday;

  /// No description provided for @plannerPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get plannerPreviousWeek;

  /// No description provided for @plannerNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get plannerNextWeek;

  /// No description provided for @plannerPlannedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Planned workout'**
  String get plannerPlannedWorkout;

  /// No description provided for @plannerCompletedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Completed workout'**
  String get plannerCompletedWorkout;

  /// No description provided for @plannerRestLegend.
  ///
  /// In en, this message translates to:
  /// **'— Rest day'**
  String get plannerRestLegend;

  /// No description provided for @plannerNothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for this day.'**
  String get plannerNothingPlanned;

  /// No description provided for @plannerWorkoutLogged.
  ///
  /// In en, this message translates to:
  /// **'Workout logged'**
  String get plannerWorkoutLogged;

  /// No description provided for @plannerWorkoutNotLogged.
  ///
  /// In en, this message translates to:
  /// **'Workout not logged'**
  String get plannerWorkoutNotLogged;

  /// No description provided for @plannerRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get plannerRemove;

  /// No description provided for @plannerRemoveDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove planned day?'**
  String get plannerRemoveDayTitle;

  /// No description provided for @plannerRemoveDayDetails.
  ///
  /// In en, this message translates to:
  /// **'This does not delete any workout log.'**
  String get plannerRemoveDayDetails;

  /// No description provided for @plannerLogWorkout.
  ///
  /// In en, this message translates to:
  /// **'Log this workout'**
  String get plannerLogWorkout;

  /// No description provided for @plannerAvailableOnDay.
  ///
  /// In en, this message translates to:
  /// **'Available on the day'**
  String get plannerAvailableOnDay;

  /// No description provided for @plannerMySplits.
  ///
  /// In en, this message translates to:
  /// **'My splits'**
  String get plannerMySplits;

  /// No description provided for @plannerNoSplits.
  ///
  /// In en, this message translates to:
  /// **'No splits yet. Create one or add starter splits.'**
  String get plannerNoSplits;

  /// No description provided for @plannerCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first split'**
  String get plannerCreateFirst;

  /// No description provided for @plannerAddStarters.
  ///
  /// In en, this message translates to:
  /// **'Add starter splits'**
  String get plannerAddStarters;

  /// No description provided for @plannerDeleteDetails.
  ///
  /// In en, this message translates to:
  /// **'Days already planned will stay unchanged.'**
  String get plannerDeleteDetails;

  /// No description provided for @plannerDeleteExplanation.
  ///
  /// In en, this message translates to:
  /// **'Deleting a split keeps the days already planned.'**
  String get plannerDeleteExplanation;

  /// No description provided for @plannerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get plannerToday;

  /// No description provided for @plannerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get plannerName;

  /// No description provided for @plannerType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get plannerType;

  /// No description provided for @plannerDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get plannerDuration;

  /// No description provided for @plannerDurationHint.
  ///
  /// In en, this message translates to:
  /// **'1 to 600 minutes'**
  String get plannerDurationHint;

  /// No description provided for @plannerEffort.
  ///
  /// In en, this message translates to:
  /// **'Effort (%)'**
  String get plannerEffort;

  /// No description provided for @plannerEffortHint.
  ///
  /// In en, this message translates to:
  /// **'0 to 100'**
  String get plannerEffortHint;

  /// No description provided for @plannerInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name between 1 and 100 characters.'**
  String get plannerInvalidName;

  /// No description provided for @plannerInvalidDuration.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 600 minutes.'**
  String get plannerInvalidDuration;

  /// No description provided for @plannerInvalidEffort.
  ///
  /// In en, this message translates to:
  /// **'Enter effort from 0 to 100%.'**
  String get plannerInvalidEffort;

  /// No description provided for @plannerPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get plannerPush;

  /// No description provided for @plannerPull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get plannerPull;

  /// No description provided for @plannerLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get plannerLegs;

  /// No description provided for @plannerSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String plannerSaveError(String error);

  /// No description provided for @plannerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load planner: {error}'**
  String plannerLoadError(String error);

  /// No description provided for @plannerOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open workout logger: {error}'**
  String plannerOpenError(String error);

  /// No description provided for @plannerSelectedDay.
  ///
  /// In en, this message translates to:
  /// **'Selected day: {date}'**
  String plannerSelectedDay(String date);

  /// No description provided for @plannerWorkoutSummary.
  ///
  /// In en, this message translates to:
  /// **'Workout · {minutes} min · {effort}% effort'**
  String plannerWorkoutSummary(String minutes, String effort);

  /// No description provided for @plannerSplitSummary.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {effort}% effort'**
  String plannerSplitSummary(String minutes, String effort);

  /// No description provided for @plannerEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String plannerEditName(String name);

  /// No description provided for @plannerDeleteName.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String plannerDeleteName(String name);

  /// No description provided for @plannerDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String plannerDeleteQuestion(String name);

  /// No description provided for @splitPushDay.
  ///
  /// In en, this message translates to:
  /// **'Push Day'**
  String get splitPushDay;

  /// No description provided for @splitPullDay.
  ///
  /// In en, this message translates to:
  /// **'Pull Day'**
  String get splitPullDay;

  /// No description provided for @splitLegDay.
  ///
  /// In en, this message translates to:
  /// **'Leg Day Hypertrophy'**
  String get splitLegDay;

  /// No description provided for @splitUpper.
  ///
  /// In en, this message translates to:
  /// **'Upper Body Power'**
  String get splitUpper;

  /// No description provided for @splitCalisthenics.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics & Core'**
  String get splitCalisthenics;

  /// No description provided for @splitOlympic.
  ///
  /// In en, this message translates to:
  /// **'Olympic Weightlifting'**
  String get splitOlympic;

  /// No description provided for @sportBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get sportBasketball;

  /// No description provided for @sportFootball.
  ///
  /// In en, this message translates to:
  /// **'Football / Soccer'**
  String get sportFootball;

  /// No description provided for @sportTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get sportTennis;

  /// No description provided for @sportBoxing.
  ///
  /// In en, this message translates to:
  /// **'Boxing / MMA'**
  String get sportBoxing;

  /// No description provided for @sportSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming Laps'**
  String get sportSwimming;

  /// No description provided for @sportSprints.
  ///
  /// In en, this message translates to:
  /// **'Track Sprint Intervals'**
  String get sportSprints;

  /// No description provided for @intensityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get intensityLight;

  /// No description provided for @intensityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get intensityModerate;

  /// No description provided for @intensityVigorous.
  ///
  /// In en, this message translates to:
  /// **'Vigorous'**
  String get intensityVigorous;

  /// No description provided for @mergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Splits & Sports Merge'**
  String get mergeTitle;

  /// No description provided for @mergeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine gym splits with daily sports.'**
  String get mergeSubtitle;

  /// No description provided for @mergeManage.
  ///
  /// In en, this message translates to:
  /// **'Manage splits'**
  String get mergeManage;

  /// No description provided for @mergeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in again.'**
  String get mergeSignIn;

  /// No description provided for @mergeInvalidTotal.
  ///
  /// In en, this message translates to:
  /// **'Enter valid durations with a combined total of 1 to 600 minutes.'**
  String get mergeInvalidTotal;

  /// No description provided for @mergeNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'The combined name must be 100 characters or fewer.'**
  String get mergeNameTooLong;

  /// No description provided for @mergeReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace existing plan?'**
  String get mergeReplaceTitle;

  /// No description provided for @mergeReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get mergeReplace;

  /// No description provided for @mergeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Planned successfully.'**
  String get mergeSuccess;

  /// No description provided for @mergeWorkoutSplit.
  ///
  /// In en, this message translates to:
  /// **'Workout split'**
  String get mergeWorkoutSplit;

  /// No description provided for @mergeSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get mergeSplit;

  /// No description provided for @mergeSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get mergeSport;

  /// No description provided for @mergeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get mergeUnavailable;

  /// No description provided for @mergeInvalidDuration.
  ///
  /// In en, this message translates to:
  /// **'Invalid duration'**
  String get mergeInvalidDuration;

  /// No description provided for @mergeSprintEstimate.
  ///
  /// In en, this message translates to:
  /// **'Track sprint intervals use the HIIT or circuit estimate.'**
  String get mergeSprintEstimate;

  /// No description provided for @mergeAddWeight.
  ///
  /// In en, this message translates to:
  /// **'Calorie estimate unavailable - add your weight'**
  String get mergeAddWeight;

  /// No description provided for @mergeCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get mergeCompleteProfile;

  /// No description provided for @mergeSportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Calorie estimate unavailable for this sport.'**
  String get mergeSportUnavailable;

  /// No description provided for @mergeEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Estimate based on activity type, duration, intensity and your weight.'**
  String get mergeEstimateNote;

  /// No description provided for @mergePlanDate.
  ///
  /// In en, this message translates to:
  /// **'Plan on a date'**
  String get mergePlanDate;

  /// No description provided for @mergeLogWorkout.
  ///
  /// In en, this message translates to:
  /// **'Log workout'**
  String get mergeLogWorkout;

  /// No description provided for @mergeLogSport.
  ///
  /// In en, this message translates to:
  /// **'Log sport'**
  String get mergeLogSport;

  /// No description provided for @mergePlannerEffort.
  ///
  /// In en, this message translates to:
  /// **'Planner effort (%)'**
  String get mergePlannerEffort;

  /// No description provided for @mergeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get mergeContinue;

  /// No description provided for @mergeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load splits: {error}'**
  String mergeLoadError(String error);

  /// No description provided for @mergePlanError.
  ///
  /// In en, this message translates to:
  /// **'Could not plan: {error}'**
  String mergePlanError(String error);

  /// No description provided for @mergeReplaceDetails.
  ///
  /// In en, this message translates to:
  /// **'{date} already has \"{name}\". Replace it?'**
  String mergeReplaceDetails(String date, String name);

  /// No description provided for @mergeSavedName.
  ///
  /// In en, this message translates to:
  /// **'{name} (My split)'**
  String mergeSavedName(String name);

  /// No description provided for @mergeMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} minutes'**
  String mergeMinutesLabel(String label);

  /// No description provided for @mergeCombinedDuration.
  ///
  /// In en, this message translates to:
  /// **'Combined duration: {duration}'**
  String mergeCombinedDuration(String duration);

  /// No description provided for @mergeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String mergeMinutes(String minutes);

  /// No description provided for @mergeShortMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String mergeShortMinutes(String minutes);

  /// No description provided for @mergeNamedValue.
  ///
  /// In en, this message translates to:
  /// **'{name}: {value}'**
  String mergeNamedValue(String name, String value);

  /// No description provided for @mergeCalories.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String mergeCalories(String calories);

  /// No description provided for @mergeEstimatedCalories.
  ///
  /// In en, this message translates to:
  /// **'Estimated calories burned: {value}'**
  String mergeEstimatedCalories(String value);

  /// No description provided for @mergeDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String mergeDate(String date);

  /// No description provided for @caloriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meals, macros & activity'**
  String get caloriesSubtitle;

  /// No description provided for @foodLog.
  ///
  /// In en, this message translates to:
  /// **'Food Log'**
  String get foodLog;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @foodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This food is no longer available in the food database. The meal was not changed.'**
  String get foodUnavailable;

  /// No description provided for @foodOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open food: {error}'**
  String foodOpenError(String error);

  /// No description provided for @activitySaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save activity: {error}'**
  String activitySaveError(String error);

  /// No description provided for @burnedAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} kcal burned'**
  String burnedAmount(String amount);

  /// No description provided for @deleteNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteNamed(String name);

  /// No description provided for @noWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No workouts logged today yet.'**
  String get noWorkouts;

  /// No description provided for @manualInvalidCalories.
  ///
  /// In en, this message translates to:
  /// **'Enter a calorie amount greater than zero.'**
  String get manualInvalidCalories;

  /// No description provided for @manualTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Nutrition or Workout Burn'**
  String get manualTitle;

  /// No description provided for @manualFood.
  ///
  /// In en, this message translates to:
  /// **'Food Intake (+)'**
  String get manualFood;

  /// No description provided for @manualBurn.
  ///
  /// In en, this message translates to:
  /// **'Workout Burn (+)'**
  String get manualBurn;

  /// No description provided for @manualFoodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grass-fed Steak'**
  String get manualFoodHint;

  /// No description provided for @manualBurnHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Olympic Lifts'**
  String get manualBurnHint;

  /// No description provided for @caloriesKcal.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get caloriesKcal;

  /// No description provided for @manualProtein.
  ///
  /// In en, this message translates to:
  /// **'🔴 Protein'**
  String get manualProtein;

  /// No description provided for @manualCarbs.
  ///
  /// In en, this message translates to:
  /// **'🔵 Carbs'**
  String get manualCarbs;

  /// No description provided for @manualFats.
  ///
  /// In en, this message translates to:
  /// **'🟠 Fats'**
  String get manualFats;

  /// No description provided for @manualGreens.
  ///
  /// In en, this message translates to:
  /// **'🟢 Greens'**
  String get manualGreens;

  /// No description provided for @manualStrength.
  ///
  /// In en, this message translates to:
  /// **'🟡 Strength / Gym'**
  String get manualStrength;

  /// No description provided for @manualCardio.
  ///
  /// In en, this message translates to:
  /// **'🔷 Cardio / Sports'**
  String get manualCardio;

  /// No description provided for @manualMobility.
  ///
  /// In en, this message translates to:
  /// **'🟢 Mobility / Stage'**
  String get manualMobility;

  /// No description provided for @saveActivity.
  ///
  /// In en, this message translates to:
  /// **'Save activity'**
  String get saveActivity;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Rings & Workouts'**
  String get activityTitle;

  /// No description provided for @activitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track workouts and calories burned'**
  String get activitySubtitle;

  /// No description provided for @burned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get burned;

  /// No description provided for @burnTarget.
  ///
  /// In en, this message translates to:
  /// **'/ {amount} kcal target'**
  String burnTarget(String amount);

  /// No description provided for @burnGoalNote.
  ///
  /// In en, this message translates to:
  /// **'Daily burn goal • total includes mobility'**
  String get burnGoalNote;

  /// No description provided for @burnRingNote.
  ///
  /// In en, this message translates to:
  /// **'Each ring uses the daily burn goal.'**
  String get burnRingNote;

  /// No description provided for @totalBurn.
  ///
  /// In en, this message translates to:
  /// **'Total burn ({amount} kcal)'**
  String totalBurn(String amount);

  /// No description provided for @strengthBurn.
  ///
  /// In en, this message translates to:
  /// **'Strength burn ({amount} kcal)'**
  String strengthBurn(String amount);

  /// No description provided for @cardioBurn.
  ///
  /// In en, this message translates to:
  /// **'Cardio burn ({amount} kcal)'**
  String cardioBurn(String amount);

  /// No description provided for @burnStats.
  ///
  /// In en, this message translates to:
  /// **'Burn Stats'**
  String get burnStats;

  /// No description provided for @strengthBurnLabel.
  ///
  /// In en, this message translates to:
  /// **'Strength Burn'**
  String get strengthBurnLabel;

  /// No description provided for @cardioBurnLabel.
  ///
  /// In en, this message translates to:
  /// **'Cardio Burn'**
  String get cardioBurnLabel;

  /// No description provided for @burnTypeStrength.
  ///
  /// In en, this message translates to:
  /// **'strength'**
  String get burnTypeStrength;

  /// No description provided for @burnTypeCardio.
  ///
  /// In en, this message translates to:
  /// **'cardio'**
  String get burnTypeCardio;

  /// No description provided for @burnTypeMobility.
  ///
  /// In en, this message translates to:
  /// **'mobility'**
  String get burnTypeMobility;

  /// No description provided for @workoutLogs.
  ///
  /// In en, this message translates to:
  /// **'Workout Logs ({count})'**
  String workoutLogs(String count);

  /// No description provided for @workoutInvalidDuration.
  ///
  /// In en, this message translates to:
  /// **'Enter a duration between 1 and 600 minutes.'**
  String get workoutInvalidDuration;

  /// No description provided for @workoutInvalidCalories.
  ///
  /// In en, this message translates to:
  /// **'Enter calories between 0 and 5000.'**
  String get workoutInvalidCalories;

  /// No description provided for @workoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout logged.'**
  String get workoutSaved;

  /// No description provided for @workoutRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Saved, but the activity list could not be refreshed. Please retry.'**
  String get workoutRefreshError;

  /// No description provided for @workoutSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save workout: {error}'**
  String workoutSaveError(String error);

  /// No description provided for @workoutStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength training'**
  String get workoutStrength;

  /// No description provided for @workoutWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get workoutWalking;

  /// No description provided for @workoutRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get workoutRunning;

  /// No description provided for @workoutCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get workoutCycling;

  /// No description provided for @workoutSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get workoutSwimming;

  /// No description provided for @workoutFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get workoutFootball;

  /// No description provided for @workoutBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get workoutBasketball;

  /// No description provided for @workoutTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get workoutTennis;

  /// No description provided for @workoutCircuit.
  ///
  /// In en, this message translates to:
  /// **'HIIT or circuit'**
  String get workoutCircuit;

  /// No description provided for @workoutMartialArts.
  ///
  /// In en, this message translates to:
  /// **'Boxing or martial arts'**
  String get workoutMartialArts;

  /// No description provided for @workoutYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga or stretching'**
  String get workoutYoga;

  /// No description provided for @workoutJumpRope.
  ///
  /// In en, this message translates to:
  /// **'Jump rope'**
  String get workoutJumpRope;

  /// No description provided for @workoutOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get workoutOther;

  /// No description provided for @workoutActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'{icon} {name}'**
  String workoutActivityLabel(String icon, String name);

  /// No description provided for @workoutSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} - {minutes} min'**
  String workoutSavedTitle(String name, String minutes);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @workoutIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get workoutIntensity;

  /// No description provided for @workoutEstimateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Estimate unavailable — enter calories manually.'**
  String get workoutEstimateUnavailable;

  /// No description provided for @workoutEstimate.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount} kcal burned'**
  String workoutEstimate(String amount);

  /// No description provided for @workoutFormula.
  ///
  /// In en, this message translates to:
  /// **'MET x weight x hours'**
  String get workoutFormula;

  /// No description provided for @workoutEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Calorie burn is an estimate.'**
  String get workoutEstimateNote;

  /// No description provided for @workoutManualOther.
  ///
  /// In en, this message translates to:
  /// **'Other activities require manual calories.'**
  String get workoutManualOther;

  /// No description provided for @workoutCaloriesEditable.
  ///
  /// In en, this message translates to:
  /// **'Calories burned (editable)'**
  String get workoutCaloriesEditable;

  /// No description provided for @workoutCaloriesHint.
  ///
  /// In en, this message translates to:
  /// **'0 to 5000 kcal'**
  String get workoutCaloriesHint;

  /// No description provided for @workoutUseEstimate.
  ///
  /// In en, this message translates to:
  /// **'Use estimate'**
  String get workoutUseEstimate;

  /// No description provided for @workoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get workoutSaving;

  /// No description provided for @workoutSave.
  ///
  /// In en, this message translates to:
  /// **'Save workout'**
  String get workoutSave;

  /// No description provided for @foodEaten.
  ///
  /// In en, this message translates to:
  /// **'kcal eaten'**
  String get foodEaten;

  /// No description provided for @foodBalance.
  ///
  /// In en, this message translates to:
  /// **'DAILY ENERGY BALANCE'**
  String get foodBalance;

  /// No description provided for @foodTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'target unavailable'**
  String get foodTargetUnavailable;

  /// No description provided for @foodOver.
  ///
  /// In en, this message translates to:
  /// **'kcal over'**
  String get foodOver;

  /// No description provided for @foodLeft.
  ///
  /// In en, this message translates to:
  /// **'kcal left'**
  String get foodLeft;

  /// No description provided for @foodEstimated.
  ///
  /// In en, this message translates to:
  /// **' • Estimated'**
  String get foodEstimated;

  /// No description provided for @foodGoalSummary.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal}{estimated} • Logged items: {count}'**
  String foodGoalSummary(String goal, String estimated, String count);

  /// No description provided for @foodProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get foodProtein;

  /// No description provided for @foodCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get foodCarbs;

  /// No description provided for @foodFats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get foodFats;

  /// No description provided for @foodFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get foodFiber;

  /// No description provided for @foodSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get foodSugar;

  /// No description provided for @foodSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get foodSodium;

  /// No description provided for @foodGrams.
  ///
  /// In en, this message translates to:
  /// **'{amount} g'**
  String foodGrams(String amount);

  /// No description provided for @foodMilligrams.
  ///
  /// In en, this message translates to:
  /// **'{amount} mg'**
  String foodMilligrams(String amount);

  /// No description provided for @foodMacroGoal.
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {goal} g'**
  String foodMacroGoal(String eaten, String goal);

  /// No description provided for @foodLabelValue.
  ///
  /// In en, this message translates to:
  /// **'{label} {value}'**
  String foodLabelValue(String label, String value);

  /// No description provided for @foodAdd.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get foodAdd;

  /// No description provided for @foodCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile for an accurate target'**
  String get foodCompleteProfile;

  /// No description provided for @foodDismissReminder.
  ///
  /// In en, this message translates to:
  /// **'Dismiss profile reminder'**
  String get foodDismissReminder;

  /// No description provided for @foodToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Food Log'**
  String get foodToday;

  /// No description provided for @foodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get foodAll;

  /// No description provided for @foodBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get foodBreakfast;

  /// No description provided for @foodLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get foodLunch;

  /// No description provided for @foodDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get foodDinner;

  /// No description provided for @foodSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get foodSnacks;

  /// No description provided for @foodSnacksHeading.
  ///
  /// In en, this message translates to:
  /// **'Snacks & Toppings'**
  String get foodSnacksHeading;

  /// No description provided for @foodEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your daily log is empty'**
  String get foodEmpty;

  /// No description provided for @foodEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a meal to start tracking today.'**
  String get foodEmptyHint;

  /// No description provided for @foodHeading.
  ///
  /// In en, this message translates to:
  /// **'{icon} {name}'**
  String foodHeading(String icon, String name);

  /// No description provided for @foodGroupTotals.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal • {protein}g P'**
  String foodGroupTotals(String calories, String protein);

  /// No description provided for @foodNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items logged for {meal}.'**
  String foodNoItems(String meal);

  /// No description provided for @foodUncheck.
  ///
  /// In en, this message translates to:
  /// **'Uncheck {name}'**
  String foodUncheck(String name);

  /// No description provided for @foodLogNamed.
  ///
  /// In en, this message translates to:
  /// **'Log {name}'**
  String foodLogNamed(String name);

  /// No description provided for @foodManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get foodManualEntry;

  /// No description provided for @foodCustomGrams.
  ///
  /// In en, this message translates to:
  /// **'{amount} g custom'**
  String foodCustomGrams(String amount);

  /// No description provided for @foodServing.
  ///
  /// In en, this message translates to:
  /// **'{name} ({amount})'**
  String foodServing(String name, String amount);

  /// No description provided for @foodProteinShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} P'**
  String foodProteinShort(String amount);

  /// No description provided for @foodCarbsShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} C'**
  String foodCarbsShort(String amount);

  /// No description provided for @foodFatsShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} F'**
  String foodFatsShort(String amount);

  /// No description provided for @foodCaloriesLines.
  ///
  /// In en, this message translates to:
  /// **'{amount}\nkcal'**
  String foodCaloriesLines(String amount);

  /// No description provided for @foodEditPortion.
  ///
  /// In en, this message translates to:
  /// **'Edit portion {name}'**
  String foodEditPortion(String name);

  /// No description provided for @foodDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate {name}'**
  String foodDuplicate(String name);

  /// No description provided for @foodDuplicateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This food is no longer available to duplicate.'**
  String get foodDuplicateUnavailable;

  /// No description provided for @foodSavedRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Food was saved, but the activity list could not be refreshed. Please retry.'**
  String get foodSavedRefreshError;

  /// No description provided for @foodDeletedRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Food was deleted, but the activity list could not be refreshed. Please retry.'**
  String get foodDeletedRefreshError;

  /// No description provided for @foodDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Food duplicated.'**
  String get foodDuplicated;

  /// No description provided for @foodDeleted.
  ///
  /// In en, this message translates to:
  /// **'Food deleted.'**
  String get foodDeleted;

  /// No description provided for @foodDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'Could not duplicate food: {error}'**
  String foodDuplicateError(String error);

  /// No description provided for @foodDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete food: {error}'**
  String foodDeleteError(String error);

  /// No description provided for @foodUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update meal: {error}'**
  String foodUpdateError(String error);

  /// No description provided for @explorerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the food database.'**
  String get explorerLoadError;

  /// No description provided for @explorerManual.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Quick add manually'**
  String get explorerManual;

  /// No description provided for @explorerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search foods in English or Arabic...'**
  String get explorerSearch;

  /// No description provided for @explorerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get explorerClear;

  /// No description provided for @explorerShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}'**
  String explorerShowing(String shown, String total);

  /// No description provided for @explorerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching foods found'**
  String get explorerEmpty;

  /// No description provided for @explorerEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try another search or remove a filter.'**
  String get explorerEmptyHint;

  /// No description provided for @explorerDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Nutrition values are approximate estimates.'**
  String get explorerDisclaimer;

  /// No description provided for @explorerPer100.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g: {calories} kcal'**
  String explorerPer100(String calories);

  /// No description provided for @explorerLog.
  ///
  /// In en, this message translates to:
  /// **'+ Log'**
  String get explorerLog;

  /// No description provided for @explorerStandard.
  ///
  /// In en, this message translates to:
  /// **'100 g standard reference'**
  String get explorerStandard;

  /// No description provided for @explorerInvalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between 1 and 3000 g.'**
  String get explorerInvalidWeight;

  /// No description provided for @explorerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}.'**
  String explorerUpdated(String name);

  /// No description provided for @explorerLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged {name} ({calories} kcal)'**
  String explorerLogged(String name, String calories);

  /// No description provided for @explorerSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save food: {error}'**
  String explorerSaveError(String error);

  /// No description provided for @explorerPortions.
  ///
  /// In en, this message translates to:
  /// **'Quick Household & Restaurant Portions'**
  String get explorerPortions;

  /// No description provided for @explorerExactWeight.
  ///
  /// In en, this message translates to:
  /// **'Exact Weight (Grams)'**
  String get explorerExactWeight;

  /// No description provided for @unitGrams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGrams;

  /// No description provided for @explorerNutrient.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount}'**
  String explorerNutrient(String name, String amount);

  /// No description provided for @explorerMeal.
  ///
  /// In en, this message translates to:
  /// **'Log to Meal'**
  String get explorerMeal;

  /// No description provided for @explorerAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add to Daily Log'**
  String get explorerAdd;

  /// No description provided for @explorerSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get explorerSaveChanges;

  /// No description provided for @foodFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get foodFat;

  /// No description provided for @foodSnackSingular.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get foodSnackSingular;

  /// No description provided for @groupAmerican.
  ///
  /// In en, this message translates to:
  /// **'American & Latin'**
  String get groupAmerican;

  /// No description provided for @groupAsian.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get groupAsian;

  /// No description provided for @groupCafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes & Bakeries'**
  String get groupCafes;

  /// No description provided for @groupEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian'**
  String get groupEgyptian;

  /// No description provided for @groupEuropean.
  ///
  /// In en, this message translates to:
  /// **'European'**
  String get groupEuropean;

  /// No description provided for @groupMiddleEastern.
  ///
  /// In en, this message translates to:
  /// **'Middle Eastern & African'**
  String get groupMiddleEastern;

  /// No description provided for @groupRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw & Fitness Staples'**
  String get groupRaw;

  /// No description provided for @groupRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants & Fast Food'**
  String get groupRestaurants;

  /// No description provided for @groupSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get groupSnacks;

  /// No description provided for @tagProtein.
  ///
  /// In en, this message translates to:
  /// **'High Protein'**
  String get tagProtein;

  /// No description provided for @tagFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness Staple'**
  String get tagFitness;

  /// No description provided for @tagStreet.
  ///
  /// In en, this message translates to:
  /// **'Street Food'**
  String get tagStreet;

  /// No description provided for @tagVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get tagVegan;

  /// No description provided for @tagKeto.
  ///
  /// In en, this message translates to:
  /// **'Keto Friendly'**
  String get tagKeto;

  /// No description provided for @tagLowCarb.
  ///
  /// In en, this message translates to:
  /// **'Low Carb'**
  String get tagLowCarb;

  /// No description provided for @tagOils.
  ///
  /// In en, this message translates to:
  /// **'Oils'**
  String get tagOils;

  /// No description provided for @tagToppings.
  ///
  /// In en, this message translates to:
  /// **'Toppings'**
  String get tagToppings;

  /// No description provided for @tagDesserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get tagDesserts;

  /// No description provided for @tagRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get tagRaw;

  /// No description provided for @tagCooked.
  ///
  /// In en, this message translates to:
  /// **'Cooked'**
  String get tagCooked;

  /// No description provided for @profileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid birth date (age 13–100), sex, activity, weight (30–300 kg), and height (120–230 cm).'**
  String get profileInvalid;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String profileSaveError(String error);

  /// No description provided for @profileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get profileWeight;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profileHeight;

  /// No description provided for @profileChooseBirth.
  ///
  /// In en, this message translates to:
  /// **'Choose birth date'**
  String get profileChooseBirth;

  /// No description provided for @profileBirth.
  ///
  /// In en, this message translates to:
  /// **'Birth date: {date}'**
  String profileBirth(String date);

  /// No description provided for @profileSex.
  ///
  /// In en, this message translates to:
  /// **'Sex for the estimate'**
  String get profileSex;

  /// No description provided for @profileMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileMale;

  /// No description provided for @profileFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileFemale;

  /// No description provided for @profileUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get profileUnspecified;

  /// No description provided for @profileActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity level'**
  String get profileActivity;

  /// No description provided for @profileSedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get profileSedentary;

  /// No description provided for @profileSedentaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Mostly sitting, little exercise.'**
  String get profileSedentaryDescription;

  /// No description provided for @profileLightDescription.
  ///
  /// In en, this message translates to:
  /// **'Light exercise 1–3 days per week.'**
  String get profileLightDescription;

  /// No description provided for @profileModerateDescription.
  ///
  /// In en, this message translates to:
  /// **'Exercise 3–5 days per week.'**
  String get profileModerateDescription;

  /// No description provided for @profileVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get profileVeryActive;

  /// No description provided for @profileVeryActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Hard exercise 6–7 days per week.'**
  String get profileVeryActiveDescription;

  /// No description provided for @profileAthlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get profileAthlete;

  /// No description provided for @profileAthleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Very demanding daily training or physical work.'**
  String get profileAthleteDescription;

  /// No description provided for @profileTarget.
  ///
  /// In en, this message translates to:
  /// **'Your daily target: {target}{estimated}'**
  String profileTarget(String target, String estimated);

  /// No description provided for @profileBmr.
  ///
  /// In en, this message translates to:
  /// **'BMR: {bmr} • Maintenance: {maintenance}'**
  String profileBmr(String bmr, String maintenance);

  /// No description provided for @profileCompleteFields.
  ///
  /// In en, this message translates to:
  /// **'Complete all fields for a personal estimate.'**
  String get profileCompleteFields;

  /// No description provided for @profileAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Goal adjustment: {amount} kcal{minor}'**
  String profileAdjustment(String amount, String minor);

  /// No description provided for @profileMinor.
  ///
  /// In en, this message translates to:
  /// **' (maintenance for under 18)'**
  String get profileMinor;

  /// No description provided for @profileDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Estimates are not medical advice.'**
  String get profileDisclaimer;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSave;

  /// No description provided for @memberFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get memberFree;

  /// No description provided for @memberSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get memberSilver;

  /// No description provided for @memberGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get memberGold;

  /// No description provided for @membershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Privilege membership'**
  String get membershipTitle;

  /// No description provided for @membershipLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading membership...'**
  String get membershipLoading;

  /// No description provided for @membershipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Membership unavailable'**
  String get membershipUnavailable;

  /// No description provided for @membershipUnavailableConnection.
  ///
  /// In en, this message translates to:
  /// **'Membership unavailable. Check your connection.'**
  String get membershipUnavailableConnection;

  /// No description provided for @membershipCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current membership: {tier}'**
  String membershipCurrent(String tier);

  /// No description provided for @membershipProfile.
  ///
  /// In en, this message translates to:
  /// **'Privilege {tier} Member'**
  String membershipProfile(String tier);

  /// No description provided for @membershipRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry membership'**
  String get membershipRetry;

  /// No description provided for @membershipBenefits.
  ///
  /// In en, this message translates to:
  /// **'Available in the app'**
  String get membershipBenefits;

  /// No description provided for @membershipFood.
  ///
  /// In en, this message translates to:
  /// **'Food and workout logging'**
  String get membershipFood;

  /// No description provided for @membershipCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community and streak tracking'**
  String get membershipCommunity;

  /// No description provided for @membershipAcademy.
  ///
  /// In en, this message translates to:
  /// **'Academy exercise guides'**
  String get membershipAcademy;

  /// No description provided for @membershipRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards and achievements'**
  String get membershipRewards;

  /// No description provided for @membershipSplits.
  ///
  /// In en, this message translates to:
  /// **'Create and save custom splits'**
  String get membershipSplits;

  /// No description provided for @membershipBenefit.
  ///
  /// In en, this message translates to:
  /// **'• {benefit}'**
  String membershipBenefit(String benefit);

  /// No description provided for @membershipComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon. Payments are not available yet.'**
  String get membershipComingSoon;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Athlete Profile'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile successfully updated!'**
  String get profileUpdated;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profileFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullNameHint;

  /// No description provided for @profileGoal.
  ///
  /// In en, this message translates to:
  /// **'Target Goal'**
  String get profileGoal;

  /// No description provided for @profileChooseGoal.
  ///
  /// In en, this message translates to:
  /// **'Choose a target goal'**
  String get profileChooseGoal;

  /// No description provided for @profileBio.
  ///
  /// In en, this message translates to:
  /// **'Athlete bio'**
  String get profileBio;

  /// No description provided for @profileHandle.
  ///
  /// In en, this message translates to:
  /// **'@{username}'**
  String profileHandle(String username);

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// No description provided for @profileAddBio.
  ///
  /// In en, this message translates to:
  /// **'Add a bio'**
  String get profileAddBio;

  /// No description provided for @profileQuotedBio.
  ///
  /// In en, this message translates to:
  /// **'“{bio}”'**
  String profileQuotedBio(String bio);

  /// No description provided for @profileCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get profileCurrentWeight;

  /// No description provided for @profileHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeightLabel;

  /// No description provided for @profileCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Calorie Goal'**
  String get profileCalorieGoal;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileKg.
  ///
  /// In en, this message translates to:
  /// **'{amount} kg'**
  String profileKg(String amount);

  /// No description provided for @profileCm.
  ///
  /// In en, this message translates to:
  /// **'{amount} cm'**
  String profileCm(String amount);

  /// No description provided for @profileCalorieValue.
  ///
  /// In en, this message translates to:
  /// **'{amount}{estimated}'**
  String profileCalorieValue(String amount, String estimated);

  /// No description provided for @profileCompleteCalorie.
  ///
  /// In en, this message translates to:
  /// **'Complete your calorie profile'**
  String get profileCompleteCalorie;

  /// No description provided for @profileEditCalorie.
  ///
  /// In en, this message translates to:
  /// **'Edit calorie profile'**
  String get profileEditCalorie;

  /// No description provided for @profileRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards Store'**
  String get profileRewards;

  /// No description provided for @profileBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges & Achievements'**
  String get profileBadges;

  /// No description provided for @profileActiveTarget.
  ///
  /// In en, this message translates to:
  /// **'Active Target:'**
  String get profileActiveTarget;

  /// No description provided for @profileTrack.
  ///
  /// In en, this message translates to:
  /// **'Track →'**
  String get profileTrack;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out of Privilege'**
  String get profileSignOut;

  /// No description provided for @alertsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Alerts (updates unavailable)'**
  String get alertsUnavailable;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get alertsTryAgain;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @alertsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get alertsMarkRead;

  /// No description provided for @alertsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up.'**
  String get alertsEmpty;

  /// No description provided for @alertsGroupMissing.
  ///
  /// In en, this message translates to:
  /// **'This group is no longer available.'**
  String get alertsGroupMissing;

  /// No description provided for @alertsNoDestination.
  ///
  /// In en, this message translates to:
  /// **'This alert has no destination.'**
  String get alertsNoDestination;

  /// No description provided for @alertsLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get alertsLikes;

  /// No description provided for @alertsComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get alertsComments;

  /// No description provided for @alertsFriendPosts.
  ///
  /// In en, this message translates to:
  /// **'Friend posts'**
  String get alertsFriendPosts;

  /// No description provided for @alertsFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests, acceptances and follows'**
  String get alertsFriendRequests;

  /// No description provided for @alertSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get alertSomeone;

  /// No description provided for @alertFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a friend request.'**
  String alertFriendRequest(String name);

  /// No description provided for @alertFriendAccepted.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted your friend request.'**
  String alertFriendAccepted(String name);

  /// No description provided for @alertCommentBody.
  ///
  /// In en, this message translates to:
  /// **'{name} commented: {body}'**
  String alertCommentBody(String name, String body);

  /// No description provided for @alertComment.
  ///
  /// In en, this message translates to:
  /// **'{name} commented on your post.'**
  String alertComment(String name);

  /// No description provided for @alertPostLike.
  ///
  /// In en, this message translates to:
  /// **'{name} liked your post.'**
  String alertPostLike(String name);

  /// No description provided for @alertCommentLike.
  ///
  /// In en, this message translates to:
  /// **'{name} liked your comment.'**
  String alertCommentLike(String name);

  /// No description provided for @alertFollow.
  ///
  /// In en, this message translates to:
  /// **'{name} started following you.'**
  String alertFollow(String name);

  /// No description provided for @alertFriendPost.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a new post.'**
  String alertFriendPost(String name);

  /// No description provided for @alertChallengeInvite.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to a challenge.'**
  String alertChallengeInvite(String name);

  /// No description provided for @alertChallengeResult.
  ///
  /// In en, this message translates to:
  /// **'Your challenge results are ready.'**
  String get alertChallengeResult;

  /// No description provided for @alertBadge.
  ///
  /// In en, this message translates to:
  /// **'You earned a badge!'**
  String get alertBadge;

  /// No description provided for @alertAchievement.
  ///
  /// In en, this message translates to:
  /// **'You completed an achievement!'**
  String get alertAchievement;

  /// No description provided for @alertLevel.
  ///
  /// In en, this message translates to:
  /// **'You reached a new level!'**
  String get alertLevel;

  /// No description provided for @alertReward.
  ///
  /// In en, this message translates to:
  /// **'Your reward has been redeemed.'**
  String get alertReward;

  /// No description provided for @alertGroupRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} requested to join your group.'**
  String alertGroupRequest(String name);

  /// No description provided for @alertGroupApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} approved your group request.'**
  String alertGroupApproved(String name);

  /// No description provided for @alertGroupRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed you from a group.'**
  String alertGroupRemoved(String name);

  /// No description provided for @alertGroupBanned.
  ///
  /// In en, this message translates to:
  /// **'{name} banned you from a group.'**
  String alertGroupBanned(String name);

  /// No description provided for @alertGroupInvited.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to a group.'**
  String alertGroupInvited(String name);

  /// No description provided for @alertUnknown.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification.'**
  String get alertUnknown;

  /// No description provided for @plannerWeekRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String plannerWeekRange(String start, String end);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language / اللغة'**
  String get language;

  /// No description provided for @languageError.
  ///
  /// In en, this message translates to:
  /// **'Could not save language. Please try again.'**
  String get languageError;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make Privilege feel like yours'**
  String get settingsSubtitle;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @photoPrivate.
  ///
  /// In en, this message translates to:
  /// **'Stored privately on this device'**
  String get photoPrivate;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get opening;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'App appearance'**
  String get appearance;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose a color theme'**
  String get chooseTheme;

  /// No description provided for @savedDevice.
  ///
  /// In en, this message translates to:
  /// **'Your selection is saved on this device.'**
  String get savedDevice;

  /// No description provided for @choosePhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get choosePhotos;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @smallerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a smaller photo (under 900 KB).'**
  String get smallerPhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get photoUpdated;

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get photoRemoved;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera or photo library.'**
  String get cameraError;

  /// No description provided for @savePhotoError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile photo.'**
  String get savePhotoError;

  /// No description provided for @saveThemeError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your theme.'**
  String get saveThemeError;

  /// No description provided for @themePrivilege.
  ///
  /// In en, this message translates to:
  /// **'Privilege'**
  String get themePrivilege;

  /// No description provided for @themeOcean.
  ///
  /// In en, this message translates to:
  /// **'Deep Ocean'**
  String get themeOcean;

  /// No description provided for @themeForest.
  ///
  /// In en, this message translates to:
  /// **'Evergreen'**
  String get themeForest;

  /// No description provided for @themeViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet Edge'**
  String get themeViolet;

  /// No description provided for @themePrivilegeDescription.
  ///
  /// In en, this message translates to:
  /// **'Crimson energy with a premium gold finish'**
  String get themePrivilegeDescription;

  /// No description provided for @themeOceanDescription.
  ///
  /// In en, this message translates to:
  /// **'Midnight blue with bright, clear aqua'**
  String get themeOceanDescription;

  /// No description provided for @themeForestDescription.
  ///
  /// In en, this message translates to:
  /// **'Deep evergreen with a fresh mint spark'**
  String get themeForestDescription;

  /// No description provided for @themeVioletDescription.
  ///
  /// In en, this message translates to:
  /// **'Graphite plum with a luminous violet glow'**
  String get themeVioletDescription;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @splits.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get splits;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @arena.
  ///
  /// In en, this message translates to:
  /// **'Streak Arena'**
  String get arena;

  /// No description provided for @cheatMeals.
  ///
  /// In en, this message translates to:
  /// **'Cheat Meals'**
  String get cheatMeals;

  /// No description provided for @cravingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cravings & Treats'**
  String get cravingsTitle;

  /// No description provided for @classified.
  ///
  /// In en, this message translates to:
  /// **'Classified Level'**
  String get classified;

  /// No description provided for @academy.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get academy;

  /// No description provided for @academyTitle.
  ///
  /// In en, this message translates to:
  /// **'Fitness Academy'**
  String get academyTitle;

  /// No description provided for @vipPlans.
  ///
  /// In en, this message translates to:
  /// **'VIP Plans'**
  String get vipPlans;

  /// No description provided for @botTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI Privilege Bot'**
  String get botTooltip;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Create an account with your email and password.'**
  String get createAccountDescription;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'Log in with your email and password.'**
  String get loginDescription;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Use 8-72 characters with at least one letter and one number.'**
  String get passwordHint;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyAccount;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newAccount;

  /// No description provided for @loginUnavailableFeatures.
  ///
  /// In en, this message translates to:
  /// **'Password reset and social sign-in will be available after setup.'**
  String get loginUnavailableFeatures;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterPassword;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be 8-72 characters and include a letter and a number.'**
  String get invalidPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get invalidCredentials;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before logging in.'**
  String get emailNotConfirmed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your internet connection and try again.'**
  String get networkError;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in right now. Please try again.'**
  String get signInError;

  /// No description provided for @registrationError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please try again.'**
  String get registrationError;

  /// No description provided for @registrationCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created. Log in to continue.'**
  String get registrationCreated;

  /// No description provided for @registrationConfirm.
  ///
  /// In en, this message translates to:
  /// **'If this email can be registered, check your inbox for a confirmation link, then log in.'**
  String get registrationConfirm;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'ATHLETE TARGET SETUP'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize your athletic splits and calorie targets'**
  String get setupSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @exampleName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alex Johnson'**
  String get exampleName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers and underscores'**
  String get usernameHint;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @primaryGoal.
  ///
  /// In en, this message translates to:
  /// **'Primary Target Goal'**
  String get primaryGoal;

  /// No description provided for @goalChampionship.
  ///
  /// In en, this message translates to:
  /// **'Natural Championship Qualification'**
  String get goalChampionship;

  /// No description provided for @goalMuscle.
  ///
  /// In en, this message translates to:
  /// **'Lean Muscle Mass Hypertrophy'**
  String get goalMuscle;

  /// No description provided for @goalSports.
  ///
  /// In en, this message translates to:
  /// **'Sports & Strength Split Merger'**
  String get goalSports;

  /// No description provided for @goalFatLoss.
  ///
  /// In en, this message translates to:
  /// **'Metabolic Fat Loss & Calorie Deficit'**
  String get goalFatLoss;

  /// No description provided for @estimatedTarget.
  ///
  /// In en, this message translates to:
  /// **'Estimated Calorie Target:'**
  String get estimatedTarget;

  /// No description provided for @enterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter details and choose a goal'**
  String get enterDetails;

  /// No description provided for @kcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'kcal/day'**
  String get kcalPerDay;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup & Enter'**
  String get completeSetup;

  /// No description provided for @invalidUsername.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3 to 20 letters, numbers or underscores.'**
  String get invalidUsername;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name (up to 60 characters).'**
  String get invalidName;

  /// No description provided for @missingMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Enter both your weight and height.'**
  String get missingMeasurements;

  /// No description provided for @invalidMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Weight must be 35-250 kg and height 120-230 cm.'**
  String get invalidMeasurements;

  /// No description provided for @chooseGoal.
  ///
  /// In en, this message translates to:
  /// **'Choose a primary target goal.'**
  String get chooseGoal;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken.'**
  String get usernameTaken;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Please log in again.'**
  String get sessionExpired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
