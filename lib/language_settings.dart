import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettings extends ChangeNotifier {
  static const _preferenceKey = 'privilege_language';
  Locale selected = const Locale('en');

  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    selected =
        Locale(preferences.getString(_preferenceKey) == 'ar' ? 'ar' : 'en');
    notifyListeners();
  }

  Future<void> select(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'ar') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    if (selected.languageCode == languageCode) return;
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_preferenceKey, languageCode)) {
      throw StateError('Could not save language');
    }
    selected = Locale(languageCode);
    notifyListeners();
  }
}

final languageSettings = LanguageSettings();
