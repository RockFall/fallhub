import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('timed cards spread between first and last hour', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final day = DateTime(2026, 8, 31);
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: Scaffold(
          backgroundColor: ColonyColors.void_,
          body: ColonyAgendaRail(
            day: day,
            now: DateTime(2026, 8, 31, 13, 25),
            maxHeight: 280,
            title: 'Agenda do dia',
            nowLabel: 'NOW',
            blocks: [
              ColonyAgendaBlock(
                id: 'bday',
                title: 'Aniversário',
                timeLabel: 'Dia todo',
                start: DateTime(2026, 8, 31),
                end: DateTime(2026, 9, 1),
                color: ColonyAgendaColors.social,
                allDay: true,
              ),
              ColonyAgendaBlock(
                id: 'meet',
                title: 'Reunião',
                timeLabel: '10:00 - 11:00',
                start: DateTime(2026, 8, 31, 10),
                end: DateTime(2026, 8, 31, 11),
                color: ColonyAgendaColors.meeting,
              ),
              ColonyAgendaBlock(
                id: 'aula',
                title: 'Aula criptografia',
                timeLabel: '19:00 - 21:00',
                start: DateTime(2026, 8, 31, 19),
                end: DateTime(2026, 8, 31, 21),
                color: ColonyAgendaColors.focus,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('ANIVERSÁRIO'), findsOneWidget);
    expect(find.text('REUNIÃO'), findsOneWidget);
    expect(find.text('AULA CRIPTOGRAFIA'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);

    final meet = tester.getRect(
      find.byKey(const ValueKey('agenda-block-meet')),
    );
    final aula = tester.getRect(
      find.byKey(const ValueKey('agenda-block-aula')),
    );
    expect(aula.top, greaterThan(meet.top + 80));
    expect(
      tester.getRect(find.byKey(const ValueKey('agenda-allday-bday'))).bottom,
      lessThan(meet.top),
    );
  });
}
