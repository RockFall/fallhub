import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

ColonyAgendaBlock _block({
  required String id,
  required DateTime start,
  required DateTime end,
  bool allDay = false,
  bool visualOnly = false,
}) {
  return ColonyAgendaBlock(
    id: id,
    title: id,
    timeLabel: id,
    start: start,
    end: end,
    color: ColonyAgendaColors.meeting,
    allDay: allDay,
    visualOnly: visualOnly,
  );
}

void main() {
  final day = DateTime(2026, 8, 31);

  test('window follows first and last timed hours', () {
    final layout = layoutColonyAgendaRail(
      blocks: [
        _block(
          id: 'meet',
          start: DateTime(2026, 8, 31, 10),
          end: DateTime(2026, 8, 31, 11),
        ),
        _block(
          id: 'aula',
          start: DateTime(2026, 8, 31, 19),
          end: DateTime(2026, 8, 31, 21),
        ),
      ],
      day: day,
      canvasHeight: 280,
    );

    expect(layout.viewStartHour, 10);
    expect(layout.viewEndHour, 21);
    expect(layout.timed, hasLength(2));
    final meet = layout.timed.singleWhere((p) => p.block.id == 'meet');
    final aula = layout.timed.singleWhere((p) => p.block.id == 'aula');
    expect(aula.top, greaterThan(meet.top + 100));
    expect(layout.yAt(21), closeTo(280 - kColonyAgendaRailPad, 0.5));
    expect(layout.yAt(10), closeTo(kColonyAgendaRailPad, 0.5));
  });

  test('all-day birthday does not collapse the hour scale', () {
    final layout = layoutColonyAgendaRail(
      blocks: [
        _block(
          id: 'bday',
          start: DateTime(2026, 8, 31),
          end: DateTime(2026, 9, 1),
          allDay: true,
        ),
        _block(
          id: 'meet',
          start: DateTime(2026, 8, 31, 10),
          end: DateTime(2026, 8, 31, 11),
        ),
        _block(
          id: 'aula',
          start: DateTime(2026, 8, 31, 19),
          end: DateTime(2026, 8, 31, 21),
        ),
      ],
      day: day,
      canvasHeight: 280,
    );

    expect(layout.allDay.map((b) => b.id), ['bday']);
    expect(layout.viewStartHour, 10);
    expect(layout.viewEndHour, 21);
    final meet = layout.timed.singleWhere((p) => p.block.id == 'meet');
    final aula = layout.timed.singleWhere((p) => p.block.id == 'aula');
    expect(aula.top, greaterThan(meet.top + 100));
  });

  test('duration >= 20h is treated as all-day even without the flag', () {
    expect(
      colonyAgendaBlockIsAllDay(
        _block(
          id: 'holiday',
          start: DateTime(2026, 8, 31),
          end: DateTime(2026, 9, 1),
        ),
        day,
      ),
      isTrue,
    );
    expect(
      colonyAgendaBlockIsAllDay(
        _block(
          id: 'sleep',
          start: DateTime(2026, 8, 31),
          end: DateTime(2026, 8, 31, 7, 30),
        ),
        day,
      ),
      isFalse,
    );
  });

  test('overlapping meetings share lanes in the same cluster', () {
    final layout = layoutColonyAgendaRail(
      blocks: [
        _block(
          id: 'a',
          start: DateTime(2026, 8, 31, 10),
          end: DateTime(2026, 8, 31, 11),
        ),
        _block(
          id: 'b',
          start: DateTime(2026, 8, 31, 10, 30),
          end: DateTime(2026, 8, 31, 11, 30),
        ),
        _block(
          id: 'c',
          start: DateTime(2026, 8, 31, 16),
          end: DateTime(2026, 8, 31, 17),
        ),
      ],
      day: day,
      canvasHeight: 280,
    );
    final a = layout.timed.singleWhere((p) => p.block.id == 'a');
    final b = layout.timed.singleWhere((p) => p.block.id == 'b');
    final c = layout.timed.singleWhere((p) => p.block.id == 'c');
    expect(a.laneCount, 2);
    expect(b.laneCount, 2);
    expect(a.lane, isNot(b.lane));
    expect(c.laneCount, 1);
  });

  test('hour ticks include the window ends', () {
    expect(colonyAgendaHourTicks(10, 21), [10, 12, 14, 16, 18, 20, 21]);
    expect(colonyAgendaHourTicks(8, 20), [8, 12, 16, 20]);
  });
}
