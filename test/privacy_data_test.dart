import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/coach_preferences.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/language_settings.dart';
import 'package:privilege/screens/privacy_data.dart';
import 'package:privilege/screens/settings.dart';
import 'package:privilege/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    languageSettings.selected = const Locale('en');
  });

  Widget app(Widget home) => ListenableBuilder(
        listenable: languageSettings,
        builder: (_, __) => MaterialApp(
          locale: languageSettings.selected,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(),
          home: home,
        ),
      );

  testWidgets('Settings privacy row opens the privacy and data screen',
      (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: SettingsScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy & Data'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyDataScreen), findsOneWidget);
    expect(find.text('What we store'), findsOneWidget);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('privacy sections fit 360px in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      languageSettings.selected = Locale(language);
      await tester.pumpWidget(app(const PrivacyDataScreen()));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(PrivacyDataScreen));
      final l = AppLocalizations.of(context)!;
      for (final text in [
        l.privacyDataTitle,
        l.privacyStoreTitle,
        l.privacyCoachTitle,
        l.privacyChoicesTitle,
        l.privacyDeletionTitle,
        l.privacyCopyEmail,
      ]) {
        await tester.scrollUntilVisible(find.text(text), 200,
            scrollable: find.byType(Scrollable).first);
        expect(find.text(text), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('privacy consent uses the coach preference and copy works',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      coachConsentPreferenceKey: true,
    });
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(app(const PrivacyDataScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Share calorie information with the coach'), 200,
        scrollable: find.byType(Scrollable).first);
    final consent = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(consent.value, isTrue);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(coachConsentPreferenceKey), isFalse);

    await tester.ensureVisible(find.text('Copy email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy email'));
    await tester.pumpAndSettle();
    expect(copiedText, privacySupportEmail);
    expect(tester.takeException(), isNull);
  });
}
