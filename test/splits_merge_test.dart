import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/data.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/user_profile.dart';
import 'package:privilege/logic/workout_estimate.dart';
import 'package:privilege/screens/home_shell.dart';
import 'package:privilege/screens/splits.dart';
import 'package:privilege/services/planner_repository.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';

import 'planner_fake.dart';
import 'progression_fake.dart';

class _State extends AppState {
  _State(FakePlanner repo) : super(plannerRepository: repo);
  int saves = 0;
  @override
  Future<void> addBurn(BurnItem workout) async => saves++;
}

void main() {
  Future<(FakePlanner, _State)> render(WidgetTester tester,
      {double scale = 1, FakePlanner? repository, String? language}) async {
    final repo = repository ?? FakePlanner();
    final state = _State(repo)
      ..profile = defaultUserProfile.copyWith(weightKg: 80, hasWeight: true);
    addTearDown(state.dispose);
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      locale: language == null ? null : Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(body: SplitsScreen(state: state, onManageSplits: () {})),
    ));
    await tester.pumpAndSettle();
    return (repo, state);
  }

  Future<void> visible(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 180,
        scrollable: find
            .descendant(
                of: find.byType(SplitsScreen),
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await visible(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label, String name) async {
    await tester.drag(find.byType(ListView).first, const Offset(0, 1400));
    await tester.pumpAndSettle();
    await tap(
        tester, find.widgetWithText(DropdownButtonFormField<String>, label));
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  test('splits has no hardcoded Arabic or user-facing literal labels', () {
    final source = File('lib/screens/splits.dart').readAsStringSync();
    expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
    expect(
        RegExp(r"""(?:Text\(\s*(?:const\s*)?|ScreenHeader\(\s*|(?:labelText|hintText|helperText|tooltip|label|title)\s*:\s*)['"]""")
            .allMatches(source),
        isEmpty);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('localized splits and planning at 360 in $language',
        (tester) async {
      final repo = FakePlanner()
        ..splits.addAll([
          const PlannerSplit(
              id: 'starter',
              name: 'Push',
              kind: 'workout',
              duration: 60,
              effort: 70),
          const PlannerSplit(
              id: 'custom',
              name: 'Custom name',
              kind: 'workout',
              duration: 40,
              effort: 70),
        ]);
      await render(tester, repository: repo, language: language);
      final context = tester.element(find.byType(SplitsScreen));
      final l = AppLocalizations.of(context)!;
      expect(Directionality.of(context),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(find.text(l.mergeTitle), findsOneWidget);
      expect(find.text(l.mergeSubtitle), findsOneWidget);
      expect(find.text(l.splitPushDay), findsWidgets);
      await tap(
          tester,
          find.widgetWithText(
              DropdownButtonFormField<String>, l.mergeWorkoutSplit));
      expect(find.text(l.mergeSavedName(l.plannerPush)), findsOneWidget);
      expect(find.text(l.mergeSavedName('Custom name')), findsOneWidget);
      await tester.tap(find.text(l.mergeSavedName(l.plannerPush)));
      await tester.pumpAndSettle();
      await visible(
          tester, find.text(l.mergeEstimatedCalories(l.mergeCalories('920'))));
      expect(find.text(l.mergeCombinedDuration(l.mergeMinutes('120'))),
          findsOneWidget);
      expect(
          find.text(
              l.mergeNamedValue(l.plannerPush, l.mergeShortMinutes('60'))),
          findsOneWidget);
      expect(find.text(l.mergeEstimateNote), findsOneWidget);
      await tap(tester, find.text(l.mergePlanDate));
      final date = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .firstWhere(
              (s) => s.startsWith(language == 'ar' ? 'التاريخ:' : 'Date:'));
      expect(date, isNot(contains(RegExp(r'[\u0660-\u0669\u06f0-\u06f9]'))));
      await tester.tap(find.text(date));
      await tester.pumpAndSettle();
      final pickerText = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(DatePickerDialog), matching: find.byType(Text)))
          .map((text) => text.data ?? '')
          .join(' ');
      expect(
          pickerText, isNot(contains(RegExp(r'[\u0660-\u0669\u06f0-\u06f9]'))));
      final pickerContext = tester.element(find.byType(DatePickerDialog));
      await tester.tap(find
          .text(MaterialLocalizations.of(pickerContext).cancelButtonLabel)
          .last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, l.mergePlannerEffort), '101');
      await tester.tap(find.text(l.mergeContinue));
      await tester.pumpAndSettle();
      expect(find.text(l.plannerInvalidEffort), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, l.mergePlannerEffort), '70');
      await tester.tap(find.text(l.mergeContinue));
      await tester.pumpAndSettle();
      expect(repo.days.single.name, 'Push + Basketball');
      expect(repo.splits.first.name, 'Push');
      await tap(tester, find.text(l.mergePlanDate));
      await tester.tap(find.text(l.mergeContinue));
      await tester.pumpAndSettle();
      expect(find.text(l.mergeReplaceTitle), findsOneWidget);
      await tester.tap(find.text(l.plannerCancel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  test('sport MET rows and per-segment rounding', () {
    final expected = <WorkoutActivity, List<int>>{
      WorkoutActivity.basketball: [360, 520, 640],
      WorkoutActivity.football: [560, 680, 800],
      WorkoutActivity.tennis: [480, 584, 640],
      WorkoutActivity.martialArts: [440, 624, 824],
      WorkoutActivity.swimming: [464, 560, 784],
      WorkoutActivity.circuit: [480, 640, 800],
    };
    for (final entry in expected.entries) {
      for (final intensity in WorkoutIntensity.values) {
        expect(estimateWorkoutCalories(entry.key, intensity, 80, 60),
            entry.value[intensity.index]);
      }
    }
    expect(
        estimateWorkoutCalories(
            WorkoutActivity.strength, WorkoutIntensity.moderate, 70, 1),
        6);
    expect(
        estimateWorkoutCalories(
            WorkoutActivity.tennis, WorkoutIntensity.moderate, 70, 1),
        9);
    expect(WorkoutActivity.tennis.type, BurnType.cardio);
  });

  testWidgets('built-in and saved workout splits, not rest splits',
      (tester) async {
    final repo = FakePlanner()
      ..splits.addAll([
        const PlannerSplit(
            id: 'my',
            name: 'Upper custom',
            kind: 'workout',
            duration: 42,
            effort: 60),
        const PlannerSplit(id: 'rest', name: 'Recovery', kind: 'rest'),
      ]);
    await render(tester, repository: repo);
    await tap(tester,
        find.widgetWithText(DropdownButtonFormField<String>, 'Workout split'));
    for (final split in defaultWorkoutSplits) {
      expect(find.text(split.name, skipOffstage: false), findsWidgets);
    }
    expect(find.text('Upper custom (My split)'), findsOneWidget);
    expect(find.text('Recovery'), findsNothing);
    await tester.tap(find.text('Upper custom (My split)'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('Split-minutes')))
            .controller!
            .text,
        '42');
  });

  testWidgets('estimates react to choices, minutes, intensity and weight',
      (tester) async {
    final (_, state) = await render(tester);
    await visible(tester, find.text('Estimated calories burned: 920 kcal'));
    expect(find.text('Estimated calories burned: 920 kcal'), findsOneWidget);
    await choose(tester, 'Sport', 'Tennis');
    expect(find.text('Estimated calories burned: 984 kcal'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('Split-minutes')), '1');
    await tester.enterText(find.byKey(const ValueKey('Sport-minutes')), '1');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    expect(find.text('Estimated calories burned: 17 kcal'), findsOneWidget);
    await tap(tester, find.text('Vigorous').first);
    expect(find.text('Estimated calories burned: 18 kcal'), findsOneWidget);
    state.profile = state.profile.copyWith(weightKg: 70);
    state.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Estimated calories burned: 16 kcal'), findsOneWidget);
    state.profile = state.profile.copyWith(hasWeight: false);
    state.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Calorie estimate unavailable - add your weight'),
        findsOneWidget);
    expect(find.text('Combined duration: 2 minutes'), findsOneWidget);
    expect(find.textContaining('Estimated calories burned: 16'), findsNothing);
    expect(find.text('Complete your profile'), findsOneWidget);
    state.profile =
        state.profile.copyWith(hasWeight: true, weightKg: double.nan);
    state.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Calorie estimate unavailable - add your weight'),
        findsOneWidget);
  });

  testWidgets('every sport maps to its own MET row', (tester) async {
    await render(tester);
    for (final (name, total) in [
      ('Basketball', 920),
      ('Football / Soccer', 1080),
      ('Tennis', 984),
      ('Boxing / MMA', 920),
      ('Swimming Laps', 820),
      ('Track Sprint Intervals', 827),
    ]) {
      await choose(tester, 'Sport', name);
      await visible(
          tester, find.text('Estimated calories burned: $total kcal'));
      expect(
          find.text('Estimated calories burned: $total kcal'), findsOneWidget);
    }
  });

  testWidgets('planner snapshot, replace confirmation and save failures',
      (tester) async {
    final repo = FakePlanner()
      ..splits.add(const PlannerSplit(
          id: 'custom',
          name: 'Upper',
          kind: 'workout',
          duration: 40,
          effort: 25));
    final (_, state) = await render(tester, repository: repo);
    await choose(tester, 'Workout split', 'Upper (My split)');
    await tap(tester, find.text('Plan on a date'));
    await tester.enterText(
        find.widgetWithText(TextField, 'Planner effort (%)'), '81');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(repo.days.single.name, 'Upper + Basketball');
    expect(repo.days.single.sourceSplitId, 'custom');
    expect(repo.days.single.duration, 100);
    expect(repo.days.single.effort, 81);
    expect(repo.days.single.date, '2026-11-20');
    expect(state.saves, 0);
    await tap(tester, find.text('Plan on a date'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Replace existing plan?'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(repo.days.single.effort, 81);
    await tap(tester, find.text('Plan on a date'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    repo.failure = 'offline save';
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong. Please try again.'),
        findsOneWidget);
    expect(repo.days.single.effort, 81);
  });

  testWidgets('validation and guarded double tap on plan save', (tester) async {
    final (repo, _) = await render(tester);
    await tester.enterText(find.byKey(const ValueKey('Split-minutes')), '600');
    tester.testTextInput.hide();
    await tap(tester, find.text('Plan on a date'));
    expect(find.textContaining('combined total of 1 to 600'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('Split-minutes')), '60');
    tester.testTextInput.hide();
    await tap(tester, find.text('Plan on a date'));
    await tester.enterText(
        find.widgetWithText(TextField, 'Planner effort (%)'), '101');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter effort from 0 to 100%.'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Planner effort (%)'), '70');
    repo.saveGate = Completer<void>();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(repo.saveCalls, 1);
    await tester.tap(find.text('Plan on a date'), warnIfMissed: false);
    await tester.pump();
    expect(repo.saveCalls, 1);
    repo.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(repo.days.single.sourceSplitId, isNull);
    expect(repo.days.single.duration, 120);
  });

  testWidgets('name limit and planner read error do not save', (tester) async {
    final repo = FakePlanner()
      ..splits.add(PlannerSplit(
          id: 'long',
          name: 'A' * 100,
          kind: 'workout',
          duration: 60,
          effort: 70));
    await render(tester, repository: repo);
    await choose(tester, 'Workout split', '${'A' * 100} (My split)');
    await tap(tester, find.text('Plan on a date'));
    expect(find.textContaining('100 characters or fewer'), findsOneWidget);
    expect(repo.saveCalls, 0);
    await choose(tester, 'Workout split', 'Push Day');
    await tap(tester, find.text('Plan on a date'));
    repo.failure = 'offline read';
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong. Please try again.'),
        findsOneWidget);
    expect(repo.days, isEmpty);
  });

  testWidgets('choose another date and explicitly replace a plan',
      (tester) async {
    final (repo, _) = await render(tester);
    repo.days
        .add(const PlannerDay(date: '2026-11-21', name: 'Old', kind: 'rest'));
    await tap(tester, find.text('Plan on a date'));
    await tester.tap(find.textContaining('Date:'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('21').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Old'), findsOneWidget);
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(repo.days.single.date, '2026-11-21');
    expect(repo.days.single.name, 'Push Day + Basketball');
    expect(repo.days.single.effort, 70);
  });

  testWidgets('sprint interval maps to circuit in estimate and logger',
      (tester) async {
    await render(tester);
    await choose(tester, 'Sport', 'Track Sprint Intervals');
    await visible(tester, find.text('Estimated calories burned: 827 kcal'));
    await tap(tester, find.text('Log sport'));
    final selected = tester.widget<ChoiceChip>(find.ancestor(
        of: find.text('⚡ HIIT or circuit'), matching: find.byType(ChoiceChip)));
    expect(selected.selected, isTrue);
  });

  testWidgets(
      'log buttons prefill independent segments and cancellation saves nothing',
      (tester) async {
    final (_, state) = await render(tester);
    await choose(tester, 'Sport', 'Tennis');
    await tester.enterText(find.byKey(const ValueKey('Split-minutes')), '35');
    await tester.enterText(find.byKey(const ValueKey('Sport-minutes')), '25');
    tester.testTextInput.hide();
    await tap(tester, find.text('Vigorous').first);
    await tap(tester, find.text('Light').last);
    for (final item in [
      ('Log workout', '35', '🏋️ Strength training', 'Vigorous'),
      ('Log sport', '25', '🎾 Tennis', 'Light'),
    ]) {
      await tap(tester, find.text(item.$1));
      expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('workout-duration')))
              .controller!
              .text,
          item.$2);
      final activity = tester.widget<ChoiceChip>(find.ancestor(
          of: find.text(item.$3), matching: find.byType(ChoiceChip)));
      final intensity = tester.widget<ChoiceChip>(find.ancestor(
          of: find.text(item.$4).last, matching: find.byType(ChoiceChip)));
      expect(activity.selected, isTrue);
      expect(intensity.selected, isTrue);
      Navigator.of(tester.element(find.text('Log workout').last)).pop();
      await tester.pumpAndSettle();
    }
    expect(state.saves, 0);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('merge layout at 360x640 scale $scale', (tester) async {
      await render(tester, scale: scale);
      await visible(tester, find.text('Log sport'));
      expect(find.text('Log sport').hitTestable(), findsOneWidget);
      await tap(tester, find.text('Plan on a date'));
      expect(
          find.widgetWithText(TextField, 'Planner effort (%)'), findsOneWidget);
      expect(find.text('Continue').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Free user can navigate Manage splits to Home', (tester) async {
    final state = _State(FakePlanner());
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: HomeShell(
          plannerState: state,
          alertBell: const SizedBox.shrink(),
          progressionRepository: FakeProgression()..tier = 'Free'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Splits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage splits'));
    await tester.pumpAndSettle();
    expect(find.text('Plan Organiser'), findsOneWidget);
  });
}
