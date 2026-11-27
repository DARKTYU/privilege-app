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

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @splashSlogan.
  ///
  /// In en, this message translates to:
  /// **'Eat Well; Stay Well'**
  String get splashSlogan;

  /// No description provided for @postImageOpen.
  ///
  /// In en, this message translates to:
  /// **'Open post image'**
  String get postImageOpen;

  /// No description provided for @postImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Post image'**
  String get postImageTitle;

  /// No description provided for @postImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Post image is unavailable.'**
  String get postImageUnavailable;

  /// No description provided for @postImageRetry.
  ///
  /// In en, this message translates to:
  /// **'Post image is unavailable. Retry'**
  String get postImageRetry;

  /// No description provided for @errorUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'Could not load notification count.'**
  String get errorUnreadCount;

  /// No description provided for @errorAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'Account changed. Please try again.'**
  String get errorAccountChanged;

  /// No description provided for @errorPlannerBusy.
  ///
  /// In en, this message translates to:
  /// **'A planner save is already in progress.'**
  String get errorPlannerBusy;

  /// No description provided for @errorActivityLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load today’s activity.'**
  String get errorActivityLoad;

  /// No description provided for @errorPointsBalance.
  ///
  /// In en, this message translates to:
  /// **'Could not load the store-points balance.'**
  String get errorPointsBalance;

  /// No description provided for @errorActivityDate.
  ///
  /// In en, this message translates to:
  /// **'Could not determine today’s activity date.'**
  String get errorActivityDate;

  /// No description provided for @errorFoodNotLinked.
  ///
  /// In en, this message translates to:
  /// **'This meal is not linked to a food in the database.'**
  String get errorFoodNotLinked;

  /// No description provided for @errorFoodChanged.
  ///
  /// In en, this message translates to:
  /// **'The food log could not be found or has changed.'**
  String get errorFoodChanged;

  /// No description provided for @errorFoodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This food is no longer available in the food database. The meal was not changed.'**
  String get errorFoodUnavailable;

  /// No description provided for @errorSplitMissing.
  ///
  /// In en, this message translates to:
  /// **'The split was not found or was already deleted.'**
  String get errorSplitMissing;

  /// No description provided for @errorDayMissing.
  ///
  /// In en, this message translates to:
  /// **'The planned day was not found or was already removed.'**
  String get errorDayMissing;

  /// No description provided for @errorCravingMissing.
  ///
  /// In en, this message translates to:
  /// **'The Cheat Meal was not found or was already deleted.'**
  String get errorCravingMissing;

  /// No description provided for @errorProfileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid profile details before saving.'**
  String get errorProfileInvalid;

  /// No description provided for @errorInvalidPlannerDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid planner date: {date}'**
  String errorInvalidPlannerDate(String date);

  /// No description provided for @errorProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be found. Contact the app administrator.'**
  String get errorProfileMissing;

  /// No description provided for @errorProfileNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be saved.'**
  String get errorProfileNotSaved;

  /// No description provided for @errorSignInSession.
  ///
  /// In en, this message translates to:
  /// **'Sign-in did not create a session.'**
  String get errorSignInSession;

  /// No description provided for @errorCompleteSignIn.
  ///
  /// In en, this message translates to:
  /// **'Could not complete sign-in. Please try again.'**
  String get errorCompleteSignIn;

  /// No description provided for @errorLogInSetup.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to finish setup.'**
  String get errorLogInSetup;

  /// No description provided for @errorReduceMeal.
  ///
  /// In en, this message translates to:
  /// **'There is no logged meal to reduce by {amount, plural, one{{amount} kcal} other{{amount} kcal}}.'**
  String errorReduceMeal(int amount);

  /// No description provided for @errorReduceWorkout.
  ///
  /// In en, this message translates to:
  /// **'There is no logged workout to reduce.'**
  String get errorReduceWorkout;

  /// No description provided for @activityTimeDuration.
  ///
  /// In en, this message translates to:
  /// **'{time} • {minutes, plural, one{{minutes}m} other{{minutes}m}}'**
  String activityTimeDuration(String time, int minutes);

  /// No description provided for @feedbackLoggedMeal.
  ///
  /// In en, this message translates to:
  /// **'Logged {name} (+{calories, plural, one{{calories} kcal} other{{calories} kcal}})!'**
  String feedbackLoggedMeal(String name, int calories);

  /// No description provided for @caloriesAddedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'+{calories} kcal added'**
  String caloriesAddedConfirmation(String calories);

  /// No description provided for @caloriesBurnedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'+{calories} kcal burned'**
  String caloriesBurnedConfirmation(String calories);

  /// No description provided for @feedbackUncheckedMeal.
  ///
  /// In en, this message translates to:
  /// **'Unchecked {name} (-{calories, plural, one{{calories} kcal} other{{calories} kcal}})!'**
  String feedbackUncheckedMeal(String name, int calories);

  /// No description provided for @feedbackAddedMeal.
  ///
  /// In en, this message translates to:
  /// **'Added meal {name} (+{calories, plural, one{{calories} kcal} other{{calories} kcal}})!'**
  String feedbackAddedMeal(String name, int calories);

  /// No description provided for @feedbackUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}.'**
  String feedbackUpdated(String name);

  /// No description provided for @feedbackRemovedMeal.
  ///
  /// In en, this message translates to:
  /// **'Removed {name} (-{calories, plural, one{{calories} kcal} other{{calories} kcal}})!'**
  String feedbackRemovedMeal(String name, int calories);

  /// No description provided for @feedbackAddedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Added workout {name} (-{calories, plural, one{{calories} kcal burn} other{{calories} kcal burn}})!'**
  String feedbackAddedWorkout(String name, int calories);

  /// No description provided for @feedbackRemovedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Removed {name} (-{calories, plural, one{{calories} kcal burn} other{{calories} kcal burn}})!'**
  String feedbackRemovedWorkout(String name, int calories);

  /// No description provided for @feedbackDeductFood.
  ///
  /// In en, this message translates to:
  /// **'Deducted {amount, plural, one{{amount} kcal} other{{amount} kcal}} from food intake!'**
  String feedbackDeductFood(int amount);

  /// No description provided for @feedbackDeductWorkout.
  ///
  /// In en, this message translates to:
  /// **'Deducted {amount, plural, one{{amount} kcal} other{{amount} kcal}} from workout burn!'**
  String feedbackDeductWorkout(int amount);

  /// No description provided for @groupTitle.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupTitle;

  /// No description provided for @groupReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get groupReport;

  /// No description provided for @groupReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get groupReason;

  /// No description provided for @groupBanQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ban member?'**
  String get groupBanQuestion;

  /// No description provided for @groupRemoveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get groupRemoveQuestion;

  /// No description provided for @groupBanDetails.
  ///
  /// In en, this message translates to:
  /// **'This bans the member until you unban them. Their posts and comments in this group are hidden and they cannot join again.'**
  String get groupBanDetails;

  /// No description provided for @groupRemoveDetails.
  ///
  /// In en, this message translates to:
  /// **'This removes the member and hides their posts and comments in this group. They can join again.'**
  String get groupRemoveDetails;

  /// No description provided for @groupCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get groupCancel;

  /// No description provided for @groupBan.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get groupBan;

  /// No description provided for @groupRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupRemove;

  /// No description provided for @groupUnavailableInvitation.
  ///
  /// In en, this message translates to:
  /// **'This group is unavailable. Private groups require an invitation.'**
  String get groupUnavailableInvitation;

  /// No description provided for @groupAcceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get groupAcceptInvitation;

  /// No description provided for @groupHeaderDetails.
  ///
  /// In en, this message translates to:
  /// **'{category} · {members}'**
  String groupHeaderDetails(String category, String members);

  /// No description provided for @groupMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get groupMenuSettings;

  /// No description provided for @groupInvitePeople.
  ///
  /// In en, this message translates to:
  /// **'Invite people'**
  String get groupInvitePeople;

  /// No description provided for @groupBannedMembers.
  ///
  /// In en, this message translates to:
  /// **'Banned members'**
  String get groupBannedMembers;

  /// No description provided for @groupReportGroup.
  ///
  /// In en, this message translates to:
  /// **'Report group'**
  String get groupReportGroup;

  /// No description provided for @groupRulesValue.
  ///
  /// In en, this message translates to:
  /// **'Rules: {rules}'**
  String groupRulesValue(String rules);

  /// No description provided for @groupLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get groupLeave;

  /// No description provided for @groupCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get groupCancelRequest;

  /// No description provided for @groupRequestJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
  String get groupRequestJoin;

  /// No description provided for @groupInvitationRequired.
  ///
  /// In en, this message translates to:
  /// **'Invitation required'**
  String get groupInvitationRequired;

  /// No description provided for @groupJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get groupJoin;

  /// No description provided for @groupJoinToSee.
  ///
  /// In en, this message translates to:
  /// **'Join to see posts and members.'**
  String get groupJoinToSee;

  /// No description provided for @groupPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get groupPosts;

  /// No description provided for @groupCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get groupCreatePost;

  /// No description provided for @groupModeratorsPost.
  ///
  /// In en, this message translates to:
  /// **'Only moderators can post.'**
  String get groupModeratorsPost;

  /// No description provided for @groupNoPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get groupNoPosts;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembers;

  /// No description provided for @groupNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members found.'**
  String get groupNoMembers;

  /// No description provided for @groupJoinRequests.
  ///
  /// In en, this message translates to:
  /// **'Join requests'**
  String get groupJoinRequests;

  /// No description provided for @groupUnbanQuestion.
  ///
  /// In en, this message translates to:
  /// **'Unban member?'**
  String get groupUnbanQuestion;

  /// No description provided for @groupUnbanDetails.
  ///
  /// In en, this message translates to:
  /// **'They can join again. Previously hidden posts and comments will remain hidden.'**
  String get groupUnbanDetails;

  /// No description provided for @groupUnban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get groupUnban;

  /// No description provided for @groupNoBanned.
  ///
  /// In en, this message translates to:
  /// **'No banned members.'**
  String get groupNoBanned;

  /// No description provided for @groupBannedDate.
  ///
  /// In en, this message translates to:
  /// **'Banned {date}'**
  String groupBannedDate(String date);

  /// No description provided for @groupBannedBy.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String groupBannedBy(String name);

  /// No description provided for @groupSearchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get groupSearchUsers;

  /// No description provided for @groupSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get groupSearch;

  /// No description provided for @groupSearchInvite.
  ///
  /// In en, this message translates to:
  /// **'Search for someone to invite.'**
  String get groupSearchInvite;

  /// No description provided for @groupNoPeople.
  ///
  /// In en, this message translates to:
  /// **'No people found.'**
  String get groupNoPeople;

  /// No description provided for @groupInvitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent.'**
  String get groupInvitationSent;

  /// No description provided for @groupInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get groupInvite;

  /// No description provided for @groupWritePost.
  ///
  /// In en, this message translates to:
  /// **'Write a post'**
  String get groupWritePost;

  /// No description provided for @groupAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get groupAddImage;

  /// No description provided for @groupImageChooseError.
  ///
  /// In en, this message translates to:
  /// **'Could not choose the image. Please try again.'**
  String get groupImageChooseError;

  /// No description provided for @groupImageTypeSizeError.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG or WebP image smaller than 8 MB.'**
  String get groupImageTypeSizeError;

  /// No description provided for @groupImageReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the image. Please choose it again.'**
  String get groupImageReadError;

  /// No description provided for @groupImageUploadError.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the image. Please try again.'**
  String get groupImageUploadError;

  /// No description provided for @groupShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get groupShare;

  /// No description provided for @groupProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable'**
  String get groupProfileUnavailable;

  /// No description provided for @groupOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupOwner;

  /// No description provided for @groupModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get groupModerator;

  /// No description provided for @groupApproveRequest.
  ///
  /// In en, this message translates to:
  /// **'Approve request'**
  String get groupApproveRequest;

  /// No description provided for @groupRemoveModerator.
  ///
  /// In en, this message translates to:
  /// **'Remove moderator role'**
  String get groupRemoveModerator;

  /// No description provided for @groupMakeModerator.
  ///
  /// In en, this message translates to:
  /// **'Make moderator'**
  String get groupMakeModerator;

  /// No description provided for @groupReportMember.
  ///
  /// In en, this message translates to:
  /// **'Report member'**
  String get groupReportMember;

  /// No description provided for @groupImageRetry.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable. Retry'**
  String get groupImageRetry;

  /// No description provided for @groupImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable.'**
  String get groupImageUnavailable;

  /// No description provided for @groupLikesRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load likes. Retry'**
  String get groupLikesRetry;

  /// No description provided for @groupNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get groupNoComments;

  /// No description provided for @groupComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get groupComment;

  /// No description provided for @groupSendComment.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get groupSendComment;

  /// No description provided for @groupsDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get groupsDiscover;

  /// No description provided for @groupsMine.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get groupsMine;

  /// No description provided for @groupsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get groupsCreate;

  /// No description provided for @groupsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search groups'**
  String get groupsSearch;

  /// No description provided for @groupsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get groupsCategory;

  /// No description provided for @groupsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupsAll;

  /// No description provided for @groupsWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight loss'**
  String get groupsWeightLoss;

  /// No description provided for @groupsMuscleBuilding.
  ///
  /// In en, this message translates to:
  /// **'Muscle building'**
  String get groupsMuscleBuilding;

  /// No description provided for @groupsRunning.
  ///
  /// In en, this message translates to:
  /// **'Running & cardio'**
  String get groupsRunning;

  /// No description provided for @groupsYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga & mobility'**
  String get groupsYoga;

  /// No description provided for @groupsNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get groupsNutrition;

  /// No description provided for @groupsBeginners.
  ///
  /// In en, this message translates to:
  /// **'Beginners'**
  String get groupsBeginners;

  /// No description provided for @groupsFitness.
  ///
  /// In en, this message translates to:
  /// **'General fitness'**
  String get groupsFitness;

  /// No description provided for @groupsOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get groupsOther;

  /// No description provided for @groupsPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get groupsPublic;

  /// No description provided for @groupsPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get groupsPrivate;

  /// No description provided for @groupsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get groupsOpen;

  /// No description provided for @groupsApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval needed'**
  String get groupsApproval;

  /// No description provided for @groupsInviteOnly.
  ///
  /// In en, this message translates to:
  /// **'Invite only'**
  String get groupsInviteOnly;

  /// No description provided for @groupsEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get groupsEveryone;

  /// No description provided for @groupsModerators.
  ///
  /// In en, this message translates to:
  /// **'Moderators'**
  String get groupsModerators;

  /// No description provided for @groupsInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get groupsInvitations;

  /// No description provided for @groupsInvitation.
  ///
  /// In en, this message translates to:
  /// **'Group invitation'**
  String get groupsInvitation;

  /// No description provided for @groupsOpenToAccept.
  ///
  /// In en, this message translates to:
  /// **'Open to accept'**
  String get groupsOpenToAccept;

  /// No description provided for @groupsNone.
  ///
  /// In en, this message translates to:
  /// **'No groups found.'**
  String get groupsNone;

  /// No description provided for @groupsSummary.
  ///
  /// In en, this message translates to:
  /// **'{category} · {visibility}'**
  String groupsSummary(String category, String visibility);

  /// No description provided for @groupsPendingSummary.
  ///
  /// In en, this message translates to:
  /// **'{summary} · Request pending'**
  String groupsPendingSummary(String summary);

  /// No description provided for @groupsMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 member} other{{count} members}}'**
  String groupsMemberCount(int count);

  /// No description provided for @groupsMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupsMember;

  /// No description provided for @groupsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get groupsRetry;

  /// No description provided for @groupsSettings.
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupsSettings;

  /// No description provided for @groupsChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get groupsChoosePhoto;

  /// No description provided for @groupsRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get groupsRemovePhoto;

  /// No description provided for @groupsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get groupsName;

  /// No description provided for @groupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupsDescription;

  /// No description provided for @groupsVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get groupsVisibility;

  /// No description provided for @groupsJoinMode.
  ///
  /// In en, this message translates to:
  /// **'Join mode'**
  String get groupsJoinMode;

  /// No description provided for @groupsPrivateInvitation.
  ///
  /// In en, this message translates to:
  /// **'Private groups require an invitation.'**
  String get groupsPrivateInvitation;

  /// No description provided for @groupsMemberLimit.
  ///
  /// In en, this message translates to:
  /// **'Member limit'**
  String get groupsMemberLimit;

  /// No description provided for @groupsWhoCanPost.
  ///
  /// In en, this message translates to:
  /// **'Who can post'**
  String get groupsWhoCanPost;

  /// No description provided for @groupsImagesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Images allowed'**
  String get groupsImagesAllowed;

  /// No description provided for @groupsChatSwitch.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get groupsChatSwitch;

  /// No description provided for @groupsChatSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Members can chat together inside the group.'**
  String get groupsChatSwitchHint;

  /// No description provided for @groupChatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open group chat'**
  String get groupChatOpen;

  /// No description provided for @groupChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get groupChatTitle;

  /// No description provided for @groupChatHint.
  ///
  /// In en, this message translates to:
  /// **'Message the group'**
  String get groupChatHint;

  /// No description provided for @groupChatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get groupChatSend;

  /// No description provided for @groupChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get groupChatEmpty;

  /// No description provided for @groupChatDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get groupChatDeleteMessage;

  /// No description provided for @groupChatOffError.
  ///
  /// In en, this message translates to:
  /// **'This group chat is turned off.'**
  String get groupChatOffError;

  /// No description provided for @groupChatRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'You are sending messages too fast. Please wait a moment.'**
  String get groupChatRateLimitError;

  /// No description provided for @groupsRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get groupsRules;

  /// No description provided for @groupsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get groupsSaving;

  /// No description provided for @groupsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get groupsSave;

  /// No description provided for @groupsCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max}'**
  String groupsCounter(String current, String max);

  /// No description provided for @groupsValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a name of at least 3 characters, a category, and a member limit from 1 to 10000.'**
  String get groupsValidation;

  /// No description provided for @groupsPhotoChooseError.
  ///
  /// In en, this message translates to:
  /// **'Could not choose the photo. Please try again.'**
  String get groupsPhotoChooseError;

  /// No description provided for @groupsPhotoSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the group photo. Please try again.'**
  String get groupsPhotoSaveError;

  /// No description provided for @groupsPhotoCreatedError.
  ///
  /// In en, this message translates to:
  /// **'Group created, but the photo could not be uploaded. You can add it from group settings.'**
  String get groupsPhotoCreatedError;

  /// No description provided for @groupsPhotoTypeError.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG or WebP photo.'**
  String get groupsPhotoTypeError;

  /// No description provided for @groupsPhotoReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the photo. Please choose it again.'**
  String get groupsPhotoReadError;

  /// No description provided for @groupsPhotoEmptyError.
  ///
  /// In en, this message translates to:
  /// **'The photo is empty. Choose another photo.'**
  String get groupsPhotoEmptyError;

  /// No description provided for @groupsPhotoMismatchError.
  ///
  /// In en, this message translates to:
  /// **'The photo does not match its file type. Choose a valid JPG, PNG or WebP image.'**
  String get groupsPhotoMismatchError;

  /// No description provided for @groupsPhotoSizeError.
  ///
  /// In en, this message translates to:
  /// **'The photo is too large. Choose one under 2 MB.'**
  String get groupsPhotoSizeError;

  /// No description provided for @groupsPhotoInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the photo. Choose a valid JPG, PNG or WebP image.'**
  String get groupsPhotoInvalidError;

  /// No description provided for @groupsBannedError.
  ///
  /// In en, this message translates to:
  /// **'You are banned from this group. Only the group owner or a moderator can unban you.'**
  String get groupsBannedError;

  /// No description provided for @groupsFullError.
  ///
  /// In en, this message translates to:
  /// **'This group is full.'**
  String get groupsFullError;

  /// No description provided for @groupsModeratorsOnlyError.
  ///
  /// In en, this message translates to:
  /// **'Only moderators can post in this group.'**
  String get groupsModeratorsOnlyError;

  /// No description provided for @groupsPostingLimitError.
  ///
  /// In en, this message translates to:
  /// **'Posting limit reached. Please try again later.'**
  String get groupsPostingLimitError;

  /// No description provided for @groupsCreationLimitError.
  ///
  /// In en, this message translates to:
  /// **'You can create up to 3 groups.'**
  String get groupsCreationLimitError;

  /// No description provided for @groupsUnavailableError.
  ///
  /// In en, this message translates to:
  /// **'This group is unavailable or requires an invitation.'**
  String get groupsUnavailableError;

  /// No description provided for @communityUsername.
  ///
  /// In en, this message translates to:
  /// **'@{username}'**
  String communityUsername(String username);

  /// No description provided for @communityLikePost.
  ///
  /// In en, this message translates to:
  /// **'Like post'**
  String get communityLikePost;

  /// No description provided for @communityUnlikePost.
  ///
  /// In en, this message translates to:
  /// **'Unlike post'**
  String get communityUnlikePost;

  /// No description provided for @communityOpenComments.
  ///
  /// In en, this message translates to:
  /// **'Open comments'**
  String get communityOpenComments;

  /// No description provided for @communityErrorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get communityErrorSignIn;

  /// No description provided for @communityErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your internet connection.'**
  String get communityErrorConnection;

  /// No description provided for @communityErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get communityErrorTimeout;

  /// No description provided for @communityErrorEmptyPost.
  ///
  /// In en, this message translates to:
  /// **'Write something before sharing your post.'**
  String get communityErrorEmptyPost;

  /// No description provided for @communityErrorPostLength.
  ///
  /// In en, this message translates to:
  /// **'Posts must be 5000 characters or fewer.'**
  String get communityErrorPostLength;

  /// No description provided for @communityErrorImageSize.
  ///
  /// In en, this message translates to:
  /// **'Choose an image smaller than 8 MB.'**
  String get communityErrorImageSize;

  /// No description provided for @communityErrorImageType.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG, or WebP image.'**
  String get communityErrorImageType;

  /// No description provided for @communityErrorDeleteOwn.
  ///
  /// In en, this message translates to:
  /// **'You can only delete your own post.'**
  String get communityErrorDeleteOwn;

  /// No description provided for @communityErrorCommentLength.
  ///
  /// In en, this message translates to:
  /// **'Comments must be 1–2000 characters.'**
  String get communityErrorCommentLength;

  /// No description provided for @communityPostGone.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available.'**
  String get communityPostGone;

  /// No description provided for @communityPostShared.
  ///
  /// In en, this message translates to:
  /// **'Your post was shared.'**
  String get communityPostShared;

  /// No description provided for @communityRequestGone.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer available.'**
  String get communityRequestGone;

  /// No description provided for @communityRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted.'**
  String get communityRequestAccepted;

  /// No description provided for @communityRequestRemoved.
  ///
  /// In en, this message translates to:
  /// **'Friend request removed.'**
  String get communityRequestRemoved;

  /// No description provided for @communityRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent.'**
  String get communityRequestSent;

  /// No description provided for @communityUnfollowed.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed.'**
  String get communityUnfollowed;

  /// No description provided for @communityFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following.'**
  String get communityFollowing;

  /// No description provided for @communityBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get communityBlocked;

  /// No description provided for @communityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated.'**
  String get communityUpdated;

  /// No description provided for @communityDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get communityDeleteQuestion;

  /// No description provided for @communityCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get communityCannotUndo;

  /// No description provided for @communityReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted.'**
  String get communityReportSubmitted;

  /// No description provided for @communityBlockQuestion.
  ///
  /// In en, this message translates to:
  /// **'Block @{username}?'**
  String communityBlockQuestion(String username);

  /// No description provided for @communityBlockDetails.
  ///
  /// In en, this message translates to:
  /// **'Their posts will no longer appear in your community.'**
  String get communityBlockDetails;

  /// No description provided for @communityDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get communityDeletePost;

  /// No description provided for @communityReportPost.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get communityReportPost;

  /// No description provided for @communityBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get communityBlockUser;

  /// No description provided for @communityImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Post image is unavailable.'**
  String get communityImageUnavailable;

  /// No description provided for @communityAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept request'**
  String get communityAcceptRequest;

  /// No description provided for @communityDeclineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get communityDeclineRequest;

  /// No description provided for @communityFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get communityFollow;

  /// No description provided for @communityUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get communityUnfollow;

  /// No description provided for @communitySendFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send friend request'**
  String get communitySendFriendRequest;

  /// No description provided for @communityRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Request pending'**
  String get communityRequestPending;

  /// No description provided for @communityReportHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us why this post should be reviewed.'**
  String get communityReportHint;

  /// No description provided for @communitySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get communitySubmit;

  /// No description provided for @communityReportValidation.
  ///
  /// In en, this message translates to:
  /// **'Please provide at least 3 characters.'**
  String get communityReportValidation;

  /// No description provided for @communityContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get communityContinue;

  /// No description provided for @communityClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get communityClose;

  /// No description provided for @communityPostHint.
  ///
  /// In en, this message translates to:
  /// **'Share a fitness or nutrition update...'**
  String get communityPostHint;

  /// No description provided for @communityAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get communityAddPhoto;

  /// No description provided for @communityRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get communityRemovePhoto;

  /// No description provided for @communityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get communityPublic;

  /// No description provided for @communitySharePost.
  ///
  /// In en, this message translates to:
  /// **'Share post'**
  String get communitySharePost;

  /// No description provided for @communityLikesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load likes: {error}'**
  String communityLikesError(String error);

  /// No description provided for @communityNoLikes.
  ///
  /// In en, this message translates to:
  /// **'No visible likes.'**
  String get communityNoLikes;

  /// No description provided for @communityLikedBy.
  ///
  /// In en, this message translates to:
  /// **'Liked by'**
  String get communityLikedBy;

  /// No description provided for @communityComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get communityComments;

  /// No description provided for @communityOlderComments.
  ///
  /// In en, this message translates to:
  /// **'Load older comments'**
  String get communityOlderComments;

  /// No description provided for @communityFirstComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment.'**
  String get communityFirstComment;

  /// No description provided for @communityLikedByAuthor.
  ///
  /// In en, this message translates to:
  /// **'Liked by author'**
  String get communityLikedByAuthor;

  /// No description provided for @communityLikeComment.
  ///
  /// In en, this message translates to:
  /// **'Like comment'**
  String get communityLikeComment;

  /// No description provided for @communityUnlikeComment.
  ///
  /// In en, this message translates to:
  /// **'Unlike comment'**
  String get communityUnlikeComment;

  /// No description provided for @communityCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get communityCommentHint;

  /// No description provided for @communitySendComment.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get communitySendComment;

  /// No description provided for @communityProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile is unavailable.'**
  String get communityProfileUnavailable;

  /// No description provided for @communityStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get communityStreak;

  /// No description provided for @communityBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get communityBest;

  /// No description provided for @communityPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get communityPosts;

  /// No description provided for @communityFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get communityFollowers;

  /// No description provided for @communityPostCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Posts} other{Posts}}'**
  String communityPostCountLabel(int count);

  /// No description provided for @communityFriendCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Friends} other{Friends}}'**
  String communityFriendCountLabel(int count);

  /// No description provided for @communityFollowerCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Followers} other{Followers}}'**
  String communityFollowerCountLabel(int count);

  /// No description provided for @communityLikeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count}} other{{count}}}'**
  String communityLikeCount(int count);

  /// No description provided for @communityCommentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count}} other{{count}}}'**
  String communityCommentCount(int count);

  /// No description provided for @communityNoBadges.
  ///
  /// In en, this message translates to:
  /// **'No badges earned yet.'**
  String get communityNoBadges;

  /// No description provided for @communityAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get communityAddFriend;

  /// No description provided for @arenaCreatePublic.
  ///
  /// In en, this message translates to:
  /// **'Create a public challenge'**
  String get arenaCreatePublic;

  /// No description provided for @arenaChallengeName.
  ///
  /// In en, this message translates to:
  /// **'Challenge name'**
  String get arenaChallengeName;

  /// No description provided for @arenaDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get arenaDescription;

  /// No description provided for @arenaChallengeType.
  ///
  /// In en, this message translates to:
  /// **'Challenge type'**
  String get arenaChallengeType;

  /// No description provided for @arenaActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get arenaActiveDays;

  /// No description provided for @arenaWorkoutCount.
  ///
  /// In en, this message translates to:
  /// **'Workout count'**
  String get arenaWorkoutCount;

  /// No description provided for @arenaDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get arenaDuration;

  /// No description provided for @arenaDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String arenaDays(int count);

  /// No description provided for @arenaWorkoutsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{countText} workout} other{{countText} workouts}}'**
  String arenaWorkoutsCount(int count, String countText);

  /// No description provided for @arenaNoPrizesRule.
  ///
  /// In en, this message translates to:
  /// **'Scores use self-reported activity logs and are unverified. No prizes are awarded.'**
  String get arenaNoPrizesRule;

  /// No description provided for @arenaNoCashRule.
  ///
  /// In en, this message translates to:
  /// **'Scores use self-reported activity logs and are unverified. There are no cash or real-world prizes.'**
  String get arenaNoCashRule;

  /// No description provided for @arenaCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get arenaCreate;

  /// No description provided for @arenaInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Challenge name must be at least 3 characters.'**
  String get arenaInvalidName;

  /// No description provided for @arenaCreated.
  ///
  /// In en, this message translates to:
  /// **'Public challenge created.'**
  String get arenaCreated;

  /// No description provided for @arenaNeedFriend.
  ///
  /// In en, this message translates to:
  /// **'Add a friend before creating a 1v1 challenge.'**
  String get arenaNeedFriend;

  /// No description provided for @arenaInvitationSent.
  ///
  /// In en, this message translates to:
  /// **'Friend challenge invitation sent.'**
  String get arenaInvitationSent;

  /// No description provided for @arenaJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined the challenge.'**
  String get arenaJoined;

  /// No description provided for @arenaAccepted.
  ///
  /// In en, this message translates to:
  /// **'Challenge accepted.'**
  String get arenaAccepted;

  /// No description provided for @arenaDeclined.
  ///
  /// In en, this message translates to:
  /// **'Challenge invitation declined.'**
  String get arenaDeclined;

  /// No description provided for @arenaRewardsStore.
  ///
  /// In en, this message translates to:
  /// **'Rewards Store'**
  String get arenaRewardsStore;

  /// No description provided for @arenaBadgesAchievements.
  ///
  /// In en, this message translates to:
  /// **'Badges & Achievements'**
  String get arenaBadgesAchievements;

  /// No description provided for @arenaSection.
  ///
  /// In en, this message translates to:
  /// **'Arena'**
  String get arenaSection;

  /// No description provided for @arenaCreateChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get arenaCreateChallenge;

  /// No description provided for @arenaPublicChallenge.
  ///
  /// In en, this message translates to:
  /// **'Public challenge'**
  String get arenaPublicChallenge;

  /// No description provided for @arenaChallengeFriend.
  ///
  /// In en, this message translates to:
  /// **'Challenge a friend'**
  String get arenaChallengeFriend;

  /// No description provided for @arenaYourActivity.
  ///
  /// In en, this message translates to:
  /// **'Your activity streak'**
  String get arenaYourActivity;

  /// No description provided for @arenaYourStreak.
  ///
  /// In en, this message translates to:
  /// **'Your streak: {days}'**
  String arenaYourStreak(String days);

  /// No description provided for @arenaLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak: {days}'**
  String arenaLongestStreak(String days);

  /// No description provided for @arenaStreakHelp.
  ///
  /// In en, this message translates to:
  /// **'Log a meal or completed workout to update your streak and earn 10 XP plus 10 store points once per active day.'**
  String get arenaStreakHelp;

  /// No description provided for @arenaChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get arenaChallenges;

  /// No description provided for @arenaLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get arenaLeaderboard;

  /// No description provided for @arenaDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get arenaDiscover;

  /// No description provided for @arenaMyChallenges.
  ///
  /// In en, this message translates to:
  /// **'My challenges'**
  String get arenaMyChallenges;

  /// No description provided for @arenaFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get arenaFinished;

  /// No description provided for @arenaFriendInvitations.
  ///
  /// In en, this message translates to:
  /// **'Friend invitations'**
  String get arenaFriendInvitations;

  /// No description provided for @arenaInvitation.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to a {metric} 1v1.'**
  String arenaInvitation(String name, String metric);

  /// No description provided for @arenaDateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String arenaDateRange(String start, String end);

  /// No description provided for @arenaDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get arenaDecline;

  /// No description provided for @arenaAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get arenaAccept;

  /// No description provided for @arenaNoOpen.
  ///
  /// In en, this message translates to:
  /// **'No open challenges yet. Create one to get started.'**
  String get arenaNoOpen;

  /// No description provided for @arenaNoChallenges.
  ///
  /// In en, this message translates to:
  /// **'No challenges to show here yet.'**
  String get arenaNoChallenges;

  /// No description provided for @arenaOneVOne.
  ///
  /// In en, this message translates to:
  /// **'1v1'**
  String get arenaOneVOne;

  /// No description provided for @arenaChallengeSummary.
  ///
  /// In en, this message translates to:
  /// **'{metric} · {dates}'**
  String arenaChallengeSummary(String metric, String dates);

  /// No description provided for @arenaParticipants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{countText} participant} other{{countText} participants}}'**
  String arenaParticipants(int count, String countText);

  /// No description provided for @arenaScore.
  ///
  /// In en, this message translates to:
  /// **'Your score: {score}'**
  String arenaScore(String score);

  /// No description provided for @arenaScoreRank.
  ///
  /// In en, this message translates to:
  /// **'Your score: {score} · #{rank}'**
  String arenaScoreRank(String score, String rank);

  /// No description provided for @arenaCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by {name}'**
  String arenaCreatedBy(String name);

  /// No description provided for @arenaJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining...'**
  String get arenaJoining;

  /// No description provided for @arenaJoin.
  ///
  /// In en, this message translates to:
  /// **'Join challenge'**
  String get arenaJoin;

  /// No description provided for @arenaNoStandings.
  ///
  /// In en, this message translates to:
  /// **'No standings yet.'**
  String get arenaNoStandings;

  /// No description provided for @arenaGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get arenaGlobal;

  /// No description provided for @arenaFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get arenaFriends;

  /// No description provided for @arenaMyLevel.
  ///
  /// In en, this message translates to:
  /// **'My level'**
  String get arenaMyLevel;

  /// No description provided for @arenaThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get arenaThisWeek;

  /// No description provided for @arenaThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get arenaThisMonth;

  /// No description provided for @arenaAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get arenaAllTime;

  /// No description provided for @arenaWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get arenaWorkouts;

  /// No description provided for @arenaNoRanked.
  ///
  /// In en, this message translates to:
  /// **'No activity has been ranked for this filter.'**
  String get arenaNoRanked;

  /// No description provided for @arenaCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Current streak: {count}} other{Current streak: {count}}}'**
  String arenaCurrentStreak(int count);

  /// No description provided for @arenaLevelStreak.
  ///
  /// In en, this message translates to:
  /// **'{level} · {streak}'**
  String arenaLevelStreak(String level, String streak);

  /// No description provided for @arenaCompletedWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Completed workouts'**
  String get arenaCompletedWorkouts;

  /// No description provided for @arenaFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get arenaFriend;

  /// No description provided for @arenaMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get arenaMetric;

  /// No description provided for @arenaSevenDayInvite.
  ///
  /// In en, this message translates to:
  /// **'Seven days · Invitation expires automatically.'**
  String get arenaSevenDayInvite;

  /// No description provided for @arenaSendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get arenaSendInvitation;

  /// No description provided for @communityHeading.
  ///
  /// In en, this message translates to:
  /// **'Your community'**
  String get communityHeading;

  /// No description provided for @communitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share progress and connect with others.'**
  String get communitySubtitle;

  /// No description provided for @communityCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Create a post'**
  String get communityCreatePost;

  /// No description provided for @communityFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get communityFeed;

  /// No description provided for @communityPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get communityPeople;

  /// No description provided for @communityGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get communityGroups;

  /// No description provided for @communityFeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Be the first to share!'**
  String get communityFeedEmpty;

  /// No description provided for @communitySearchPeople.
  ///
  /// In en, this message translates to:
  /// **'Search people'**
  String get communitySearchPeople;

  /// No description provided for @communityClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get communityClearSearch;

  /// No description provided for @communityFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get communityFriendRequests;

  /// No description provided for @communityFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get communityFriends;

  /// No description provided for @communityDiscoverPeople.
  ///
  /// In en, this message translates to:
  /// **'People to discover'**
  String get communityDiscoverPeople;

  /// No description provided for @communityResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get communityResults;

  /// No description provided for @communityNoPeople.
  ///
  /// In en, this message translates to:
  /// **'No people found. Try a different name or username.'**
  String get communityNoPeople;

  /// No description provided for @communityTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get communityTimeNow;

  /// No description provided for @communityMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute ago} other{{count} minutes ago}}'**
  String communityMinutesAgo(int count);

  /// No description provided for @communityHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour ago} other{{count} hours ago}}'**
  String communityHoursAgo(int count);

  /// No description provided for @communityDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day ago} other{{count} days ago}}'**
  String communityDaysAgo(int count);

  /// No description provided for @communityPostTime.
  ///
  /// In en, this message translates to:
  /// **'@{username} · {time}'**
  String communityPostTime(String username, String time);

  /// No description provided for @coachTitle.
  ///
  /// In en, this message translates to:
  /// **'Privilege Coach'**
  String get coachTitle;

  /// No description provided for @coachAiBadge.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get coachAiBadge;

  /// No description provided for @coachNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get coachNewChat;

  /// No description provided for @coachClose.
  ///
  /// In en, this message translates to:
  /// **'Close chat'**
  String get coachClose;

  /// No description provided for @coachInfo.
  ///
  /// In en, this message translates to:
  /// **'AI can make mistakes - not medical advice - tap for details'**
  String get coachInfo;

  /// No description provided for @coachAbout.
  ///
  /// In en, this message translates to:
  /// **'About the coach'**
  String get coachAbout;

  /// No description provided for @coachNoticeMistakes.
  ///
  /// In en, this message translates to:
  /// **'The coach can make mistakes.'**
  String get coachNoticeMistakes;

  /// No description provided for @coachNoticeMedical.
  ///
  /// In en, this message translates to:
  /// **'Not medical advice. For health problems, ask a doctor.'**
  String get coachNoticeMedical;

  /// No description provided for @coachNoticeCloud.
  ///
  /// In en, this message translates to:
  /// **'Messages are sent to Google Gemini to get a reply.'**
  String get coachNoticeCloud;

  /// No description provided for @coachNoticePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Do not share personal or health details you do not want sent.'**
  String get coachNoticePrivacy;

  /// No description provided for @coachNoticeMemory.
  ///
  /// In en, this message translates to:
  /// **'The coach does not remember earlier messages.'**
  String get coachNoticeMemory;

  /// No description provided for @coachGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get coachGotIt;

  /// No description provided for @coachConsent.
  ///
  /// In en, this message translates to:
  /// **'Share my calorie target and today’s totals with the coach'**
  String get coachConsent;

  /// No description provided for @coachAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get coachAttachPhoto;

  /// No description provided for @coachTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get coachTakePhoto;

  /// No description provided for @coachChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get coachChooseGallery;

  /// No description provided for @coachRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get coachRemovePhoto;

  /// No description provided for @coachPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The photo is too large. Choose one under 600 KB.'**
  String get coachPhotoTooLarge;

  /// No description provided for @coachPhotoNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This photo type is not allowed. Choose a JPEG, PNG, or WebP image.'**
  String get coachPhotoNotAllowed;

  /// No description provided for @coachPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open the selected photo. Please try again.'**
  String get coachPhotoUnavailable;

  /// No description provided for @coachPhotoConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the photo notice first.'**
  String get coachPhotoConsentRequired;

  /// No description provided for @coachPhotoQuotaError.
  ///
  /// In en, this message translates to:
  /// **'The daily photo limit has been reached. Photo requests use more of your daily allowance.'**
  String get coachPhotoQuotaError;

  /// No description provided for @coachPhotoNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Before sending a photo'**
  String get coachPhotoNoticeTitle;

  /// No description provided for @coachPhotoNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'The photo is sent to the AI provider to answer you. The provider\'s free tier may use data to improve its services. Do not include faces, ID cards, or private documents. Privilege does not store the photo.'**
  String get coachPhotoNoticeBody;

  /// No description provided for @coachContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get coachContinue;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @coachWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi! How can I help today?'**
  String get coachWelcome;

  /// No description provided for @coachTraining.
  ///
  /// In en, this message translates to:
  /// **'Suggest a full-body workout'**
  String get coachTraining;

  /// No description provided for @coachProteinRecipe.
  ///
  /// In en, this message translates to:
  /// **'High-protein recipe'**
  String get coachProteinRecipe;

  /// No description provided for @coachCaloriesLeft.
  ///
  /// In en, this message translates to:
  /// **'Calories left?'**
  String get coachCaloriesLeft;

  /// No description provided for @coachSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snack ideas'**
  String get coachSnacks;

  /// No description provided for @coachResponding.
  ///
  /// In en, this message translates to:
  /// **'Coach is responding…'**
  String get coachResponding;

  /// No description provided for @coachRequestsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Requests left today: {count}} other{Requests left today: {count}}}'**
  String coachRequestsLeft(int count);

  /// No description provided for @coachInputHint.
  ///
  /// In en, this message translates to:
  /// **'Message the coach'**
  String get coachInputHint;

  /// No description provided for @coachSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get coachSend;

  /// No description provided for @coachCounter.
  ///
  /// In en, this message translates to:
  /// **'{count}/2000'**
  String coachCounter(String count);

  /// No description provided for @coachPreferenceError.
  ///
  /// In en, this message translates to:
  /// **'Could not save or load consent. Please try again.'**
  String get coachPreferenceError;

  /// No description provided for @coachSignInError.
  ///
  /// In en, this message translates to:
  /// **'Sign in with an account to use the coach.'**
  String get coachSignInError;

  /// No description provided for @coachBirthDateError.
  ///
  /// In en, this message translates to:
  /// **'Add your birth date in Profile to use the coach.'**
  String get coachBirthDateError;

  /// No description provided for @coachAgeError.
  ///
  /// In en, this message translates to:
  /// **'The AI coach is for users 18 and over.'**
  String get coachAgeError;

  /// No description provided for @coachQuotaError.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached.'**
  String get coachQuotaError;

  /// No description provided for @coachQuotaResetError.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached. Resets: {date}'**
  String coachQuotaResetError(String date);

  /// No description provided for @coachUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The coach is unavailable right now.'**
  String get coachUnavailable;

  /// No description provided for @coachBusy.
  ///
  /// In en, this message translates to:
  /// **'The coach is busy right now. Please try again in a moment.'**
  String get coachBusy;

  /// No description provided for @coachLocalHelp.
  ///
  /// In en, this message translates to:
  /// **'Local help (not AI): ask about your calories, weekly plan or streak in the app.'**
  String get coachLocalHelp;

  /// No description provided for @coachUnavailableHelp.
  ///
  /// In en, this message translates to:
  /// **'{error}\n\n{help}'**
  String coachUnavailableHelp(String error, String help);

  /// No description provided for @coachTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get coachTryAgain;

  /// No description provided for @recipeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save favorites.'**
  String get recipeSignIn;

  /// No description provided for @recipeLoadFavoritesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load favorites: {error}'**
  String recipeLoadFavoritesError(String error);

  /// No description provided for @recipeSaveFavoriteError.
  ///
  /// In en, this message translates to:
  /// **'Could not save favorite: {error}'**
  String recipeSaveFavoriteError(String error);

  /// No description provided for @recipeDeviceSaveError.
  ///
  /// In en, this message translates to:
  /// **'The device did not save the favorite.'**
  String get recipeDeviceSaveError;

  /// No description provided for @recipeLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged {name} ({kcal, plural, one{{kcal} kcal} other{{kcal} kcal}})'**
  String recipeLogged(String name, int kcal);

  /// No description provided for @recipeLogError.
  ///
  /// In en, this message translates to:
  /// **'Could not log recipe: {error}'**
  String recipeLogError(String error);

  /// No description provided for @recipeDatabaseError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the food database.'**
  String get recipeDatabaseError;

  /// No description provided for @recipeSampleNotice.
  ///
  /// In en, this message translates to:
  /// **'Sample recipes. Favorites are saved on this device.'**
  String get recipeSampleNotice;

  /// No description provided for @recipeLoadingActivity.
  ///
  /// In en, this message translates to:
  /// **'Loading today’s activity...'**
  String get recipeLoadingActivity;

  /// No description provided for @recipeActivityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Today’s activity is unavailable.'**
  String get recipeActivityUnavailable;

  /// No description provided for @recipeTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Daily target unavailable.'**
  String get recipeTargetUnavailable;

  /// No description provided for @recipeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining today: {kcal, plural, one{{kcal} kcal} other{{kcal} kcal}} · {protein} g protein'**
  String recipeRemaining(int kcal, String protein);

  /// No description provided for @recipeTargetReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached today\'s target'**
  String get recipeTargetReached;

  /// No description provided for @recipeBestFit.
  ///
  /// In en, this message translates to:
  /// **'Best fit for today'**
  String get recipeBestFit;

  /// No description provided for @recipeAll.
  ///
  /// In en, this message translates to:
  /// **'All recipes'**
  String get recipeAll;

  /// No description provided for @recipeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get recipeFilterAll;

  /// No description provided for @recipeFits.
  ///
  /// In en, this message translates to:
  /// **'Fits today'**
  String get recipeFits;

  /// No description provided for @recipeHighProtein.
  ///
  /// In en, this message translates to:
  /// **'High protein'**
  String get recipeHighProtein;

  /// No description provided for @recipeHighFiber.
  ///
  /// In en, this message translates to:
  /// **'High fiber'**
  String get recipeHighFiber;

  /// No description provided for @recipeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get recipeLight;

  /// No description provided for @recipeQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get recipeQuick;

  /// No description provided for @recipeRetryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Retry favorites'**
  String get recipeRetryFavorites;

  /// No description provided for @recipeNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No recipes match this filter.'**
  String get recipeNoMatches;

  /// No description provided for @recipeRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get recipeRemoveFavorite;

  /// No description provided for @recipeAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add favorite'**
  String get recipeAddFavorite;

  /// No description provided for @recipeKcal.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, one{{amount} kcal} other{{amount} kcal}}'**
  String recipeKcal(int amount);

  /// No description provided for @recipeMacro.
  ///
  /// In en, this message translates to:
  /// **'{amount} g {macro}'**
  String recipeMacro(String amount, String macro);

  /// No description provided for @recipeSummary.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{{minutes} min} other{{minutes} min}} · {difficulty} · {meal}'**
  String recipeSummary(int minutes, String difficulty, String meal);

  /// No description provided for @recipeDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get recipeDifficultyEasy;

  /// No description provided for @recipeDifficultyEasyMedium.
  ///
  /// In en, this message translates to:
  /// **'Easy / Medium'**
  String get recipeDifficultyEasyMedium;

  /// No description provided for @recipeDifficultyInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get recipeDifficultyInstant;

  /// No description provided for @recipeEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated from ingredients'**
  String get recipeEstimated;

  /// No description provided for @recipeOver.
  ///
  /// In en, this message translates to:
  /// **'Over by {kcal, plural, one{{kcal} kcal} other{{kcal} kcal}}'**
  String recipeOver(int kcal);

  /// No description provided for @recipeNutritionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Nutrition not available'**
  String get recipeNutritionUnavailable;

  /// No description provided for @recipeLogging.
  ///
  /// In en, this message translates to:
  /// **'Logging...'**
  String get recipeLogging;

  /// No description provided for @recipeLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get recipeLog;

  /// No description provided for @recipePhotosError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recipe photos.'**
  String get recipePhotosError;

  /// No description provided for @recipePhotoIllustration.
  ///
  /// In en, this message translates to:
  /// **'Photo is for illustration'**
  String get recipePhotoIllustration;

  /// No description provided for @recipePhotoCredit.
  ///
  /// In en, this message translates to:
  /// **'Photo: {credit}'**
  String recipePhotoCredit(String credit);

  /// No description provided for @recipeDetails.
  ///
  /// In en, this message translates to:
  /// **'Recipe details'**
  String get recipeDetails;

  /// No description provided for @recipeNutritionPerServing.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per serving'**
  String get recipeNutritionPerServing;

  /// No description provided for @recipeMacroLine.
  ///
  /// In en, this message translates to:
  /// **'Protein {protein} g · Carbs {carbs} g · Fat {fat} g'**
  String recipeMacroLine(String protein, String carbs, String fat);

  /// No description provided for @recipeMicroLine.
  ///
  /// In en, this message translates to:
  /// **'Fiber {fiber} g · Sugar {sugar} g · Sodium {sodium} mg'**
  String recipeMicroLine(String fiber, String sugar, String sodium);

  /// No description provided for @recipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeIngredients;

  /// No description provided for @recipeIngredientAmount.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount} g'**
  String recipeIngredientAmount(String name, String amount);

  /// No description provided for @recipeIngredientUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ingredient details unavailable.'**
  String get recipeIngredientUnavailable;

  /// No description provided for @recipeHowToCook.
  ///
  /// In en, this message translates to:
  /// **'How to cook'**
  String get recipeHowToCook;

  /// No description provided for @recipeStep.
  ///
  /// In en, this message translates to:
  /// **'{number}. {step}'**
  String recipeStep(String number, String step);

  /// No description provided for @cravingLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log in again.'**
  String get cravingLogin;

  /// No description provided for @cravingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Cheat Meals: {error}'**
  String cravingLoadError(String error);

  /// No description provided for @cravingLimitError.
  ///
  /// In en, this message translates to:
  /// **'The selected month already has 2 Cheat Meals. {error}'**
  String cravingLimitError(String error);

  /// No description provided for @cravingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String cravingSaveError(String error);

  /// No description provided for @cravingValidate.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 200 characters.'**
  String get cravingValidate;

  /// No description provided for @cravingDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Cheat Meal?'**
  String get cravingDeleteTitle;

  /// No description provided for @cravingPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get cravingPreviousMonth;

  /// No description provided for @cravingNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get cravingNextMonth;

  /// No description provided for @cravingMonday.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get cravingMonday;

  /// No description provided for @cravingTuesday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get cravingTuesday;

  /// No description provided for @cravingWednesday.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get cravingWednesday;

  /// No description provided for @cravingThursday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get cravingThursday;

  /// No description provided for @cravingFriday.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get cravingFriday;

  /// No description provided for @cravingSaturday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get cravingSaturday;

  /// No description provided for @cravingSunday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get cravingSunday;

  /// No description provided for @cravingUsed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} of 2 used this month} other{{count} of 2 used this month}}'**
  String cravingUsed(int count);

  /// No description provided for @cravingMonthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit reached. Edit or delete an entry to make room.'**
  String get cravingMonthlyLimit;

  /// No description provided for @cravingDay.
  ///
  /// In en, this message translates to:
  /// **'Cheat Meal for day {day}'**
  String cravingDay(String day);

  /// No description provided for @cravingCharacters.
  ///
  /// In en, this message translates to:
  /// **'1 to 200 characters'**
  String get cravingCharacters;

  /// No description provided for @cravingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Cheat Meal'**
  String get cravingAdd;

  /// No description provided for @cravingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meals added yet.'**
  String get cravingEmpty;

  /// No description provided for @cravingEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cravingEdit;

  /// No description provided for @cravingEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Cheat Meal'**
  String get cravingEditTitle;

  /// No description provided for @cravingNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get cravingNotes;

  /// No description provided for @cravingDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String cravingDate(String date);

  /// No description provided for @academyAllGuides.
  ///
  /// In en, this message translates to:
  /// **'All Guides'**
  String get academyAllGuides;

  /// No description provided for @academyGymLifts.
  ///
  /// In en, this message translates to:
  /// **'Gym Lifts'**
  String get academyGymLifts;

  /// No description provided for @academySportMechanics.
  ///
  /// In en, this message translates to:
  /// **'Sport Mechanics'**
  String get academySportMechanics;

  /// No description provided for @academyStarterRules.
  ///
  /// In en, this message translates to:
  /// **'Starter Rules'**
  String get academyStarterRules;

  /// No description provided for @academyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'General information, not professional advice. Check with a qualified coach or doctor.'**
  String get academyDisclaimer;

  /// No description provided for @academyCues.
  ///
  /// In en, this message translates to:
  /// **'Key Execution Cues'**
  String get academyCues;

  /// No description provided for @academyMistakes.
  ///
  /// In en, this message translates to:
  /// **'Common Mistakes to Avoid'**
  String get academyMistakes;

  /// No description provided for @academyMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered Cue'**
  String get academyMastered;

  /// No description provided for @academySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Biomechanical masterclasses for gym lifts, sports conditioning & fitness foundations.'**
  String get academySubtitle;

  /// No description provided for @academySearch.
  ///
  /// In en, this message translates to:
  /// **'Search bench, squats, basketball, nutrition...'**
  String get academySearch;

  /// No description provided for @academyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No guides match your search.'**
  String get academyEmpty;

  /// No description provided for @academyMuscles.
  ///
  /// In en, this message translates to:
  /// **'Muscles: {muscles}'**
  String academyMuscles(String muscles);

  /// No description provided for @academyBurn.
  ///
  /// In en, this message translates to:
  /// **'about {kcal, plural, one{{kcal} kcal} other{{kcal} kcal}} / {minutes, plural, one{{minutes} mins} other{{minutes} mins}}'**
  String academyBurn(int kcal, int minutes);

  /// No description provided for @academyLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Knowledge'**
  String get academyLifetime;

  /// No description provided for @academyLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get academyLearn;

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
  /// **'Workout · {minutes, plural, one{{minutes} min} other{{minutes} min}} · {effort}% effort'**
  String plannerWorkoutSummary(int minutes, String effort);

  /// No description provided for @plannerSplitSummary.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{{minutes} min} other{{minutes} min}} · {effort}% effort'**
  String plannerSplitSummary(int minutes, String effort);

  /// No description provided for @plannerWorkoutNoDuration.
  ///
  /// In en, this message translates to:
  /// **'Workout · null min · {effort}% effort'**
  String plannerWorkoutNoDuration(String effort);

  /// No description provided for @plannerSplitNoDuration.
  ///
  /// In en, this message translates to:
  /// **'null min · {effort}% effort'**
  String plannerSplitNoDuration(String effort);

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
  /// **'{minutes, plural, one{{minutes} minutes} other{{minutes} minutes}}'**
  String mergeMinutes(int minutes);

  /// No description provided for @mergeShortMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{{minutes} min} other{{minutes} min}}'**
  String mergeShortMinutes(int minutes);

  /// No description provided for @mergeNamedValue.
  ///
  /// In en, this message translates to:
  /// **'{name}: {value}'**
  String mergeNamedValue(String name, String value);

  /// No description provided for @mergeCalories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{calories} kcal} other{{calories} kcal}}'**
  String mergeCalories(int count, String calories);

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
  /// **'{count, plural, one{{amount} kcal burned} other{{amount} kcal burned}}'**
  String burnedAmount(int count, String amount);

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
  /// **'Goal: {amount} kcal'**
  String burnTarget(String amount);

  /// No description provided for @burnGoalNote.
  ///
  /// In en, this message translates to:
  /// **'Daily burn goal • the total includes mobility workouts.'**
  String get burnGoalNote;

  /// No description provided for @burnRingNote.
  ///
  /// In en, this message translates to:
  /// **'Each ring uses the daily burn goal as its target.'**
  String get burnRingNote;

  /// No description provided for @totalBurn.
  ///
  /// In en, this message translates to:
  /// **'Total burn ({amount, plural, one{{amount} kcal} other{{amount} kcal}})'**
  String totalBurn(int amount);

  /// No description provided for @strengthBurn.
  ///
  /// In en, this message translates to:
  /// **'Strength burn ({amount, plural, one{{amount} kcal} other{{amount} kcal}})'**
  String strengthBurn(int amount);

  /// No description provided for @cardioBurn.
  ///
  /// In en, this message translates to:
  /// **'Cardio burn ({amount, plural, one{{amount} kcal} other{{amount} kcal}})'**
  String cardioBurn(int amount);

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
  /// **'{count, plural, one{Workout Logs ({count})} other{Workout Logs ({count})}}'**
  String workoutLogs(int count);

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
  /// **'{name} - {minutes, plural, one{{minutes} min} other{{minutes} min}}'**
  String workoutSavedTitle(String name, int minutes);

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
  /// **'≈ {amount, plural, one{{amount} kcal burned} other{{amount} kcal burned}}'**
  String workoutEstimate(int amount);

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
  /// **'Goal: {goal}{estimated} • {count, plural, one{Logged items: {count}} other{Logged items: {count}}}'**
  String foodGoalSummary(String goal, String estimated, int count);

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
  /// **'{calories, plural, one{{calories} kcal} other{{calories} kcal}} • {protein}g P'**
  String foodGroupTotals(int calories, String protein);

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
  /// **'{amount, plural, one{{amount}\nkcal} other{{amount}\nkcal}}'**
  String foodCaloriesLines(int amount);

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
  /// **'{shown, plural, one{Showing {shown} of {total}} other{Showing {shown} of {total}}}'**
  String explorerShowing(int shown, String total);

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
  /// **'Per 100 g: {calories, plural, one{{calories} kcal} other{{calories} kcal}}'**
  String explorerPer100(int calories);

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
  /// **'Logged {name} ({calories, plural, one{{calories} kcal} other{{calories} kcal}})'**
  String explorerLogged(String name, int calories);

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
  /// **'Goal adjustment: {count, plural, one{{amount} kcal} other{{amount} kcal}}{minor}'**
  String profileAdjustment(int count, String amount, String minor);

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
  /// **'Demo checkout: no real payment is taken. Real payments are not connected yet.'**
  String get membershipComingSoon;

  /// No description provided for @membershipPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get membershipPlansTitle;

  /// No description provided for @membershipPlansUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Plans could not be loaded.'**
  String get membershipPlansUnavailable;

  /// No description provided for @membershipFreePrice.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get membershipFreePrice;

  /// No description provided for @membershipPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} / 30 days'**
  String membershipPrice(String price);

  /// No description provided for @membershipPerkFree.
  ///
  /// In en, this message translates to:
  /// **'Base themes, frames and titles in the rewards store'**
  String get membershipPerkFree;

  /// No description provided for @membershipPerkSilver.
  ///
  /// In en, this message translates to:
  /// **'Everything in Free, plus Ember and Aurora themes, Gold and Platinum frames, and two extra titles'**
  String get membershipPerkSilver;

  /// No description provided for @membershipPerkGold.
  ///
  /// In en, this message translates to:
  /// **'Everything in Silver, plus the Galaxy theme, Diamond frame and Champion Spirit title'**
  String get membershipPerkGold;

  /// No description provided for @membershipChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose {plan}'**
  String membershipChoose(String plan);

  /// No description provided for @membershipCurrentPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get membershipCurrentPlanButton;

  /// No description provided for @membershipCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel membership'**
  String get membershipCancel;

  /// No description provided for @membershipKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep membership'**
  String get membershipKeep;

  /// No description provided for @membershipCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo checkout'**
  String get membershipCheckoutTitle;

  /// No description provided for @membershipCheckoutBody.
  ///
  /// In en, this message translates to:
  /// **'{summary}\n\nThis is a demo: no real payment is taken.'**
  String membershipCheckoutBody(String summary);

  /// No description provided for @membershipConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start demo membership'**
  String get membershipConfirm;

  /// No description provided for @membershipCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel your membership?'**
  String get membershipCancelTitle;

  /// No description provided for @membershipCancelBody.
  ///
  /// In en, this message translates to:
  /// **'You return to the Free plan right away. Rewards you already redeemed stay in your account.'**
  String get membershipCancelBody;

  /// No description provided for @membershipStarted.
  ///
  /// In en, this message translates to:
  /// **'Membership started: {plan}.'**
  String membershipStarted(String plan);

  /// No description provided for @membershipCancelled.
  ///
  /// In en, this message translates to:
  /// **'Membership cancelled.'**
  String get membershipCancelled;

  /// No description provided for @membershipActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this. Check your connection and try again.'**
  String get membershipActionFailed;

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

  /// No description provided for @memberHandle.
  ///
  /// In en, this message translates to:
  /// **'Member {id}'**
  String memberHandle(String id);

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

  /// No description provided for @progressLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load progress. Check your connection.'**
  String get progressLoadError;

  /// No description provided for @progressNoLevels.
  ///
  /// In en, this message translates to:
  /// **'No levels are available yet.'**
  String get progressNoLevels;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get levelPro;

  /// No description provided for @levelBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get levelBronze;

  /// No description provided for @levelSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get levelSilver;

  /// No description provided for @levelGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get levelGold;

  /// No description provided for @levelPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get levelPlatinum;

  /// No description provided for @levelDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get levelDiamond;

  /// No description provided for @levelElite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get levelElite;

  /// No description provided for @levelChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get levelChampion;

  /// No description provided for @progressLevel.
  ///
  /// In en, this message translates to:
  /// **'Level: {name}'**
  String progressLevel(String name);

  /// No description provided for @progressHighest.
  ///
  /// In en, this message translates to:
  /// **'{xp, plural, one{{xp} XP} other{{xp} XP}} · Highest level'**
  String progressHighest(int xp);

  /// No description provided for @progressNext.
  ///
  /// In en, this message translates to:
  /// **'{xp, plural, one{{xp} XP} other{{xp} XP}} · {remaining, plural, one{{remaining} XP} other{{remaining} XP}} to {name}'**
  String progressNext(int xp, int remaining, String name);

  /// No description provided for @progressFreeze.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Freeze token: {countText}} other{Freeze tokens: {countText}}}'**
  String progressFreeze(int count, String countText);

  /// No description provided for @progressPoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{countText} store point} other{{countText} store points}}'**
  String progressPoints(int count, String countText);

  /// No description provided for @rewardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Redeem {name}?'**
  String rewardConfirm(String name);

  /// No description provided for @rewardSpend.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Spend {count} store points?} other{Spend {count} store points?}}'**
  String rewardSpend(int count);

  /// No description provided for @rewardRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get rewardRedeem;

  /// No description provided for @rewardRequestSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the redemption request.'**
  String get rewardRequestSaveError;

  /// No description provided for @rewardRequestClearError.
  ///
  /// In en, this message translates to:
  /// **'Could not clear the completed redemption request.'**
  String get rewardRequestClearError;

  /// No description provided for @rewardDone.
  ///
  /// In en, this message translates to:
  /// **'Reward redeemed.'**
  String get rewardDone;

  /// No description provided for @rewardFreezeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Freeze tokens: {count} / 3} other{Freeze tokens: {count} / 3}}'**
  String rewardFreezeCount(int count);

  /// No description provided for @rewardInfo.
  ///
  /// In en, this message translates to:
  /// **'Digital items only. Themes, frames and titles are saved to your rewards; applying them is not available yet.'**
  String get rewardInfo;

  /// No description provided for @rewardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rewards are available right now.'**
  String get rewardEmpty;

  /// No description provided for @rewardUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited stock'**
  String get rewardUnlimited;

  /// No description provided for @rewardRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} remaining} other{{count} remaining}}'**
  String rewardRemaining(int count);

  /// No description provided for @rewardDetails.
  ///
  /// In en, this message translates to:
  /// **'{cost, plural, one{{cost} points} other{{cost} points}} · {tier} tier · {stock}'**
  String rewardDetails(int cost, String tier, String stock);

  /// No description provided for @rewardRequires.
  ///
  /// In en, this message translates to:
  /// **'Requires {tier} tier'**
  String rewardRequires(String tier);

  /// No description provided for @rewardNeedPoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Need {count} more points} other{Need {count} more points}}'**
  String rewardNeedPoints(int count);

  /// No description provided for @rewardRedeeming.
  ///
  /// In en, this message translates to:
  /// **'Redeeming...'**
  String get rewardRedeeming;

  /// No description provided for @rewardOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get rewardOwned;

  /// No description provided for @rewardOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get rewardOutOfStock;

  /// No description provided for @rewardErrorPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough store points.'**
  String get rewardErrorPoints;

  /// No description provided for @rewardErrorStock.
  ///
  /// In en, this message translates to:
  /// **'This reward is out of stock.'**
  String get rewardErrorStock;

  /// No description provided for @rewardErrorTier.
  ///
  /// In en, this message translates to:
  /// **'Your subscription tier does not qualify for this reward.'**
  String get rewardErrorTier;

  /// No description provided for @rewardErrorTokens.
  ///
  /// In en, this message translates to:
  /// **'You can hold at most three freeze tokens.'**
  String get rewardErrorTokens;

  /// No description provided for @rewardErrorOwned.
  ///
  /// In en, this message translates to:
  /// **'You already own this item.'**
  String get rewardErrorOwned;

  /// No description provided for @rewardErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This reward is no longer available.'**
  String get rewardErrorUnavailable;

  /// No description provided for @rewardErrorGeneral.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm redemption. Check your connection and retry.'**
  String get rewardErrorGeneral;

  /// No description provided for @progressBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get progressBadges;

  /// No description provided for @progressNoBadges.
  ///
  /// In en, this message translates to:
  /// **'No badges available yet.'**
  String get progressNoBadges;

  /// No description provided for @progressEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get progressEarned;

  /// No description provided for @progressLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get progressLocked;

  /// No description provided for @progressBadgeDetails.
  ///
  /// In en, this message translates to:
  /// **'{description}\n{status}'**
  String progressBadgeDetails(String description, String status);

  /// No description provided for @progressAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get progressAchievements;

  /// No description provided for @progressNoAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements available yet.'**
  String get progressNoAchievements;

  /// No description provided for @progressAchievementValue.
  ///
  /// In en, this message translates to:
  /// **'{progress} / {threshold} · {xp, plural, one{{xp} XP} other{{xp} XP}}'**
  String progressAchievementValue(String progress, String threshold, int xp);

  /// No description provided for @progressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get progressCompleted;

  /// No description provided for @pathSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save checklist: {error}'**
  String pathSaveError(String error);

  /// No description provided for @pathTracked.
  ///
  /// In en, this message translates to:
  /// **'Tracked by the app · {value}'**
  String pathTracked(String value);

  /// No description provided for @pathSelfReported.
  ///
  /// In en, this message translates to:
  /// **'Self-reported, not verified'**
  String get pathSelfReported;

  /// No description provided for @pathOutside.
  ///
  /// In en, this message translates to:
  /// **'Done outside the app'**
  String get pathOutside;

  /// No description provided for @pathLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get pathLoading;

  /// No description provided for @pathTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pathway'**
  String get pathTitle;

  /// No description provided for @pathDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Self-reported progress, not verified or certified'**
  String get pathDisclaimer;

  /// No description provided for @pathLoadingChecks.
  ///
  /// In en, this message translates to:
  /// **'Loading checklist...'**
  String get pathLoadingChecks;

  /// No description provided for @pathLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load checklist: {error}'**
  String pathLoadError(String error);

  /// No description provided for @pathFoundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get pathFoundation;

  /// No description provided for @pathLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak (all time)'**
  String get pathLongestStreak;

  /// No description provided for @pathDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{{days} days} other{{days} days}}'**
  String pathDays(int days);

  /// No description provided for @pathSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set a personal training goal'**
  String get pathSetGoal;

  /// No description provided for @pathLearnBasics.
  ///
  /// In en, this message translates to:
  /// **'Learn the basics of your chosen sport'**
  String get pathLearnBasics;

  /// No description provided for @pathNovice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get pathNovice;

  /// No description provided for @pathWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts logged (all time)'**
  String get pathWorkouts;

  /// No description provided for @pathRoutine.
  ///
  /// In en, this message translates to:
  /// **'Practice a consistent routine'**
  String get pathRoutine;

  /// No description provided for @pathCoach.
  ///
  /// In en, this message translates to:
  /// **'Ask a qualified coach for feedback'**
  String get pathCoach;

  /// No description provided for @pathCompetitor.
  ///
  /// In en, this message translates to:
  /// **'Competitor-ready'**
  String get pathCompetitor;

  /// No description provided for @pathMeals.
  ///
  /// In en, this message translates to:
  /// **'Consumed meals logged (all time)'**
  String get pathMeals;

  /// No description provided for @pathSkills.
  ///
  /// In en, this message translates to:
  /// **'Practice your event skills'**
  String get pathSkills;

  /// No description provided for @pathRequirements.
  ///
  /// In en, this message translates to:
  /// **'Review an event organizer’s requirements'**
  String get pathRequirements;

  /// No description provided for @pathNational.
  ///
  /// In en, this message translates to:
  /// **'National level'**
  String get pathNational;

  /// No description provided for @pathAppLevel.
  ///
  /// In en, this message translates to:
  /// **'App level'**
  String get pathAppLevel;

  /// No description provided for @pathNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get pathNotAvailable;

  /// No description provided for @pathMilestone.
  ///
  /// In en, this message translates to:
  /// **'Plan your next training milestone'**
  String get pathMilestone;

  /// No description provided for @pathEvents.
  ///
  /// In en, this message translates to:
  /// **'Explore national events and their rules'**
  String get pathEvents;

  /// No description provided for @pathPro.
  ///
  /// In en, this message translates to:
  /// **'Pro pathway'**
  String get pathPro;

  /// No description provided for @pathPreparation.
  ///
  /// In en, this message translates to:
  /// **'Make a long-term preparation plan'**
  String get pathPreparation;

  /// No description provided for @pathResearch.
  ///
  /// In en, this message translates to:
  /// **'Research the official pathway for your sport'**
  String get pathResearch;

  /// No description provided for @pathRegister.
  ///
  /// In en, this message translates to:
  /// **'How to register: check the organizer\'s official site for rules and registration'**
  String get pathRegister;

  /// No description provided for @plannerWeekRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String plannerWeekRange(String start, String end);

  /// No description provided for @defaultHighProteinFuel.
  ///
  /// In en, this message translates to:
  /// **'High-Protein Fuel'**
  String get defaultHighProteinFuel;

  /// No description provided for @defaultAthleticTraining.
  ///
  /// In en, this message translates to:
  /// **'Athletic Training'**
  String get defaultAthleticTraining;

  /// No description provided for @defaultQuickCalorieSnack.
  ///
  /// In en, this message translates to:
  /// **'Quick Calorie Snack'**
  String get defaultQuickCalorieSnack;

  /// No description provided for @defaultQuickExerciseBurn.
  ///
  /// In en, this message translates to:
  /// **'Quick Exercise Burn'**
  String get defaultQuickExerciseBurn;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
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
  /// **'Cheat Meals'**
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
  /// **'Social sign-in will be available later.'**
  String get loginUnavailableFeatures;

  /// No description provided for @loginOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOrDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @socialSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with that account. Please try again.'**
  String get socialSignInFailed;

  /// No description provided for @privacyDeleteTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get privacyDeleteTypeLabel;

  /// No description provided for @privacyDeleteTypeMismatch.
  ///
  /// In en, this message translates to:
  /// **'Type the word DELETE exactly.'**
  String get privacyDeleteTypeMismatch;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to request the code from your email.'**
  String get resetInstructions;

  /// No description provided for @resetChoosePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetChoosePassword;

  /// No description provided for @resetCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email and your new password.'**
  String get resetCodeInstructions;

  /// No description provided for @resetSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get resetSendCode;

  /// No description provided for @resetCode.
  ///
  /// In en, this message translates to:
  /// **'Code from your email'**
  String get resetCode;

  /// No description provided for @resetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetNewPassword;

  /// No description provided for @resetUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get resetUpdatePassword;

  /// No description provided for @resetResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resetResendCode;

  /// No description provided for @resetResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} seconds'**
  String resetResendCountdown(int seconds);

  /// No description provided for @resetNeutralMessage.
  ///
  /// In en, this message translates to:
  /// **'If this email has an account, we sent a code.'**
  String get resetNeutralMessage;

  /// No description provided for @resetCodeFormatError.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email using 6 to 10 digits.'**
  String get resetCodeFormatError;

  /// No description provided for @resetInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code is invalid or has expired. Request a new code and try again.'**
  String get resetInvalidCode;

  /// No description provided for @resetTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get resetTooManyRequests;

  /// No description provided for @resetError.
  ///
  /// In en, this message translates to:
  /// **'Could not reset the password. Please try again.'**
  String get resetError;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password was updated. You can now log in.'**
  String get resetSuccess;

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
  /// **'No internet connection. Check your connection and try again.'**
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
  /// **'Train for a natural (drug-free) competition'**
  String get goalChampionship;

  /// No description provided for @goalMuscle.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get goalMuscle;

  /// No description provided for @goalSports.
  ///
  /// In en, this message translates to:
  /// **'Mix sports and strength training'**
  String get goalSports;

  /// No description provided for @goalFatLoss.
  ///
  /// In en, this message translates to:
  /// **'Lose body fat'**
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

  /// No description provided for @privacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyDataTitle;

  /// No description provided for @privacyDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How your app data is stored and used'**
  String get privacyDataSubtitle;

  /// No description provided for @privacyStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'What we store'**
  String get privacyStoreTitle;

  /// No description provided for @privacyStoreBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile, food and workout logs, community content you post, and your progress are stored in the app\'s Supabase database. Your profile photo and theme stay only on your device.'**
  String get privacyStoreBody;

  /// No description provided for @privacyCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'AI coach'**
  String get privacyCoachTitle;

  /// No description provided for @privacyCoachBody.
  ///
  /// In en, this message translates to:
  /// **'Messages are sent to Google Gemini to get a reply and are not stored by the app. Calorie numbers are shared only if you turn on the consent switch. Do not share personal or health details you do not want sent. The coach can make mistakes and is not medical advice.'**
  String get privacyCoachBody;

  /// No description provided for @privacyChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your choices'**
  String get privacyChoicesTitle;

  /// No description provided for @privacyConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Share calorie information with the coach'**
  String get privacyConsentTitle;

  /// No description provided for @privacyConsentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses the same consent setting as the AI coach.'**
  String get privacyConsentSubtitle;

  /// No description provided for @privacyDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data deletion'**
  String get privacyDeletionTitle;

  /// No description provided for @privacyDeletionBody.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data linked to it. This cannot be undone.'**
  String get privacyDeletionBody;

  /// No description provided for @privacySupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get privacySupport;

  /// No description provided for @privacyCopyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy email'**
  String get privacyCopyEmail;

  /// No description provided for @privacyEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Support email copied.'**
  String get privacyEmailCopied;

  /// No description provided for @privacyEmailCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the support email.'**
  String get privacyEmailCopyFailed;

  /// No description provided for @privacySignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get privacySignOut;

  /// No description provided for @privacyDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get privacyDeleteButton;

  /// No description provided for @privacyDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account permanently?'**
  String get privacyDeleteDialogTitle;

  /// No description provided for @privacyDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, food and workout logs, XP, badges, posts, comments, friendships and the groups you own, including their photos. This cannot be undone.'**
  String get privacyDeleteDialogBody;

  /// No description provided for @privacyDeletePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get privacyDeletePasswordLabel;

  /// No description provided for @privacyDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get privacyDeleteConfirm;

  /// No description provided for @privacyDeleteWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'That password is not correct.'**
  String get privacyDeleteWrongPassword;

  /// No description provided for @privacyDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Your account could not be deleted. Please check your connection and try again.'**
  String get privacyDeleteFailed;

  /// No description provided for @privacyDeleteDone.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get privacyDeleteDone;
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
