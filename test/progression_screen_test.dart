import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/screens/progression.dart';
import 'package:privilege/services/progression_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'progression_fake.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
