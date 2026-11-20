import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/progression_content.dart';
import 'package:privilege/screens/progression.dart';
import 'package:privilege/services/progression_repository.dart';

import 'progression_fake.dart';

void main() {
  test('every seeded item has an Arabic name and description', () {
    final sql = File('supabase/rewards_badges_levels.sql').readAsStringSync();
    final seed = File('supabase/seed.sql').readAsStringSync();
    String section(String start, String end, String text) => text.substring(
        text.indexOf(start), text.indexOf(end, text.indexOf(start)));
    final badgeSql = section('insert into public.badges(', 'on conflict', sql);
    final metrics = RegExp(r"\('([^']+)','[^']+','[^']+'\)")
        .allMatches(badgeSql)
        .map((m) => m[1]!)
        .toList();
    final thresholds = RegExp(r'\((\d+)\)')
        .allMatches(badgeSql)
        .map((m) => int.parse(m[1]!))
        .toList();
    final badges = {
      for (final metric in metrics)
        for (final n in thresholds) '${metric}_$n'
    };
    final achievementSql =
        section('insert into public.achievements(', 'on conflict', sql);
    final achievements = RegExp(r"\('([^']+)','[^']+','[^']+',")
        .allMatches(achievementSql)
        .map((m) => m[1]!)
        .toSet();
    final rewardSql =
        section('insert into public.rewards(', 'on conflict', sql);
    final seedRewards =
        section('insert into public.rewards(', 'on conflict', seed);
    final rewards = RegExp(r"\('([^']+)','[^']+',")
        .allMatches('$rewardSql\n$seedRewards')
        .map((m) => m[1]!)
        .toSet();
    expect(badges, hasLength(35));
    expect(achievements, hasLength(12));
    expect(rewards, hasLength(26));
    for (final (keys, translations) in [
      (badges, badgeTranslations),
      (achievements, achievementTranslations),
      (rewards, rewardTranslations),
    ]) {
      expect(translations.keys.toSet(), keys);
      for (final key in keys) {
        expect(translations[key]!.name.trim(), isNotEmpty, reason: key);
        expect(translations[key]!.description.trim(), isNotEmpty, reason: key);
        expect(translations[key]!.name, contains(RegExp(r'[\u0600-\u06ff]')),
            reason: key);
        expect(translations[key]!.description,
            contains(RegExp(r'[\u0600-\u06ff]')),
            reason: key);
        expect(translations[key]!.name, isNot(contains(RegExp(r'[٠-٩]'))),
            reason: key);
        expect(
            translations[key]!.description, isNot(contains(RegExp(r'[٠-٩]'))),
            reason: key);
      }
    }
  });

  test('unknown keys and English mode preserve server text', () {
    const original = (name: 'Custom name', description: 'Custom description');
    expect(
        localizedProgressionContent(badgeTranslations, 'future',
            name: original.name,
            description: original.description,
            arabic: true),
        original);
    expect(
        localizedProgressionContent(achievementTranslations, 'meal_10',
            name: original.name,
            description: original.description,
            arabic: false),
        original);
    expect(
        localizedProgressionContent(rewardTranslations, 'Future reward',
            name: original.name,
            description: original.description,
            arabic: true),
        original);
  });

  for (final language in ['en', 'ar']) {
    testWidgets(
        'store, confirmation, badge and achievement show $language content',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeProgression()
        ..badgeList = [
          const BadgeProgress('Meals 1', 'Consumed meals logged: 1.', true,
              code: 'meals_1')
        ]
        ..achievementList = [
          const AchievementProgress(
              'Meal logger', 'Log 10 consumed meals.', 0, 10, 25,
              code: 'meal_10')
        ];
      Widget app(Widget child) => MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: child),
          );
      final ar = language == 'ar';
      await tester.pumpWidget(app(RewardsStoreScreen(repository: repo)));
      await tester.pumpAndSettle();
      final rewardName = ar
          ? rewardTranslations['Streak freeze token']!.name
          : 'Streak freeze token';
      final rewardDescription = ar
          ? rewardTranslations['Streak freeze token']!.description
          : 'One freeze';
      expect(find.text(rewardName), findsOneWidget);
      expect(find.text(rewardDescription), findsOneWidget);
      final l =
          AppLocalizations.of(tester.element(find.byType(RewardsStoreScreen)))!;
      await tester.tap(find.text(l.rewardRedeem));
      await tester.pumpAndSettle();
      expect(find.text(l.rewardConfirm(rewardName)), findsOneWidget);
      await tester.tap(find.text(l.plannerCancel));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(BadgesAchievementsScreen(repository: repo)));
      await tester.pumpAndSettle();
      final badge = ar
          ? badgeTranslations['meals_1']!
          : (name: 'Meals 1', description: 'Consumed meals logged: 1.');
      final achievement = ar
          ? achievementTranslations['meal_10']!
          : (name: 'Meal logger', description: 'Log 10 consumed meals.');
      expect(find.text(badge.name), findsOneWidget);
      expect(find.textContaining(badge.description), findsOneWidget);
      await tester.ensureVisible(find.text(achievement.name));
      await tester.pumpAndSettle();
      expect(find.text(achievement.name), findsOneWidget);
      expect(find.text(achievement.description), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
