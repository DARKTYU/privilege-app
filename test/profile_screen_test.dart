import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/screens/profile.dart';
import 'package:privilege/ui.dart';

import 'progression_fake.dart';

void main() {
  for (final tier in ['Free', 'Silver', 'Gold']) {
    testWidgets(
        'profile displays $tier database membership without verification',
        (tester) async {
      final repository = FakeProgression()..tier = tier;
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: ProfileScreen(progressionRepository: repository)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Privilege $tier Member'), findsOneWidget);
      expect(find.textContaining('Drug-Free Verified'), findsNothing);
      expect(find.byIcon(Icons.verified_user), findsNothing);
    });
  }

  testWidgets('profile shows an error and retries membership loading',
      (tester) async {
    final repository = FakeProgression()..error = Exception('offline');
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(body: ProfileScreen(progressionRepository: repository)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Membership unavailable'), findsOneWidget);
    expect(find.textContaining('Privilege Pro Member'), findsNothing);
    repository
      ..error = null
      ..tier = 'Silver';
    await tester.tap(find.text('Retry membership'));
    await tester.pumpAndSettle();
    expect(find.text('Privilege Silver Member'), findsOneWidget);
  });

  testWidgets('profile opens the calorie profile sheet', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
          body: ProfileScreen(progressionRepository: FakeProgression())),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete your calorie profile'));
    await tester.tap(find.text('Complete your calorie profile'));
    await tester.pumpAndSettle();
    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('Choose birth date'), findsOneWidget);
  });
}
