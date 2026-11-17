import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/screens/calories.dart';
import 'package:privilege/ui.dart';

void main() {
  testWidgets('Progress & Meals does not show the placeholder teams',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const Scaffold(
        body: DefaultTabController(
          length: 2,
          child: ProgressTab(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Active Meals & Burn Logs'), findsOneWidget);
    expect(find.text('Team Iron'), findsNothing);
    expect(find.text('Rivals'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
