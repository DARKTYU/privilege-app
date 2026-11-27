import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/coach_preferences.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/language_settings.dart';
import 'package:privilege/screens/privacy_data.dart';
import 'package:privilege/screens/settings.dart';
import 'package:privilege/services/account_types.dart';
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

  // Opens the privacy screen on top of a home page so closing it can be checked.
  Future<void> openPrivacy(WidgetTester tester, DeleteAccountAction action,
      {bool? requiresPassword}) async {
    await tester.pumpWidget(app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => PrivacyDataScreen(
                  deleteAccount: action, requiresPassword: requiresPassword))),
          child: const Text('open privacy'),
        ),
      ),
    )));
    await tester.tap(find.text('open privacy'));
    await tester.pumpAndSettle();
  }

  Future<void> openDeleteDialog(WidgetTester tester) async {
    final l = AppLocalizations.of(tester.element(find.byType(PrivacyDataScreen)))!;
    await tester.scrollUntilVisible(find.text(l.privacyDeleteButton), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text(l.privacyDeleteButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.privacyDeleteButton));
    await tester.pumpAndSettle();
  }

  testWidgets('delete account needs a password and Cancel keeps the account',
      (tester) async {
    var calls = 0;
    await openPrivacy(tester, (_) async => calls++);
    await openDeleteDialog(tester);
    expect(find.text('Delete your account permanently?'), findsOneWidget);

    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(calls, 0);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account permanently?'), findsNothing);
    expect(find.byType(PrivacyDataScreen), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('accounts without a password confirm by typing DELETE',
      (tester) async {
    String? sent;
    await openPrivacy(tester, (password) async => sent = password,
        requiresPassword: false);
    await openDeleteDialog(tester);
    expect(find.text('Type DELETE to confirm'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'delete me');
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
    expect(find.text('Type the word DELETE exactly.'), findsOneWidget);
    expect(sent, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
    expect(sent, '');
    expect(find.byType(PrivacyDataScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong password keeps the dialog open with a message',
      (tester) async {
    String? sent;
    await openPrivacy(tester, (password) async {
      sent = password;
      throw AuthException('invalid_credentials', 'That password is not correct.');
    });
    await openDeleteDialog(tester);
    await tester.enterText(find.byType(TextField), 'wrong-pass-1');
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
    expect(sent, 'wrong-pass-1');
    expect(find.text('That password is not correct.'), findsOneWidget);
    expect(find.text('Delete your account permanently?'), findsOneWidget);
    expect(find.byType(PrivacyDataScreen), findsOneWidget);
  });

  testWidgets('an unexpected failure shows the generic delete error',
      (tester) async {
    await openPrivacy(tester, (_) async => throw StateError('boom'));
    await openDeleteDialog(tester);
    await tester.enterText(find.byType(TextField), 'some-password-1');
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Your account could not be deleted. Please check your connection and try again.'),
        findsOneWidget);
    expect(find.text('Delete forever'), findsOneWidget);
  });

  testWidgets('a successful deletion closes the dialog and the privacy screen',
      (tester) async {
    String? sent;
    await openPrivacy(tester, (password) async => sent = password);
    await openDeleteDialog(tester);
    await tester.enterText(find.byType(TextField), 'right-pass-1');
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
    expect(sent, 'right-pass-1');
    expect(find.text('Delete your account permanently?'), findsNothing);
    expect(find.byType(PrivacyDataScreen), findsNothing);
    expect(find.text('open privacy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('delete dialog fits 360px in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      languageSettings.selected = Locale(language);
      await openPrivacy(tester, (_) async {});
      await openDeleteDialog(tester);
      final l = AppLocalizations.of(
          tester.element(find.byType(PrivacyDataScreen)))!;
      expect(find.text(l.privacyDeleteDialogTitle), findsOneWidget);
      expect(find.text(l.privacyDeleteDialogBody), findsOneWidget);
      expect(find.text(l.privacyDeleteConfirm), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
