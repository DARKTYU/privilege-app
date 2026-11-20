import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:privilege/l10n/app_localizations_ar.dart';
import 'package:privilege/l10n/app_localizations_en.dart';
import 'package:privilege/logic/localized_dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  test('planner dates use localized names and Western digits across years', () {
    final start = DateTime(2026, 12, 27);
    final end = DateTime(2027, 1, 2);
    final en = AppLocalizationsEn().plannerWeekRange(
        localizedPlannerDate(start, 'en'), localizedPlannerDate(end, 'en'));
    final ar = AppLocalizationsAr().plannerWeekRange(
        localizedPlannerDate(start, 'ar'), localizedPlannerDate(end, 'ar'));
    expect(en, contains('Dec'));
    expect(en, contains('2027'));
    expect(ar, contains('2026'));
    expect(ar, contains('2027'));
    expect(ar, contains(RegExp(r'[\u0600-\u06ff]')));
    expect(ar, isNot(contains(RegExp(r'[\u0660-\u0669\u06f0-\u06f9]'))));
    expect(localizedPlannerWeekday(start, 'ar'),
        contains(RegExp(r'[\u0600-\u06ff]')));
    expect(localizedPlannerWeekday(start, 'en'), 'Sun');
  });
}
