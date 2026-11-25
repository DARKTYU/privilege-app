import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/language_settings.dart';
import 'package:privilege/screens/subscription.dart';
import 'package:privilege/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progression_fake.dart';
import 'subscription_fake.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    languageSettings.selected = const Locale('en');
  });

  Widget app(Widget home) => ListenableBuilder(
        listenable: languageSettings,
        builder: (_, __) => MaterialApp(
          locale: languageSettings.selected,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(),
          home: Scaffold(body: home),
        ),
      );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Free user sees real prices and can choose Silver or Gold',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(SubscriptionScreen(
        progressionRepository: FakeProgression()..tier = 'Free',
        subscriptionRepository: FakeSubscriptions())));
    await tester.pumpAndSettle();
    expect(find.text('\$9.99 / 30 days'), findsOneWidget);
    expect(find.text('\$14.99 / 30 days'), findsOneWidget);
    expect(find.text('Current plan'), findsOneWidget);
    expect(find.text('Choose Silver'), findsOneWidget);
    expect(find.text('Choose Gold'), findsOneWidget);
    expect(find.text('Cancel membership'), findsNothing);
  });

  testWidgets('demo checkout names itself, subscribes once and refreshes',
      (tester) async {
    phone(tester);
    final progression = FakeProgression()..tier = 'Free';
    final subscriptions = FakeSubscriptions()
      ..onTierChange = (tier) => progression.tier = tier;
    await tester.pumpWidget(app(SubscriptionScreen(
        progressionRepository: progression,
        subscriptionRepository: subscriptions)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Choose Silver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Silver'));
    await tester.pumpAndSettle();
    expect(find.text('Demo checkout'), findsOneWidget);
    expect(find.textContaining('no real payment is taken'), findsWidgets);
    expect(subscriptions.subscribed, isEmpty);

    await tester.tap(find.text('Start demo membership'));
    await tester.pumpAndSettle();
    expect(subscriptions.subscribed, ['Silver']);
    expect(find.text('Current membership: Silver'), findsOneWidget);
    expect(find.text('Choose Silver'), findsNothing);
    expect(find.text('Choose Gold'), findsOneWidget);
    expect(find.text('Cancel membership'), findsOneWidget);
  });

  testWidgets('cancelling the checkout dialog changes nothing',
      (tester) async {
    phone(tester);
    final subscriptions = FakeSubscriptions();
    await tester.pumpWidget(app(SubscriptionScreen(
        progressionRepository: FakeProgression()..tier = 'Free',
        subscriptionRepository: subscriptions)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose Gold'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Gold'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(subscriptions.subscribed, isEmpty);
    expect(find.text('Current membership: Free'), findsOneWidget);
  });

  testWidgets('Gold user can cancel and returns to Free', (tester) async {
    phone(tester);
    final progression = FakeProgression()..tier = 'Gold';
    final subscriptions = FakeSubscriptions()
      ..onTierChange = (tier) => progression.tier = tier;
    await tester.pumpWidget(app(SubscriptionScreen(
        progressionRepository: progression,
        subscriptionRepository: subscriptions)));
    await tester.pumpAndSettle();
    expect(find.text('Choose Silver'), findsNothing);
    expect(find.text('Choose Gold'), findsNothing);

    await tester.tap(find.text('Cancel membership'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel your membership?'), findsOneWidget);
    await tester.tap(find.text('Keep membership'));
    await tester.pumpAndSettle();
    expect(subscriptions.cancels, 0);

    await tester.tap(find.text('Cancel membership'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel membership'));
    await tester.pumpAndSettle();
    expect(subscriptions.cancels, 1);
    expect(find.text('Current membership: Free'), findsOneWidget);
  });

  testWidgets('a failed subscription shows an error and keeps the tier',
      (tester) async {
    phone(tester);
    final subscriptions = FakeSubscriptions()..actionError = Exception('x');
    await tester.pumpWidget(app(SubscriptionScreen(
        progressionRepository: FakeProgression()..tier = 'Free',
        subscriptionRepository: subscriptions)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose Silver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Silver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start demo membership'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not complete this'), findsOneWidget);
    expect(find.text('Current membership: Free'), findsOneWidget);
  });

  testWidgets('plans failure is visible and retryable', (tester) async {
    phone(tester);
    final subscriptions = FakeSubscriptions()..plansError = Exception('off');
    await tester.pumpWidget(app(SubscriptionScreen(
        progressionRepository: FakeProgression()..tier = 'Free',
        subscriptionRepository: subscriptions)));
    await tester.pumpAndSettle();
    expect(find.text('Plans could not be loaded.'), findsOneWidget);
    subscriptions.plansError = null;
    await tester.tap(find.text('Retry membership'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Silver'), findsOneWidget);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('membership screen fits 360px in $language', (tester) async {
      phone(tester);
      languageSettings.selected = Locale(language);
      await tester.pumpWidget(app(SubscriptionScreen(
          progressionRepository: FakeProgression()..tier = 'Silver',
          subscriptionRepository: FakeSubscriptions())));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(SubscriptionScreen)))!;
      expect(find.text(l.membershipPlansTitle), findsOneWidget);
      await tester.scrollUntilVisible(find.text(l.membershipComingSoon), 200,
          scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
    });
  }
}
