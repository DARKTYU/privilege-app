import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations_ar.dart';
import 'package:privilege/l10n/app_localizations_en.dart';
import 'package:privilege/ui.dart';

void main() {
  test('display number formatting is grouped in every locale', () {
    expect(fmt(2660), '2,660');
    expect(fmt(170.0), '170');
    expect(fmt(108.5), '108.5');
    final arabic = AppLocalizationsAr();
    expect(arabic.burnTarget(fmt(2660)), 'الهدف: 2,660 سعرة');
  });

  testWidgets('left-to-right handles stay ordered on an RTL screen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AccountHandle('user_abcdefghijklmnop'),
      ),
    ));
    expect(
        find.descendant(
            of: find.byWidgetPredicate((widget) =>
                widget is Directionality &&
                widget.textDirection == TextDirection.ltr),
            matching: find.text('Member abcd')),
        findsOneWidget);
    expect(find.text('Member abcd'), findsOneWidget);
  });

  test('minutes and days follow English and Arabic plural rules', () {
    final ar = AppLocalizationsAr();
    final en = AppLocalizationsEn();
    const expectedMinutes = {
      0: '0 دقيقة',
      1: 'دقيقة واحدة',
      2: 'دقيقتان',
      3: '3 دقائق',
      5: '5 دقائق',
      10: '10 دقائق',
      11: '11 دقيقة',
      15: '15 دقيقة',
      20: '20 دقيقة',
    };
    const expectedDays = {
      0: '0 يوم',
      1: 'يوم واحد',
      2: 'يومان',
      3: '3 أيام',
      5: '5 أيام',
      10: '10 أيام',
      11: '11 يومًا',
      15: '15 يومًا',
      20: '20 يومًا',
    };
    for (final n in expectedMinutes.keys) {
      expect(ar.mergeMinutes(n), expectedMinutes[n], reason: '$n minutes');
      expect(ar.recipeSummary(n, 'سهل', 'غداء'),
          '${expectedMinutes[n]} · سهل · غداء');
      expect(ar.arenaDays(n), expectedDays[n], reason: '$n days');
      expect(en.mergeMinutes(n), '$n minutes');
      expect(en.arenaDays(n), n == 1 ? '1 day' : '$n days');
      expect(ar.mergeMinutes(n), isNot(contains(RegExp(r'[٠-٩]'))));
      expect(ar.arenaDays(n), isNot(contains(RegExp(r'[٠-٩]'))));
    }
  });

  test('relative-time and member forms use Arabic grammatical cases', () {
    final ar = AppLocalizationsAr();
    expect(ar.communityMinutesAgo(2), 'منذ دقيقتين');
    expect(ar.communityDaysAgo(2), 'منذ يومين');
    expect(ar.communityHoursAgo(3), 'منذ 3 ساعات');
    expect(ar.groupsMemberCount(2), 'عضوان');
    expect(ar.groupsMemberCount(5), '5 أعضاء');
    expect(ar.arenaParticipants(11, '11'), '11 مشاركًا');
    expect(ar.communityLikeCount(2), 'إعجابان');
    expect(ar.communityCommentCount(5), '5 تعليقات');
    expect(ar.communityPostCountLabel(3), 'منشورات');
    expect(ar.communityFriendCountLabel(2), 'صديقان');
    expect(ar.communityFollowerCountLabel(11), 'متابعًا');
    expect(ar.progressHighest(3), '3 نقاط خبرة · أعلى مستوى');
  });

  test('calories and remaining requests use Arabic plurals with western digits',
      () {
    final ar = AppLocalizationsAr();
    const calories = {
      0: '0 سعرة',
      1: 'سعرة واحدة',
      2: 'سعرتان',
      3: '3 سعرات',
      5: '5 سعرات',
      10: '10 سعرات',
      11: '11 سعرة',
      20: '20 سعرة',
    };
    const requests = {
      0: 'المتبقي اليوم: 0 طلب',
      1: 'المتبقي اليوم: طلب واحد',
      2: 'المتبقي اليوم: طلبان',
      3: 'المتبقي اليوم: 3 طلبات',
      5: 'المتبقي اليوم: 5 طلبات',
      10: 'المتبقي اليوم: 10 طلبات',
      11: 'المتبقي اليوم: 11 طلبًا',
      20: 'المتبقي اليوم: 20 طلبًا',
    };
    for (final n in calories.keys) {
      expect(ar.recipeKcal(n), calories[n]);
      expect(ar.mergeCalories(n, '$n'), calories[n]);
      expect(ar.coachRequestsLeft(n), requests[n]);
      expect(ar.recipeKcal(n), isNot(contains(RegExp(r'[٠-٩]'))));
      expect(ar.coachRequestsLeft(n), isNot(contains(RegExp(r'[٠-٩]'))));
    }
  });
}
