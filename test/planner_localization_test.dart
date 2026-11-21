import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/screens/plan.dart';
import 'package:privilege/screens/splits.dart';
import 'package:privilege/services/planner_repository.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';

import 'planner_fake.dart';

void main() {
  test('planner screen files contain no hardcoded Arabic letters', () {
    for (final path in ['lib/screens/plan.dart', 'lib/screens/splits.dart']) {
      expect(File(path).readAsStringSync(),
          isNot(contains(RegExp(r'[\u0600-\u06ff]'))),
          reason: path);
    }
  });

  test('planner has no literal text, labels, hints or tooltips', () {
    final source = File('lib/screens/plan.dart').readAsStringSync();
    expect(
        RegExp(r"""(?:Text\(\s*(?:const\s*)?|(?:labelText|hintText|helperText|tooltip|label|title)\s*:\s*)['"]""")
            .allMatches(source),
        isEmpty);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('Plan translates forms and preserves stored names in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
              name: 'My custom split',
              kind: 'workout',
              duration: 45,
              effort: 50),
        ]);
      final state = AppState(plannerRepository: repo);
      addTearDown(state.dispose);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: Scaffold(body: PlanScreen(state: state)),
      ));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(PlanScreen));
      final l = AppLocalizations.of(context)!;
      expect(find.text(language == 'ar' ? 'منظم الخطة' : 'Plan Organiser'),
          findsOneWidget);
      expect(Directionality.of(context),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(find.text(l.plannerNothingPlanned), findsOneWidget);
      final selectedDate = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .firstWhere((text) => text.startsWith(
              language == 'ar' ? 'اليوم المحدد:' : 'Selected day:'));
      expect(selectedDate,
          isNot(contains(RegExp(r'[\u0660-\u0669\u06f0-\u06f9]'))));
      expect(find.text(language == 'ar' ? 'دفع' : 'Push'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('My custom split'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('My custom split'), findsOneWidget);
      await tester
          .ensureVisible(find.byTooltip(l.plannerEditName(l.plannerPush)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l.plannerEditName(l.plannerPush)));
      await tester.pumpAndSettle();
      expect(find.text(l.plannerEditSplit), findsOneWidget);
      expect(
          tester
              .widget<TextFormField>(
                  find.widgetWithText(TextFormField, l.plannerName))
              .controller!
              .text,
          'Push');
      await tester.enterText(
          find.widgetWithText(TextFormField, l.plannerName), '');
      await tester.tap(find.text(l.plannerSave));
      await tester.pumpAndSettle();
      expect(find.text(l.plannerInvalidName), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextFormField, l.plannerName), 'Push');
      await tester.tap(find.text(l.plannerSave));
      await tester.pumpAndSettle();
      expect(repo.splits.first.name, 'Push');
      expect(repo.splits.last.name, 'My custom split');
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['en', 'ar']) {
    for (final planner in [true, false]) {
      testWidgets('${planner ? 'Plan' : 'Splits'} fits at 360 in $language',
          (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FakePlanner()
          ..splits.add(const PlannerSplit(
              id: 'custom',
              name: 'Push',
              kind: 'workout',
              duration: 60,
              effort: 70));
        final state = AppState(plannerRepository: repo);
        addTearDown(state.dispose);
        await tester.pumpWidget(MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(),
          home: Scaffold(
              body: planner
                  ? PlanScreen(state: state)
                  : SplitsScreen(state: state, onManageSplits: () {})),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (!planner && language == 'ar') {
          expect(find.text('تمرين الدفع'), findsWidgets);
          expect(find.text('كرة السلة'), findsWidgets);
          await tester.tap(find.byType(DropdownButtonFormField<String>).first);
          await tester.pumpAndSettle();
          expect(find.text('دفع (تقسيمتي)'), findsOneWidget);
        }
      });
    }
  }
}
