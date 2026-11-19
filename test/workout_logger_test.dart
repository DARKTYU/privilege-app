import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/user_profile.dart';
import 'package:privilege/logic/workout_estimate.dart';
import 'package:privilege/screens/calories.dart';
import 'package:privilege/screens/workout_logger_sheet.dart';
import 'package:privilege/state.dart';
import 'package:privilege/theme_settings.dart';
import 'package:privilege/ui.dart';

class _WorkoutState extends AppState {
  BurnItem? saved;
  bool fail = false;
  @override
  Future<void> addBurn(BurnItem workout) async {
    if (fail) throw StateError('offline');
    saved = workout;
    burns.add(workout.copyWith(id: 'saved'));
    notifyListeners();
  }

  @override
  Future<void> removeBurn(String id) async {
    burns.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}

void main() {
  test('MET table computes requested estimates and maps existing categories',
      () {
    expect(
        estimateWorkoutCalories(
            WorkoutActivity.running, WorkoutIntensity.moderate, 80, 30),
        392);
    expect(
        estimateWorkoutCalories(
            WorkoutActivity.strength, WorkoutIntensity.moderate, 70, 60),
        350);
    expect(
        estimateWorkoutCalories(
            WorkoutActivity.other, WorkoutIntensity.moderate, 80, 30),
        isNull);
    for (final activity in WorkoutActivity.values) {
      expect(
          activity.type,
          activity == WorkoutActivity.strength
              ? BurnType.strength
              : BurnType.cardio);
    }
    expect(
        estimateWorkoutCalories(
            WorkoutActivity.running, WorkoutIntensity.moderate, 80, 0),
        isNull);
    expect(
        estimateWorkoutCalories(
            WorkoutActivity.running, WorkoutIntensity.moderate, 80, 601),
        isNull);
  });

  Future<void> open(WidgetTester tester, _WorkoutState state) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(body: ActivityTab(state: state)),
    ));
    await tester.ensureVisible(find.text('Log workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log workout'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('running estimate saves through addBurn and deletes',
      (tester) async {
    final state = _WorkoutState()
      ..profile = defaultUserProfile.copyWith(weightKg: 80);
    addTearDown(state.dispose);
    await open(tester, state);
    await tapVisible(tester, find.text('🏃 Running'));
    expect(find.text('≈ 392 kcal burned'), findsOneWidget);
    expect(find.text('MET x weight x hours'), findsOneWidget);
    await tapVisible(tester, find.text('Save workout'));
    expect(state.saved!.title, 'Running - 30 min');
    expect(state.saved!.calories, 392);
    expect(state.saved!.type, BurnType.cardio);
    expect(state.saved!.durationMin, 30);
    await tapVisible(tester, find.byTooltip('Delete Running - 30 min'));
    expect(state.burns, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('strength estimate and manual override are saved',
      (tester) async {
    final state = _WorkoutState()
      ..profile = defaultUserProfile.copyWith(weightKg: 70);
    addTearDown(state.dispose);
    await open(tester, state);
    await tapVisible(tester, find.text('60 min'));
    expect(find.text('≈ 350 kcal burned'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('workout-calories')));
    await tester.enterText(find.byKey(const ValueKey('workout-calories')), '0');
    await tapVisible(tester, find.text('Save workout'));
    expect(state.saved!.calories, 0);
    expect(state.saved!.type, BurnType.strength);
    expect(state.saved!.durationMin, 60);
  });

  testWidgets('manual override persists as inputs change and can be reset',
      (tester) async {
    final state = _WorkoutState()
      ..profile = defaultUserProfile.copyWith(weightKg: 80);
    addTearDown(state.dispose);
    await open(tester, state);
    final field = find.byKey(const ValueKey('workout-calories'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '275');
    await tapVisible(tester, find.text('🏃 Running'));
    expect(find.text('≈ 392 kcal burned'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, '275');
    await tapVisible(tester, find.text('Use estimate'));
    expect(tester.widget<TextField>(field).controller!.text, '392');
    await tapVisible(tester, find.text('🏃 Other'));
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(
        find.text('Other activities require manual calories.'), findsOneWidget);
  });

  testWidgets('missing weight and Other require manual calories',
      (tester) async {
    final state = _WorkoutState()
      ..profile = defaultUserProfile.copyWith(hasWeight: false);
    addTearDown(state.dispose);
    await open(tester, state);
    expect(find.text('Estimate unavailable — enter calories manually.'),
        findsOneWidget);
    await tapVisible(tester, find.text('Complete your profile'));
    expect(find.text('Complete your profile'), findsWidgets);
    Navigator.of(tester.element(find.text('Save profile'))).pop();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('🏃 Other'));
    await tester.ensureVisible(find.byKey(const ValueKey('workout-calories')));
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('workout-calories')))
            .controller!
            .text,
        isEmpty);
    await tester.enterText(
        find.byKey(const ValueKey('workout-calories')), '200');
    await tapVisible(tester, find.text('Save workout'));
    expect(state.saved!.calories, 200);
    expect(state.saved!.type, BurnType.cardio);
  });

  testWidgets('duration and calorie bounds and save errors are shown',
      (tester) async {
    final state = _WorkoutState()..fail = true;
    addTearDown(state.dispose);
    await open(tester, state);
    final minutes = find.byKey(const ValueKey('workout-duration'));
    await tester.enterText(minutes, '0');
    await tapVisible(tester, find.text('Save workout'));
    expect(find.text('Enter a duration between 1 and 600 minutes.'),
        findsOneWidget);
    await tester.ensureVisible(minutes);
    await tester.enterText(minutes, '601');
    await tapVisible(tester, find.text('Save workout'));
    expect(find.text('Enter a duration between 1 and 600 minutes.'),
        findsOneWidget);
    await tester.ensureVisible(minutes);
    await tester.enterText(minutes, '1');
    await tester.ensureVisible(find.byKey(const ValueKey('workout-calories')));
    await tester.enterText(
        find.byKey(const ValueKey('workout-calories')), '5001');
    await tapVisible(tester, find.text('Save workout'));
    expect(find.text('Enter calories between 0 and 5000.'), findsOneWidget);
    await tester.ensureVisible(minutes);
    await tester.enterText(minutes, '600');
    await tester.ensureVisible(find.byKey(const ValueKey('workout-calories')));
    await tester.enterText(
        find.byKey(const ValueKey('workout-calories')), '5000');
    await tapVisible(tester, find.text('Save workout'));
    expect(find.textContaining('Could not save workout:'), findsOneWidget);
    expect(state.saved, isNull);
  });

  testWidgets('logger builds for every theme in light and dark',
      (tester) async {
    final state = _WorkoutState();
    addTearDown(state.dispose);
    final previous = themeSettings.selected;
    addTearDown(() => themeSettings.selected = previous);
    for (final preset in AppThemePreset.values) {
      themeSettings.selected = preset;
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.dark
            ? buildTheme(preset)
            : ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: preset.primary, brightness: brightness));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(body: WorkoutLoggerSheet(state: state)),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Log workout'), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: '${preset.label} $brightness');
      }
    }
  });

  testWidgets('old quick burns remain visible in Workout Logs', (tester) async {
    final state = _WorkoutState()
      ..burns.add(const BurnItem(
        id: 'old',
        title: 'Quick Exercise Burn',
        time: 'now',
        calories: 100,
        type: BurnType.cardio,
        durationMin: 10,
        icon: '🔥',
      ));
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: Scaffold(body: ActivityTab(state: state))));
    await tester.scrollUntilVisible(find.text('Quick Exercise Burn'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ActivityTab), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(find.text('100 kcal burned'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Delete Quick Exercise Burn'));
    expect(state.burns, isEmpty);
  });
}
