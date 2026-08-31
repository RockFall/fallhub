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
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is NeedInspectRailPainter,
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('NeedInspectBar fillSlot does not overflow a short slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: const Scaffold(
          body: SizedBox(
            width: 220,
            height: 28,
            child: NeedInspectBar(label: 'Sono', value: 0.4, fillSlot: true),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('SONO'), findsOneWidget);
  });

  testWidgets('NeedInspectBar primary label is larger than compact', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: const Scaffold(
          body: Column(
            children: [
              NeedInspectBar(
                label: 'Sono',
                value: 0.4,
                scale: NeedInspectBarScale.primary,
              ),
              NeedInspectBar(
                label: 'Foco',
                value: 0.3,
                scale: NeedInspectBarScale.compact,
              ),
            ],
          ),
        ),
      ),
    );

    final sono = tester.widget<Text>(find.text('SONO'));
    final foco = tester.widget<Text>(find.text('FOCO'));
    expect(sono.style!.fontSize, 12);
    expect(foco.style!.fontSize, 9);
    expect(sono.style!.fontSize, greaterThan(foco.style!.fontSize!));
  });

  testWidgets('NeedInspectBar drag commits snapped scale', (tester) async {
    double? committed;
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: NeedInspectBar(
                label: 'Humor',
                value: 0.5,
                showPointer: true,
                onValueCommit: (v) => committed = v,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(NeedInspectBar), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(committed, isNotNull);
    expect(committed, greaterThan(0.5));
  });
}
