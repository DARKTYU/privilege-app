import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:privilege/l10n_strings.dart';
import 'package:privilege/language_settings.dart';
import 'package:privilege/services/activity_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    languageSettings.selected = const Locale('en');
  });
  tearDown(() => languageSettings.selected = const Locale('en'));

  test('saved language helper follows selection and restore', () async {
    expect(savedLanguageStrings().localeName, 'en');
    await languageSettings.select('ar');
    expect(savedLanguageStrings().localeName, 'ar');
    languageSettings.selected = const Locale('en');
    await languageSettings.restore();
    expect(savedLanguageStrings().localeName, 'ar');
  });

  test('unknown errors are hidden and known errors are translated', () async {
    final english = savedLanguageStrings();
    expect(friendlyError(StateError('private server detail')), english.genericError);
    await languageSettings.select('ar');
    final arabic = savedLanguageStrings();
    expect(friendlyError(StateError('private server detail')), arabic.genericError);
    expect(friendlyError(StateError(english.errorFoodChanged)), arabic.errorFoodChanged);
  });

  test('activity times use localized periods and western digits', () async {
    await initializeDateFormatting('ar');
    final morning = DateTime(2026, 1, 2, 9, 5);
    final evening = DateTime(2026, 1, 2, 21, 5);
    final en = savedLanguageStrings();
    expect(formatActivityTime(morning, en), contains('AM'));
    expect(formatActivityTime(evening, en), contains('PM'));
    await languageSettings.select('ar');
    final ar = savedLanguageStrings();
    final am = formatActivityTime(morning, ar);
    final pm = formatActivityTime(evening, ar);
    expect(am, contains('ص'));
    expect(pm, contains('م'));
    expect(am, contains('9:05'));
    expect(pm, contains('9:05'));
    expect('$am$pm', isNot(contains(RegExp(r'[\u0660-\u0669\u06f0-\u06f9]'))));
  });
}
