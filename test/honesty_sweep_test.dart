import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/user_profile.dart';
import 'package:privilege/screens/champion.dart';
import 'package:privilege/screens/cheats.dart';
import 'package:privilege/screens/plan.dart';
import 'package:privilege/screens/profile.dart';
import 'package:privilege/screens/recipes.dart';
import 'package:privilege/screens/settings.dart';
import 'package:privilege/screens/splits.dart';
import 'package:privilege/screens/subscription.dart';
import 'package:privilege/state.dart';
import 'package:privilege/services/progression_repository.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progression_fake.dart';
import 'calories_test_database.dart';

Widget _app(Widget child) =>
    MaterialApp(theme: buildTheme(), home: Scaffold(body: child));

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async => FoodDatabase().load());
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appState.profile = defaultUserProfile.copyWith(name: 'Sam Lee');
    appState.streak = 4;
    appState.longestStreak = 9;
    appState.activityLoading = false;
    appState.activityError = null;
    appState.meals.clear();
    appState.burns.clear();
  });

  testWidgets('pathway shows real activity, level and unverified checklist',
      (tester) async {
    _tallScreen(tester);
    appState.burns.add(const BurnItem(
        id: '1',
        title: 'Run',
        time: '',
        calories: 100,
        type: BurnType.cardio,
        durationMin: 20,
        icon: ''));
    await tester.pumpWidget(_app(ChampionScreen(
        progressionRepository: FakeProgression()
          ..counts = const ActivityCounts(meals: 27, workouts: 42))));
    await tester.pumpAndSettle();
    expect(find.text('Tracked by the app · 9 days'), findsOneWidget);
    expect(find.text('Tracked by the app · 42'), findsOneWidget);
    expect(find.text('Tracked by the app · 27'), findsOneWidget);
    expect(find.text('Tracked by the app · Bronze'), findsOneWidget);
    for (final name in [
      'Foundation',
      'Novice',
      'Competitor-ready',
      'National level',
      'Pro pathway'
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Self-reported progress, not verified or certified'),
        findsOneWidget);
    expect(find.text('Done outside the app'), findsWidgets);
    expect(find.textContaining('WADA'), findsNothing);
    expect(find.textContaining('Eligible'), findsNothing);
    expect(find.textContaining('#88'), findsNothing);
    await tester.tap(find.text('Set a personal training goal'));
    await tester.pump();
    final checkbox = tester.widget<CheckboxListTile>(find.ancestor(
        of: find.text('Set a personal training goal'),
        matching: find.byType(CheckboxListTile)));
    expect(checkbox.value, isTrue);
  });

  testWidgets('pathway does not turn activity load errors into zero progress',
      (tester) async {
    _tallScreen(tester);
    appState.activityError = 'offline';
    await tester.pumpWidget(
        _app(ChampionScreen(progressionRepository: FakeProgression())));
    await tester.pumpAndSettle();
    expect(find.text('Tracked by the app · Unavailable'), findsOneWidget);
  });

  for (final tier in ['Free', 'Silver', 'Gold']) {
    testWidgets('membership displays real $tier without payment actions',
        (tester) async {
      await tester.pumpWidget(_app(SubscriptionScreen(
          progressionRepository: FakeProgression()..tier = tier)));
      await tester.pumpAndSettle();
      expect(find.text('Current membership: $tier'), findsOneWidget);
      expect(find.text('Coming soon. Payments are not available yet.'),
          findsOneWidget);
      expect(find.textContaining('Upgrade to'), findsNothing);
      expect(find.textContaining('Gemini'), findsNothing);
      expect(find.textContaining('WADA'), findsNothing);
    });
  }

  testWidgets('membership failure is visible and retryable', (tester) async {
    final repo = FakeProgression()..error = Exception('offline');
    await tester
        .pumpWidget(_app(SubscriptionScreen(progressionRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Membership unavailable. Check your connection.'),
        findsOneWidget);
    repo
      ..error = null
      ..tier = 'Gold';
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Current membership: Gold'), findsOneWidget);
  });

  for (final tier in ['Free', 'Silver', 'Gold']) {
    testWidgets('custom splits checks database membership $tier',
        (tester) async {
      await tester.pumpWidget(_app(
          SplitsScreen(progressionRepository: FakeProgression()..tier = tier)));
      await tester.tap(find.text('Add Split'));
      await tester.pumpAndSettle();
      if (tier == 'Free') {
        expect(find.textContaining('require Silver or Gold'), findsOneWidget);
        expect(find.text('Create Custom Split'), findsNothing);
      } else {
        expect(find.text('Create Custom Split'), findsOneWidget);
      }
    });
  }

  testWidgets('custom split membership errors are visible', (tester) async {
    await tester.pumpWidget(_app(SplitsScreen(
        progressionRepository: FakeProgression()
          ..error = Exception('offline'))));
    await tester.tap(find.text('Add Split'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not check membership'), findsOneWidget);
  });

  testWidgets('split estimates carry disclaimer and no fake sync',
      (tester) async {
    await tester.pumpWidget(
        _app(SplitsScreen(progressionRepository: FakeProgression())));
    await tester.tap(find.text('+ Merge Splits & Calculate Load'));
    await tester.pumpAndSettle();
    expect(find.text('Estimates only, not medical or coaching advice.'),
        findsOneWidget);
    expect(find.textContaining('Synced'), findsNothing);
    expect(find.text('Merge Day Active'), findsNothing);
  });

  testWidgets('profile and settings use initials and no fake bio or body fat',
      (tester) async {
    await tester.pumpWidget(
        _app(ProfileScreen(progressionRepository: FakeProgression())));
    await tester.pumpAndSettle();
    expect(find.text('SL'), findsOneWidget);
    expect(find.text('Add a bio'), findsOneWidget);
    expect(find.text('Body Fat %'), findsNothing);
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('SL'), findsOneWidget);
  });

  testWidgets('cheat meals start empty and remain explicitly unsaved',
      (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(_app(const CheatsScreen()));
    expect(find.text('Not saved yet'), findsOneWidget);
    expect(find.text('No meals added yet.'), findsOneWidget);
    expect(find.textContaining('Allowed'), findsNothing);
    expect(find.textContaining('budgeted'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Pizza');
    await tester.tap(find.byTooltip('Add Cheat Meal'));
    await tester.pump();
    expect(find.textContaining('Pizza (Day'), findsOneWidget);
    expect(find.text('Not saved yet'), findsOneWidget);
  });

  testWidgets('planner does not change a day or claim it saved a split',
      (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(_app(const PlanScreen()));
    final before = tester.widgetList<Text>(find.text('Workout Days')).length;
    await tester.tap(find.text('Add Split'));
    await tester.pump();
    expect(tester.widgetList<Text>(find.text('Workout Days')).length, before);
    expect(find.text('Not saved yet'), findsOneWidget);
    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
    expect(find.textContaining('Added'), findsNothing);
  });

  testWidgets('recipe favorites are saved on this device', (tester) async {
    await tester.pumpWidget(_app(RecipesScreen(
        accountId: () => 'user-a',
        database: CaloriesTestDatabase(FoodDatabase()))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Favorites are saved on this device.'),
        findsOneWidget);
    expect(find.textContaining('million recipes'), findsNothing);
    expect(find.text('Saved'), findsNothing);
    await tester.tap(find.byTooltip('Add favorite').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsOneWidget);
  });

  for (final screen in <String, Widget Function()>{
    'pathway': () => ChampionScreen(progressionRepository: FakeProgression()),
    'membership': () =>
        SubscriptionScreen(progressionRepository: FakeProgression()),
    'splits': () => SplitsScreen(progressionRepository: FakeProgression()),
    'cheat meals': () => const CheatsScreen(),
    'planner': () => const PlanScreen(),
    'recipes': () => RecipesScreen(
        accountId: () => 'user-a',
        database: CaloriesTestDatabase(FoodDatabase())),
  }.entries) {
    testWidgets('${screen.key} scrolls without overflow at 360 x 640',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(screen.value()));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -450));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
