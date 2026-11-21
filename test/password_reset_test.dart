import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/screens/login.dart';
import 'package:privilege/screens/password_reset.dart';
import 'package:privilege/services/account_types.dart';
import 'package:privilege/ui.dart';

class _FakeResetService implements PasswordResetService {
  bool wrongCode = false;
  bool networkError = false;
  bool requested = false;
  bool completed = false;

  @override
  Future<void> requestCode(String email) async {
    requested = true;
    if (networkError) throw AuthException('network', 'unused');
  }

  @override
  Future<void> resetPassword(String email, String code, String password) async {
    if (wrongCode) {
      throw AuthException('invalid_code', 'unused');
    }
    completed = true;
  }
}

Widget _app(Widget home, String language) => MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(),
      home: home,
    );

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('reset request shows localized no-internet error in $language',
        (tester) async {
      final service = _FakeResetService()..networkError = true;
      await tester.pumpWidget(_app(
          PasswordResetScreen(service: service), language));
      final l = AppLocalizations.of(
          tester.element(find.byType(PasswordResetScreen)))!;
      await tester.enterText(
          find.byType(TextField).first, 'person@example.com');
      await tester.tap(find.text(l.resetSendCode));
      await tester.pumpAndSettle();
      expect(find.text(l.networkError), findsOneWidget);
      expect(find.text(l.resetNeutralMessage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('password reset flow fits 360px in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _FakeResetService();
      await tester.pumpWidget(
          _app(LoginScreen(passwordResetService: service), language));
      final l = AppLocalizations.of(tester.element(find.byType(LoginScreen)))!;
      await tester.tap(find.text(l.forgotPassword));
      await tester.pumpAndSettle();
      expect(find.byType(PasswordResetScreen), findsOneWidget);

      await tester.enterText(
          find.byType(TextField).first, 'person@example.com');
      await tester.tap(find.text(l.resetSendCode));
      await tester.pumpAndSettle();
      expect(service.requested, isTrue);
      expect(find.text(l.resetNeutralMessage), findsOneWidget);
      expect(find.text(l.resetResendCountdown(60)), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField).at(1), '12345');
      await tester.enterText(find.byType(TextField).at(2), 'Password1');
      await tester.enterText(find.byType(TextField).at(3), 'Otherpass1');
      expect(find.text(l.resetCodeFormatError), findsOneWidget);
      expect(find.text(l.passwordMismatch), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.widgetWithText(
          ElevatedButton, l.resetUpdatePassword)).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(1), '12a456');
      await tester.pump();
      expect(find.text(l.resetCodeFormatError), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField).at(1),
          language == 'en' ? '12345678' : '123456');
      await tester.enterText(find.byType(TextField).at(3), 'Password1');
      await tester.pumpAndSettle();
      final updateButton = tester.widget<ElevatedButton>(find.widgetWithText(
          ElevatedButton, l.resetUpdatePassword));
      expect(updateButton.onPressed, isNotNull);
      service.wrongCode = true;
      await tester.ensureVisible(find.text(l.resetUpdatePassword));
      await tester.tap(find.text(l.resetUpdatePassword));
      await tester.pumpAndSettle();
      expect(find.text(l.resetInvalidCode), findsOneWidget);

      service.wrongCode = false;
      await tester.ensureVisible(find.text(l.resetUpdatePassword));
      await tester.tap(find.text(l.resetUpdatePassword));
      await tester.pumpAndSettle();
      expect(service.completed, isTrue);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(l.resetSuccess), findsOneWidget);
      expect(find.text(l.enterPassword), findsNothing);
      expect(
          tester.widget<TextField>(find.byType(TextField).first).controller!.text,
          'person@example.com');
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
