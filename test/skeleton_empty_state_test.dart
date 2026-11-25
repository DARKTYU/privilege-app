import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/ui.dart';

void main() {
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      MaterialApp(
        theme: buildTheme(),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      );

  testWidgets('skeleton list shows placeholders and animates',
      (tester) async {
    await tester.pumpWidget(host(const SkeletonList(count: 3)));
    expect(find.byType(SkeletonBox), findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skeleton list is static when animations are disabled',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(host(const SkeletonList(count: 3)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('skeleton list does not overflow a small area', (tester) async {
    await tester.pumpWidget(
        host(const SizedBox(height: 120, child: SkeletonList(count: 6))));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('skeleton list works right to left', (tester) async {
    await tester.pumpWidget(
        host(const SkeletonList(), direction: TextDirection.rtl));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state shows title, message and a working button',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(EmptyState(
      icon: Icons.restaurant_menu_rounded,
      title: 'Nothing here yet',
      message: 'Add something to start.',
      actionLabel: 'Add',
      onAction: () => taps++,
    )));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Add something to start.'), findsOneWidget);
    await tester.tap(find.text('Add'));
    expect(taps, 1);
  });

  testWidgets('empty state without an action shows no button',
      (tester) async {
    await tester.pumpWidget(host(const EmptyState(
        icon: Icons.forum_outlined, title: 'No posts yet.')));
    await tester.pumpAndSettle();
    expect(find.text('No posts yet.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
