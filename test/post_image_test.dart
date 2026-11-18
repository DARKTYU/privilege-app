import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/widgets/post_image.dart';

void main() {
  testWidgets(
      'square image keeps its aspect ratio and opens zoomable fullscreen',
      (tester) async {
    final data = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 50, 50), Paint()..color = Colors.red);
      final image = await recorder.endRecording().toImage(50, 50);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      image.dispose();
      return bytes.buffer.asUint8List();
    });
    final provider = MemoryImage(data!);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: PostImage(image: provider),
          ),
        ),
      ),
    ));
    await tester.runAsync(
        () => precacheImage(provider, tester.element(find.byType(PostImage))));
    await tester.pumpAndSettle();
    final inline = tester.widget<Image>(find.byType(Image));
    expect(inline.fit, BoxFit.contain);
    final size = tester.getSize(find.byType(Image));
    expect(size.width, closeTo(size.height, 0.1));
    expect(size.height, lessThanOrEqualTo(400));
    await tester.tap(find.byType(PostImage));
    await tester.pumpAndSettle();
    expect(find.text('Post image'), findsOneWidget);
    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.maxScale, greaterThan(1));
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final transform = find.descendant(
        of: find.byType(InteractiveViewer), matching: find.byType(Transform));
    final before =
        tester.widget<Transform>(transform.first).transform.getMaxScaleOnAxis();
    final center = tester.getCenter(find.byType(InteractiveViewer));
    final first =
        await tester.startGesture(center + const Offset(-30, 0), pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(30, 0), pointer: 2);
    await first.moveTo(center + const Offset(-100, 0));
    await second.moveTo(center + const Offset(100, 0));
    await tester.pump();
    final after =
        tester.widget<Transform>(transform.first).transform.getMaxScaleOnAxis();
    expect(after, greaterThan(before));
    await first.up();
    await second.up();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('a tall image stays contained within the maximum height',
      (tester) async {
    final data = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 50, 200), Paint()..color = Colors.blue);
      final image = await recorder.endRecording().toImage(50, 200);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      image.dispose();
      return bytes.buffer.asUint8List();
    });
    final provider = MemoryImage(data!);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child:
                    SizedBox(width: 300, child: PostImage(image: provider))))));
    await tester.runAsync(
        () => precacheImage(provider, tester.element(find.byType(PostImage))));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Image)).height, lessThanOrEqualTo(400));
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
  });
}
