import 'dart:ui' as ui;

import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NeedInspectBar reports tap and long-press', (tester) async {
    var taps = 0;
    var longs = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: Scaffold(
          body: NeedInspectBar(
            label: 'Sono',
            value: 0.4,
            onTap: () => taps++,
            onLongPress: () => longs++,
          ),
        ),
      ),
    );

    expect(find.text('SONO'), findsOneWidget);
    await tester.tap(find.text('SONO'));
    expect(taps, 1);
    await tester.longPress(find.text('SONO'));
    expect(longs, 1);
  });

  testWidgets('NeedInspectBar paints a solid rail without texture or ?', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: const Scaffold(
          body: Column(
            children: [
              NeedInspectBar(label: 'Sono', value: 0.4),
              NeedInspectBar(label: 'Foco', value: null),
            ],
          ),
        ),
      ),
    );

    expect(find.text('?'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('NeedInspectRailPainter fills a solid cyan trough', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const painter = NeedInspectRailPainter(
      value: 1.0,
      showTicks: false,
      showPointer: false,
      selected: false,
      railHeight: 16,
    );
    painter.paint(canvas, const Size(24, 16));
    final image = await recorder.endRecording().toImage(24, 16);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);
    // Sample the interior, away from the 1px border.
    const x = 12;
    const y = 8;
    final i = (y * 24 + x) * 4;
    final color = Color.fromARGB(
      bytes!.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
    expect(color, ColonyColors.needsFill);
  });
}
