import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/data.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/screens/academy.dart';
import 'package:privilege/screens/cheats.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';

import 'cravings_classified_fake.dart';
import 'planner_fake.dart';

void main() {
  test('screen-owned labels contain no hardcoded UI strings or Arabic', () {
    final visible = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|(?:sectionTitle|PrimaryButton|fieldDecoration)\(\s*|(?:tooltip|labelText|hintText|helperText|semanticLabel)\s*:\s*)['"]""");
    for (final path in [
      'lib/screens/cheats.dart',
      'lib/screens/academy.dart'
    ]) {
      final source = File(path).readAsStringSync();
      expect(visible.allMatches(source), isEmpty, reason: path);
      expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))), reason: path);
    }
  });

  for (final language in ['en', 'ar']) {
    testWidgets('academy fits and filters at 360 in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: const Scaffold(body: AcademyScreen()),
      ));
      await tester.pumpAndSettle();
      final l =
          AppLocalizations.of(tester.element(find.byType(AcademyScreen)))!;
      expect(find.text(l.academyAllGuides), findsOneWidget);
      expect(find.text(l.academyBurn(120, 15)), findsOneWidget);
      expect(find.text(l.levelBeginner), findsWidgets);
      final guide = guides.first;
      final ar = language == 'ar';
      expect(find.text(guide.localizedSubCategory(ar).toUpperCase()),
          findsOneWidget);
      expect(find.text(l.academyMuscles(guide.localizedMuscles(ar).join(', '))),
          findsOneWidget);
      await tester.tap(find.text(guide.localizedTitle(ar)));
      await tester.pumpAndSettle();
      expect(find.text(l.academyDisclaimer), findsOneWidget);
      expect(find.text(l.academyCues.toUpperCase()), findsOneWidget);
      expect(find.text(guide.localizedCues(ar).first), findsOneWidget);
      expect(
          find.text(ar ? guide.cues.first : guide.cuesAr.first), findsNothing);
      await tester.scrollUntilVisible(
          find.text(guide.localizedMistakes(ar).first), 150,
          scrollable: find
              .descendant(
                  of: find.byType(DraggableScrollableSheet),
                  matching: find.byType(Scrollable))
              .first);
      expect(find.text(guide.localizedMistakes(ar).first), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pillars');
      await tester.pumpAndSettle();
      expect(find.text(l.academyLifetime), findsOneWidget);
      await tester.enterText(find.byType(TextField), guides.first.titleAr);
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == guide.localizedTitle(ar)),
          findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no guide matches this');
      await tester.pumpAndSettle();
      expect(find.text(l.academyEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cravings fits and saves at 360 in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeCravings();
      final state = AppState(
        plannerRepository: FakePlanner(),
        cravingsRepository: repo,
        classifiedChecksRepository: FakeClassifiedChecks(),
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: Scaffold(body: CheatsScreen(state: state)),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(CheatsScreen)))!;
      expect(find.byTooltip(l.cravingPreviousMonth), findsOneWidget);
      expect(find.text(l.cravingUsed(0)), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Pizza');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l.cravingAdd));
      await tester.tap(find.text(l.cravingAdd));
      await tester.pumpAndSettle();
      expect(repo.current.single.notes, 'Pizza');
      expect(find.text(l.cravingUsed(1)), findsOneWidget);
      await tester.ensureVisible(find.text(l.cravingEdit));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.cravingEdit));
      await tester.pumpAndSettle();
      expect(find.text(l.cravingEditTitle), findsOneWidget);
      await tester
          .tap(find.textContaining(language == 'ar' ? 'التاريخ:' : 'Date:'));
      await tester.pumpAndSettle();
      expect(find.text('20'), findsWidgets);
      expect(find.text('٢٠'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.plannerCancel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
