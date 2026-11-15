import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/screens/arena.dart';
import 'package:privilege/ui.dart';

void main() {
  testWidgets('Streak Arena shows activity state without mock arena data',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: AppPage(
          title: 'Streak Arena',
          builder: () => ArenaScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ArenaScreen), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('YOUR ACTIVITY STREAK'), findsOneWidget);
    expect(find.text('ARENA FEATURES'), findsOneWidget);
    expect(find.textContaining('coming in Stage 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
