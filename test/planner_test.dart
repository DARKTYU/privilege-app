import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/screens/plan.dart';
import 'package:privilege/services/planner_repository.dart';
import 'package:privilege/state.dart';
import 'package:privilege/theme_settings.dart';
import 'package:privilege/ui.dart';

import 'planner_fake.dart';

void main() {
  test(
      'state saves snapshots independently and keeps them when split is deleted',
      () async {
    final repo = FakePlanner();
    final state = AppState(plannerRepository: repo);
    addTearDown(state.dispose);
    await state.loadPlanner('2026-11-15', '2026-11-21');
    await state.createPlannerSplits([
      const PlannerSplit(
          id: '', name: 'Push', kind: 'workout', duration: 60, effort: 70)
    ]);
    final split = state.plannerSplits.single;
    await state.planDayFromSplit('2026-11-20', split);
    await state.editPlannerDay(const PlannerDay(
        date: '2026-11-20',
        name: 'Custom',
        kind: 'workout',
        duration: 40,
        effort: 50));
    expect(state.plannerSplits.single.name, 'Push');
    expect(state.plannerSplits.single.duration, 60);
    await state.deletePlannerSplit(split.id);
    expect(state.plannerDays.single.name, 'Custom');
    await state.loadPlanner('2026-11-15', '2026-11-21');
    expect(state.plannerDays.single.duration, 40);
    await state.removePlannerDay('2026-11-20');
    expect(state.plannerDays, isEmpty);
    await state.markPlannerRest('2026-11-20');
    expect(state.plannerDays.single.name, 'Rest day');
  });

  test('failed saves leave state unchanged', () async {
    final repo = FakePlanner();
    final state = AppState(plannerRepository: repo);
    addTearDown(state.dispose);
    await state.loadPlanner('2026-11-15', '2026-11-21');
    repo.failure = 'offline';
    await expectLater(
        state.markPlannerRest('2026-11-20'), throwsA(isA<StateError>()));
    expect(state.plannerDays, isEmpty);
    await expectLater(
        state.createPlannerSplits(
            [const PlannerSplit(id: '', name: 'Rest', kind: 'rest')]),
        throwsA(isA<StateError>()));
    expect(state.plannerSplits, isEmpty);
  });

  Future<(FakePlanner, AppState)> render(WidgetTester tester,
      {double scale = 1}) async {
    final repo = FakePlanner();
    final state = AppState(plannerRepository: repo);
    addTearDown(state.dispose);
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
      home: Scaffold(body: PlanScreen(state: state)),
    ));
    await tester.pumpAndSettle();
    return (repo, state);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('empty state, starter splits and guarded repeat taps',
      (tester) async {
    final (repo, state) = await render(tester);
    expect(find.text('Nothing planned for this day.'), findsOneWidget);
    expect(find.text('Create your first split'), findsOneWidget);
    expect(find.byKey(const ValueKey('planned-2026-11-20')), findsNothing);
    final button = find.text('Add starter splits');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    repo.createGate = Completer<void>();
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(repo.createCalls, 1);
    repo.createGate!.complete();
    await tester.pumpAndSettle();
    expect(repo.createCalls, 1);
    expect(state.plannerSplits.map((s) => s.name), ['Push', 'Pull', 'Legs']);
    await state.loadPlanner('2026-11-15', '2026-11-21');
    await tester.pumpAndSettle();
    expect(state.plannerSplits.map((s) => s.name), ['Push', 'Pull', 'Legs']);
    expect(find.text('Add starter splits'), findsNothing);
  });

  testWidgets('split form validates and reports save errors', (tester) async {
    final (repo, state) = await render(tester);
    await tapVisible(tester, find.text('Create your first split'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name between 1 and 100 characters.'),
        findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Push');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'), '601');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Effort (%)'), '101');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter 1 to 600 minutes.'), findsOneWidget);
    expect(find.text('Enter effort from 0 to 100%.'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'), '60');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Effort (%)'), '70');
    repo.failure = 'network failure';
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('network failure'), findsOneWidget);
    expect(state.plannerSplits, isEmpty);
  });

  testWidgets('plan, edit and remove a day; delete keeps snapshot',
      (tester) async {
    final (repo, state) = await render(tester);
    await tapVisible(tester, find.text('Add starter splits'));
    await tapVisible(tester, find.text('Plan this day'));
    await tester.tap(find.text('Push').last);
    await tester.pumpAndSettle();
    expect(state.plannerDays.single.name, 'Push');
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('planned-2026-11-20')), findsOneWidget);
    await tapVisible(tester, find.text('Edit this day'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'Custom');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'), '45');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(state.plannerDays.single.name, 'Custom');
    expect(state.plannerSplits.first.name, 'Push');
    await tapVisible(tester, find.byTooltip('Delete Push'));
    expect(
        find.text('Days already planned will stay unchanged.'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repo.days.single.name, 'Custom');
    await tapVisible(tester, find.text('Remove'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(state.plannerDays, isEmpty);
  });

  testWidgets('dots use workout date and week navigation', (tester) async {
    final (repo, state) = await render(tester);
    await state.markPlannerRest('2026-11-18');
    await state.savePlannerDay(const PlannerDay(
        date: '2026-11-19',
        name: 'A',
        kind: 'workout',
        duration: 30,
        effort: 50));
    await state.savePlannerDay(const PlannerDay(
        date: '2026-11-20',
        name: 'B',
        kind: 'workout',
        duration: 30,
        effort: 50));
    repo.workouts.add('2026-11-20');
    await state.loadPlanner('2026-11-15', '2026-11-21');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rest-2026-11-18')), findsOneWidget);
    expect(find.byKey(const ValueKey('planned-2026-11-19')), findsOneWidget);
    expect(find.byKey(const ValueKey('completed-2026-11-20')), findsOneWidget);
    expect(find.text('Planned workout'), findsOneWidget);
    expect(find.text('Completed workout'), findsOneWidget);
    expect(find.text('Workout logged'), findsOneWidget);
    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('\u2068Nov 22, 2026\u2069 – \u2068Nov 28, 2026\u2069'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('completed-2026-11-20')), findsNothing);
    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('completed-2026-11-20')), findsOneWidget);
  });

  testWidgets('rest, split edit and logging availability follow the date',
      (tester) async {
    final (repo, state) = await render(tester);
    await tapVisible(tester, find.text('Add starter splits'));
    await tapVisible(tester, find.byTooltip('Edit Push'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Upper');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(state.plannerSplits.first.name, 'Upper');
    expect(state.plannerSplits.map((split) => split.name),
        ['Upper', 'Pull', 'Legs']);
    await state.loadPlanner('2026-11-15', '2026-11-21');
    await tester.pumpAndSettle();
    expect(state.plannerSplits.map((split) => split.name),
        ['Upper', 'Pull', 'Legs']);
    await tapVisible(tester, find.text('Plan this day'));
    await tester.tap(find.text('Rest day').last);
    await tester.pumpAndSettle();
    expect(state.plannerDays.single.kind, 'rest');
    await tapVisible(tester, find.text('Plan this day'));
    await tester.tap(find.text('Upper').last);
    await tester.pumpAndSettle();
    expect(state.plannerDays.single.kind, 'workout');
    expect(find.text('Log this workout'), findsOneWidget);
    await tapVisible(tester, find.text('Log this workout'));
    expect(find.text('Log workout'), findsWidgets);
    final duration = tester
        .widget<TextField>(find.byKey(const ValueKey('workout-duration')));
    expect(duration.controller!.text, '60');
    await tester.enterText(
        find.byKey(const ValueKey('workout-duration')), '45');
    expect(duration.controller!.text, '45');
    tester.testTextInput.hide();
    Navigator.of(tester.element(find.text('Log workout').last)).pop();
    await tester.pumpAndSettle();
    await state.savePlannerDay(const PlannerDay(
        date: '2026-11-21',
        name: 'Future',
        kind: 'workout',
        duration: 30,
        effort: 50));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('planner-date-2026-11-21')));
    await tester.pumpAndSettle();
    expect(find.text('Available on the day'), findsOneWidget);
    expect(find.text('Log this workout'), findsNothing);
    repo.failure = 'offline day';
    await tapVisible(tester, find.text('Plan this day'));
    await tester.tap(find.text('Rest day').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('offline day'), findsOneWidget);
    expect(state.plannerDays.where((d) => d.date == '2026-11-21').single.name,
        'Future');
    repo.failure = null;
    await state.savePlannerDay(const PlannerDay(
        date: '2026-11-19',
        name: 'Past',
        kind: 'workout',
        duration: 30,
        effort: 50));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('planner-date-2026-11-19')));
    await tester.pumpAndSettle();
    expect(find.text('Log this workout'), findsNothing);
    expect(find.text('Available on the day'), findsNothing);
  });

  testWidgets('today selection, marker, friendly date and week navigation',
      (tester) async {
    await render(tester);
    expect(find.text('Selected day: Fri, Nov 20'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-2026-11-20')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('planner-date-2026-11-19')));
    await tester.pumpAndSettle();
    expect(find.text('Selected day: Thu, Nov 19'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-2026-11-20')), findsOneWidget);
    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('Selected day: Sun, Nov 22'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-2026-11-20')), findsNothing);
    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.text('Selected day: Fri, Nov 20'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-2026-11-20')), findsOneWidget);
  });

  testWidgets('day chooser groups workout splits before saved rest splits',
      (tester) async {
    final (_, state) = await render(tester);
    await state.createPlannerSplits([
      const PlannerSplit(id: '', name: 'Custom rest', kind: 'rest'),
      const PlannerSplit(
          id: '', name: 'Workout A', kind: 'workout', duration: 25, effort: 50),
      const PlannerSplit(id: '', name: 'Another rest', kind: 'rest'),
      const PlannerSplit(
          id: '', name: 'Workout B', kind: 'workout', duration: 35, effort: 60),
    ]);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Plan this day'));
    final dialog = find.byType(AlertDialog);
    final tiles = tester.widgetList<ListTile>(
        find.descendant(of: dialog, matching: find.byType(ListTile)));
    expect(tiles.map((tile) => (tile.title! as Text).data),
        ['Rest day', 'Workout A', 'Workout B', 'Custom rest', 'Another rest']);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets(
        'split dialogs space fields and show validation at scale $scale',
        (tester) async {
      final (_, state) = await render(tester, scale: scale);
      await tester.scrollUntilVisible(
          find.text('Create your first split'), 200,
          scrollable: find.descendant(
              of: find.byType(ListView), matching: find.byType(Scrollable)));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Create your first split'));

      Future<void> checkForm() async {
        final name = find.widgetWithText(TextFormField, 'Name');
        final type = find.byType(DropdownButtonFormField<String>);
        final duration =
            find.widgetWithText(TextFormField, 'Duration (minutes)');
        final effort = find.widgetWithText(TextFormField, 'Effort (%)');
        expect(find.text('1 to 600 minutes'), findsOneWidget);
        expect(find.text('0 to 100'), findsOneWidget);
        expect(tester.getTopLeft(type).dy - tester.getBottomLeft(name).dy,
            greaterThanOrEqualTo(12));
        expect(tester.getTopLeft(duration).dy - tester.getBottomLeft(type).dy,
            greaterThanOrEqualTo(12));
        expect(tester.getTopLeft(effort).dy - tester.getBottomLeft(duration).dy,
            greaterThanOrEqualTo(12));
        await tester.enterText(name, '');
        await tester.enterText(duration, '601');
        await tester.enterText(effort, '101');
        tester.testTextInput.hide();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(tester.state<FormFieldState<String>>(name).errorText,
            'Enter a name between 1 and 100 characters.');
        expect(tester.state<FormFieldState<String>>(duration).errorText,
            'Enter 1 to 600 minutes.');
        expect(tester.state<FormFieldState<String>>(effort).errorText,
            'Enter effort from 0 to 100%.');
        for (final (field, message) in [
          (name, 'Enter a name between 1 and 100 characters.'),
          (duration, 'Enter 1 to 600 minutes.'),
          (effort, 'Enter effort from 0 to 100%.'),
        ]) {
          expect(find.descendant(of: field, matching: find.text(message)),
              findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(effort);
        await tester.pumpAndSettle();
        expect(
            tester.getRect(find.text('Save')).bottom, lessThanOrEqualTo(640));
      }

      await checkForm();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await state.createPlannerSplits([
        const PlannerSplit(
            id: '', name: 'Push', kind: 'workout', duration: 60, effort: 70)
      ]);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byTooltip('Edit Push'));
      await checkForm();
    });
  }

  testWidgets('rest day avoids duplicate label but keeps custom names',
      (tester) async {
    final (_, state) = await render(tester);
    await state.markPlannerRest('2026-11-20');
    await tester.pumpAndSettle();
    expect(find.text('Rest day'), findsOneWidget);
    await state.savePlannerDay(
        const PlannerDay(date: '2026-11-20', name: 'Recovery', kind: 'rest'));
    await tester.pumpAndSettle();
    expect(find.text('Recovery'), findsOneWidget);
    expect(find.text('Rest day'), findsOneWidget);
  });

  testWidgets('today marker contrasts with selected and unselected backgrounds',
      (tester) async {
    final (_, state) = await render(tester, scale: 1.5);
    final previous = themeSettings.selected;
    addTearDown(() => themeSettings.selected = previous);
    final marker = find.byKey(const ValueKey('today-2026-11-20'));
    final today = find.byKey(const ValueKey('planner-date-2026-11-20'));
    final other = find.byKey(const ValueKey('planner-date-2026-11-19'));
    for (final preset in AppThemePreset.values) {
      themeSettings.selected = preset;
      state.notifyListeners();
      await tester.pumpAndSettle();
      for (final isSelected in [true, false]) {
        await tester.tap(isSelected ? today : other);
        await tester.pumpAndSettle();
        final color = tester.widget<Container>(marker).color!;
        final background = isSelected ? preset.primary : preset.surface;
        final a = color.computeLuminance();
        final b = background.computeLuminance();
        final contrast = ((a > b ? a : b) + 0.05) / ((a < b ? a : b) + 0.05);
        expect(contrast, greaterThanOrEqualTo(3), reason: preset.label);
        expect(tester.getSize(marker).width, greaterThanOrEqualTo(18));
        expect(tester.getSize(marker).height, greaterThanOrEqualTo(2));
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('planner renders at 360x640 with large text', (tester) async {
    await render(tester, scale: 1.5);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Deleting a split keeps the days already planned.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
