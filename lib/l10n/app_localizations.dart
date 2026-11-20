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

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get profileSaveError;

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
