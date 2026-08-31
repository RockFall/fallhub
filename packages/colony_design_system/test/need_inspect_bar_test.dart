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
}
