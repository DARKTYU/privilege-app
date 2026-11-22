import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/coach_safety.dart';
import 'package:privilege/screens/chat.dart';
import 'package:privilege/services/coach_client.dart';
import 'package:privilege/coach_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:privilege/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _photoBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Z9ZQAAAAASUVORK5CYII=');

class FakeCoachImagePicker implements CoachImagePicker {
  CoachPhoto? photo;
  @override
  Future<CoachPhoto?> pick(ImageSource source) async => photo;
}

class FakeCoach implements CoachClient {
  @override
  String? accountId = 'user-1';
  final List<Map<String, Object>> requests = [];
  CoachException? error;
  Completer<CoachReply>? pending;
  CoachReply reply = const CoachReply('Hello from the coach', 29, null);

  @override
  Future<CoachReply> send(Map<String, Object> body) async {
    requests.add(body);
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return reply;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> start(WidgetTester tester, FakeCoach client,
      {AppState? state,
      Future<void> Function()? refresh,
      CoachImagePicker? imagePicker,
      Size size = const Size(800, 900),
      double scale = 1,
      String language = 'en'}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: ChatScreen(
            client: client,
            state: state,
            imagePicker: imagePicker,
            refreshActivity: refresh ?? () async {}),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, String message) async {
    await tester.enterText(find.byType(TextField), message);
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
  }

  testWidgets('photo attachment can be selected, shown and removed',
      (tester) async {
    final picker = FakeCoachImagePicker()
      ..photo = CoachPhoto(bytes: _photoBytes, mime: 'image/jpeg');
    await start(tester, FakeCoach(), imagePicker: picker);
    final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
    await tester.tap(find.byTooltip(l.coachAttachPhoto));
    await tester.pumpAndSettle();
    expect(find.text(l.coachTakePhoto), findsOneWidget);
    expect(find.text(l.coachChooseGallery), findsOneWidget);
    await tester.tap(find.text(l.coachChooseGallery));
    await tester.pumpAndSettle();
    expect(find.byTooltip(l.coachRemovePhoto), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    await tester.tap(find.byTooltip(l.coachRemovePhoto));
    await tester.pumpAndSettle();
    expect(find.byTooltip(l.coachRemovePhoto), findsNothing);
  });

  testWidgets('one failed send creates one error and clears typing',
      (tester) async {
    final client = FakeCoach()..error = const CoachException('unavailable');
    await start(tester, client);
    final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byTooltip(l.coachSend));
    await tester.tap(find.byTooltip(l.coachSend));
    await tester.pumpAndSettle();
    expect(client.requests, hasLength(1));
    expect(
        find.text(l.coachUnavailableHelp(l.coachUnavailable, l.coachLocalHelp)),
        findsOneWidget);
    expect(find.bySemanticsLabel(l.coachResponding), findsNothing);
  });

  testWidgets('photo-only send uses image body and notice is one time',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final picker = FakeCoachImagePicker()
      ..photo = CoachPhoto(bytes: _photoBytes, mime: 'image/png');
    final client = FakeCoach();
    final state = AppState()
      ..targetCalories = 2200
      ..loggedIn = true;
    addTearDown(state.dispose);
    await start(tester, client,
        state: state, imagePicker: picker, refresh: () async {});
    final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
    await tester.tap(find.byTooltip(l.coachAttachPhoto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.coachChooseGallery));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l.coachSend));
    await tester.pumpAndSettle();
    expect(find.text(l.coachPhotoNoticeTitle), findsOneWidget);
    await tester.tap(find.text(l.coachContinue));
    await tester.pumpAndSettle();
    final body = client.requests.single;
    expect(body['message'], '');
    expect(body['consent'], isFalse);
    expect(body['photo_consent'], isTrue);
    expect(body['app_language'], 'en');
    expect(body['image'], {
      'mime': 'image/png',
      'data':
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Z9ZQAAAAASUVORK5CYII=',
    });
    expect(find.byType(Image), findsWidgets);

    await tester.tap(find.byTooltip(l.coachAttachPhoto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.coachChooseGallery));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l.coachSend));
    await tester.pumpAndSettle();
    expect(find.text(l.coachPhotoNoticeTitle), findsNothing);
    expect(client.requests.length, 2);
  });

  for (final entry in <String, String Function(AppLocalizations)>{
    'image_too_large': (l) => l.coachPhotoTooLarge,
    'invalid_image': (l) => l.coachPhotoNotAllowed,
    'invalid_image_mime': (l) => l.coachPhotoNotAllowed,
    'invalid_image_data': (l) => l.coachPhotoNotAllowed,
    'multiple_images': (l) => l.coachPhotoNotAllowed,
    'photo_consent_required': (l) => l.coachPhotoConsentRequired,
    'image_consent_required': (l) => l.coachPhotoConsentRequired,
    'quota_exceeded': (l) => l.coachPhotoQuotaError,
  }.entries) {
    testWidgets('photo error ${entry.key} is localized', (tester) async {
      final picker = FakeCoachImagePicker()
        ..photo = CoachPhoto(bytes: _photoBytes, mime: 'image/jpeg');
      SharedPreferences.setMockInitialValues({
        coachPhotoNoticePreferenceKey: true,
      });
      final client = FakeCoach()..error = CoachException(entry.key);
      final state = AppState()
        ..targetCalories = 2200
        ..loggedIn = true;
      addTearDown(state.dispose);
      await start(tester, client,
          state: state, imagePicker: picker, refresh: () async {});
      final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
      await tester.tap(find.byTooltip(l.coachAttachPhoto));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.coachChooseGallery));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l.coachSend));
      await tester.pumpAndSettle();
      expect(find.text(entry.value(l)), findsOneWidget);
    });
  }

  testWidgets('chat input loses focus when the app pauses', (tester) async {
    final client = FakeCoach();
    await start(tester, client);
    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    final focus = FocusManager.instance.primaryFocus;
    expect(focus?.hasFocus, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(focus?.hasFocus, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });

  test('chat has no hardcoded UI strings or Arabic', () {
    final source = File('lib/screens/chat.dart').readAsStringSync();
    final labels = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|(?:label|tooltip|hintText)\s*:\s*|fieldDecoration\(\s*)['"]""");
    final matches = labels.allMatches(source).map((m) => m.group(0)).toList();
    expect(matches, ['Text(\'']);
    expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
  });

  for (final language in ['en', 'ar']) {
    for (final index in [0, 1, 2, 3]) {
      testWidgets('suggestion $index sends in $language', (tester) async {
        final client = FakeCoach();
        await start(tester, client,
            language: language, size: const Size(360, 640));
        final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
        final question = [
          l.coachTraining,
          l.coachProteinRecipe,
          l.coachCaloriesLeft,
          l.coachSnacks
        ][index];
        await tester.ensureVisible(find.text(question));
        await tester.tap(find.text(question));
        await tester.pumpAndSettle();
        expect(client.requests.single['message'], question);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('localized chat controls and suggestions at 360 in $language',
        (tester) async {
      final client = FakeCoach();
      await start(tester, client,
          language: language, size: const Size(360, 640));
      final context = tester.element(find.byType(ChatScreen));
      final l = AppLocalizations.of(context)!;
      expect(find.text(l.coachTitle), findsOneWidget);
      expect(find.text(l.coachWelcome), findsOneWidget);
      expect(find.text(l.coachConsent), findsOneWidget);
      expect(find.byTooltip(l.coachNewChat), findsOneWidget);
      expect(find.byTooltip(l.coachClose), findsOneWidget);
      expect(find.byTooltip(l.coachSend), findsOneWidget);
      expect(find.text(l.coachAiBadge), findsOneWidget);
      await tester.tap(find.text(l.coachInfo));
      await tester.pumpAndSettle();
      expect(find.text(l.coachAbout), findsOneWidget);
      for (final text in [
        l.coachNoticeMistakes,
        l.coachNoticeMedical,
        l.coachNoticeCloud,
        l.coachNoticePrivacy,
        l.coachNoticeMemory
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      await tester.tap(find.text(l.coachGotIt));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l.coachTraining));
      await tester.tap(find.text(l.coachTraining));
      await tester.pumpAndSettle();
      expect(client.requests.single['message'], l.coachTraining);
      expect(find.text(l.coachRequestsLeft(29)), findsOneWidget);
      expect(find.text(l.coachWelcome), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('localized failures and retry in $language', (tester) async {
      final client = FakeCoach()..error = const CoachException('unavailable');
      await start(tester, client,
          language: language, size: const Size(360, 640));
      final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.byTooltip(l.coachSend));
      await tester.pumpAndSettle();
      expect(
          find.text(
              l.coachUnavailableHelp(l.coachUnavailable, l.coachLocalHelp)),
          findsOneWidget);
      expect(find.text(l.coachTryAgain), findsOneWidget);
      client.error = null;
      await tester.tap(find.text(l.coachTryAgain));
      await tester.pumpAndSettle();
      expect(client.requests.map((request) => request['message']),
          ['Hello', 'Hello']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing locale updates local errors without changing history',
      (tester) async {
    final client = FakeCoach()..error = const CoachException('unavailable');
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(locale.dispose);
    await tester.pumpWidget(ValueListenableBuilder<Locale>(
      valueListenable: locale,
      builder: (context, value, _) => MaterialApp(
        locale: value,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChatScreen(client: client, refreshActivity: () async {}),
      ),
    ));
    await tester.pumpAndSettle();
    await send(tester, 'Hello');
    expect(find.text('Try again'), findsOneWidget);
    locale.value = const Locale('ar');
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
    expect(find.text(l.coachTryAgain), findsOneWidget);
    expect(
        find.text(l.coachUnavailableHelp(l.coachUnavailable, l.coachLocalHelp)),
        findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(client.requests, hasLength(1));
  });

  for (final code in [
    'authentication_required',
    'registered_user_required',
    'birth_date_required',
    'underage',
    'quota_exceeded'
  ]) {
    testWidgets('Arabic error $code has no retry and western digits',
        (tester) async {
      final client = FakeCoach()
        ..error = CoachException(code, resetAt: DateTime.utc(2026, 11, 21));
      await start(tester, client, language: 'ar', size: const Size(360, 640));
      final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.byTooltip(l.coachSend));
      await tester.pumpAndSettle();
      final expected = switch (code) {
        'authentication_required' ||
        'registered_user_required' =>
          l.coachSignInError,
        'birth_date_required' => l.coachBirthDateError,
        'underage' => l.coachAgeError,
        _ => l.coachQuotaError,
      };
      expect(find.textContaining(expected), findsOneWidget);
      expect(find.text(l.coachTryAgain), findsNothing);
      final bubble = tester.widget<SelectableText>(find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText &&
              (widget.data?.contains(expected) ?? false)));
      expect(bubble.data,
          isNot(contains(RegExp(r'[\u0660-\u0669\u06f0-\u06f9]'))));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Arabic emergency reply is immediate in English app',
      (tester) async {
    final client = FakeCoach();
    await start(tester, client, language: 'en');
    await tester.enterText(find.byType(TextField), 'مش قادرة أتنفس');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(find.text(coachEmergencyReply('مش قادرة أتنفس')!), findsOneWidget);
    expect(client.requests, isEmpty);
  });

  testWidgets(
      'coach avatars contain the logo at header, welcome and bubble sizes',
      (tester) async {
    final client = FakeCoach();
    await start(tester, client, scale: 1.5);
    final avatars = find.byWidgetPredicate((widget) =>
        widget is Semantics && widget.properties.label == 'Privilege Coach');
    expect(avatars, findsNWidgets(2));
    expect(tester.getSize(avatars.at(0)), const Size(44, 44));
    expect(tester.getSize(avatars.at(1)), const Size(88, 88));
    for (final avatar in [avatars.at(0), avatars.at(1)]) {
      final image = tester.widget<Image>(
          find.descendant(of: avatar, matching: find.byType(Image)));
      expect(image.fit, BoxFit.contain);
      expect(image.filterQuality, FilterQuality.high);
      final container = tester.widget<Container>(
          find.descendant(of: avatar, matching: find.byType(Container)).first);
      final size = tester.getSize(avatar).width;
      expect(container.padding, EdgeInsets.all(size * 0.15));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.border, isNotNull);
    }
    expect(tester.takeException(), isNull);
    await send(tester, 'Hello');
    expect(avatars, findsNWidgets(2));
    expect(tester.getSize(avatars.at(0)), const Size(44, 44));
    expect(tester.getSize(avatars.at(1)), const Size(32, 32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('consent off sends no context, new chat clears history',
      (tester) async {
    final client = FakeCoach();
    await start(tester, client);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);
    await send(tester, 'Hello');
    expect(client.requests.single,
        {'message': 'Hello', 'consent': false, 'app_language': 'en'});
    expect(find.text('Hello from the coach'), findsOneWidget);
    expect(find.text('Requests left today: 29'), findsOneWidget);
    await tester.tap(find.byTooltip('New chat'));
    await tester.pump();
    expect(find.text('Hello from the coach'), findsNothing);
    expect(find.textContaining('Requests left today:'), findsNothing);
  });

  testWidgets('info row opens localized notice and both dismissals work',
      (tester) async {
    await start(tester, FakeCoach());
    expect(find.textContaining('The coach can make mistakes'), findsNothing);
    await tester.tap(find.textContaining('AI can make mistakes'));
    await tester.pumpAndSettle();
    expect(find.text('About the coach'), findsOneWidget);
    final dialog = find.byType(AlertDialog);
    expect(
        find.descendant(
            of: dialog,
            matching: find.byWidgetPredicate((widget) =>
                widget is Semantics &&
                widget.properties.label == 'Privilege Coach')),
        findsOneWidget);
    for (final (icon, english, arabic) in [
      (
        Icons.warning_amber_rounded,
        'The coach can make mistakes.',
        'المدرب قد يخطئ.'
      ),
      (
        Icons.medical_services_outlined,
        'Not medical advice. For health problems, ask a doctor.',
        'ليست نصيحة طبية. للمشاكل الصحية استشر طبيباً.'
      ),
      (
        Icons.cloud_outlined,
        'Messages are sent to Google Gemini to get a reply.',
        'تُرسل رسائلك إلى Google Gemini للحصول على رد.'
      ),
      (
        Icons.lock_outline,
        'Do not share personal or health details you do not want sent.',
        'لا تشارك تفاصيل شخصية أو صحية لا تريد إرسالها.'
      ),
      (
        Icons.memory,
        'The coach does not remember earlier messages.',
        'المدرب لا يتذكر الرسائل السابقة.'
      ),
    ]) {
      expect(find.descendant(of: dialog, matching: find.byIcon(icon)),
          findsOneWidget);
      expect(find.text(english), findsOneWidget);
      expect(find.text(arabic), findsNothing);
    }
    final button = find.widgetWithText(ElevatedButton, 'Got it');
    expect(tester.getSize(button).width, greaterThan(200));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    await tester.tap(find.textContaining('AI can make mistakes'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
  });

  testWidgets('notice is scrollable and dismissible on small screens',
      (tester) async {
    await start(tester, FakeCoach(), size: const Size(360, 640), scale: 1.5);
    await tester.tap(find.textContaining('AI can make mistakes'));
    await tester.pumpAndSettle();
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
    final last = find.text('The coach does not remember earlier messages.');
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(last.hitTestable(), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bot opens a dismissible keyboard-aware sheet over the screen',
      (tester) async {
    final client = FakeCoach();
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: const Text('Previous screen'),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton(
            tooltip: 'AI Privilege Bot',
            onPressed: () => showCoachSheet(context,
                client: client, refreshActivity: () async {}),
            child: const Icon(Icons.smart_toy_rounded),
          );
        }),
      ),
    ));
    await tester.tap(find.byTooltip('AI Privilege Bot'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Previous screen', skipOffstage: false), findsOneWidget);
    expect(find.text('Privilege Coach'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    final height = tester.getSize(find.byType(ChatScreen)).height;
    expect(height, closeTo(tester.view.physicalSize.height * .92, 1));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.byType(TextField)).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height - 260));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsNothing);
    expect(find.text('Previous screen'), findsOneWidget);
    await tester.tap(find.byTooltip('AI Privilege Bot'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ChatScreen), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsNothing);
  });

  testWidgets('sheet fits a small screen with large text and keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final client = FakeCoach();
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: Scaffold(body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showCoachSheet(context,
              client: client, refreshActivity: () async {}),
          child: const Text('Open'),
        );
      })),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.byType(TextField)).dy,
        lessThanOrEqualTo(380));
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(client.requests.single['message'], 'Hello');
    expect(tester.takeException(), isNull);
  });

  for (final suggestion in [
    'Training ideas',
    'High-protein recipe',
    'Calories left?',
    'Snack ideas',
  ]) {
    testWidgets('welcome card sends $suggestion', (tester) async {
      final client = FakeCoach();
      await start(tester, client);
      expect(find.textContaining('How can I help today?'), findsOneWidget);
      await tester.ensureVisible(find.text(suggestion));
      await tester.tap(find.text(suggestion));
      await tester.pumpAndSettle();
      expect(client.requests.single['message'], suggestion);
      expect(find.textContaining('How can I help today?'), findsNothing);
      expect(find.byType(ActionChip), findsWidgets);
      await tester.tap(find.byTooltip('New chat'));
      await tester.pumpAndSettle();
      expect(find.textContaining('How can I help today?'), findsOneWidget);
    });
  }

  for (final language in ['en', 'ar']) {
    testWidgets('coach avatar stays top-aligned for long reply in $language',
        (tester) async {
      final client = FakeCoach()
        ..reply = CoachReply(
            List.filled(20, 'A long coach reply line.').join('\n'), 29, null);
      await start(tester, client,
          language: language, size: const Size(360, 640));
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
      await tester.tap(find.byTooltip(l.coachSend));
      await tester.pumpAndSettle();
      final row = tester.widget<Row>(find
          .ancestor(
              of: find.textContaining('A long coach reply line.'),
              matching: find.byWidgetPredicate((widget) =>
                  widget is Row && widget.mainAxisSize == MainAxisSize.min))
          .first);
      expect(row.crossAxisAlignment, CrossAxisAlignment.start);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('coach bold spans are selectable and lists stay readable',
      (tester) async {
    final client = FakeCoach()
      ..reply = const CoachReply(
          '**Plan**\n1. Warm up\n2. **Train** safely\n**unfinished', 25, null);
    await start(tester, client);
    await send(tester, 'Hi');
    final finder = find.byWidgetPredicate((widget) =>
        widget is SelectableText &&
        widget.textSpan?.toPlainText() ==
            'Plan\n1. Warm up\n2. Train safely\nunfinished');
    expect(finder, findsOneWidget);
    final text = tester.widget<SelectableText>(finder);
    expect(text.textDirection, TextDirection.ltr);
    final spans = text.textSpan!.children!.cast<TextSpan>();
    expect(spans.firstWhere((span) => span.text == 'Plan').style!.fontWeight,
        FontWeight.bold);
    expect(spans.firstWhere((span) => span.text == 'Train').style!.fontWeight,
        FontWeight.bold);
    expect(find.text('Requests left today: 25'), findsOneWidget);
  });

  testWidgets('Arabic bold reply stays selectable and right-to-left',
      (tester) async {
    final client = FakeCoach()
      ..reply = const CoachReply('**تمرين**\n1. ابدأ بهدوء', null, null);
    await start(tester, client);
    await send(tester, 'مرحبا');
    final finder = find.byWidgetPredicate((widget) =>
        widget is SelectableText &&
        widget.textSpan?.toPlainText() == 'تمرين\n1. ابدأ بهدوء');
    expect(finder, findsOneWidget);
    final text = tester.widget<SelectableText>(finder);
    expect(text.textDirection, TextDirection.rtl);
    expect(
        text.textSpan!.children!
            .cast<TextSpan>()
            .firstWhere((span) => span.text == 'تمرين')
            .style!
            .fontWeight,
        FontWeight.bold);
  });

  testWidgets('consent persists and sends exactly three numeric values',
      (tester) async {
    final client = FakeCoach();
    final state = AppState()
      ..targetCalories = 2200
      ..loggedIn = true;
    addTearDown(state.dispose);
    await start(tester, client, state: state);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await send(tester, 'Hello');
    expect(client.requests.single, {
      'message': 'Hello',
      'consent': true,
      'app_language': 'en',
      'context': {
        'calorie_target': 2200,
        'calories_consumed': 0,
        'calories_burned': 0
      },
    });
    await tester.pumpWidget(const SizedBox());
    await start(tester, client, state: state);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue);
  });

  testWidgets('consented context uses refreshed today totals', (tester) async {
    final client = FakeCoach();
    final state = AppState()
      ..targetCalories = 2200
      ..loggedIn = true;
    addTearDown(state.dispose);
    await start(tester, client, state: state, refresh: () async {
      state.meals.add(const MealItem(
          id: 'm',
          name: 'Meal',
          time: '',
          calories: 410,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          fiberGrams: 0,
          icon: '',
          consumed: true,
          category: MealCategory.lunch));
      state.burns.add(const BurnItem(
          id: 'b',
          title: 'Run',
          time: '',
          calories: 120,
          type: BurnType.cardio,
          durationMin: 20,
          icon: ''));
    });
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await send(tester, 'Hi');
    expect(client.requests.single['context'], {
      'calorie_target': 2200,
      'calories_consumed': 410,
      'calories_burned': 120
    });
  });

  testWidgets('activity refresh failure does not send stale context',
      (tester) async {
    final client = FakeCoach();
    final state = AppState()
      ..targetCalories = 2200
      ..loggedIn = true;
    addTearDown(state.dispose);
    await start(tester, client, state: state, refresh: () async {
      state.activityError = 'offline';
    });
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await send(tester, 'Hi');
    expect(client.requests, isEmpty);
    expect(find.textContaining('The coach is unavailable right now'),
        findsOneWidget);
  });

  testWidgets('provider error restores photo and text for resend',
      (tester) async {
    final picker = FakeCoachImagePicker()
      ..photo = CoachPhoto(bytes: _photoBytes, mime: 'image/jpeg');
    final client = FakeCoach()
      ..error = const CoachException('provider_unavailable');
    SharedPreferences.setMockInitialValues({
      coachPhotoNoticePreferenceKey: true,
    });
    await start(tester, client, imagePicker: picker);
    final l = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
    await tester.enterText(find.byType(TextField), 'What is this?');
    await tester.tap(find.byTooltip(l.coachAttachPhoto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.coachChooseGallery));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l.coachSend));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'What is this?');
    expect(find.byTooltip(l.coachRemovePhoto), findsOneWidget);
    expect(find.text(l.coachBusy), findsOneWidget);
  });

  for (final entry in {
    'authentication_required': 'Sign in with an account to use the coach',
    'registered_user_required': 'Sign in with an account to use the coach',
    'birth_date_required': 'Add your birth date in Profile',
    'underage': 'The AI coach is for users 18 and over',
    'quota_exceeded': 'Daily limit reached',
    'provider_unavailable':
        'The coach is busy right now. Please try again in a moment.',
  }.entries) {
    testWidgets('shows ${entry.key} without pretending success',
        (tester) async {
      final client = FakeCoach()
        ..error =
            CoachException(entry.key, resetAt: DateTime.utc(2026, 11, 21));
      await start(tester, client);
      await send(tester, 'Hi');
      expect(find.textContaining(entry.value), findsOneWidget);
      if (entry.key != 'provider_unavailable') {
        expect(find.text('Try again'), findsNothing);
      }
      if (entry.key == 'quota_exceeded') {
        expect(find.textContaining('Resets:'), findsOneWidget);
      }
      if (entry.key == 'provider_unavailable') {
        expect(find.textContaining('not AI'), findsNothing);
      }
    });
  }

  testWidgets('retry resends the failed message once per tap', (tester) async {
    final client = FakeCoach()..error = const CoachException('unavailable');
    await start(tester, client);
    await send(tester, 'My question');
    expect(find.text('Try again'), findsOneWidget);
    client.error = null;
    client.pending = Completer<CoachReply>();
    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(client.requests.length, 2);
    expect(client.requests.last['message'], 'My question');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Draft');
    final retry =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Try again'));
    expect(retry.onPressed, isNull);
    client.pending!.complete(const CoachReply('Recovered', 10, null));
    await tester.pumpAndSettle();
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('emergency replies are local in English and Egyptian Arabic',
      (tester) async {
    final client = FakeCoach();
    await start(tester, client);
    await send(tester, 'I have chest pain');
    expect(find.textContaining('local emergency services'), findsOneWidget);
    await send(tester, 'مش قادرة أتنفس');
    expect(find.textContaining('الطوارئ المحلية'), findsOneWidget);
    expect(client.requests, isEmpty);
    final arabic = tester.widget<SelectableText>(find.widgetWithText(
        SelectableText, coachEmergencyReply('مش قادرة أتنفس')!));
    expect(arabic.textDirection, TextDirection.rtl);
  });

  testWidgets('one request at a time and loading visible', (tester) async {
    final client = FakeCoach()..pending = Completer<CoachReply>();
    await start(tester, client);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(find.text('•••'), findsOneWidget);
    expect(find.bySemanticsLabel('Coach is responding…'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Another');
    await tester.pump();
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.send_rounded))
            .onPressed,
        isNull);
    expect(client.requests.length, 1);
    client.pending!.complete(const CoachReply('Done', null, null));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.send_rounded))
            .onPressed,
        isNotNull);
  });

  testWidgets('enforces a 2000 code-point limit', (tester) async {
    final client = FakeCoach();
    await start(tester, client);
    await tester.enterText(find.byType(TextField), 'a' * 2000);
    await tester.pump();
    expect(find.text('2000/2000'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a' * 2001);
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .controller!
            .text
            .length,
        2000);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect((client.requests.single['message'] as String).length, 2000);
  });

  testWidgets('new chat ignores an in-flight reply', (tester) async {
    final client = FakeCoach()..pending = Completer<CoachReply>();
    await start(tester, client);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.tap(find.byTooltip('New chat'));
    client.pending!.complete(const CoachReply('Old reply', 1, null));
    await tester.pumpAndSettle();
    expect(find.text('Old reply'), findsNothing);
  });

  testWidgets('layout fits small screen at large text scale', (tester) async {
    final client = FakeCoach();
    await start(tester, client, size: const Size(360, 640), scale: 1.5);
    expect(tester.takeException(), isNull);
    await send(tester, 'Hello');
    expect(tester.takeException(), isNull);
  });
}
