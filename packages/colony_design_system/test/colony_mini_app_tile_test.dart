import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ColonyMiniAppTile shows label and invokes onPressed',
      (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColonyMiniAppTile(
            label: 'Habitat',
            icon: Icons.cottage_outlined,
            backgroundColor: ColonyMiniAppColors.habitat,
            onPressed: () => tapped++,
          ),
        ),
      ),
    );

    expect(find.text('Habitat'), findsOneWidget);
    await tester.tap(find.text('Habitat'));
    expect(tapped, 1);
  });

  testWidgets('ColonyQuickActionBar lays out four actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColonyQuickActionBar(
            actions: [
              ColonyQuickAction(
                label: 'A',
                icon: Icons.favorite_outline,
                onPressed: () {},
              ),
              ColonyQuickAction(
                label: 'B',
                icon: Icons.style_outlined,
                onPressed: () {},
              ),
              ColonyQuickAction(
                label: 'C',
                icon: Icons.inbox_outlined,
                onPressed: () {},
              ),
              ColonyQuickAction(
                label: 'D',
                icon: Icons.cottage_outlined,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });
}
