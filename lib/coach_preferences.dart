import 'package:shared_preferences/shared_preferences.dart';

const coachConsentPreferenceKey = 'coach_share_calorie_context';

Future<bool> loadCoachConsent() async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getBool(coachConsentPreferenceKey) ?? false;
}

Future<bool> saveCoachConsent(bool value) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.setBool(coachConsentPreferenceKey, value);
}
