import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/coach_safety.dart';
import 'package:privilege/screens/chat.dart';
import 'package:privilege/services/coach_client.dart';
import 'package:privilege/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      Size size = const Size(800, 900),
      double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: ChatScreen(
            client: client,
            state: state,
            refreshActivity: refresh ?? () async {}),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, String message) async {
    await tester.enterText(find.byType(TextField), message);
    await tester.pump();
    await tester.tap(find.byTooltip('Send / إرسال'));
    await tester.pumpAndSettle();
  }

  testWidgets('consent off sends no context, new chat clears history',
      (tester) async {
    final client = FakeCoach();
    await start(tester, client);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);
    await send(tester, 'Hello');
    expect(client.requests.single, {'message': 'Hello', 'consent': false});
    expect(find.text('Hello from the coach'), findsOneWidget);
    expect(find.text('Requests left today: 29\nالمتبقي اليوم: 29'),
        findsOneWidget);
    await tester.tap(find.byTooltip('New chat / محادثة جديدة'));
    await tester.pump();
    expect(find.text('Hello from the coach'), findsNothing);
    expect(find.textContaining('Requests left today:'), findsNothing);
  });

  testWidgets('notice has separate aligned English and Arabic paragraphs',
      (tester) async {
    await start(tester, FakeCoach());
    final english = tester.widget<SelectableText>(find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            (widget.data?.startsWith('The coach can make mistakes') ?? false)));
    final arabic = tester.widget<SelectableText>(find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            (widget.data?.startsWith('قد يخطئ المدرب') ?? false)));
    expect(english.textDirection, TextDirection.ltr);
    expect(english.textAlign, TextAlign.left);
    expect(arabic.textDirection, TextDirection.rtl);
    expect(arabic.textAlign, TextAlign.right);
  });

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
    expect(find.text('Requests left today: 25\nالمتبقي اليوم: 25'),
        findsOneWidget);
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

  for (final entry in {
    'authentication_required': 'Sign in with an account to use the coach',
    'registered_user_required': 'Sign in with an account to use the coach',
    'birth_date_required': 'Add your birth date in Profile',
    'underage': 'The AI coach is for users 18 and over',
    'quota_exceeded': 'Daily limit reached',
    'provider_unavailable': 'The coach is unavailable right now',
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
        expect(find.text('Try again / حاول مرة أخرى'), findsNothing);
      }
      if (entry.key == 'quota_exceeded') {
        expect(find.textContaining('Resets:'), findsOneWidget);
      }
      if (entry.key == 'provider_unavailable') {
        expect(find.textContaining('not AI'), findsOneWidget);
      }
    });
  }

  testWidgets('retry resends the failed message once per tap', (tester) async {
    final client = FakeCoach()..error = const CoachException('unavailable');
    await start(tester, client);
    await send(tester, 'My question');
    expect(find.text('Try again / حاول مرة أخرى'), findsOneWidget);
    client.error = null;
    client.pending = Completer<CoachReply>();
    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.tap(find.text('Try again / حاول مرة أخرى'));
    await tester.pump();
    expect(client.requests.length, 2);
    expect(client.requests.last['message'], 'My question');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Draft');
    final retry = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Try again / حاول مرة أخرى'));
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
    await tester.tap(find.byTooltip('Send / إرسال'));
    await tester.pump();
    expect(find.textContaining('Coach is responding'), findsOneWidget);
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
    await tester.tap(find.byTooltip('Send / إرسال'));
    await tester.pumpAndSettle();
    expect((client.requests.single['message'] as String).length, 2000);
  });

  testWidgets('new chat ignores an in-flight reply', (tester) async {
    final client = FakeCoach()..pending = Completer<CoachReply>();
    await start(tester, client);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send / إرسال'));
    await tester.pump();
    await tester.tap(find.byTooltip('New chat / محادثة جديدة'));
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
