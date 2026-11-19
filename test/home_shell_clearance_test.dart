import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/calorie_target.dart';
import 'package:privilege/logic/user_profile.dart';
import 'package:privilege/screens/home_shell.dart';
import 'package:privilege/screens/profile.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';

import 'progression_fake.dart';

void main() {
  setUpAll(() async => FoodDatabase().load());
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
            progressionRepository: FakeProgression()),
      ));
      await tester.pumpAndSettle();
      final chip = find.text('Community');
      final fab = find.byTooltip('AI Privilege Bot - coming soon');
      final nav = find.byType(BottomAppBar);
      final homeEnd = find.text('Quick Add');
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
