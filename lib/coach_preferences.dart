import 'package:shared_preferences/shared_preferences.dart';

const coachConsentPreferenceKey = 'coach_share_calorie_context';
const coachPhotoNoticePreferenceKey = 'coach_photo_notice_accepted';

Future<bool> loadCoachConsent() async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getBool(coachConsentPreferenceKey) ?? false;
}

Future<bool> saveCoachConsent(bool value) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.setBool(coachConsentPreferenceKey, value);
}

Future<bool> loadCoachPhotoNoticeAccepted() async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getBool(coachPhotoNoticePreferenceKey) ?? false;
}

Future<bool> saveCoachPhotoNoticeAccepted([bool accepted = true]) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.setBool(coachPhotoNoticePreferenceKey, accepted);
}
