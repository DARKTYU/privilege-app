import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/screens/cheats.dart';
import 'package:privilege/screens/champion.dart';
import 'package:privilege/services/cravings_repository.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';
import 'cravings_classified_fake.dart';
import 'planner_fake.dart';
import 'progression_fake.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final list = find.byType(ListView).first;
    await tester.scrollUntilVisible(finder, 180,
        scrollable:
            find.descendant(of: list, matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> mount(WidgetTester tester, Widget screen,
      {double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Scaffold(body: screen)));
    await tester.pumpAndSettle();
  }

  AppState create(FakeCravings meals, FakeClassifiedChecks checks) => AppState(
      plannerRepository: FakePlanner(),
      cravingsRepository: meals,
      classifiedChecksRepository: checks);

  for (final language in ['en', 'ar']) {
    testWidgets('classified pathway fits and persists at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final checks = FakeClassifiedChecks();
      final state = create(FakeCravings(), checks);
      addTearDown(state.dispose);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: Scaffold(
            body: ChampionScreen(
                state: state, progressionRepository: FakeProgression())),
      ));
      await tester.pumpAndSettle();
      final l =
          AppLocalizations.of(tester.element(find.byType(ChampionScreen)))!;
      expect(find.text(l.pathTitle), findsOneWidget);
      await tapVisible(tester, find.text(l.pathSetGoal));
      expect(checks.current, {'foundation_goal'});
      await tapVisible(tester, find.text(l.pathRegister));
      expect(find.text(l.pathTracked(l.levelBronze)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('add edit delete and reload; navigation and month limit',
      (tester) async {
    final repo = FakeCravings();
    final state = create(repo, FakeClassifiedChecks());
    addTearDown(state.dispose);
    await mount(tester, CheatsScreen(state: state));
    expect(find.text('November 2026'), findsOneWidget);
    await tapVisible(tester, find.text('Add Cheat Meal'));
    expect(find.text('Enter 1 to 200 characters.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Pizza');
    await tapVisible(tester, find.text('Add Cheat Meal'));
    expect(find.text('1 of 2 used this month'), findsOneWidget);
    expect(find.byKey(const ValueKey('craving-marker-20')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cake');
    await tapVisible(tester, find.text('Add Cheat Meal'));
    expect(find.text('2 of 2 used this month'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Add Cheat Meal'))
            .onPressed,
        isNull);
    await tapVisible(tester, find.text('Edit').first);
    await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'Edited');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.current.any((item) => item.notes == 'Edited'), isTrue);
    await tapVisible(tester, find.text('Delete').first);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(repo.current, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await mount(tester, CheatsScreen(state: state));
    expect(find.text('1 of 2 used this month'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);
    expect(find.text('0 of 2 used this month'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 used this month'), findsOneWidget);
  });

  testWidgets('a selected day is saved and marked', (tester) async {
    final meals = FakeCravings();
    final state = create(meals, FakeClassifiedChecks());
    addTearDown(state.dispose);
    await mount(tester, CheatsScreen(state: state));
    await tester.tap(find.byKey(const ValueKey('craving-day-7')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lunch');
    await tapVisible(tester, find.text('Add Cheat Meal'));
    expect(meals.current.single.date, '2026-11-07');
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('craving-marker-7')), findsOneWidget);
  });

  testWidgets('server limit refresh, save error and double taps',
      (tester) async {
    final repo = FakeCravings();
    final state = create(repo, FakeClassifiedChecks());
    addTearDown(state.dispose);
    await mount(tester, CheatsScreen(state: state));
    await tester.enterText(find.byType(TextField), 'Tea');
    repo.gate = Completer<void>();
    await tapVisible(tester, find.text('Add Cheat Meal'));
    expect(repo.writes, 1);
    await tester.tap(find.text('Add Cheat Meal'), warnIfMissed: false);
    expect(repo.writes, 1);
    repo.gate!.complete();
    repo.gate = null;
    await tester.pumpAndSettle();
    repo.current.addAll([
      const Craving(id: 'external1', date: '2026-11-02', notes: 'External'),
    ]);
    await tester.enterText(find.byType(TextField), 'More');
    await tapVisible(tester, find.text('Add Cheat Meal'));
    expect(find.textContaining('The selected month already has 2 Cheat Meals.'),
        findsOneWidget);
    expect(find.text('2 of 2 used this month'), findsOneWidget);
    expect(repo.current, hasLength(2));
  });

  testWidgets('editing to full month rejected and leaves original intact',
      (tester) async {
    final repo = FakeCravings()
      ..current.addAll([
        const Craving(id: '1', date: '2026-11-20', notes: 'Original'),
        const Craving(id: '2', date: '2026-12-01', notes: 'One'),
        const Craving(id: '3', date: '2026-12-02', notes: 'Two'),
      ]);
    final state = create(repo, FakeClassifiedChecks());
    addTearDown(state.dispose);
    await mount(tester, CheatsScreen(state: state));
    await tapVisible(tester, find.text('Edit'));
    await tester.tap(find.textContaining('Date:'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The selected month already has 2 Cheat Meals.'),
        findsOneWidget);
    expect(repo.current.first.date, '2026-11-20');
    expect(find.text('Original'), findsOneWidget);
  });

  testWidgets('legacy over-limit notes can be edited without moving date',
      (tester) async {
    final repo = FakeCravings()
      ..current.addAll([
        const Craving(id: '1', date: '2026-11-20', notes: 'First'),
        const Craving(id: '2', date: '2026-11-21', notes: 'Second'),
        const Craving(id: '3', date: '2026-11-22', notes: 'Third'),
      ]);
    final state = create(repo, FakeClassifiedChecks());
    addTearDown(state.dispose);
    await mount(tester, CheatsScreen(state: state));
    await tapVisible(tester, find.text('First'));
    await tapVisible(tester, find.text('Edit').first);
    await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'Changed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.current.first.notes, 'Changed');
    expect(repo.current.first.date, '2026-11-20');
  });

  testWidgets('load failures can be retried without false empty data',
      (tester) async {
    final meals = FakeCravings()..error = 'offline meals';
    final checks = FakeClassifiedChecks()..error = 'offline checks';
    final state = create(meals, checks);
    addTearDown(state.dispose);
    await mount(tester, CheatsScreen(state: state));
    expect(find.textContaining('Something went wrong. Please try again.'),
        findsOneWidget);
    expect(find.text('0 of 2 used this month'), findsNothing);
    meals.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 2 used this month'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await mount(tester,
        ChampionScreen(state: state, progressionRepository: FakeProgression()));
    expect(find.textContaining('Something went wrong. Please try again.'),
        findsOneWidget);
    final checkbox = tester.widget<CheckboxListTile>(find.ancestor(
        of: find.text('Set a personal training goal'),
        matching: find.byType(CheckboxListTile)));
    expect(checkbox.onChanged, isNull);
    checks.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong. Please try again.'),
        findsNothing);
  });

  testWidgets('save error leaves data unchanged and is displayed',
      (tester) async {
    final meals = FakeCravings();
    final state = create(meals, FakeClassifiedChecks());
    addTearDown(state.dispose);
    await mount(tester, CheatsScreen(state: state));
    await tester.enterText(find.byType(TextField), 'Cake');
    meals.error = 'network unavailable';
    await tapVisible(tester, find.text('Add Cheat Meal'));
    expect(find.textContaining('Something went wrong. Please try again.'),
        findsOneWidget);
    expect(meals.current, isEmpty);
    expect(find.text('0 of 2 used this month'), findsOneWidget);
  });

  testWidgets('checklist persists and failures do not change ticks',
      (tester) async {
    final checks = FakeClassifiedChecks();
    final state = create(FakeCravings(), checks);
    addTearDown(state.dispose);
    Widget screen() =>
        ChampionScreen(state: state, progressionRepository: FakeProgression());
    await mount(tester, screen());
    final text = find.text('Set a personal training goal');
    await tapVisible(tester, text);
    expect(checks.current, {'foundation_goal'});
    await tester.pumpWidget(const SizedBox());
    await mount(tester, screen());
    CheckboxListTile tile() => tester.widget(
        find.ancestor(of: text, matching: find.byType(CheckboxListTile)));
    expect(tile().value, isTrue);
    checks.error = 'offline';
    await tapVisible(tester, text);
    expect(tile().value, isTrue);
    expect(find.textContaining('Something went wrong. Please try again.'),
        findsOneWidget);
    checks.error = null;
    await tapVisible(tester, text);
    expect(tile().value, isFalse);
    expect(checks.current, isEmpty);
  });

  testWidgets('all five checklist items use stable keys', (tester) async {
    final checks = FakeClassifiedChecks();
    final state = create(FakeCravings(), checks);
    addTearDown(state.dispose);
    await mount(tester,
        ChampionScreen(state: state, progressionRepository: FakeProgression()));
    for (final name in [
      'Set a personal training goal',
      'Practice a consistent routine',
      'Practice your event skills',
      'Plan your next training milestone',
      'Make a long-term preparation plan',
    ]) {
      await tapVisible(tester, find.text(name));
    }
    expect(checks.current, {
      'foundation_goal',
      'novice_routine',
      'competitor_skills',
      'national_milestone',
      'pro_preparation'
    });
  });

  testWidgets('account switch clears both screens and loads new owner',
      (tester) async {
    final meals = FakeCravings()
      ..current
          .add(const Craving(id: 'a', date: '2026-11-20', notes: 'Private A'));
    final checks = FakeClassifiedChecks()..current.add('foundation_goal');
    final state = create(meals, checks);
    addTearDown(state.dispose);
    await mount(tester, CheatsScreen(state: state));
    await tapVisible(tester, find.text('Private A'));
    expect(find.text('Private A'), findsOneWidget);
    meals.accountId = 'user-b';
    state.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Private A'), findsNothing);
    expect(find.text('0 of 2 used this month'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await mount(tester,
        ChampionScreen(state: state, progressionRepository: FakeProgression()));
    checks.accountId = 'user-b';
    state.notifyListeners();
    await tester.pumpAndSettle();
    final tile = tester.widget<CheckboxListTile>(find.ancestor(
        of: find.text('Set a personal training goal'),
        matching: find.byType(CheckboxListTile)));
    expect(tile.value, isFalse);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('both screens fit 360x640 at scale $scale', (tester) async {
      final state = create(FakeCravings(), FakeClassifiedChecks());
      addTearDown(state.dispose);
      await mount(tester, CheatsScreen(state: state), scale: scale);
      await tapVisible(tester, find.text('Add Cheat Meal'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await mount(
          tester,
          ChampionScreen(
              state: state, progressionRepository: FakeProgression()),
          scale: scale);
      await tapVisible(tester, find.text('Make a long-term preparation plan'));
      expect(tester.takeException(), isNull);
    });
  }
}
