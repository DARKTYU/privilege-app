import 'package:flutter/widgets.dart';

import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_en.dart';
import 'l10n/app_localizations_ar.dart';
import 'language_settings.dart';

AppLocalizations strings(BuildContext context) =>
    AppLocalizations.of(context) ?? AppLocalizationsEn();

AppLocalizations savedLanguageStrings() =>
    lookupAppLocalizations(languageSettings.selected);

String friendlyError(Object error, {AppLocalizations? localizations}) {
  final l = localizations ?? savedLanguageStrings();
  final en = AppLocalizationsEn();
  final ar = AppLocalizationsAr();
  final known = <(String, String, String)>[
    (en.sessionExpired, ar.sessionExpired, l.sessionExpired),
    (en.communityErrorSignIn, ar.communityErrorSignIn, l.communityErrorSignIn),
    (
      en.communityErrorConnection,
      ar.communityErrorConnection,
      l.communityErrorConnection
    ),
    (
      en.communityErrorTimeout,
      ar.communityErrorTimeout,
      l.communityErrorTimeout
    ),
    (en.networkError, ar.networkError, l.networkError),
    (en.errorAccountChanged, ar.errorAccountChanged, l.errorAccountChanged),
    (en.errorPlannerBusy, ar.errorPlannerBusy, l.errorPlannerBusy),
    (en.errorActivityLoad, ar.errorActivityLoad, l.errorActivityLoad),
    (en.errorPointsBalance, ar.errorPointsBalance, l.errorPointsBalance),
    (en.errorActivityDate, ar.errorActivityDate, l.errorActivityDate),
    (en.errorFoodNotLinked, ar.errorFoodNotLinked, l.errorFoodNotLinked),
    (en.errorFoodChanged, ar.errorFoodChanged, l.errorFoodChanged),
    (en.errorFoodUnavailable, ar.errorFoodUnavailable, l.errorFoodUnavailable),
    (
      en.foodDuplicateUnavailable,
      ar.foodDuplicateUnavailable,
      l.foodDuplicateUnavailable
    ),
    (en.errorSplitMissing, ar.errorSplitMissing, l.errorSplitMissing),
    (en.errorDayMissing, ar.errorDayMissing, l.errorDayMissing),
    (en.errorCravingMissing, ar.errorCravingMissing, l.errorCravingMissing),
    (en.errorProfileInvalid, ar.errorProfileInvalid, l.errorProfileInvalid),
    (en.errorProfileMissing, ar.errorProfileMissing, l.errorProfileMissing),
    (en.errorProfileNotSaved, ar.errorProfileNotSaved, l.errorProfileNotSaved),
    (en.errorSignInSession, ar.errorSignInSession, l.errorSignInSession),
    (en.errorCompleteSignIn, ar.errorCompleteSignIn, l.errorCompleteSignIn),
    (en.errorLogInSetup, ar.errorLogInSetup, l.errorLogInSetup),
    (en.invalidEmail, ar.invalidEmail, l.invalidEmail),
    (en.invalidPassword, ar.invalidPassword, l.invalidPassword),
    (en.invalidUsername, ar.invalidUsername, l.invalidUsername),
    (en.passwordMismatch, ar.passwordMismatch, l.passwordMismatch),
    (en.invalidCredentials, ar.invalidCredentials, l.invalidCredentials),
    (en.emailNotConfirmed, ar.emailNotConfirmed, l.emailNotConfirmed),
    (en.signInError, ar.signInError, l.signInError),
    (en.registrationError, ar.registrationError, l.registrationError),
    (en.registrationCreated, ar.registrationCreated, l.registrationCreated),
    (en.registrationConfirm, ar.registrationConfirm, l.registrationConfirm),
    (en.usernameTaken, ar.usernameTaken, l.usernameTaken),
    (
      en.communityErrorEmptyPost,
      ar.communityErrorEmptyPost,
      l.communityErrorEmptyPost
    ),
    (
      en.communityErrorPostLength,
      ar.communityErrorPostLength,
      l.communityErrorPostLength
    ),
    (
      en.communityErrorImageSize,
      ar.communityErrorImageSize,
      l.communityErrorImageSize
    ),
    (
      en.communityErrorImageType,
      ar.communityErrorImageType,
      l.communityErrorImageType
    ),
    (
      en.communityErrorDeleteOwn,
      ar.communityErrorDeleteOwn,
      l.communityErrorDeleteOwn
    ),
    (
      en.communityErrorCommentLength,
      ar.communityErrorCommentLength,
      l.communityErrorCommentLength
    ),
    (en.errorUnreadCount, ar.errorUnreadCount, l.errorUnreadCount),
    (en.groupsPhotoTypeError, ar.groupsPhotoTypeError, l.groupsPhotoTypeError),
    (en.groupsPhotoReadError, ar.groupsPhotoReadError, l.groupsPhotoReadError),
    (
      en.groupsPhotoEmptyError,
      ar.groupsPhotoEmptyError,
      l.groupsPhotoEmptyError
    ),
    (
      en.groupsPhotoMismatchError,
      ar.groupsPhotoMismatchError,
      l.groupsPhotoMismatchError
    ),
    (en.groupsPhotoSizeError, ar.groupsPhotoSizeError, l.groupsPhotoSizeError),
    (
      en.groupsPhotoInvalidError,
      ar.groupsPhotoInvalidError,
      l.groupsPhotoInvalidError
    ),
    (
      en.groupImageTypeSizeError,
      ar.groupImageTypeSizeError,
      l.groupImageTypeSizeError
    ),
    (en.groupImageReadError, ar.groupImageReadError, l.groupImageReadError),
    (
      en.groupImageUploadError,
      ar.groupImageUploadError,
      l.groupImageUploadError
    ),
    (en.groupsBannedError, ar.groupsBannedError, l.groupsBannedError),
    (en.groupsFullError, ar.groupsFullError, l.groupsFullError),
    (
      en.groupsModeratorsOnlyError,
      ar.groupsModeratorsOnlyError,
      l.groupsModeratorsOnlyError
    ),
    (
      en.groupsPostingLimitError,
      ar.groupsPostingLimitError,
      l.groupsPostingLimitError
    ),
    (
      en.groupsCreationLimitError,
      ar.groupsCreationLimitError,
      l.groupsCreationLimitError
    ),
    (
      en.groupsUnavailableError,
      ar.groupsUnavailableError,
      l.groupsUnavailableError
    ),
    (en.genericError, ar.genericError, l.genericError),
  ];
  final value = error is StateError
      ? error.message.toString()
      : error is FormatException
          ? error.message
          : error.toString();
  for (final (english, arabic, translated) in known) {
    if (value == english || value == arabic) return translated;
  }
  debugPrint('Operation failed: $error');
  return l.genericError;
}
