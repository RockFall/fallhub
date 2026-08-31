import 'dart:io';
import 'dart:ui' as ui;

import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _writePng(WidgetTester tester, Finder finder, String name) async {
  final dir = Directory('/opt/cursor/artifacts');
  if (!dir.existsSync()) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${dir.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _host({required Widget child}) {
  return MaterialApp(
    theme: ColonyTheme.dark(),
    home: Scaffold(
      backgroundColor: ColonyColors.void_,
      body: Padding(padding: const EdgeInsets.all(12), child: child),
    ),
  );
}

void main() {
  testWidgets('keyword icons and chrome on a mixed calendar day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final day = DateTime(2026, 8, 31);
    await tester.pumpWidget(
      _host(
        child: RepaintBoundary(
          key: const ValueKey('agenda-rail-shot'),
          child: ColonyAgendaRail(
            day: day,
            now: DateTime(2026, 8, 31, 13, 25),
            maxHeight: 320,
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
                iconName: 'cake',
                allDay: true,
              ),
              ColonyAgendaBlock(
                id: 'meet',
                title: 'Reunião',
                timeLabel: '10:00 - 11:00',
                start: DateTime(2026, 8, 31, 10),
                end: DateTime(2026, 8, 31, 11),
                color: ColonyAgendaColors.meeting,
                iconName: 'briefcase',
              ),
              ColonyAgendaBlock(
                id: 'war',
                title: 'War Room',
                timeLabel: '14:00 - 15:00',
                start: DateTime(2026, 8, 31, 14),
                end: DateTime(2026, 8, 31, 15),
                color: ColonyAgendaColors.meeting,
                iconName: 'radio',
              ),
              ColonyAgendaBlock(
                id: 'aula',
                title: 'Aula criptografia',
                timeLabel: '19:00 - 21:00',
                start: DateTime(2026, 8, 31, 19),
                end: DateTime(2026, 8, 31, 21),
                color: ColonyAgendaColors.meeting,
                iconName: 'cap',
                warning: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('ANIVERSÁRIO'), findsOneWidget);
    expect(find.text('REUNIÃO'), findsOneWidget);
    expect(find.text('AULA CRIPTOGRAFIA'), findsOneWidget);
    await _writePng(
      tester,
      find.byKey(const ValueKey('agenda-rail-shot')),
      'agenda_keyword_icons_rail.png',
    );
  });

  testWidgets(
    'reference day blocks keep moon / crosshair / cap / utensils / star',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final day = DateTime(2026, 5, 19);
      await tester.pumpWidget(
        _host(
          child: RepaintBoundary(
            key: const ValueKey('agenda-rail-ref'),
            child: ColonyAgendaRail(
              day: day,
              now: DateTime(2026, 5, 19, 12, 4),
              maxHeight: 360,
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
                ColonyAgendaBlock(
                  id: 'aula',
                  title: 'Aula',
                  timeLabel: '14:30 - 16:00',
                  start: DateTime(2026, 5, 19, 14, 30),
                  end: DateTime(2026, 5, 19, 16),
                  color: ColonyAgendaColors.meeting,
                  iconName: 'cap',
                  warning: true,
                ),
                ColonyAgendaBlock(
                  id: 'dinner',
                  title: 'Jantar',
                  timeLabel: '19:00 - 20:00',
                  start: DateTime(2026, 5, 19, 19),
                  end: DateTime(2026, 5, 19, 20),
                  color: ColonyAgendaColors.meal,
                  iconName: 'utensils',
                ),
                ColonyAgendaBlock(
                  id: 'free',
                  title: 'Livre',
                  timeLabel: '20:00 - 24:00',
                  start: DateTime(2026, 5, 19, 20),
                  end: DateTime(2026, 5, 19, 24),
                  color: ColonyAgendaColors.free,
                  iconName: 'star',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('SONO'), findsOneWidget);
      expect(find.text('FOCO'), findsOneWidget);
      expect(find.text('AULA'), findsOneWidget);
      expect(find.text('JANTAR'), findsOneWidget);
      expect(find.text('LIVRE'), findsOneWidget);
      expect(find.text('NOW'), findsOneWidget);
      await _writePng(
        tester,
        find.byKey(const ValueKey('agenda-rail-ref')),
        'agenda_day_icons_reference.png',
      );
    },
  );
}
