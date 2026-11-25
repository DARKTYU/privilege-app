import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/logic/calorie_target.dart';
import 'package:privilege/logic/user_profile.dart';
import 'package:privilege/screens/home_shell.dart';
import 'package:privilege/screens/chat.dart';
import 'package:privilege/screens/profile.dart';
import 'package:privilege/services/coach_client.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progression_fake.dart';
import 'planner_fake.dart';

class FakeCoachClient implements CoachClient {
  @override
  String? get accountId => 'test-user';

  @override
  Future<CoachReply> send(Map<String, Object> body) async =>
      const CoachReply('Hello', null, null);
}

void main() {
  setUpAll(() async => FoodDatabase().load());
  test('home shell contains no hardcoded UI strings or Arabic', () {
    final source = File('lib/screens/home_shell.dart').readAsStringSync();
    final labels = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|(?:tooltip|labelText|hintText|semanticLabel)\s*:\s*)['"]""");
    expect(labels.allMatches(source), isEmpty);
    expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
  });
  for (final language in ['en', 'ar']) {
    testWidgets('shell navigation fits at 360 in $language', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(plannerRepository: FakePlanner());
      addTearDown(state.dispose);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: HomeShell(
            alertBell: const SizedBox(height: 32),
            progressionRepository: FakeProgression(),
            plannerState: state),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(HomeShell)))!;
      expect(find.byTooltip(l.botTooltip), findsOneWidget);
      for (final label in [
        l.home,
        l.splits,
        l.calories,
        l.profile,
        l.community,
        l.recipes
      ]) {
        expect(find.text(label), findsWidgets);
      }
      await tester.tap(find.text(l.splits));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('logging from a pushed page closes it once and keeps the shell',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    caloriesLogEvents.value = null;
    final state = AppState(plannerRepository: FakePlanner());
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(),
      home: HomeShell(
          alertBell: const SizedBox(height: 32),
          progressionRepository: FakeProgression(),
          plannerState: state),
    ));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(HomeShell))).push(
        MaterialPageRoute<void>(
            builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        notifyCaloriesLog(CaloriesResultKind.food, 300);
                        Navigator.pop(context);
                      },
                      child: const Text('save-test'),
                    ),
                  ),
                )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('save-test'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('save-test'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bot button opens sheet and preserves selected tab',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(plannerRepository: FakePlanner());
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: HomeShell(
          alertBell: const SizedBox(height: 32),
          progressionRepository: FakeProgression(),
          coachClient: FakeCoachClient(),
          plannerState: state),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.tap(find.byTooltip('AI Privilege Bot'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(ChatScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Close chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
  for (final scale in [1.0, 1.5]) {
    testWidgets('Home and Profile clear bottom overlays at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: HomeShell(
            alertBell: const SizedBox(height: 32),
            progressionRepository: FakeProgression(),
            plannerState: AppState(plannerRepository: FakePlanner())),
      ));
      await tester.pumpAndSettle();
      final chip = find.text('Community');
      final fab = find.byTooltip('AI Privilege Bot');
      final nav = find.byType(BottomAppBar);
      final homeEnd =
          find.text('Deleting a split keeps the days already planned.');
      await tester.scrollUntilVisible(homeEnd, 250,
          scrollable: find
              .descendant(
                  of: find.byType(HomeShell), matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      final homeRect = tester.getRect(homeEnd);
      expect(homeRect.bottom, lessThan(tester.getTopLeft(chip).dy));
      expect(homeRect.overlaps(tester.getRect(fab)), isFalse);
      expect(homeRect.overlaps(tester.getRect(nav)), isFalse);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      final signOut = find.text('Sign Out of Privilege');
      final scroll = find.descendant(
          of: find.byType(ProfileScreen), matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(signOut, 250, scrollable: scroll.first);
      await tester.pumpAndSettle();
      final button =
          find.ancestor(of: signOut, matching: find.byType(OutlinedButton));
      final rect = tester.getRect(button);
      expect(rect.bottom, lessThanOrEqualTo(tester.getTopLeft(chip).dy));
      expect(rect.overlaps(tester.getRect(fab)), isFalse);
      expect(rect.overlaps(tester.getRect(nav)), isFalse);
      expect(button.hitTestable(), findsOneWidget);
    });
  }

  testWidgets('profile switches between complete and edit calorie profile',
      (tester) async {
    appState.profile =
        defaultUserProfile.copyWith(hasWeight: false, hasHeight: false);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
          body: ProfileScreen(progressionRepository: FakeProgression())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Complete your calorie profile'), findsOneWidget);
    appState.profile = defaultUserProfile.copyWith(
        hasWeight: true,
        hasHeight: true,
        birthDate: DateTime(1995, 1, 1),
        sex: TargetSex.unspecified,
        activity: TargetActivity.moderate);
    appState.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Edit calorie profile'), findsOneWidget);
    expect(find.text('Complete your calorie profile'), findsNothing);
  });
}
