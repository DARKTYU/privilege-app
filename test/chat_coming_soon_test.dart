import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/screens/chat.dart';

void main() {
  testWidgets('chat clearly reports that messages are not sent',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatScreen()));
    expect(find.text('Coming soon'), findsOneWidget);
    expect(
        find.text(
            'AI chat, photo analysis and voice features are coming soon.'),
        findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('AI chat is coming soon. Your message was not sent.'),
        findsOneWidget);
  });
}
