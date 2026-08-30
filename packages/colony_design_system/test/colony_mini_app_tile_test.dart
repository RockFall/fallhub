import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ColonyMiniAppTile shows label and invokes onPressed',
      (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
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
        theme: ColonyTheme.dark(),
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

  testWidgets('ColonyNavTile and pip meter render', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: Scaffold(
          body: Column(
            children: [
              ColonyNavTile(
                label: 'Perfil',
                iconName: 'person',
                onPressed: () => taps++,
              ),
              const ColonyPipMeter(label: 'Humor', filled: 3),
              ColonyDateHeader(
                label: 'SEGUNDA-FEIRA, 19 DE MAIO',
                onMenu: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('PERFIL'), findsOneWidget);
    expect(find.textContaining('HUMOR'), findsOneWidget);
    expect(find.byType(ColonyIconButton), findsOneWidget);
    await tester.tap(find.text('PERFIL'));
    expect(taps, 1);
  });

  testWidgets('ColonyAgendaRail shows blocks and NOW', (tester) async {
    final day = DateTime(2026, 5, 19);
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: Scaffold(
          body: ColonyAgendaRail(
            day: day,
            now: DateTime(2026, 5, 19, 12, 4),
            title: 'Agenda do dia',
            nowLabel: 'NOW',
            blocks: [
              ColonyAgendaBlock(
                id: 'sleep',
                title: 'Sono',
                timeLabel: '00:00 - 07:30',
                start: DateTime(2026, 5, 19, 0),
                end: DateTime(2026, 5, 19, 7, 30),
                color: ColonyAgendaColors.sleep,
                iconName: 'moon',
              ),
              ColonyAgendaBlock(
                id: 'focus',
                title: 'Foco',
                timeLabel: '07:30 - 12:00',
                start: DateTime(2026, 5, 19, 7, 30),
                end: DateTime(2026, 5, 19, 12),
                color: ColonyAgendaColors.focus,
                iconName: 'crosshair',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('SONO'), findsOneWidget);
    expect(find.text('FOCO'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);
  });
}
