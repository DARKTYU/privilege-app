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
          expect(find.text('Push (My split)'), findsOneWidget);
        }
      });
    }
  }
}
