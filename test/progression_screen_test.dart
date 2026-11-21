import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/screens/progression.dart';
import 'package:privilege/services/progression_repository.dart';
import 'package:privilege/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'progression_fake.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('progression and pathway contain no hardcoded UI literals', () {
    final pattern = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|(?:sectionTitle|_step|_tracked|_outside)\(\s*|(?:tooltip|labelText|hintText|semanticLabel)\s*:\s*)['"]""");
    for (final path in [
      'lib/screens/progression.dart',
      'lib/screens/champion.dart'
    ]) {
      final source = File(path).readAsStringSync();
      expect(pattern.allMatches(source), isEmpty, reason: path);
      expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))), reason: path);
    }
  });

  for (final language in ['en', 'ar']) {
    testWidgets('progression screens fit at 360 in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeProgression();
      Widget app(Widget screen) => MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: screen),
          );
      await tester.pumpWidget(app(LevelProgressPanel(repository: repo)));
      await tester.pumpAndSettle();
      final l =
          AppLocalizations.of(tester.element(find.byType(LevelProgressPanel)))!;
      expect(find.text(l.progressLevel(l.levelBronze)), findsOneWidget);
      expect(
          find.text(l.progressNext(100, 400, l.levelSilver)), findsOneWidget);
      await tester.pumpWidget(app(RewardsStoreScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text(l.progressPoints(200, fmt(200))), findsOneWidget);
      await tester.tap(find.text(l.rewardRedeem));
      await tester.pumpAndSettle();
      expect(find.text(l.rewardSpend(50)), findsOneWidget);
      await tester.tap(find.text(l.plannerCancel));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(BadgesAchievementsScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text(l.progressBadges.toUpperCase()), findsOneWidget);
      await tester.ensureVisible(
          find.text(l.progressAchievementValue('10', '100', 150)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('store displays balance, token, tier and redeems a reward',
      (tester) async {
    final repo = FakeProgression();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RewardsStoreScreen(repository: repo)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('200 store points'), findsOneWidget);
    expect(find.text('Freeze tokens: 1 / 3'), findsOneWidget);
    expect(find.textContaining('Free tier'), findsOneWidget);
    await tester.tap(find.text('Redeem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redeem').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(repo.redemptions, 1);
    expect(find.text('150 store points'), findsOneWidget);
    expect(find.text('Freeze tokens: 2 / 3'), findsOneWidget);
  });

  testWidgets('retry after uncertain redemption reuses its request id',
      (tester) async {
    final repo = FakeProgression()..redemptionFailure = Exception('connection');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RewardsStoreScreen(repository: repo)),
    ));
    await tester.pumpAndSettle();
    Future<void> attempt() async {
      await tester.tap(find.text('Redeem').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Redeem').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
    }

    await attempt();
    expect(find.textContaining('Could not confirm redemption'), findsOneWidget);
    repo.redemptionFailure = null;
    await attempt();
    expect(repo.requests.length, 2);
    expect(repo.requests[0], repo.requests[1]);
  });

  testWidgets('badges and achievements show earned and locked progress',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: BadgesAchievementsScreen(repository: FakeProgression())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('First meal'), findsOneWidget);
    expect(find.textContaining('Earned'), findsOneWidget);
    expect(find.textContaining('Locked'), findsOneWidget);
    expect(find.text('10 / 100 · 150 XP'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        0.1);
  });

  testWidgets('achievement tracks show zero, partial and completed progress',
      (tester) async {
    final repo = FakeProgression()
      ..achievementList = [
        const AchievementProgress('Zero', '', 0, 10, 5),
        const AchievementProgress('Partial', '', 3, 100, 5),
        const AchievementProgress('Complete', '', 10, 10, 5),
      ]
      ..badgeList = [];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BadgesAchievementsScreen(repository: repo))));
    await tester.pumpAndSettle();
    final bars = tester
        .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator))
        .toList();
    expect(bars.map((bar) => bar.value), [0, 0.03, 1]);
    for (final bar in bars) {
      expect(bar.backgroundColor, kLine);
      expect(bar.color, isNot(bar.backgroundColor));
    }
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('earned badges appear before locked badges', (tester) async {
    final repo = FakeProgression()
      ..badgeList = [
        const BadgeProgress('Locked first', '', false),
        const BadgeProgress('Earned later', '', true),
      ]
      ..achievementList = [];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BadgesAchievementsScreen(repository: repo))));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Earned later')).dy,
        lessThan(tester.getTopLeft(find.text('Locked first')).dy));
  });

  testWidgets('level card names the next level and remaining XP',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home:
            Scaffold(body: LevelProgressPanel(repository: FakeProgression()))));
    await tester.pumpAndSettle();
    expect(find.text('100 XP · 400 XP to Silver'), findsOneWidget);
    final bar = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 0.2);
    expect(bar.backgroundColor, kLine);
  });

  testWidgets('store locks rewards for insufficient tier and points',
      (tester) async {
    const gold = StoreReward(
        id: 'gold',
        name: 'Gold frame',
        description: '',
        kind: 'frame',
        cost: 100,
        stock: 5,
        tier: 'Gold',
        owned: false);
    const expensive = StoreReward(
        id: 'expensive',
        name: 'Expensive free frame',
        description: '',
        kind: 'frame',
        cost: 250,
        stock: 5,
        tier: 'Free',
        owned: false);
    const affordable = StoreReward(
        id: 'free',
        name: 'Free frame',
        description: '',
        kind: 'frame',
        cost: 100,
        stock: 5,
        tier: 'Free',
        owned: false);
    final repo = FakeProgression()..rewardList = [gold, expensive, affordable];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: RewardsStoreScreen(repository: repo))));
    await tester.pumpAndSettle();
    expect(find.text('Requires Gold tier'), findsOneWidget);
    expect(find.text('Need 50 more points'), findsOneWidget);
    final buttons =
        tester.widgetList<FilledButton>(find.byType(FilledButton)).toList();
    expect(buttons[0].onPressed, isNull);
    expect(buttons[1].onPressed, isNull);
    expect(buttons[2].onPressed, isNotNull);
    await tester.tap(find.byType(FilledButton).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('store reports loading errors with retry', (tester) async {
    final repo = FakeProgression()..error = Exception('offline');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RewardsStoreScreen(repository: repo)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Could not load progress. Check your connection.'),
        findsOneWidget);
    repo.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('200 store points'), findsOneWidget);
  });

  test('redemption errors have understandable messages', () {
    expect(
        redemptionError(
            const PostgrestException(message: 'Insufficient store points')),
        contains('Not enough'));
    expect(
        redemptionError(
            const PostgrestException(message: 'Reward is out of stock')),
        contains('out of stock'));
    expect(
        redemptionError(const PostgrestException(
            message: 'Subscription tier does not qualify')),
        contains('tier'));
  });
}
