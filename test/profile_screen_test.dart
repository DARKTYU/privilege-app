import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/l10n/app_localizations_ar.dart';
import 'package:privilege/l10n/app_localizations_en.dart';
import 'package:privilege/screens/profile.dart';
import 'package:privilege/screens/subscription.dart';
import 'package:privilege/ui.dart';

import 'progression_fake.dart';
import 'subscription_fake.dart';

void main() {
  test('profile, alerts and subscription have no hardcoded UI labels', () {
    final pattern = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|ScreenHeader\(\s*|(?:tooltip|labelText|hintText|semanticLabel)\s*:\s*)['"]""");
    for (final path in [
      'lib/screens/profile.dart',
      'lib/screens/alerts.dart',
      'lib/screens/subscription.dart'
    ]) {
      final source = File(path).readAsStringSync();
      expect(pattern.allMatches(source), isEmpty, reason: path);
      expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))), reason: path);
    }
  });

  test('Arabic bio is shown without Latin quote marks, English keeps them', () {
    expect(AppLocalizationsAr().profileQuotedBio('road to champion'),
        'road to champion');
    expect(AppLocalizationsEn().profileQuotedBio('road to champion'),
        '\u201croad to champion\u201d');
  });

  for (final language in ['en', 'ar']) {
    testWidgets('profile and membership fit at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeProgression()..tier = 'Gold';
      Widget app(Widget screen) => MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildTheme(),
            home: Scaffold(body: screen),
          );
      await tester.pumpWidget(app(ProfileScreen(progressionRepository: repo)));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ProfileScreen));
      final l = AppLocalizations.of(context)!;
      expect(find.text(l.profileTitle), findsOneWidget);
      expect(find.text(l.membershipProfile(l.memberGold)), findsOneWidget);
      await tester.tap(find.text(l.profileEdit));
      await tester.pumpAndSettle();
      expect(find.text(l.profileGoal), findsOneWidget);
      await tester.ensureVisible(find.text(l.profileSaveChanges));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(SubscriptionScreen(
          progressionRepository: repo,
          subscriptionRepository: FakeSubscriptions())));
      await tester.pumpAndSettle();
      expect(find.text(l.membershipCurrent(l.memberGold)), findsOneWidget);
      expect(find.text(l.membershipComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final tier in ['Free', 'Silver', 'Gold']) {
    testWidgets(
        'profile displays $tier database membership without verification',
        (tester) async {
      final repository = FakeProgression()..tier = tier;
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: ProfileScreen(progressionRepository: repository)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Privilege $tier Member'), findsOneWidget);
      expect(find.textContaining('Drug-Free Verified'), findsNothing);
      expect(find.byIcon(Icons.verified_user), findsNothing);
    });
  }

  testWidgets('profile shows an error and retries membership loading',
      (tester) async {
    final repository = FakeProgression()..error = Exception('offline');
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(body: ProfileScreen(progressionRepository: repository)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Membership unavailable'), findsOneWidget);
    expect(find.textContaining('Privilege Pro Member'), findsNothing);
    repository
      ..error = null
      ..tier = 'Silver';
    await tester.tap(find.text('Retry membership'));
    await tester.pumpAndSettle();
    expect(find.text('Privilege Silver Member'), findsOneWidget);
  });

  testWidgets('profile opens the calorie profile sheet', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
          body: ProfileScreen(progressionRepository: FakeProgression())),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete your calorie profile'));
    await tester.tap(find.text('Complete your calorie profile'));
    await tester.pumpAndSettle();
    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('Choose birth date'), findsOneWidget);
  });
}
