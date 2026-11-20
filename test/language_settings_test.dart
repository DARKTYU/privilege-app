import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/language_settings.dart';
import 'package:privilege/main.dart';
import 'package:privilege/screens/home_shell.dart';
import 'package:privilege/screens/login.dart';
import 'package:privilege/screens/onboarding.dart';
import 'package:privilege/screens/settings.dart';
import 'package:privilege/screens/splits.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'planner_fake.dart';
import 'progression_fake.dart';

void main() {
  setUpAll(() async => FoodDatabase().load());
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    languageSettings.selected = const Locale('en');
  });
  tearDown(() => languageSettings.selected = const Locale('en'));

  Widget app(Widget child) => ListenableBuilder(
        listenable: languageSettings,
        builder: (_, __) => MaterialApp(
          locale: languageSettings.selected,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildTheme(),
          home: child,
        ),
      );

  test(
      'choice persists, restores, and unsupported saved values default to English',
      () async {
    final settings = LanguageSettings();
    await settings.restore();
    expect(settings.selected, const Locale('en'));
    await settings.select('ar');
    final restored = LanguageSettings();
    await restored.restore();
    expect(restored.selected, const Locale('ar'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('privilege_language'), 'ar');
    await prefs.setString('privilege_language', 'invalid');
    await restored.restore();
    expect(restored.selected, const Locale('en'));
    await expectLater(restored.select('invalid'), throwsArgumentError);
  });

  testWidgets('Settings chooser immediately switches and persists locale',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const Scaffold(body: SettingsScreen())));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية').last);
    await tester.pumpAndSettle();
    expect(languageSettings.selected, const Locale('ar'));
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.rtl);
    expect(
        MaterialLocalizations.of(tester.element(find.byType(SettingsScreen)))
            .formatDecimal(123),
        '123');
    expect(
        (await SharedPreferences.getInstance()).getString('privilege_language'),
        'ar');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('اللغة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.ltr);
  });

  testWidgets('navigation updates in Arabic without losing the selected tab',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState(plannerRepository: FakePlanner());
    addTearDown(state.dispose);
    await tester.pumpWidget(app(HomeShell(
        alertBell: const SizedBox(height: 32),
        progressionRepository: FakeProgression(),
        plannerState: state)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Splits'));
    await tester.pumpAndSettle();
    expect(find.byType(SplitsScreen), findsOneWidget);
    await languageSettings.select('ar');
    await tester.pumpAndSettle();
    for (final label in ['الرئيسية', 'التمارين', 'السعرات', 'الملف الشخصي']) {
      expect(find.text(label), findsWidgets);
    }
    expect(Directionality.of(tester.element(find.byType(HomeShell))),
        TextDirection.rtl);
    expect(find.byType(SplitsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PrivilegeApp applies the locale without resetting login input',
      (tester) async {
    final restoring = appState.restoring;
    final loggedIn = appState.loggedIn;
    appState.restoring = false;
    appState.loggedIn = false;
    addTearDown(() {
      appState.restoring = restoring;
      appState.loggedIn = loggedIn;
    });
    await tester.pumpWidget(const PrivilegeApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'person@example.com');
    await languageSettings.select('ar');
    await tester.pumpAndSettle();
    expect(find.text('مرحباً بعودتك'), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'person@example.com');
    expect(Directionality.of(tester.element(find.byType(LoginScreen))),
        TextDirection.rtl);
  });

  for (final screen in <Widget>[
    const LoginScreen(),
    const OnboardingScreen(),
    const Scaffold(body: SettingsScreen())
  ]) {
    testWidgets('${screen.runtimeType} builds at 360px in Arabic',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      languageSettings.selected = const Locale('ar');
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (screen is LoginScreen) {
        await tester.tap(find.text('تسجيل الدخول'));
        await tester.pump();
        expect(find.text('أدخل بريداً إلكترونياً صالحاً.'), findsOneWidget);
      }
      if (screen is OnboardingScreen) {
        await tester.ensureVisible(find.text('إكمال الإعداد والدخول'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('إكمال الإعداد والدخول'));
        await tester.pump();
        expect(find.textContaining('اسم المستخدم من 3 إلى 20'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
