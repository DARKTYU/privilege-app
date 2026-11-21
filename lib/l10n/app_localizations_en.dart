// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get splashSlogan => 'Eat Well; Stay Well';

  @override
  String get postImageOpen => 'Open post image';

  @override
  String get postImageTitle => 'Post image';

  @override
  String get postImageUnavailable => 'Post image is unavailable.';

  @override
  String get postImageRetry => 'Post image is unavailable. Retry';

  @override
  String get errorUnreadCount => 'Could not load notification count.';

  @override
  String get errorAccountChanged => 'Account changed. Please try again.';

  @override
  String get errorPlannerBusy => 'A planner save is already in progress.';

  @override
  String get errorActivityLoad => 'Could not load today’s activity.';

  @override
  String get errorPointsBalance => 'Could not load the store-points balance.';

  @override
  String get errorActivityDate => 'Could not determine today’s activity date.';

  @override
  String get errorFoodNotLinked =>
      'This meal is not linked to a food in the database.';

  @override
  String get errorFoodChanged =>
      'The food log could not be found or has changed.';

  @override
  String get errorFoodUnavailable =>
      'This food is no longer available in the food database. The meal was not changed.';

  @override
  String get errorSplitMissing =>
      'The split was not found or was already deleted.';

  @override
  String get errorDayMissing =>
      'The planned day was not found or was already removed.';

  @override
  String get errorCravingMissing =>
      'The Cheat Meal was not found or was already deleted.';

  @override
  String get errorProfileInvalid =>
      'Enter valid profile details before saving.';

  @override
  String errorInvalidPlannerDate(String date) {
    return 'Invalid planner date: $date';
  }

  @override
  String get errorProfileMissing =>
      'Your profile could not be found. Contact the app administrator.';

  @override
  String get errorProfileNotSaved => 'Your profile could not be saved.';

  @override
  String get errorSignInSession => 'Sign-in did not create a session.';

  @override
  String get errorCompleteSignIn =>
      'Could not complete sign-in. Please try again.';

  @override
  String get errorLogInSetup => 'Please log in again to finish setup.';

  @override
  String errorReduceMeal(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount kcal',
      one: '$amount kcal',
    );
    return 'There is no logged meal to reduce by $_temp0.';
  }

  @override
  String get errorReduceWorkout => 'There is no logged workout to reduce.';

  @override
  String activityTimeDuration(String time, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '${minutes}m',
      one: '${minutes}m',
    );
    return '$time • $_temp0';
  }

  @override
  String feedbackLoggedMeal(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal',
      one: '$calories kcal',
    );
    return 'Logged $name (+$_temp0)!';
  }

  @override
  String feedbackUncheckedMeal(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal',
      one: '$calories kcal',
    );
    return 'Unchecked $name (-$_temp0)!';
  }

  @override
  String feedbackAddedMeal(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal',
      one: '$calories kcal',
    );
    return 'Added meal $name (+$_temp0)!';
  }

  @override
  String feedbackUpdated(String name) {
    return 'Updated $name.';
  }

  @override
  String feedbackRemovedMeal(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal',
      one: '$calories kcal',
    );
    return 'Removed $name (-$_temp0)!';
  }

  @override
  String feedbackAddedWorkout(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal burn',
      one: '$calories kcal burn',
    );
    return 'Added workout $name (-$_temp0)!';
  }

  @override
  String feedbackRemovedWorkout(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal burn',
      one: '$calories kcal burn',
    );
    return 'Removed $name (-$_temp0)!';
  }

  @override
  String feedbackDeductFood(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount kcal',
      one: '$amount kcal',
    );
    return 'Deducted $_temp0 from food intake!';
  }

  @override
  String feedbackDeductWorkout(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount kcal',
      one: '$amount kcal',
    );
    return 'Deducted $_temp0 from workout burn!';
  }

  @override
  String get groupTitle => 'Group';

  @override
  String get groupReport => 'Report';

  @override
  String get groupReason => 'Reason';

  @override
  String get groupBanQuestion => 'Ban member?';

  @override
  String get groupRemoveQuestion => 'Remove member?';

  @override
  String get groupBanDetails =>
      'This bans the member until you unban them. Their posts and comments in this group are hidden and they cannot join again.';

  @override
  String get groupRemoveDetails =>
      'This removes the member and hides their posts and comments in this group. They can join again.';

  @override
  String get groupCancel => 'Cancel';

  @override
  String get groupBan => 'Ban';

  @override
  String get groupRemove => 'Remove';

  @override
  String get groupUnavailableInvitation =>
      'This group is unavailable. Private groups require an invitation.';

  @override
  String get groupAcceptInvitation => 'Accept invitation';

  @override
  String groupHeaderDetails(String category, String members) {
    return '$category · $members';
  }

  @override
  String get groupMenuSettings => 'Settings';

  @override
  String get groupInvitePeople => 'Invite people';

  @override
  String get groupBannedMembers => 'Banned members';

  @override
  String get groupReportGroup => 'Report group';

  @override
  String groupRulesValue(String rules) {
    return 'Rules: $rules';
  }

  @override
  String get groupLeave => 'Leave group';

  @override
  String get groupCancelRequest => 'Cancel request';

  @override
  String get groupRequestJoin => 'Request to join';

  @override
  String get groupInvitationRequired => 'Invitation required';

  @override
  String get groupJoin => 'Join';

  @override
  String get groupJoinToSee => 'Join to see posts and members.';

  @override
  String get groupPosts => 'Posts';

  @override
  String get groupCreatePost => 'Create post';

  @override
  String get groupModeratorsPost => 'Only moderators can post.';

  @override
  String get groupNoPosts => 'No posts yet.';

  @override
  String get groupMembers => 'Members';

  @override
  String get groupNoMembers => 'No members found.';

  @override
  String get groupJoinRequests => 'Join requests';

  @override
  String get groupUnbanQuestion => 'Unban member?';

  @override
  String get groupUnbanDetails =>
      'They can join again. Previously hidden posts and comments will remain hidden.';

  @override
  String get groupUnban => 'Unban';

  @override
  String get groupNoBanned => 'No banned members.';

  @override
  String groupBannedDate(String date) {
    return 'Banned $date';
  }

  @override
  String groupBannedBy(String name) {
    return 'By $name';
  }

  @override
  String get groupSearchUsers => 'Search users';

  @override
  String get groupSearch => 'Search';

  @override
  String get groupSearchInvite => 'Search for someone to invite.';

  @override
  String get groupNoPeople => 'No people found.';

  @override
  String get groupInvitationSent => 'Invitation sent.';

  @override
  String get groupInvite => 'Invite';

  @override
  String get groupWritePost => 'Write a post';

  @override
  String get groupAddImage => 'Add image';

  @override
  String get groupImageChooseError =>
      'Could not choose the image. Please try again.';

  @override
  String get groupImageTypeSizeError =>
      'Choose a JPG, PNG or WebP image smaller than 8 MB.';

  @override
  String get groupImageReadError =>
      'Could not read the image. Please choose it again.';

  @override
  String get groupImageUploadError =>
      'Could not upload the image. Please try again.';

  @override
  String get groupShare => 'Share';

  @override
  String get groupProfileUnavailable => 'Profile unavailable';

  @override
  String get groupOwner => 'Owner';

  @override
  String get groupModerator => 'Moderator';

  @override
  String get groupApproveRequest => 'Approve request';

  @override
  String get groupRemoveModerator => 'Remove moderator role';

  @override
  String get groupMakeModerator => 'Make moderator';

  @override
  String get groupReportMember => 'Report member';

  @override
  String get groupImageRetry => 'Image unavailable. Retry';

  @override
  String get groupImageUnavailable => 'Image unavailable.';

  @override
  String get groupLikesRetry => 'Could not load likes. Retry';

  @override
  String get groupNoComments => 'No comments yet.';

  @override
  String get groupComment => 'Comment';

  @override
  String get groupSendComment => 'Send comment';

  @override
  String get groupsDiscover => 'Discover';

  @override
  String get groupsMine => 'My groups';

  @override
  String get groupsCreate => 'Create group';

  @override
  String get groupsSearch => 'Search groups';

  @override
  String get groupsCategory => 'Category';

  @override
  String get groupsAll => 'All';

  @override
  String get groupsWeightLoss => 'Weight loss';

  @override
  String get groupsMuscleBuilding => 'Muscle building';

  @override
  String get groupsRunning => 'Running & cardio';

  @override
  String get groupsYoga => 'Yoga & mobility';

  @override
  String get groupsNutrition => 'Nutrition';

  @override
  String get groupsBeginners => 'Beginners';

  @override
  String get groupsFitness => 'General fitness';

  @override
  String get groupsOther => 'Other';

  @override
  String get groupsPublic => 'Public';

  @override
  String get groupsPrivate => 'Private';

  @override
  String get groupsOpen => 'Open';

  @override
  String get groupsApproval => 'Approval needed';

  @override
  String get groupsInviteOnly => 'Invite only';

  @override
  String get groupsEveryone => 'Everyone';

  @override
  String get groupsModerators => 'Moderators';

  @override
  String get groupsInvitations => 'Invitations';

  @override
  String get groupsInvitation => 'Group invitation';

  @override
  String get groupsOpenToAccept => 'Open to accept';

  @override
  String get groupsNone => 'No groups found.';

  @override
  String groupsSummary(String category, String visibility) {
    return '$category · $visibility';
  }

  @override
  String groupsPendingSummary(String summary) {
    return '$summary · Request pending';
  }

  @override
  String groupsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get groupsMember => 'Member';

  @override
  String get groupsRetry => 'Try again';

  @override
  String get groupsSettings => 'Group settings';

  @override
  String get groupsChoosePhoto => 'Choose photo';

  @override
  String get groupsRemovePhoto => 'Remove photo';

  @override
  String get groupsName => 'Name';

  @override
  String get groupsDescription => 'Description';

  @override
  String get groupsVisibility => 'Visibility';

  @override
  String get groupsJoinMode => 'Join mode';

  @override
  String get groupsPrivateInvitation => 'Private groups require an invitation.';

  @override
  String get groupsMemberLimit => 'Member limit';

  @override
  String get groupsWhoCanPost => 'Who can post';

  @override
  String get groupsImagesAllowed => 'Images allowed';

  @override
  String get groupsChatPhase2 => 'Chat (coming in phase 2)';

  @override
  String get groupsChatUnavailable =>
      'This setting is saved, but chat is not available yet.';

  @override
  String get groupsRules => 'Rules';

  @override
  String get groupsSaving => 'Saving...';

  @override
  String get groupsSave => 'Save';

  @override
  String groupsCounter(String current, String max) {
    return '$current / $max';
  }

  @override
  String get groupsValidation =>
      'Enter a name of at least 3 characters, a category, and a member limit from 1 to 10000.';

  @override
  String get groupsPhotoChooseError =>
      'Could not choose the photo. Please try again.';

  @override
  String get groupsPhotoSaveError =>
      'Could not save the group photo. Please try again.';

  @override
  String get groupsPhotoCreatedError =>
      'Group created, but the photo could not be uploaded. You can add it from group settings.';

  @override
  String get groupsPhotoTypeError => 'Choose a JPG, PNG or WebP photo.';

  @override
  String get groupsPhotoReadError =>
      'Could not read the photo. Please choose it again.';

  @override
  String get groupsPhotoEmptyError =>
      'The photo is empty. Choose another photo.';

  @override
  String get groupsPhotoMismatchError =>
      'The photo does not match its file type. Choose a valid JPG, PNG or WebP image.';

  @override
  String get groupsPhotoSizeError =>
      'The photo is too large. Choose one under 2 MB.';

  @override
  String get groupsPhotoInvalidError =>
      'Could not read the photo. Choose a valid JPG, PNG or WebP image.';

  @override
  String get groupsBannedError =>
      'You are banned from this group. Only the group owner or a moderator can unban you.';

  @override
  String get groupsFullError => 'This group is full.';

  @override
  String get groupsModeratorsOnlyError =>
      'Only moderators can post in this group.';

  @override
  String get groupsPostingLimitError =>
      'Posting limit reached. Please try again later.';

  @override
  String get groupsCreationLimitError => 'You can create up to 3 groups.';

  @override
  String get groupsUnavailableError =>
      'This group is unavailable or requires an invitation.';

  @override
  String communityUsername(String username) {
    return '@$username';
  }

  @override
  String get communityLikePost => 'Like post';

  @override
  String get communityUnlikePost => 'Unlike post';

  @override
  String get communityOpenComments => 'Open comments';

  @override
  String get communityErrorSignIn => 'Please sign in again.';

  @override
  String get communityErrorConnection =>
      'Could not connect. Check your internet connection.';

  @override
  String get communityErrorTimeout =>
      'The request timed out. Please try again.';

  @override
  String get communityErrorEmptyPost =>
      'Write something before sharing your post.';

  @override
  String get communityErrorPostLength =>
      'Posts must be 5000 characters or fewer.';

  @override
  String get communityErrorImageSize => 'Choose an image smaller than 8 MB.';

  @override
  String get communityErrorImageType => 'Choose a JPG, PNG, or WebP image.';

  @override
  String get communityErrorDeleteOwn => 'You can only delete your own post.';

  @override
  String get communityErrorCommentLength =>
      'Comments must be 1–2000 characters.';

  @override
  String get communityPostGone => 'This post is no longer available.';

  @override
  String get communityPostShared => 'Your post was shared.';

  @override
  String get communityRequestGone => 'This request is no longer available.';

  @override
  String get communityRequestAccepted => 'Friend request accepted.';

  @override
  String get communityRequestRemoved => 'Friend request removed.';

  @override
  String get communityRequestSent => 'Friend request sent.';

  @override
  String get communityUnfollowed => 'Unfollowed.';

  @override
  String get communityFollowing => 'Following.';

  @override
  String get communityBlocked => 'User blocked.';

  @override
  String get communityUpdated => 'Updated.';

  @override
  String get communityDeleteQuestion => 'Delete this post?';

  @override
  String get communityCannotUndo => 'This cannot be undone.';

  @override
  String get communityReportSubmitted => 'Report submitted.';

  @override
  String communityBlockQuestion(String username) {
    return 'Block @$username?';
  }

  @override
  String get communityBlockDetails =>
      'Their posts will no longer appear in your community.';

  @override
  String get communityDeletePost => 'Delete post';

  @override
  String get communityReportPost => 'Report post';

  @override
  String get communityBlockUser => 'Block user';

  @override
  String get communityImageUnavailable => 'Post image is unavailable.';

  @override
  String get communityAcceptRequest => 'Accept request';

  @override
  String get communityDeclineRequest => 'Decline request';

  @override
  String get communityFollow => 'Follow';

  @override
  String get communityUnfollow => 'Unfollow';

  @override
  String get communitySendFriendRequest => 'Send friend request';

  @override
  String get communityRequestPending => 'Request pending';

  @override
  String get communityReportHint => 'Tell us why this post should be reviewed.';

  @override
  String get communitySubmit => 'Submit';

  @override
  String get communityReportValidation =>
      'Please provide at least 3 characters.';

  @override
  String get communityContinue => 'Continue';

  @override
  String get communityClose => 'Close';

  @override
  String get communityPostHint => 'Share a fitness or nutrition update...';

  @override
  String get communityAddPhoto => 'Add photo';

  @override
  String get communityRemovePhoto => 'Remove photo';

  @override
  String get communityPublic => 'Public';

  @override
  String get communitySharePost => 'Share post';

  @override
  String communityLikesError(String error) {
    return 'Could not load likes: $error';
  }

  @override
  String get communityNoLikes => 'No visible likes.';

  @override
  String get communityLikedBy => 'Liked by';

  @override
  String get communityComments => 'Comments';

  @override
  String get communityOlderComments => 'Load older comments';

  @override
  String get communityFirstComment => 'Be the first to comment.';

  @override
  String get communityLikedByAuthor => 'Liked by author';

  @override
  String get communityLikeComment => 'Like comment';

  @override
  String get communityUnlikeComment => 'Unlike comment';

  @override
  String get communityCommentHint => 'Write a comment...';

  @override
  String get communitySendComment => 'Send comment';

  @override
  String get communityProfileUnavailable => 'Profile is unavailable.';

  @override
  String get communityStreak => 'Streak';

  @override
  String get communityBest => 'Best';

  @override
  String get communityPosts => 'Posts';

  @override
  String get communityFollowers => 'Followers';

  @override
  String communityPostCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Posts',
      one: 'Posts',
    );
    return '$_temp0';
  }

  @override
  String communityFriendCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Friends',
      one: 'Friends',
    );
    return '$_temp0';
  }

  @override
  String communityFollowerCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Followers',
      one: 'Followers',
    );
    return '$_temp0';
  }

  @override
  String communityLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count',
      one: '$count',
    );
    return '$_temp0';
  }

  @override
  String communityCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count',
      one: '$count',
    );
    return '$_temp0';
  }

  @override
  String get communityNoBadges => 'No badges earned yet.';

  @override
  String get communityAddFriend => 'Add friend';

  @override
  String get arenaCreatePublic => 'Create a public challenge';

  @override
  String get arenaChallengeName => 'Challenge name';

  @override
  String get arenaDescription => 'Description (optional)';

  @override
  String get arenaChallengeType => 'Challenge type';

  @override
  String get arenaActiveDays => 'Active days';

  @override
  String get arenaWorkoutCount => 'Workout count';

  @override
  String get arenaDuration => 'Duration';

  @override
  String arenaDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String arenaWorkoutsCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText workouts',
      one: '$countText workout',
    );
    return '$_temp0';
  }

  @override
  String get arenaNoPrizesRule =>
      'Scores use self-reported activity logs and are unverified. No prizes are awarded.';

  @override
  String get arenaNoCashRule =>
      'Scores use self-reported activity logs and are unverified. There are no cash or real-world prizes.';

  @override
  String get arenaCreate => 'Create';

  @override
  String get arenaInvalidName =>
      'Challenge name must be at least 3 characters.';

  @override
  String get arenaCreated => 'Public challenge created.';

  @override
  String get arenaNeedFriend => 'Add a friend before creating a 1v1 challenge.';

  @override
  String get arenaInvitationSent => 'Friend challenge invitation sent.';

  @override
  String get arenaJoined => 'You joined the challenge.';

  @override
  String get arenaAccepted => 'Challenge accepted.';

  @override
  String get arenaDeclined => 'Challenge invitation declined.';

  @override
  String get arenaRewardsStore => 'Rewards Store';

  @override
  String get arenaBadgesAchievements => 'Badges & Achievements';

  @override
  String get arenaSection => 'Arena';

  @override
  String get arenaCreateChallenge => 'Create challenge';

  @override
  String get arenaPublicChallenge => 'Public challenge';

  @override
  String get arenaChallengeFriend => 'Challenge a friend';

  @override
  String get arenaYourActivity => 'Your activity streak';

  @override
  String arenaYourStreak(String days) {
    return 'Your streak: $days';
  }

  @override
  String arenaLongestStreak(String days) {
    return 'Longest streak: $days';
  }

  @override
  String get arenaStreakHelp =>
      'Log a meal or completed workout to update your streak and earn 10 XP plus 10 store points once per active day.';

  @override
  String get arenaChallenges => 'Challenges';

  @override
  String get arenaLeaderboard => 'Leaderboard';

  @override
  String get arenaDiscover => 'Discover';

  @override
  String get arenaMyChallenges => 'My challenges';

  @override
  String get arenaFinished => 'Finished';

  @override
  String get arenaFriendInvitations => 'Friend invitations';

  @override
  String arenaInvitation(String name, String metric) {
    return '$name invited you to a $metric 1v1.';
  }

  @override
  String arenaDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get arenaDecline => 'Decline';

  @override
  String get arenaAccept => 'Accept';

  @override
  String get arenaNoOpen =>
      'No open challenges yet. Create one to get started.';

  @override
  String get arenaNoChallenges => 'No challenges to show here yet.';

  @override
  String get arenaOneVOne => '1v1';

  @override
  String arenaChallengeSummary(String metric, String dates) {
    return '$metric · $dates';
  }

  @override
  String arenaParticipants(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText participants',
      one: '$countText participant',
    );
    return '$_temp0';
  }

  @override
  String arenaScore(String score) {
    return 'Your score: $score';
  }

  @override
  String arenaScoreRank(String score, String rank) {
    return 'Your score: $score · #$rank';
  }

  @override
  String arenaCreatedBy(String name) {
    return 'Created by $name';
  }

  @override
  String get arenaJoining => 'Joining...';

  @override
  String get arenaJoin => 'Join challenge';

  @override
  String get arenaNoStandings => 'No standings yet.';

  @override
  String get arenaGlobal => 'Global';

  @override
  String get arenaFriends => 'Friends';

  @override
  String get arenaMyLevel => 'My level';

  @override
  String get arenaThisWeek => 'This week';

  @override
  String get arenaThisMonth => 'This month';

  @override
  String get arenaAllTime => 'All time';

  @override
  String get arenaWorkouts => 'Workouts';

  @override
  String get arenaNoRanked => 'No activity has been ranked for this filter.';

  @override
  String arenaCurrentStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Current streak: $count',
      one: 'Current streak: $count',
    );
    return '$_temp0';
  }

  @override
  String arenaLevelStreak(String level, String streak) {
    return '$level · $streak';
  }

  @override
  String get arenaCompletedWorkouts => 'Completed workouts';

  @override
  String get arenaFriend => 'Friend';

  @override
  String get arenaMetric => 'Metric';

  @override
  String get arenaSevenDayInvite =>
      'Seven days · Invitation expires automatically.';

  @override
  String get arenaSendInvitation => 'Send invitation';

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
  String coachRequestsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Requests left today: $count',
      one: 'Requests left today: $count',
    );
    return '$_temp0';
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
  String recipeLogged(String name, int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      kcal,
      locale: localeName,
      other: '$kcal kcal',
      one: '$kcal kcal',
    );
    return 'Logged $name ($_temp0)';
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
  String recipeRemaining(int kcal, String protein) {
    String _temp0 = intl.Intl.pluralLogic(
      kcal,
      locale: localeName,
      other: '$kcal kcal',
      one: '$kcal kcal',
    );
    return 'Remaining today: $_temp0 · $protein g protein';
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
  String recipeKcal(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount kcal',
      one: '$amount kcal',
    );
    return '$_temp0';
  }

  @override
  String recipeMacro(String amount, String macro) {
    return '$amount g $macro';
  }

  @override
  String recipeSummary(int minutes, String difficulty, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
    );
    return '$_temp0 · $difficulty · $meal';
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
  String recipeOver(int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      kcal,
      locale: localeName,
      other: '$kcal kcal',
      one: '$kcal kcal',
    );
    return 'Over by $_temp0';
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
    return 'Could not load Cheat Meals: $error';
  }

  @override
  String cravingLimitError(String error) {
    return 'The selected month already has 2 Cheat Meals. $error';
  }

  @override
  String cravingSaveError(String error) {
    return 'Could not save: $error';
  }

  @override
  String get cravingValidate => 'Enter 1 to 200 characters.';

  @override
  String get cravingDeleteTitle => 'Delete Cheat Meal?';

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
  String cravingUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of 2 used this month',
      one: '$count of 2 used this month',
    );
    return '$_temp0';
  }

  @override
  String get cravingMonthlyLimit =>
      'Monthly limit reached. Edit or delete an entry to make room.';

  @override
  String cravingDay(String day) {
    return 'Cheat Meal for day $day';
  }

  @override
  String get cravingCharacters => '1 to 200 characters';

  @override
  String get cravingAdd => 'Add Cheat Meal';

  @override
  String get cravingEmpty => 'No meals added yet.';

  @override
  String get cravingEdit => 'Edit';

  @override
  String get cravingEditTitle => 'Edit Cheat Meal';

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
  String academyBurn(int kcal, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      kcal,
      locale: localeName,
      other: '$kcal kcal',
      one: '$kcal kcal',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes mins',
      one: '$minutes mins',
    );
    return 'about $_temp0 / $_temp1';
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
  String plannerWorkoutSummary(int minutes, String effort) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
    );
    return 'Workout · $_temp0 · $effort% effort';
  }

  @override
  String plannerSplitSummary(int minutes, String effort) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
    );
    return '$_temp0 · $effort% effort';
  }

  @override
  String plannerWorkoutNoDuration(String effort) {
    return 'Workout · null min · $effort% effort';
  }

  @override
  String plannerSplitNoDuration(String effort) {
    return 'null min · $effort% effort';
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
  String mergeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minutes',
    );
    return '$_temp0';
  }

  @override
  String mergeShortMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
    );
    return '$_temp0';
  }

  @override
  String mergeNamedValue(String name, String value) {
    return '$name: $value';
  }

  @override
  String mergeCalories(int count, String calories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$calories kcal',
      one: '$calories kcal',
    );
    return '$_temp0';
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
  String burnedAmount(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount kcal burned',
      one: '$amount kcal burned',
    );
    return '$_temp0';
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
    return 'Goal: $amount kcal';
  }

  @override
  String get burnGoalNote =>
      'Daily burn goal • the total includes mobility workouts.';

  @override
  String get burnRingNote =>
      'Each ring uses the daily burn goal as its target.';

  @override
  String totalBurn(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount kcal',
      one: '$amount kcal',
    );
    return 'Total burn ($_temp0)';
  }

  @override
  String strengthBurn(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount kcal',
      one: '$amount kcal',
    );
    return 'Strength burn ($_temp0)';
  }

  @override
  String cardioBurn(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount kcal',
      one: '$amount kcal',
    );
    return 'Cardio burn ($_temp0)';
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
  String workoutLogs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Workout Logs ($count)',
      one: 'Workout Logs ($count)',
    );
    return '$_temp0';
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
  String workoutSavedTitle(String name, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
    );
    return '$name - $_temp0';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get workoutIntensity => 'Intensity';

  @override
  String get workoutEstimateUnavailable =>
      'Estimate unavailable — enter calories manually.';

  @override
  String workoutEstimate(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount kcal burned',
      one: '$amount kcal burned',
    );
    return '≈ $_temp0';
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
  String foodGoalSummary(String goal, String estimated, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Logged items: $count',
      one: 'Logged items: $count',
    );
    return 'Goal: $goal$estimated • $_temp0';
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
  String foodGroupTotals(int calories, String protein) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal',
      one: '$calories kcal',
    );
    return '$_temp0 • ${protein}g P';
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
  String foodCaloriesLines(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount\nkcal',
      one: '$amount\nkcal',
    );
    return '$_temp0';
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
  String explorerShowing(int shown, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      shown,
      locale: localeName,
      other: 'Showing $shown of $total',
      one: 'Showing $shown of $total',
    );
    return '$_temp0';
  }

  @override
  String get explorerEmpty => 'No matching foods found';

  @override
  String get explorerEmptyHint => 'Try another search or remove a filter.';

  @override
  String get explorerDisclaimer =>
      'Nutrition values are approximate estimates.';

  @override
  String explorerPer100(int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal',
      one: '$calories kcal',
    );
    return 'Per 100 g: $_temp0';
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
  String explorerLogged(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories kcal',
      one: '$calories kcal',
    );
    return 'Logged $name ($_temp0)';
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
  String profileAdjustment(int count, String amount, String minor) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount kcal',
      one: '$amount kcal',
    );
    return 'Goal adjustment: $_temp0$minor';
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
  String memberHandle(String id) {
    return 'Member $id';
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
  String progressHighest(int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      xp,
      locale: localeName,
      other: '$xp XP',
      one: '$xp XP',
    );
    return '$_temp0 · Highest level';
  }

  @override
  String progressNext(int xp, int remaining, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      xp,
      locale: localeName,
      other: '$xp XP',
      one: '$xp XP',
    );
    String _temp1 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining XP',
      one: '$remaining XP',
    );
    return '$_temp0 · $_temp1 to $name';
  }

  @override
  String progressFreeze(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Freeze tokens: $countText',
      one: 'Freeze token: $countText',
    );
    return '$_temp0';
  }

  @override
  String progressPoints(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText store points',
      one: '$countText store point',
    );
    return '$_temp0';
  }

  @override
  String rewardConfirm(String name) {
    return 'Redeem $name?';
  }

  @override
  String rewardSpend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Spend $count store points?',
      one: 'Spend $count store points?',
    );
    return '$_temp0';
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
  String rewardFreezeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Freeze tokens: $count / 3',
      one: 'Freeze tokens: $count / 3',
    );
    return '$_temp0';
  }

  @override
  String get rewardInfo =>
      'Digital items only. Themes, frames and titles are saved to your rewards; applying them is not available yet.';

  @override
  String get rewardEmpty => 'No rewards are available right now.';

  @override
  String get rewardUnlimited => 'Unlimited stock';

  @override
  String rewardRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count remaining',
      one: '$count remaining',
    );
    return '$_temp0';
  }

  @override
  String rewardDetails(int cost, String tier, String stock) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost points',
      one: '$cost points',
    );
    return '$_temp0 · $tier tier · $stock';
  }

  @override
  String rewardRequires(String tier) {
    return 'Requires $tier tier';
  }

  @override
  String rewardNeedPoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Need $count more points',
      one: 'Need $count more points',
    );
    return '$_temp0';
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
  String progressAchievementValue(String progress, String threshold, int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      xp,
      locale: localeName,
      other: '$xp XP',
      one: '$xp XP',
    );
    return '$progress / $threshold · $_temp0';
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
  String pathDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days days',
    );
    return '$_temp0';
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
  String get defaultHighProteinFuel => 'High-Protein Fuel';

  @override
  String get defaultAthleticTraining => 'Athletic Training';

  @override
  String get defaultQuickCalorieSnack => 'Quick Calorie Snack';

  @override
  String get defaultQuickExerciseBurn => 'Quick Exercise Burn';

  @override
  String get language => 'Language';

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
  String get cravingsTitle => 'Cheat Meals';

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
      'Social sign-in will be available later.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetInstructions =>
      'Enter your email to request the code from your email.';

  @override
  String get resetChoosePassword => 'Choose a new password';

  @override
  String get resetCodeInstructions =>
      'Enter the code from your email and your new password.';

  @override
  String get resetSendCode => 'Send code';

  @override
  String get resetCode => 'Code from your email';

  @override
  String get resetNewPassword => 'New password';

  @override
  String get resetUpdatePassword => 'Update password';

  @override
  String get resetResendCode => 'Resend code';

  @override
  String resetResendCountdown(int seconds) {
    return 'Resend in $seconds seconds';
  }

  @override
  String get resetNeutralMessage =>
      'If this email has an account, we sent a code.';

  @override
  String get resetCodeFormatError =>
      'Enter the code from your email using 6 to 10 digits.';

  @override
  String get resetInvalidCode =>
      'The code is invalid or has expired. Request a new code and try again.';

  @override
  String get resetTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get resetError => 'Could not reset the password. Please try again.';

  @override
  String get resetSuccess => 'Your password was updated. You can now log in.';

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
      'No internet connection. Check your connection and try again.';

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
  String get goalChampionship => 'Train for a natural competition';

  @override
  String get goalMuscle => 'Build muscle';

  @override
  String get goalSports => 'Mix sports and strength training';

  @override
  String get goalFatLoss => 'Lose body fat';

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

  @override
  String get privacyDataTitle => 'Privacy & Data';

  @override
  String get privacyDataSubtitle => 'How your app data is stored and used';

  @override
  String get privacyStoreTitle => 'What we store';

  @override
  String get privacyStoreBody =>
      'Your profile, food and workout logs, community content you post, and your progress are stored in the app\'s Supabase database. Your profile photo and theme stay only on your device.';

  @override
  String get privacyCoachTitle => 'AI coach';

  @override
  String get privacyCoachBody =>
      'Messages are sent to Google Gemini to get a reply and are not stored by the app. Calorie numbers are shared only if you turn on the consent switch. Do not share personal or health details you do not want sent. The coach can make mistakes and is not medical advice.';

  @override
  String get privacyChoicesTitle => 'Your choices';

  @override
  String get privacyConsentTitle => 'Share calorie information with the coach';

  @override
  String get privacyConsentSubtitle =>
      'Uses the same consent setting as the AI coach.';

  @override
  String get privacyDeletionTitle => 'Data deletion';

  @override
  String get privacyDeletionBody =>
      'Account deletion is not available inside the app yet. To request deletion of your data, contact support.';

  @override
  String get privacySupport => 'Contact support';

  @override
  String get privacyCopyEmail => 'Copy email';

  @override
  String get privacyEmailCopied => 'Support email copied.';

  @override
  String get privacyEmailCopyFailed => 'Could not copy the support email.';

  @override
  String get privacySignOut => 'Sign out';
}
