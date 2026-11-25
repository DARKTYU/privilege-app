import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/main.dart';
import 'package:privilege/state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    appState.restoring = false;
    appState.loggedIn = false;
    appState.onboardingDone = false;
  });

  tearDown(() {
    appState.restoring = false;
    appState.loggedIn = false;
    appState.onboardingDone = false;
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  late WidgetTester tester;

  testWidgets('cold-start intro routes signed-out users to login',
      (widgetTester) async {
    tester = widgetTester;
    await tester.pumpWidget(PrivilegeApp(
      loginBuilder: (_) => const SizedBox(key: ValueKey('fake-login')),
      homeBuilder: (_) => const SizedBox(key: ValueKey('fake-home')),
    ));
    expect(find.byKey(const ValueKey('intro')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1799));
    expect(find.byKey(const ValueKey('fake-login')), findsNothing);
    await tester.pump(const Duration(milliseconds: 301));
    expect(find.byKey(const ValueKey('fake-login')), findsOneWidget);
  });

  testWidgets('cold-start intro routes signed-in users to home',
      (widgetTester) async {
    tester = widgetTester;
    appState.loggedIn = true;
    appState.onboardingDone = true;
    await tester.pumpWidget(PrivilegeApp(
      loginBuilder: (_) => const SizedBox(key: ValueKey('fake-login')),
      homeBuilder: (_) => const SizedBox(key: ValueKey('fake-home')),
    ));
    expect(find.byKey(const ValueKey('intro')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('fake-home')), findsOneWidget);
  });

  testWidgets('intro tagline appears word by word and stays visible',
      (widgetTester) async {
    tester = widgetTester;
    await tester.pumpWidget(PrivilegeApp(
      loginBuilder: (_) => const SizedBox(key: ValueKey('fake-login')),
      homeBuilder: (_) => const SizedBox(key: ValueKey('fake-home')),
    ));
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Eat'), findsOneWidget);
    expect(find.text('Stay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a slow session restore keeps the finished intro on screen',
      (widgetTester) async {
    tester = widgetTester;
    appState.restoring = true;
    await tester.pumpWidget(PrivilegeApp(
      loginBuilder: (_) => const SizedBox(key: ValueKey('fake-login')),
      homeBuilder: (_) => const SizedBox(key: ValueKey('fake-home')),
    ));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byKey(const ValueKey('intro')), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-login')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled animations use a 500 ms intro', (widgetTester) async {
    tester = widgetTester;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpWidget(PrivilegeApp(
      loginBuilder: (_) => const SizedBox(key: ValueKey('fake-login')),
      homeBuilder: (_) => const SizedBox(key: ValueKey('fake-home')),
    ));
    await tester.pump(const Duration(milliseconds: 499));
    expect(find.byKey(const ValueKey('intro')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('fake-login')), findsOneWidget);
  });

  testWidgets('intro does not reappear when the app resumes',
      (widgetTester) async {
    tester = widgetTester;
    await tester.pumpWidget(PrivilegeApp(
      loginBuilder: (_) => const SizedBox(key: ValueKey('fake-login')),
      homeBuilder: (_) => const SizedBox(key: ValueKey('fake-home')),
    ));
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 301));
    expect(find.byKey(const ValueKey('fake-login')), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const ValueKey('intro')), findsNothing);
    expect(find.byKey(const ValueKey('fake-login')), findsOneWidget);
  });
}
